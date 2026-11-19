import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Apply Flutter's plugin after the Android and Kotlin plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Owner-controlled release credentials: ignored local file or environment only.
// A missing configuration must never silently fall back to the debug key.
val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("key.properties")
if (releasePropertiesFile.isFile) {
    releasePropertiesFile.inputStream().use { releaseProperties.load(it) }
}
fun signingValue(property: String, environment: String): String? =
    providers.environmentVariable(environment).orNull?.takeIf { it.isNotBlank() }
        ?: releaseProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val releaseStorePath = signingValue("storeFile", "SANCTUARY_KEYSTORE_PATH")
val releaseStoreFile = releaseStorePath?.let { rootProject.file(it) }
val releaseStorePassword = signingValue("storePassword", "SANCTUARY_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "SANCTUARY_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "SANCTUARY_KEY_PASSWORD")
val releaseSigningReady = releaseStoreFile?.isFile == true &&
    releaseStorePassword != null && releaseKeyAlias != null && releaseKeyPassword != null
val allowUnsignedRelease = providers.gradleProperty("allowUnsignedRelease")
    .map { it == "true" }.getOrElse(false)

android {
    namespace = "com.sanctuary.relax_mindfulness"
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sanctuary.relax_mindfulness"
        // Flutter 3.38's supported Android baseline (Android 7.0).
        minSdk = 24
        // Play phone/tablet submission floor checked 2026-11-19.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.findByName("release")
        }
        debug {
            isMinifyEnabled = false
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        it.project.path == project.path && it.name.contains("Release")
    }
    if (buildsRelease && !releaseSigningReady && !allowUnsignedRelease) {
        throw GradleException(
            "Release signing is not configured. Supply owner-controlled credentials " +
                "in ignored android/key.properties or SANCTUARY_KEYSTORE_* / " +
                "SANCTUARY_KEY_* environment variables. See docs/NATIVE_RELEASE.md. " +
                "Compilation-only CI can explicitly opt into an UNSIGNED, " +
                "non-uploadable build with -PallowUnsignedRelease=true."
        )
    }
}

dependencies {
    // Required by flutter_local_notifications on modern Android toolchains.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

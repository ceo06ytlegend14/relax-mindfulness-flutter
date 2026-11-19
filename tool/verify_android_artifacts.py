#!/usr/bin/env python3
"""Inspect compilation-only artifacts; never signs, uploads or installs an app.

ELF/ZIP checks are static 16 KB compatibility evidence, not a device test.
"""
import os
import re
import struct
import subprocess
import sys
import zipfile
from pathlib import Path

from ci_report_tests import escape


ABI_MACHINES = {'arm64-v8a': 183, 'x86_64': 62}
PAGE_SIZE = 16384


def check_elf(header, abi, name):
    if len(header) < 64 or header[:4] != b'\x7fELF' or header[4] != 2 or header[5] not in (1, 2):
        raise ValueError(f'{name}: expected a valid 64-bit ELF header.')
    endian = '<' if header[5] == 1 else '>'
    machine = struct.unpack_from(endian + 'H', header, 18)[0]
    if machine != ABI_MACHINES[abi]:
        raise ValueError(f'{name}: ELF architecture does not match its ABI directory.')
    offset = struct.unpack_from(endian + 'Q', header, 32)[0]
    size, count = struct.unpack_from(endian + 'HH', header, 54)
    if size < 56 or not 0 < count <= 512 or offset + size * count > len(header):
        raise ValueError(f'{name}: invalid or truncated ELF program headers.')
    loads = 0
    for index in range(count):
        start = offset + size * index
        if struct.unpack_from(endian + 'I', header, start)[0] != 1:  # PT_LOAD
            continue
        loads += 1
        file_offset, address = struct.unpack_from(endian + 'QQ', header, start + 8)
        alignment = struct.unpack_from(endian + 'Q', header, start + 48)[0]
        if alignment < PAGE_SIZE or alignment & (alignment - 1) or (address - file_offset) % PAGE_SIZE:
            raise ValueError(f'{name}: a PT_LOAD segment is not 16 KB page compatible.')
    if not loads:
        raise ValueError(f'{name}: no loadable ELF segments were found.')


def check_archive(file, *, unsigned_bundle=False):
    checked = []
    with zipfile.ZipFile(file) as archive:
        if unsigned_bundle and any(re.match(r'^META-INF/[^/]+\.(?:RSA|DSA|EC|SF)$', entry.filename, re.I)
                                   for entry in archive.infolist()):
            raise ValueError('Compilation-only AAB unexpectedly contains a signing certificate/signature.')
        for entry in archive.infolist():
            match = re.search(r'(?:^|/)lib/(arm64-v8a|x86_64)/[^/]+\.so$', entry.filename)
            if match:
                with archive.open(entry) as source:
                    header = source.read(65536)  # Bounded; no extraction or whole-library allocation.
                check_elf(header, match[1], entry.filename)
                checked.append(entry.filename)
    if not any('/arm64-v8a/' in name for name in checked):
        raise ValueError(f'{Path(file).name}: no checked arm64-v8a native library was found.')
    return checked


def check_manifest(badging, tree):
    app_id = re.search(r"package: name='([^']+)'", badging)
    # Build-tools 36's AAPT2 uses minSdkVersion; legacy aapt used sdkVersion.
    # Neither compileSdkVersion nor a missing minimum may satisfy this gate.
    minimum = re.search(r"(?m)^[ \t]*(?:minSdkVersion|sdkVersion):'(\d+)'", badging)
    target = re.search(r"(?m)^[ \t]*targetSdkVersion:'(\d+)'", badging)
    if not app_id or app_id[1] != 'com.sanctuary.relax_mindfulness':
        raise ValueError('The compiled Android application ID changed unexpectedly.')
    if not minimum or int(minimum[1]) != 24 or not target or int(target[1]) < 36:
        raise ValueError('Compiled Android min/target SDK values do not meet the declared 24/36 baseline. '
                         f'Observed min={minimum[1] if minimum else "missing"}, '
                         f'target={target[1] if target else "missing"}.')
    # AAPT2 prints the full Android namespace URI; aapt prints its short prefix.
    billing = re.search(
        r'com\.google\.android\.play\.billingclient\.version[^\n]*\n\s*A:\s+'
        r'(?:android:|http://schemas\.android\.com/apk/res/android:)value[^\n]*?"(\d+)\.[^"\n]*"',
        tree,
    )
    if not billing or int(billing[1]) < 8:
        raise ValueError('Compiled manifest does not declare supported Play Billing Library 8+ metadata.')
    return int(target[1]), int(billing[1])


def run_tool(command):
    result = subprocess.run([str(part) for part in command], capture_output=True, text=True, check=False)
    if result.returncode:
        raise ValueError(f'{Path(command[0]).name} failed: {(result.stderr or result.stdout)[-3500:]}')
    return result.stdout


def main():
    apk = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/app/outputs/flutter-apk/app-debug.apk')
    bundle = Path(sys.argv[2] if len(sys.argv) > 2 else 'build/app/outputs/bundle/release/app-release.aab')
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT', ''))
    try:
        apk_libraries = check_archive(apk)
        bundle_libraries = check_archive(bundle, unsigned_bundle=True)
        tools = sdk / 'build-tools' / '36.0.0'
        run_tool([tools / 'zipalign', '-c', '-P', '16', '4', apk])
        badging = run_tool([tools / 'aapt2', 'dump', 'badging', apk])
        tree = run_tool([tools / 'aapt2', 'dump', 'xmltree', apk, '--file', 'AndroidManifest.xml'])
        target, billing = check_manifest(badging, tree)
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f'::error title=Android artifact verification failed::{escape(error)}')
        return 1
    summary = (f'Static artifacts verified: application ID preserved, target API {target}, Billing Library {billing}, '
               f'{len(apk_libraries)} APK / {len(bundle_libraries)} AAB 64-bit libraries with 16 KB ELF alignment, '
               'APK ZIP alignment, and an unsigned compilation-only AAB. Device/store validation is still required.')
    print(summary)
    print(f'::notice title=Android artifact evidence::{escape(summary)}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

// Native builds do not import web libraries. The web implementation only hides
// the DOM install entry while the Flutter full-screen player owns that corner.
export 'pwa_player_visibility_stub.dart'
    if (dart.library.html) 'pwa_player_visibility_web.dart';

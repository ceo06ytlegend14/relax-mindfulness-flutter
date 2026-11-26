// Native builds do not import web libraries. The web implementation only hides
// the DOM install entry while a player, chooser or wellbeing header owns it.
export 'pwa_player_visibility_stub.dart'
    if (dart.library.html) 'pwa_player_visibility_web.dart';

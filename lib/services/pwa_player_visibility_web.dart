// This conditional implementation targets the project's JavaScript web build.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void setPwaPlayerExpanded(bool expanded) {
  html.document.documentElement?.classes.toggle(
    'sanctuary-player-expanded',
    expanded,
  );
}

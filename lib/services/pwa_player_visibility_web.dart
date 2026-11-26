// This conditional implementation targets the project's JavaScript web build.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

// A pushed wellbeing page can cover another. Track owners so disposing one
// route cannot reveal the entry over a still-visible sibling/header.
final Set<Object> _wellbeingOwners = {};

void setPwaWellbeingPageVisible(Object owner, bool visible) {
  if (visible) {
    _wellbeingOwners.add(owner);
  } else {
    _wellbeingOwners.remove(owner);
  }
  html.document.documentElement?.classes.toggle(
    'sanctuary-wellbeing-open',
    _wellbeingOwners.isNotEmpty,
  );
}

final Set<Object> _playerOwners = {};
const _legacyPlayerOwner = 'legacy-player';

void setPwaPlayerExpanded(bool expanded, {Object? owner}) {
  final token = owner ?? _legacyPlayerOwner;
  if (expanded)
    _playerOwners.add(token);
  else
    _playerOwners.remove(token);
  // Swapping guided/ambient widgets can initialize the new owner before the
  // old one disposes. Its late cleanup must not reveal the install entry.
  html.document.documentElement?.classes.toggle(
    'sanctuary-player-expanded',
    _playerOwners.isNotEmpty,
  );
}

// Independent from the player class so closing either overlay cannot expose
// the install entry while the other overlay still owns the screen.
void setPwaSoundChooserOpen(bool open) {
  html.document.documentElement?.classes.toggle(
    'sanctuary-sound-chooser-open',
    open,
  );
}

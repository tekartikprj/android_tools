import 'package:flutter/material.dart' as legacy;
import 'package:material_ui/material_ui.dart';

/// Hosts a screen built on `package:flutter/material.dart` (a third party
/// package not yet on material_ui) in this material_ui app: the bridge
/// derives the flutter `Theme` and `MaterialLocalizations` such widgets look
/// up from the app theme and its localizations. Goes away with the last such
/// package (projects.dart `doc/material_ui_migration_plan.md` §4.4).
Widget legacyMaterialScreen(Widget screen) =>
    // A migration utility, deprecated on purpose from its first release.
    // ignore: deprecated_member_use
    MaterialUiCompatibilityBridge(child: screen);

/// Hosts a leaf widget built on `package:flutter/material.dart` inside a
/// material_ui screen: [legacyMaterialScreen] plus the flutter `Material`
/// ancestor such widgets require.
Widget legacyMaterialLeaf(Widget child) => legacyMaterialScreen(
  legacy.Material(type: legacy.MaterialType.transparency, child: child),
);

import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekartik_web_kiosk_app/legacy_material.dart';
import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';

/// Check passcode
Future<bool> checkPasscode(BuildContext context) async {
  var passcode = globalWebKioskDb.getGeneral().passcodeValue;

  var unlocked = false;
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      pageBuilder: (routeContext, _, _) => legacyMaterialScreen(
        ScreenLock(
          onCancelled: () => Navigator.of(routeContext).pop(),
          title: const Text('Enter code'),
          cancelButton: const Text('Cancel'),
          correctString: passcode,
          onUnlocked: () {
            unlocked = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    ),
  );
  return unlocked;
}

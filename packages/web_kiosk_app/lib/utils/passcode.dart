import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';

import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';

/// Check passcode
Future<bool> checkPasscode(BuildContext context) async {
  var passcode = globalWebKioskDb.getGeneral().passcodeValue;

  var unlocked = false;
  await screenLock(
    context: context,
    title: const Text('Enter code'),
    cancelButton: const Text('Cancel'),
    correctString: passcode,
    onUnlocked: () {
      unlocked = true;
      Navigator.of(context).pop();
    },
  );
  return unlocked;
}

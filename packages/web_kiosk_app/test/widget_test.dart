import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekartik_app_flutter_sembast/sembast.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';
import 'package:tekartik_web_kiosk_app/screen/settings_screen.dart';
import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';

class _FakeKiosk with TekartikKioskMockMixin implements TekartikKiosk {
  @override
  Future<PermissionInfo> getPermissionInfo() async => PermissionInfo()
    ..needOverlayPermission = false
    ..needPermissionForUsageStat = false;
}

void main() {
  testWidgets('settings passcode kept after rebuild', (tester) async {
    tekartikKioskPlugin = _FakeKiosk();
    var db = WebKioskDb(
      databaseFactory: databaseFactoryMemory,
      dbName: 'settings_passcode_test.db',
    );
    globalWebKioskDb = db;
    // Real async for the database
    await tester.runAsync(() async {
      await db.ready;
      await db.setGeneral(
        DbPrefsGeneral()
          ..url.v = 'http://stored'
          ..passcode.v = '1234',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            child: const Text('settings'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    String fieldText(int index) => tester
        .widget<TextField>(find.byType(TextField).at(index))
        .controller!
        .text;
    expect(fieldText(0), 'http://stored');
    expect(fieldText(1), '1234');

    await tester.enterText(find.byType(TextField).at(0), 'http://typed');
    await tester.enterText(find.byType(TextField).at(1), '9999');
    await tester.pump();

    // The keyboard showing up rebuilds the layout.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(fieldText(0), 'http://typed');
    expect(fieldText(1), '9999');

    // As does the record written by the on/off switch.
    await tester.runAsync(() => db.setGeneral(db.getGeneral()..on.v = true));
    await tester.pump();
    await tester.pump();
    expect(fieldText(0), 'http://typed');
    expect(fieldText(1), '9999');

    // Save
    await tester.tap(find.byIcon(Icons.check));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(SettingsScreen).evaluate().isEmpty) {
        break;
      }
    }
    expect(find.byType(SettingsScreen), findsNothing);
    var general = db.getGeneral();
    expect(general.url.v, 'http://typed');
    expect(general.passcode.v, '9999');
    expect(general.on.v, isTrue);
  });
}

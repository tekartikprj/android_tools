import 'package:festenao_theme/design.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/page/adb_device_page.dart';
import 'package:tk_adb_app/src/adb_device_shell.dart';

class _FakeAdbDeviceShell implements AdbDeviceShell {
  final packages = [
    AdbPackageInfo('com.example.a', 1, false),
    AdbPackageInfo('com.example.b', 2, false),
    AdbPackageInfo('com.example.c', 3, false),
    AdbPackageInfo('com.android.settings', 36, true),
  ];
  final uninstalled = <String>[];

  /// Packages whose uninstall fails.
  final failing = <String>{};

  @override
  Future<List<AdbPackageInfo>> listPackages() async => [...packages];

  @override
  Future<void> uninstall(String package) async {
    if (failing.contains(package)) {
      throw AdbUninstallException(package, 'Failure [DELETE_FAILED]');
    }
    uninstalled.add(package);
    packages.removeWhere((info) => info.name == package);
  }

  @override
  Future<void> reboot() async {}

  @override
  Future<void> killEmulator() async {}

  @override
  Future<String> command(String command) async => 'ran $command';
}

void main() {
  late _FakeAdbDeviceShell shell;

  setUp(() {
    shell = _FakeAdbDeviceShell();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // Every row built: the packages are a lazy list.
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: festenaoThemePresets.first.themeData(Brightness.light),
        home: BlocProvider(
          blocBuilder: () => AdbDevicePageBloc(
            adbDeviceInfo: AdbDeviceInfo()
              ..serial = 'emulator-5554'
              ..type = 'device',
            shell: shell,
            pollDelay: null,
          ),
          child: const AdbDevicePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> uninstallSelected(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Uninstall'));
    await tester.pumpAndSettle();
  }

  testWidgets('system packages hidden by default, shown with the chip', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('com.example.a'), findsOneWidget);
    expect(find.text('com.android.settings'), findsNothing);
    expect(find.text('Packages · 3'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'System'));
    await tester.pumpAndSettle();
    expect(find.text('com.android.settings'), findsOneWidget);
    expect(find.text('Packages · 4'), findsOneWidget);
  });

  testWidgets('uninstalls the selected packages after one confirmation', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.byTooltip('Select packages to uninstall'));
    await tester.pumpAndSettle();
    expect(find.text('Select packages'), findsOneWidget);

    await tester.tap(find.text('com.example.a'));
    await tester.tap(find.text('com.example.c'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);

    await uninstallSelected(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Uninstall 2 packages?'), findsOneWidget);
    await tester.tap(find.text('Uninstall 2'));
    await tester.pumpAndSettle();

    // No other confirmation.
    expect(find.byType(AlertDialog), findsNothing);
    expect(shell.uninstalled, ['com.example.a', 'com.example.c']);
    expect(find.text('2 packages uninstalled'), findsOneWidget);
    // Back to the normal mode, the list read again.
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('com.example.a'), findsNothing);
    expect(find.text('com.example.b'), findsOneWidget);
  });

  testWidgets('a long press selects, select all, a failure is reported', (
    tester,
  ) async {
    shell.failing.add('com.example.b');
    await pumpPage(tester);
    await tester.longPress(find.text('com.example.b'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Select all'));
    await tester.pump();
    expect(find.text('3 selected'), findsOneWidget);

    await uninstallSelected(tester);
    await tester.tap(find.text('Uninstall 3'));
    await tester.pumpAndSettle();
    expect(shell.uninstalled, ['com.example.a', 'com.example.c']);
    expect(find.textContaining('2 uninstalled, 1 failed'), findsOneWidget);
  });

  testWidgets('cancel keeps the packages and the selection', (tester) async {
    await pumpPage(tester);
    await tester.longPress(find.text('com.example.a'));
    await tester.pumpAndSettle();
    await uninstallSelected(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shell.uninstalled, isEmpty);
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('runs an adb command', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField).first, 'shell ls');
    await tester.tap(find.byTooltip('Run'));
    await tester.pumpAndSettle();
    expect(find.text('ran shell ls'), findsOneWidget);
  });
}

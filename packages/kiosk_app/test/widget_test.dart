import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';
import 'package:tekartik_kiosk_app/main.dart' as app;

class _FakeKiosk with TekartikKioskMockMixin implements TekartikKiosk {
  var installedCalls = 0;
  var processCalls = 0;

  /// The options saved by a previous start.
  var storedOptions = KioskOptions();
  BootReceiverOptions? bootOptions;
  KioskOptions? startedOptions;

  @override
  Future<PackageInfo> getPackageInfo({String? packageName}) async =>
      PackageInfo()..package = 'com.self';

  @override
  Future<KioskOptions> getKioskOptions() async => storedOptions;

  @override
  Future<void> setBootReceiverOptions(BootReceiverOptions options) async {
    bootOptions = options;
  }

  @override
  Future<void> startKioskMode({KioskOptions? options}) async {
    startedOptions = options;
  }

  @override
  Future<ModeInfo> getModeInfo() async => ModeInfo()
    ..kioskOn = false
    ..pinnedOn = false
    ..pinnedSupported = false;

  @override
  Future<BootReceiverOptions> getBootReceiverOptions() async =>
      BootReceiverOptions();

  @override
  Future<PermissionInfo> getPermissionInfo() async => PermissionInfo()
    ..needOverlayPermission = false
    ..needPermissionForUsageStat = false;

  @override
  Future<List<PackageInfo>> getInstalledPackageInfos() async {
    installedCalls++;
    return [
      PackageInfo()
        ..package = 'com.alpha'
        ..name = 'Alpha',
      PackageInfo()
        ..package = 'com.beta'
        ..name = 'Beta',
    ];
  }

  @override
  Future<List<RunningProcessInfo>> getRunningProcesses() async {
    processCalls++;
    return [
      RunningProcessInfo()
        ..processName = 'com.alpha'
        ..importance = 100,
    ];
  }
}

void main() {
  late _FakeKiosk fake;

  setUp(() {
    fake = _FakeKiosk();
    app.kiosk = fake;
  });

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Let the 2s status polling timer see the page is gone.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('apps tab search and status polling', (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pump();
    await tester.tap(find.text('Apps'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(fake.installedCalls, 1);

    await tester.enterText(find.byType(TextField), 'al');
    await tester.pump();
    // The search field stays, with its text and focus.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
    var editable = tester.state<EditableTextState>(find.byType(EditableText));
    expect(editable.textEditingValue.text, 'al');
    expect(editable.widget.focusNode.hasFocus, isTrue);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(fake.installedCalls, 1);

    // The status polling rebuilds every 2s and must not fetch again.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(fake.installedCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(editable.textEditingValue.text, 'al');

    await close(tester);
  });

  testWidgets('processes tab status polling and refresh', (tester) async {
    await tester.pumpWidget(const app.MyApp());
    await tester.pump();
    await tester.tap(find.text('Processes'));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 Running Processes'), findsOneWidget);
    expect(fake.processCalls, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(fake.processCalls, 1);
    expect(find.text('1 Running Processes'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh Process List'));
    await tester.pump();
    await tester.pump();
    expect(fake.processCalls, 2);
    expect(find.text('1 Running Processes'), findsOneWidget);

    await close(tester);
  });

  testWidgets('a toggle keeps the options being typed', (tester) async {
    fake.storedOptions = KioskOptions(
      package: 'com.stored',
      checkDelayMs: 500,
      allowedPackages: ['com.stored.allowed'],
    );
    await tester.pumpWidget(const app.MyApp());
    await tester.pump();
    final packageField = find.widgetWithText(TextField, 'Target Package Name');
    final delayField = find.widgetWithText(TextField, 'Watchdog Delay (ms)');
    String text(Finder field) =>
        tester.widget<TextField>(field).controller!.text;
    expect(text(packageField), 'com.stored');

    // Typed, not started yet.
    await tester.enterText(packageField, 'com.typed');
    await tester.enterText(delayField, '800');

    // Launch on boot: the package typed, and the fields keep what was typed.
    final boot = find.widgetWithText(SwitchListTile, 'Launch on Boot');
    await tester.ensureVisible(boot);
    await tester.tap(boot);
    await tester.pump();
    await tester.pump();
    expect(fake.bootOptions?.package, 'com.typed');
    expect(text(packageField), 'com.typed');
    expect(text(delayField), '800');

    // Started with what was typed.
    final start = find.text('START KIOSK');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    await tester.pump();
    expect(fake.startedOptions?.package, 'com.typed');
    expect(fake.startedOptions?.checkDelayMs, 800);

    await close(tester);
  });
}

import 'package:festenao_theme/design.dart';
import 'package:festenao_theme/kit.dart';
import 'package:festenao_theme/switcher.dart';
import 'package:tekartik_android_utils/bin/kill_emu.dart' as kill_emu;
import 'package:tk_adb_app/bloc/avd_manager_bloc.dart';
import 'package:tk_adb_app/page/adb_devices_page.dart';
import 'package:tk_adb_app/page/avd_manager_page.dart';
import 'package:tk_adb_app/src/app_prefs.dart';

import 'import.dart';

void main() async {
  await appMain();
}

Future<void> appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Poppins and JetBrains Mono under the names the presets ask for.
  await loadFestenaoFonts();
  await tkAdbPrefsInit();
  // The theme choice, read before the first frame.
  var themeController = tkAdbThemeController();
  await themeController.load();
  await initAndroidBuildEnvironment();
  // ignore: unnecessary_statements
  adbDevicesBloc;
  // ignore: unnecessary_statements
  avdManagerBloc;
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  /// The festenao theme chosen with the app bar button.
  final FestenaoThemeController themeController;

  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return FestenaoThemeBuilder(
      controller: themeController,
      builder: (context, controller) => MaterialApp(
        title: 'ADB tools',
        theme: controller.theme,
        darkTheme: controller.darkTheme,
        themeMode: controller.mode,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Runs [action] after a confirmation when [confirm] is given, says when
  /// it is done.
  Future<void> _command(
    BuildContext context,
    String label,
    Future<void> Function() action, {
    String? confirm,
  }) async {
    var messenger = ScaffoldMessenger.of(context);
    if (confirm != null) {
      var confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(label),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text('$label: done')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$label: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var t = context.festenao;
    const chevron = Padding(
      padding: EdgeInsets.only(right: 12),
      child: Icon(Icons.chevron_right),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADB tools'),
        actions: const [FestenaoThemeButton()],
      ),
      body: FkPage(
        children: [
          FkSectionTitle(
            'Devices',
            trailing: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => adbDevicesBloc.refresh(),
            ),
          ),
          ValueStreamBuilder<AdbDevicesBlocState>(
            stream: adbDevicesBloc.state,
            builder: (context, snapshot) => AdbDevicesCard(
              adbDeviceInfos: snapshot.data?.adbDeviceInfos,
              onOpened: adbDevicesBloc.refresh,
            ),
          ),
          const SizedBox(height: FestenaoSpace.xl),
          const FkSectionTitle('Tools'),
          FkListCard(
            children: [
              FkRow(
                leading: const FkIconBox(Icons.devices_other),
                title: 'AVD manager',
                subtitle: 'Start an emulator',
                trailing: chevron,
                onTap: () => goToAvdManagerPage(context),
              ),
              FkRow(
                leading: const FkIconBox(Icons.restart_alt),
                title: 'adb kill-server',
                subtitle: 'The server restarts on the next adb command',
                onTap: () => _command(
                  context,
                  'adb kill-server',
                  () => run('adb kill-server'),
                ),
              ),
              FkRow(
                leading: const FkIconBox(Icons.wifi),
                title: 'adb connect 192.168.1.23',
                subtitle: 'A device over the network',
                onTap: () => _command(
                  context,
                  'adb connect',
                  () => run('adb connect 192.168.1.23'),
                ),
              ),
              FkRow(
                leading: FkIconBox(Icons.power_settings_new, color: t.bad),
                title: 'Kill all emulators',
                titleColor: t.bad,
                onTap: () => _command(
                  context,
                  'Kill',
                  () => kill_emu.main(<String>[]),
                  confirm: 'Kill all the running emulators?',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

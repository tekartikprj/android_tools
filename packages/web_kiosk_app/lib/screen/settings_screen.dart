import 'package:flutter/material.dart';
import 'package:tekartik_app_flutter_widget/mini_ui.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';
import 'package:tekartik_web_kiosk_app/import/import_flutter.dart';
import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';
import 'package:tkcms_user_app/view/busy_screen_state_mixin.dart';
import 'package:tkcms_user_app/view/rx_busy_indicator.dart';

/// Settings screen
class SettingsScreen extends StatefulWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends AutoDisposeBaseState<SettingsScreen>
    with AutoDisposedBusyScreenStateMixin {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    () async {
      var info = await tekartikKioskPlugin.getPermissionInfo();
      // ignore: avoid_print
      print(info);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: globalWebKioskDb.onGeneral(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var dbPrefGeneral = snapshot.data!;
                  return ListView(
                    children: [
                      const SizedBox(height: 8),
                      ValueStreamBuilder(
                        stream: busyStream,
                        builder: (context, snapshot) {
                          var busy = snapshot.data ?? false;
                          return SwitchListTile(
                            value: dbPrefGeneral.on.v ?? false,
                            onChanged:
                                busy
                                    ? null
                                    : (on) async {
                                      await busyAction(() async {
                                        var info =
                                            await tekartikKioskPlugin
                                                .getPermissionInfo();
                                        // ignore: avoid_print
                                        print(info);
                                        if (on) {
                                          var pkgInfo =
                                              await tekartikKioskPlugin
                                                  .getPackageInfo();
                                          var info =
                                              await tekartikKioskPlugin
                                                  .getPermissionInfo();
                                          if (info.needPermissionForUsageStat) {
                                            info =
                                                await tekartikKioskPlugin
                                                    .requestPermissionForUsageStat();
                                            if (info
                                                .needPermissionForUsageStat) {
                                              if (context.mounted) {
                                                await muiSnack(
                                                  context,
                                                  'You need to enable usage stat permission',
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          if (info.needOverlayPermission) {
                                            info =
                                                await tekartikKioskPlugin
                                                    .requestOverlayPermission();
                                            if (info.needOverlayPermission) {
                                              if (context.mounted) {
                                                await muiSnack(
                                                  context,
                                                  'You need to enable overlay permission',
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          // ignore: avoid_print
                                          print(
                                            'setting boot receiver on ${pkgInfo.package}',
                                          );
                                          await tekartikKioskPlugin
                                              .setBootReceiverOptions(
                                                BootReceiverOptions(
                                                  package: pkgInfo.package,
                                                ),
                                              );
                                          //var overlayInfo = await tekartikKioskPlugin.requestOverlayPermission();
                                          //if (overlayInfo.)
                                        } else {
                                          await tekartikKioskPlugin
                                              .setBootReceiverOptions(
                                                BootReceiverOptions(),
                                              );
                                        }
                                        dbPrefGeneral.on.v = on;
                                        await sleep(1000);
                                        await globalWebKioskDb.setGeneral(
                                          dbPrefGeneral,
                                        );
                                      });
                                    },
                            title: const Text('Web kiosk enabled'),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              BusyIndicator(busy: busyStream),
            ],
          ),
        );
      },
    );
  }
}

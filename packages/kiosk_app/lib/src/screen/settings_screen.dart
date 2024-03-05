import 'package:flutter/material.dart';
import 'package:kiosk_app/main.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: const [EnableListTile()],
      ),
    );
  }
}

class EnableListTile extends StatefulWidget {
  const EnableListTile({super.key});

  @override
  State<EnableListTile> createState() => _EnableListTileState();
}

class _EnableListTileState extends State<EnableListTile> {
  bool? enabled;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootReceiverOptions>(
        future: kiosk.getBootReceiverOptions(),
        builder: (context, snapshot) {
          var options = snapshot.data;
          String? packageName;
          if (options != null) {
            packageName = options.package;
            enabled = packageName != null;
          }
          return SwitchListTile(
            title: (enabled ?? false)
                ? const Text('Enabled')
                : const Text('Disabled'),
            subtitle: packageName != null ? Text(packageName) : null,
            value: enabled ?? false,
            onChanged: enabled == null
                ? null
                : (value) {
                    setState(() {
                      enabled = value;
                    });
                    () async {
                      String? package;
                      if (value) {
                        var packageInfo = await kiosk.getPackageInfo();
                        //devPrint(packageInfo);
                        package = packageInfo.package;
                      }
                      await kiosk.setBootReceiverOptions(
                          BootReceiverOptions()..package = package);
                    }();
                  },
          );
        });
  }
}

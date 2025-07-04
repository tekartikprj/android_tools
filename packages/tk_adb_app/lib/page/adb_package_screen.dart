import 'package:festenao_common_flutter/common_utils_widget.dart';
import 'package:tk_adb_app/bloc/adb_package_screen_bloc.dart';
import 'package:tk_adb_app/import.dart';

class AdbPackageScreen extends StatefulWidget {
  const AdbPackageScreen({super.key});

  @override
  State<AdbPackageScreen> createState() => _AdbPackageScreenState();
}

class _AdbPackageScreenState extends State<AdbPackageScreen> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<AdbPackageScreenBloc>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Package ')),
      body: ValueStreamBuilder<AdbPackageScreenBlocState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var adbDeviceInfos = snapshot.data!.dumpsysPackageResult;
          var pkgInfo = adbDeviceInfos.packageInfo;
          return ListView(
            children: [
              BodyContainer(
                child: Column(
                  children: [
                    if (pkgInfo != null) ...[
                      ListTile(
                        title: Text('Package name: ${pkgInfo.packageName}'),
                      ),
                      ListTile(
                        title: Text('Version name: ${pkgInfo.versionName}'),
                      ),
                      ListTile(
                        title: Text('Version code: ${pkgInfo.versionCode}'),
                      ),
                      ListTile(
                        title: Text('Min SDK version: ${pkgInfo.minSdkVersion}'),
                      ),
                      ListTile(
                        title: Text('Target SDK version: ${pkgInfo.targetSdkVersion}'),
                      ),
                    ] else
                      const ListTile(title: Text('No package info found')),
                
                  ],
                
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> goToAdbPackageScreen(BuildContext context, {required String deviceSerial, required String packageName}) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        blocBuilder: () => AdbPackageScreenBloc(deviceSerial: deviceSerial, packageName: packageName),
        child: const AdbPackageScreen(),
      ),
    ),
  );
}

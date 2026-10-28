import 'package:festenao_theme/kit.dart';
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
      appBar: AppBar(title: const Text('Package')),
      body: ValueStreamBuilder<AdbPackageScreenBlocState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          var pkgInfo = snapshot.data?.dumpsysPackageResult.packageInfo;
          return FkPage(
            children: [
              FkHeader(title: bloc.packageName, subtitle: bloc.deviceSerial),
              if (snapshot.data == null)
                const FkCard(child: Center(child: CircularProgressIndicator()))
              else if (pkgInfo == null)
                const FkCard(
                  child: FkEmpty(
                    icon: Icons.help_outline,
                    message: 'No package info found',
                  ),
                )
              else
                FkListCard(
                  children: [
                    FkKeyValueRow(
                      label: 'Version name',
                      value: pkgInfo.versionName,
                    ),
                    FkKeyValueRow(
                      label: 'Version code',
                      value: '${pkgInfo.versionCode}',
                    ),
                    FkKeyValueRow(
                      label: 'Min SDK version',
                      value: '${pkgInfo.minSdkVersion}',
                    ),
                    FkKeyValueRow(
                      label: 'Target SDK version',
                      value: '${pkgInfo.targetSdkVersion}',
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> goToAdbPackageScreen(
  BuildContext context, {
  required String deviceSerial,
  required String packageName,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        blocBuilder: () => AdbPackageScreenBloc(
          deviceSerial: deviceSerial,
          packageName: packageName,
        ),
        child: const AdbPackageScreen(),
      ),
    ),
  );
}

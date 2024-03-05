import 'package:tk_adb_app/import.dart';

class AdbPackageInfo {
  final String name;
  final int versionCode;
  final bool system;

  AdbPackageInfo(this.name, this.versionCode, this.system);
}

class AdbDevicePageBlocState {
  final List<AdbPackageInfo> packages;

  AdbDevicePageBlocState({required this.packages});
}

class AdbDevicePageBloc extends BaseBloc {
  final AdbDeviceInfo adbDeviceInfo;

  String? get serial => adbDeviceInfo.serial;
  final _state = BehaviorSubject<AdbDevicePageBlocState>();

  AdbDevicePageBloc({required this.adbDeviceInfo}) {
    () async {
      while (!disposed) {
        refresh().unawait();
        await sleep(10000);
      }
    }();
  }

  ValueStream<AdbDevicePageBlocState> get state => _state;

  Future<List<AdbPackageInfo>> getInstalledPackages() async {
    var thirdPartyPackage = '-3';
    var systemPackage = '-s';
    var packages = <AdbPackageInfo>[];
    Future<void> addPackages(String filter) async {
      var lines = (await run(
              'adb -s $serial shell cmd package list packages $filter --show-versioncode'))
          .outLines;

      for (var line in lines) {
        var keyValues = line
            .split(' ')
            .map((e) => e.trim())
            .where((element) => element.isNotEmpty);
        String? name;
        int? versionCode;
        for (var keyValue in keyValues) {
          var parts = keyValue.split(':');
          var key = parts[0];
          if (parts.length > 1) {
            if (key == 'package') {
              name = parts[1];
            } else if (key == 'versionCode') {
              versionCode = int.tryParse(parts[1]);
            }
          }
        }
        if (name != null) {
          packages.add(
              AdbPackageInfo(name, versionCode ?? 0, filter == systemPackage));
        }
      }
    }

    await addPackages(systemPackage);
    await addPackages(thirdPartyPackage);
    packages.sort((p1, p2) {
      if (p1.system != p2.system) {
        if (p1.system) {
          return 1;
        } else {
          return -1;
        }
      }
      return p1.name.compareTo(p2.name);
    });
    return packages;
  }

  Future<void> refresh() async {
    var packages = await getInstalledPackages();
    _state.add(AdbDevicePageBlocState(packages: packages));
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }

  Future<void> deletePackage(String package) async {
    await run('adb -s $serial uninstall $package');
    await refresh();
  }
}

class AdbDevicePage extends StatefulWidget {
  const AdbDevicePage({super.key});

  @override
  State<AdbDevicePage> createState() => _AdbDevicePageState();
}

class _AdbDevicePageState extends State<AdbDevicePage> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<AdbDevicePageBloc>(context);
    var adbDeviceInfo = bloc.adbDeviceInfo;
    return Scaffold(
        appBar: AppBar(
          title: const Text('ADB Device Info'),
          actions: [
            IconButton(
                onPressed: () {
                  bloc.refresh();
                },
                icon: const Icon(Icons.read_more))
          ],
        ),
        body: ListView(children: [
          ListTile(
            title: Text(adbDeviceInfo.serial!),
          ),
          ListTile(
            title: const Text('Kill'),
            onTap: () {
              run('adb -s ${adbDeviceInfo.serial} emu kill');
            },
          ),
          ListTile(
            title: const Text('Reboot'),
            onTap: () {
              run('adb -s ${adbDeviceInfo.serial} reboot');
            },
          ),
          ListTile(
            title: const TextField(),
            subtitle: Text('adb -s ${adbDeviceInfo.serial}'),
            onTap: () {
              run('adb -s ${adbDeviceInfo.serial} reboot');
            },
          ),
          ValueStreamBuilder<AdbDevicePageBlocState>(
            stream: bloc.state,
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!.packages.map((package) {
                  var name = package.name;
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(
                        'versionCode: ${package.versionCode}${package.system ? ', system' : ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (package.system) const Text('S'),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            bloc.deletePackage(name);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          )
        ]));
  }
}

Future<void> goToAdbDevicePage(BuildContext context,
    {required AdbDeviceInfo adbDeviceInfo}) async {
  await Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
                blocBuilder: () =>
                    AdbDevicePageBloc(adbDeviceInfo: adbDeviceInfo),
                child: const AdbDevicePage(),
              )));
}

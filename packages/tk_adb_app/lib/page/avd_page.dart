import 'package:tk_adb_app/import.dart';

class AvdPageBlocState {
  final List<String> packages;

  AvdPageBlocState(this.packages);
}

class AvdPageBloc extends BaseBloc {
  final _state = BehaviorSubject<AvdPageBlocState>();
  final AvdInfo avdInfo;
  AvdPageBloc({required this.avdInfo}) {
    refresh();
  }

  void refresh() {}
  @override
  void dispose() {
    _state.close();
    super.dispose();
  }
}

class AvdPage extends StatefulWidget {
  const AvdPage({super.key});

  @override
  State<AvdPage> createState() => _AvdPageState();
}

class _AvdPageState extends State<AvdPage> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<AvdPageBloc>(context);
    var avdInfo = bloc.avdInfo;
    return Scaffold(
        appBar: AppBar(
          title: const Text('AVD Info'),
        ),
        body: ListView(children: [
          ListTile(
            title: Text(avdInfo.name!),
          ),
          ListTile(
            title: const Text('Start'),
            onTap: () {
              run('emulator -avd ${avdInfo.name}');
            },
          ),
          ListTile(
            title: const Text('Cold boot'),
            onTap: () {
              run('emulator -no-snapshot-load -avd ${avdInfo.name}');
            },
          )
        ]));
  }
}

Future<void> goToAvdPage(BuildContext context,
    {required AvdInfo avdInfo}) async {
  await Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (context) => BlocProvider(
                blocBuilder: () => AvdPageBloc(avdInfo: avdInfo),
                child: const AvdPage(),
              )));
}

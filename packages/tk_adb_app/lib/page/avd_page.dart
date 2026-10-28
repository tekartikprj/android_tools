import 'package:festenao_theme/kit.dart';
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

/// Starts the emulator of [avdInfo] (without its snapshot when [coldBoot]),
/// left running in the background.
void startAvd(
  BuildContext context, {
  required AvdInfo avdInfo,
  bool coldBoot = false,
}) {
  var name = avdInfo.name;
  unawaited(
    run('emulator ${coldBoot ? '-no-snapshot-load ' : ''}-avd $name')
        .then<void>(
          (_) {},
          onError: (Object e) {
            // ignore: avoid_print
            print('emulator $name: $e');
          },
        ),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(coldBoot ? 'Cold booting $name' : 'Starting $name')),
  );
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
      appBar: AppBar(title: const Text('AVD')),
      body: FkPage(
        children: [
          FkHeader(
            title: avdInfo.name,
            subtitle: avdInfo.device,
            actions: [
              FilledButton.icon(
                onPressed: () => startAvd(context, avdInfo: avdInfo),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    startAvd(context, avdInfo: avdInfo, coldBoot: true),
                icon: const Icon(Icons.ac_unit),
                label: const Text('Cold boot'),
              ),
            ],
          ),
          FkListCard(
            children: [
              if (avdInfo.device != null)
                FkKeyValueRow(label: 'Device', value: avdInfo.device!),
              if (avdInfo.target != null)
                FkKeyValueRow(label: 'Target', value: avdInfo.target!),
              if (avdInfo.skin != null)
                FkKeyValueRow(label: 'Skin', value: avdInfo.skin!),
              if (avdInfo.path != null)
                FkKeyValueRow(label: 'Path', value: avdInfo.path!),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> goToAvdPage(
  BuildContext context, {
  required AvdInfo avdInfo,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        blocBuilder: () => AvdPageBloc(avdInfo: avdInfo),
        child: const AvdPage(),
      ),
    ),
  );
}

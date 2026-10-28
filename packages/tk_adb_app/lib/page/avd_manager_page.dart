import 'package:festenao_theme/kit.dart';
import 'package:tk_adb_app/bloc/avd_manager_bloc.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/page/avd_page.dart';

class AvdManagerPageBlocState {
  final AvdManagerBlocState state;
  List<AvdInfo?> get avdInfos => state.avdInfos;

  AvdManagerPageBlocState({required this.state});
}

class AvdManagerPageBloc extends BaseBloc {
  final _state = BehaviorSubject<AvdManagerPageBlocState>();
  StreamSubscription? _blocSubscription;
  ValueStream<AvdManagerPageBlocState> get state => _state;
  AvdManagerPageBloc() {
    _blocSubscription = avdManagerBloc.state.listen((state) {
      _state.add(AvdManagerPageBlocState(state: state));
    });
    refresh();
  }
  @override
  void dispose() {
    _state.close();
    _blocSubscription?.cancel();
    super.dispose();
  }

  Future refresh() async {
    await avdManagerBloc.refresh();
  }
}

class AvdManagerPage extends StatefulWidget {
  const AvdManagerPage({super.key});

  @override
  State<AvdManagerPage> createState() => _AvdManagerPageState();
}

class _AvdManagerPageState extends State<AvdManagerPage> {
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<AvdManagerPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AVD Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => bloc.refresh(),
          ),
        ],
      ),
      body: ValueStreamBuilder<AvdManagerPageBlocState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          var avdInfos = snapshot.data?.avdInfos.nonNulls.toList();
          return FkPage(
            children: [
              if (avdInfos == null)
                const FkCard(child: Center(child: CircularProgressIndicator()))
              else if (avdInfos.isEmpty)
                const FkCard(
                  child: FkEmpty(
                    icon: Icons.devices_other,
                    message: 'No AVD, create one in Android Studio',
                  ),
                )
              else
                FkListCard(
                  children: [
                    for (var avdInfo in avdInfos)
                      FkRow(
                        leading: const FkIconBox(Icons.developer_mode),
                        title: avdInfo.name ?? '?',
                        subtitle: [
                          ?avdInfo.device,
                          ?avdInfo.target,
                        ].join(' · '),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Start',
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () =>
                                  startAvd(context, avdInfo: avdInfo),
                            ),
                            IconButton(
                              tooltip: 'Cold boot',
                              icon: const Icon(Icons.ac_unit),
                              onPressed: () => startAvd(
                                context,
                                avdInfo: avdInfo,
                                coldBoot: true,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => goToAvdPage(context, avdInfo: avdInfo),
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

Future<void> goToAvdManagerPage(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        blocBuilder: () => AvdManagerPageBloc(),
        child: const AvdManagerPage(),
      ),
    ),
  );
}

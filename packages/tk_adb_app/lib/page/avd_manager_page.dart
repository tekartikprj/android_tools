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
      ),
      body: ValueStreamBuilder<AvdManagerPageBlocState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          if (snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          var avdInfos = snapshot.data!.avdInfos;
          return ListView.builder(
            itemCount: avdInfos.length,
            itemBuilder: (context, index) {
              var avdInfo = avdInfos[index]!;
              return ListTile(
                title: Text(avdInfo.name!),
                onTap: () {
                  goToAvdPage(context, avdInfo: avdInfo);
                },
              );
            },
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
              )));
}

import 'package:tekartik_web_kiosk_app/import/import_bloc.dart';
import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';

/// State
class StartScreenBlocState {
  /// General prefs
  final DbPrefsGeneral dbPrefsGeneral;

  /// Constructor
  StartScreenBlocState({required this.dbPrefsGeneral});
}

/// Bloc
class StartScreenBloc extends AutoDisposeStateBaseBloc<StartScreenBlocState> {
  /// Constructor
  StartScreenBloc() {
    _init();
  }
  Future<void> _init() async {
    await globalWebKioskDb.ready;
    await for (var item in globalWebKioskDb.onGeneral()) {
      if (disposed) {
        break;
      }
      add(StartScreenBlocState(dbPrefsGeneral: item));
    }
  }
}

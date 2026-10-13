import 'package:flutter_test/flutter_test.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/src/bloc_poll.dart';

class _StateBloc extends BaseBloc {
  final state = BehaviorSubject<int>();

  @override
  void dispose() {
    state.close();
    super.dispose();
  }
}

void main() {
  const delay = Duration(milliseconds: 1);

  test('no state added after dispose', () async {
    var bloc = _StateBloc();
    var calls = 0;
    var completer = Completer<void>();
    blocPollRefresh(bloc, delay, () async {
      calls++;
      await completer.future;
      // Same guard as the app blocs refresh
      if (!bloc.disposed) {
        bloc.state.add(calls);
      }
    });
    expect(calls, 1);
    // Page closed while a refresh is running
    bloc.dispose();
    completer.complete();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, 1);
    expect(bloc.state.hasValue, isFalse);
  });

  test('error does not stop polling', () async {
    var bloc = _StateBloc();
    var errors = <Object>[];
    var calls = 0;
    var done = Completer<void>();
    blocPollRefresh(bloc, delay, () async {
      calls++;
      if (calls < 3) {
        throw StateError('offline');
      }
      bloc.dispose();
      done.complete();
    }, onError: errors.add);
    await done.future;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, 3);
    expect(errors, hasLength(2));
    expect(errors.first, isA<StateError>());
  });

  test('refreshes do not overlap', () async {
    var bloc = _StateBloc();
    var running = 0;
    var maxRunning = 0;
    var calls = 0;
    blocPollRefresh(bloc, delay, () async {
      calls++;
      running++;
      maxRunning = running > maxRunning ? running : maxRunning;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      running--;
    });
    await Future<void>.delayed(const Duration(milliseconds: 60));
    bloc.dispose();
    expect(calls, greaterThan(1));
    expect(maxRunning, 1);
  });
}

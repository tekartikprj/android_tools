import 'package:tk_adb_app/import.dart';

/// Calls [refresh] right away then every [delay] until [bloc] is disposed.
///
/// Refreshes never overlap and an error is reported to [onError] (printed by
/// default) without stopping the polling.
void blocPollRefresh(
  BaseBloc bloc,
  Duration delay,
  Future<void> Function() refresh, {
  void Function(Object error)? onError,
}) {
  () async {
    while (!bloc.disposed) {
      try {
        await refresh();
      } catch (e) {
        if (onError != null) {
          onError(e);
        } else {
          // ignore: avoid_print
          print('refresh error: $e');
        }
      }
      if (bloc.disposed) {
        break;
      }
      await sleep(delay.inMilliseconds);
    }
  }();
}

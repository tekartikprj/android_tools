import 'package:festenao_theme/kit.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/page/adb_device_page.dart';

/// The status pill of an adb device type (`device`, `offline`,
/// `unauthorized`).
FkStatusPill adbDeviceTypePill(String? type) => switch (type) {
  'device' => const FkStatusPill('online', status: FkStatus.ok, dot: true),
  'unauthorized' => const FkStatusPill('unauthorized', status: FkStatus.warn),
  _ => FkStatusPill(type ?? 'unknown'),
};

/// The connected devices in a list card, a ready one opens its page.
///
/// [adbDeviceInfos] null shows a progress.
class AdbDevicesCard extends StatelessWidget {
  final List<AdbDeviceInfo>? adbDeviceInfos;

  /// Called when back from a device page.
  final Future<void> Function()? onOpened;

  const AdbDevicesCard({
    super.key,
    required this.adbDeviceInfos,
    this.onOpened,
  });

  @override
  Widget build(BuildContext context) {
    var adbDeviceInfos = this.adbDeviceInfos;
    if (adbDeviceInfos == null) {
      return const FkCard(child: Center(child: CircularProgressIndicator()));
    }
    if (adbDeviceInfos.isEmpty) {
      return const FkCard(
        child: FkEmpty(
          icon: Icons.phonelink_off,
          message:
              'No device: start an emulator or plug a phone with USB '
              'debugging on',
        ),
      );
    }
    return FkListCard(
      children: [
        for (var adbDeviceInfo in adbDeviceInfos) _row(context, adbDeviceInfo),
      ],
    );
  }

  Widget _row(BuildContext context, AdbDeviceInfo adbDeviceInfo) {
    var serial = adbDeviceInfo.serial ?? '?';
    // Only a ready device (not offline or unauthorized) can be used
    var ready = adbDeviceInfo.type == 'device';
    return FkRow(
      leading: FkIconBox(
        serial.startsWith('emulator-')
            ? Icons.developer_mode
            : Icons.smartphone,
      ),
      title: adbDeviceInfo.model ?? serial,
      subtitle: [
        if (adbDeviceInfo.model != null) serial,
        ?adbDeviceInfo.product,
      ].join(' · '),
      badges: [adbDeviceTypePill(adbDeviceInfo.type)],
      trailing: ready
          ? const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            )
          : null,
      onTap: ready
          ? () async {
              await goToAdbDevicePage(context, adbDeviceInfo: adbDeviceInfo);
              await onOpened?.call();
            }
          : null,
    );
  }
}

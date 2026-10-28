import 'dart:math' as math;

import 'package:festenao_theme/design.dart';
import 'package:festenao_theme/kit.dart';
import 'package:tk_adb_app/import.dart';
import 'package:tk_adb_app/src/adb_device_shell.dart';
import 'package:tk_adb_app/src/app_prefs.dart';
import 'package:tk_adb_app/src/bloc_poll.dart';

import 'adb_package_screen.dart';

export 'package:tk_adb_app/src/adb_device_shell.dart' show AdbPackageInfo;

class AdbDevicePageBlocState {
  final List<AdbPackageInfo> packages;

  AdbDevicePageBlocState({required this.packages});
}

class AdbDevicePageBloc extends BaseBloc {
  final AdbDeviceInfo adbDeviceInfo;

  /// The adb commands on the device.
  final AdbDeviceShell shell;

  String? get serial => adbDeviceInfo.serial;
  final _state = BehaviorSubject<AdbDevicePageBlocState>();

  /// Reads the packages every [pollDelay], once when null.
  AdbDevicePageBloc({
    required this.adbDeviceInfo,
    AdbDeviceShell? shell,
    Duration? pollDelay = const Duration(seconds: 10),
  }) : shell = shell ?? AdbDeviceShellIo(adbDeviceInfo.serial!) {
    if (pollDelay == null) {
      unawaited(refresh());
    } else {
      blocPollRefresh(this, pollDelay, refresh);
    }
  }

  ValueStream<AdbDevicePageBlocState> get state => _state;

  Future<void> refresh() async {
    var packages = await shell.listPackages();
    if (!disposed) {
      _state.add(AdbDevicePageBlocState(packages: packages));
    }
  }

  @override
  void dispose() {
    _state.close();
    super.dispose();
  }

  /// Uninstalls [packages] one after the other, [onProgress] called with the
  /// count done after each, then reads the packages again. Returns the
  /// failures.
  Future<List<AdbUninstallException>> uninstallPackages(
    List<String> packages, {
    void Function(int done)? onProgress,
  }) async {
    var failures = <AdbUninstallException>[];
    for (var (index, package) in packages.indexed) {
      try {
        await shell.uninstall(package);
      } on AdbUninstallException catch (e) {
        failures.add(e);
      } catch (e) {
        failures.add(AdbUninstallException(package, '$e'));
      }
      onProgress?.call(index + 1);
    }
    await refresh();
    return failures;
  }
}

class AdbDevicePage extends StatefulWidget {
  const AdbDevicePage({super.key});

  @override
  State<AdbDevicePage> createState() => _AdbDevicePageState();
}

class _AdbDevicePageState extends State<AdbDevicePage> {
  /// Selection mode: rows toggle their package, uninstalled in one action.
  var _selecting = false;
  final _selected = <String>{};
  var _showSystem = tkAdbShowSystemPackages;
  final _filterController = TextEditingController();
  final _commandController = TextEditingController();
  String? _commandOutput;
  var _commandRunning = false;

  /// (done, total) while uninstalling.
  (int, int)? _uninstalling;

  AdbDevicePageBloc get _bloc => BlocProvider.of<AdbDevicePageBloc>(context);

  bool get _busy => _uninstalling != null;

  @override
  void dispose() {
    _filterController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  List<AdbPackageInfo> _visiblePackages(List<AdbPackageInfo> packages) {
    var filter = _filterController.text.trim().toLowerCase();
    return packages
        .where(
          (package) =>
              (_showSystem || !package.system) &&
              (filter.isEmpty || package.name.toLowerCase().contains(filter)),
        )
        .toList();
  }

  void _toggle(String package) {
    setState(() {
      if (!_selected.remove(package)) {
        _selected.add(package);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
  }

  void _setShowSystem(bool value, List<AdbPackageInfo> packages) {
    tkAdbShowSystemPackages = value;
    setState(() {
      _showSystem = value;
      if (!value) {
        // A hidden package is never uninstalled.
        _selected.removeAll(
          packages.where((package) => package.system).map((p) => p.name),
        );
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    Widget? content,
    required String action,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            var scheme = Theme.of(context).colorScheme;
            return AlertDialog(
              title: Text(title),
              content: content,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Uninstalls [packages] after a single confirmation listing them.
  Future<void> _uninstall(List<String> packages) async {
    var count = packages.length;
    var confirmed = await _confirm(
      title: count == 1
          ? 'Uninstall this package?'
          : 'Uninstall $count packages?',
      content: SizedBox(
        width: 480,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var package in packages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(package),
                  ),
              ],
            ),
          ),
        ),
      ),
      action: count == 1 ? 'Uninstall' : 'Uninstall $count',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _uninstalling = (0, count));
    var failures = await _bloc.uninstallPackages(
      packages,
      onProgress: (done) {
        if (mounted) {
          setState(() => _uninstalling = (done, count));
        }
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _uninstalling = null;
      _selecting = false;
      _selected.clear();
    });
    var done = count - failures.length;
    if (failures.isEmpty) {
      _snack(
        count == 1
            ? '${packages.first} uninstalled'
            : '$done packages uninstalled',
      );
    } else {
      _snack(
        '$done uninstalled, ${failures.length} failed: ${failures.join(', ')}',
      );
    }
  }

  Future<void> _runCommand() async {
    var command = _commandController.text.trim();
    if (command.isEmpty || _commandRunning) {
      return;
    }
    setState(() => _commandRunning = true);
    var output = await _bloc.shell.command(command);
    if (mounted) {
      setState(() {
        _commandRunning = false;
        _commandOutput = output;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var bloc = _bloc;
    return ValueStreamBuilder<AdbDevicePageBlocState>(
      stream: bloc.state,
      builder: (context, snapshot) {
        var packages = snapshot.data?.packages;
        // The selected packages still installed, in the list order.
        var selected = [
          ...?packages
              ?.map((package) => package.name)
              .where(_selected.contains),
        ];
        var visible = packages == null ? null : _visiblePackages(packages);
        return PopScope(
          canPop: !_selecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_busy) {
              _exitSelection();
            }
          },
          child: Scaffold(
            appBar: _selecting
                ? _selectionAppBar(selected, visible ?? const [])
                : _appBar(packages),
            body: _body(packages, visible),
          ),
        );
      },
    );
  }

  /// The page: header, command, then the packages built lazily (hundreds
  /// with the system ones), each row drawing its part of the card.
  Widget _body(List<AdbPackageInfo>? packages, List<AdbPackageInfo>? visible) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = FkWidth.of(constraints.maxWidth);
        // The FkPage padding, the content capped at 1240.
        var side = math.max(width.padding, (constraints.maxWidth - 1240) / 2);
        Widget packagesSliver;
        if (visible == null) {
          packagesSliver = const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (visible.isEmpty) {
          packagesSliver = SliverToBoxAdapter(
            child: FkCard(
              child: FkEmpty(
                icon: Icons.apps_outlined,
                message: _filterController.text.trim().isNotEmpty
                    ? 'No package matches the filter'
                    : 'No package installed',
              ),
            ),
          );
        } else {
          packagesSliver = SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) => _cardRow(
              index: index,
              count: visible.length,
              child: _packageRow(visible[index]),
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, width.padding / 2, side, 0),
              sliver: SliverList.list(
                children: [
                  if (!_selecting) ...[
                    _header(),
                    const FkSectionTitle('Command'),
                    _commandCard(),
                    const SizedBox(height: FestenaoSpace.xl),
                  ],
                  FkSectionTitle(
                    packages == null
                        ? 'Packages'
                        : 'Packages · ${visible!.length}',
                    trailing: FilterChip(
                      label: const Text('System'),
                      tooltip: 'Show the system packages',
                      selected: _showSystem,
                      onSelected: packages == null
                          ? null
                          : (value) => _setShowSystem(value, packages),
                    ),
                  ),
                  TextField(
                    controller: _filterController,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Filter the packages',
                      suffixIcon: _filterController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _filterController.clear()),
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: FestenaoSpace.m),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 0, side, width.padding * 2),
              sliver: packagesSliver,
            ),
          ],
        );
      },
    );
  }

  /// A row of the package list card. Each row draws its part of the card
  /// (its top line being the separator, the first and last rows rounded):
  /// a single rounded card thousands of pixels high is drawn with a band
  /// over its top (impeller).
  Widget _cardRow({
    required int index,
    required int count,
    required Widget child,
  }) {
    var t = context.festenao;
    var side = BorderSide(color: t.line);
    var radius = Radius.circular(t.radii.card);
    var first = index == 0;
    var last = index == count - 1;
    var borderRadius = BorderRadius.vertical(
      top: first ? radius : Radius.zero,
      bottom: last ? radius : Radius.zero,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.card,
        border: Border(
          top: side,
          left: side,
          right: side,
          bottom: last ? side : BorderSide.none,
        ),
        borderRadius: borderRadius,
      ),
      // Ink on the row, above the card, inside its corners.
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  PreferredSizeWidget? _progressBar() {
    var uninstalling = _uninstalling;
    if (uninstalling == null) {
      return null;
    }
    var (done, total) = uninstalling;
    return PreferredSize(
      preferredSize: const Size.fromHeight(4),
      child: LinearProgressIndicator(value: total == 0 ? null : done / total),
    );
  }

  AppBar _appBar(List<AdbPackageInfo>? packages) {
    return AppBar(
      title: const Text('Device'),
      actions: [
        IconButton(
          tooltip: 'Select packages to uninstall',
          icon: const Icon(Icons.checklist),
          onPressed: packages == null
              ? null
              : () => setState(() => _selecting = true),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => _bloc.refresh(),
        ),
      ],
      bottom: _progressBar(),
    );
  }

  AppBar _selectionAppBar(List<String> selected, List<AdbPackageInfo> visible) {
    var uninstalling = _uninstalling;
    var allVisibleSelected =
        visible.isNotEmpty &&
        visible.every((package) => _selected.contains(package.name));
    return AppBar(
      leading: IconButton(
        tooltip: 'Cancel the selection',
        icon: const Icon(Icons.close),
        onPressed: _busy ? null : _exitSelection,
      ),
      title: Text(
        uninstalling != null
            ? 'Uninstalling ${uninstalling.$1}/${uninstalling.$2}'
            : selected.isEmpty
            ? 'Select packages'
            : '${selected.length} selected',
      ),
      actions: [
        IconButton(
          tooltip: allVisibleSelected ? 'Deselect all' : 'Select all',
          icon: Icon(allVisibleSelected ? Icons.deselect : Icons.select_all),
          onPressed: _busy || visible.isEmpty
              ? null
              : () => setState(() {
                  var names = visible.map((package) => package.name);
                  if (allVisibleSelected) {
                    _selected.removeAll(names);
                  } else {
                    _selected.addAll(names);
                  }
                }),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: _busy || selected.isEmpty
                ? null
                : () => _uninstall(selected),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Uninstall'),
          ),
        ),
      ],
      bottom: _progressBar(),
    );
  }

  Widget _header() {
    var info = _bloc.adbDeviceInfo;
    var serial = info.serial!;
    var emulator = serial.startsWith('emulator-');
    return FkHeader(
      title: info.model ?? serial,
      subtitle: [
        if (info.model != null) serial,
        ?info.product,
        ?info.device,
      ].join(' · '),
      badge: const FkStatusPill('online', status: FkStatus.ok, dot: true),
      actions: [
        OutlinedButton.icon(
          onPressed: () async {
            if (await _confirm(title: 'Reboot $serial?', action: 'Reboot')) {
              await _bloc.shell.reboot();
              if (mounted) {
                _snack('Rebooting $serial');
              }
            }
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reboot'),
        ),
        if (emulator)
          OutlinedButton.icon(
            onPressed: () async {
              if (await _confirm(title: 'Kill $serial?', action: 'Kill')) {
                await _bloc.shell.killEmulator();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            icon: const Icon(Icons.power_settings_new),
            label: const Text('Kill'),
          ),
      ],
    );
  }

  Widget _commandCard() {
    var t = context.festenao;
    var mono = TextStyle(fontFamily: t.monoFamily);
    var output = _commandOutput;
    return FkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _commandController,
            enabled: !_commandRunning,
            style: mono,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  'adb -s ${_bloc.serial}',
                  style: mono.copyWith(color: t.ink2),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
              hintText: 'shell getprop ro.build.version.release',
              suffixIcon: IconButton(
                tooltip: 'Run',
                icon: const Icon(Icons.play_arrow),
                onPressed: _commandRunning ? null : _runCommand,
              ),
            ),
            onSubmitted: (_) => _runCommand(),
          ),
          if (_commandRunning) ...[
            const SizedBox(height: FestenaoSpace.m),
            const LinearProgressIndicator(),
          ],
          if (output != null) ...[
            const SizedBox(height: FestenaoSpace.m),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.sunk,
                borderRadius: BorderRadius.circular(t.radii.control),
              ),
              child: SelectableText(
                output.isEmpty ? '(no output)' : output,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: t.monoFamily),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _packageRow(AdbPackageInfo package) {
    var t = context.festenao;
    var name = package.name;
    return GestureDetector(
      key: ValueKey(name),
      onLongPress: _busy || _selecting
          ? null
          : () => setState(() {
              _selecting = true;
              _selected.add(name);
            }),
      child: FkRow(
        leading: _selecting
            ? Checkbox(
                value: _selected.contains(name),
                onChanged: _busy ? null : (_) => _toggle(name),
              )
            : FkIconBox(
                Icons.android,
                size: 36,
                color: package.system ? t.muted : null,
              ),
        title: name,
        subtitle: 'versionCode ${package.versionCode}',
        badges: [if (package.system) const FkStatusPill('system')],
        trailing: _selecting
            ? null
            : IconButton(
                tooltip: 'Uninstall',
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy ? null : () => _uninstall([name]),
              ),
        onTap: _selecting
            ? (_busy ? null : () => _toggle(name))
            : () => goToAdbPackageScreen(
                context,
                deviceSerial: _bloc.serial!,
                packageName: name,
              ),
      ),
    );
  }
}

Future<void> goToAdbDevicePage(
  BuildContext context, {
  required AdbDeviceInfo adbDeviceInfo,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => BlocProvider(
        blocBuilder: () => AdbDevicePageBloc(adbDeviceInfo: adbDeviceInfo),
        child: const AdbDevicePage(),
      ),
    ),
  );
}

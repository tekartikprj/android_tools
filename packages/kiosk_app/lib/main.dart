import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';

var kiosk = tekartikKioskPlugin;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiosk Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const KioskDashboardPage(),
    );
  }
}

class KioskDashboardPage extends StatefulWidget {
  const KioskDashboardPage({super.key});

  @override
  State<KioskDashboardPage> createState() => _KioskDashboardPageState();
}

class _KioskDashboardPageState extends State<KioskDashboardPage> {
  int _currentIndex = 0;

  // Controllers for configuration
  final _packageController = TextEditingController();
  final _delayController = TextEditingController(text: '400');
  final _allowedController = TextEditingController();

  // Kiosk/Pinned Mode State
  bool kioskOn = false;
  bool pinnedOn = false;
  bool pinnedSupported = false;

  // Boot options
  bool bootReceiverEnabled = false;

  // Permissions
  bool needUsageStat = true;
  bool needOverlay = true;

  // Logs and Recording
  bool _isRecording = false;
  Timer? _recordTimer;
  final List<String> _recordedLogs = [];
  String? _lastLoggedPackage;

  // Search filter for installed apps
  String _appSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadState();
    _startPermissionPolling();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _packageController.dispose();
    _delayController.dispose();
    _allowedController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    try {
      // Load current package info to fill default target package
      var selfInfo = await kiosk.getPackageInfo();
      if (_packageController.text.isEmpty) {
        _packageController.text = selfInfo.package ?? '';
      }

      // Load kiosk options
      var options = await kiosk.getKioskOptions();
      if (options.package != null) {
        _packageController.text = options.package!;
      }
      if (options.checkDelayMs != null) {
        _delayController.text = options.checkDelayMs.toString();
      }
      if (options.allowedPackages != null && options.allowedPackages!.isNotEmpty) {
        _allowedController.text = options.allowedPackages!.join(', ');
      }

      // Load mode info
      var modeInfo = await kiosk.getModeInfo();
      kioskOn = modeInfo.kioskOn;
      pinnedOn = modeInfo.pinnedOn;
      pinnedSupported = modeInfo.pinnedSupported;

      // Load boot receiver
      var bootOptions = await kiosk.getBootReceiverOptions();
      bootReceiverEnabled = bootOptions.package != null;

      // Load permissions
      var permissionInfo = await kiosk.getPermissionInfo();
      needUsageStat = permissionInfo.needPermissionForUsageStat;
      needOverlay = permissionInfo.needOverlayPermission;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading state: $e');
    }
  }

  void _startPermissionPolling() {
    // Poll permissions and status every 2 seconds to keep UI in sync
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        var permissionInfo = await kiosk.getPermissionInfo();
        var modeInfo = await kiosk.getModeInfo();
        if (mounted) {
          setState(() {
            needUsageStat = permissionInfo.needPermissionForUsageStat;
            needOverlay = permissionInfo.needOverlayPermission;
            kioskOn = modeInfo.kioskOn;
            pinnedOn = modeInfo.pinnedOn;
          });
        }
      } catch (_) {}
    });
  }

  // Starts the foreground package recorder
  void _toggleRecording(bool start) {
    if (start) {
      _recordedLogs.add('${_formatTime(DateTime.now())}: Recording started.');
      _lastLoggedPackage = null;
      _recordTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        try {
          var info = await kiosk.getCurrentRunningPackageInfo();
          var currentPkg = info.package;
          if (currentPkg != _lastLoggedPackage) {
            _lastLoggedPackage = currentPkg;
            if (mounted) {
              setState(() {
                _recordedLogs.add(
                  '${_formatTime(DateTime.now())}: Foreground changed to "$currentPkg"',
                );
              });
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _recordedLogs.add(
                '${_formatTime(DateTime.now())}: Error fetching package: $e',
              );
            });
          }
        }
      });
    } else {
      _recordTimer?.cancel();
      _recordedLogs.add('${_formatTime(DateTime.now())}: Recording stopped.');
    }
    setState(() {
      _isRecording = start;
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${(time.millisecond).toString().padLeft(3, '0')}';
  }

  Future<void> _startKiosk() async {
    try {
      var delay = int.tryParse(_delayController.text) ?? 400;
      var allowed = _allowedController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      var options = KioskOptions(
        package: _packageController.text.trim().isEmpty ? null : _packageController.text.trim(),
        checkDelayMs: delay,
        allowedPackages: allowed,
      );

      await kiosk.startKioskMode(options: options);
      await _loadState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiosk Mode started')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start Kiosk: $e')),
      );
    }
  }

  Future<void> _stopKiosk() async {
    try {
      await kiosk.stopKioskMode();
      await _loadState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiosk Mode stopped')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop Kiosk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiosk Console'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadState,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Recorder',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: 'Processes',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Apps',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildRecorderTab();
      case 2:
        return _buildProcessesTab();
      case 3:
        return _buildAppsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kiosk Status Header Card
          Card(
            color: kioskOn ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    kioskOn ? Icons.check_circle : Icons.cancel,
                    color: kioskOn ? Colors.green : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kioskOn ? 'KIOSK ACTIVE' : 'KIOSK INACTIVE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kioskOn ? Colors.green.shade900 : Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kioskOn
                              ? 'Native watchdog is monitoring and forcing the target app in foreground.'
                              : 'Kiosk mode is turned off.',
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pinned Mode Card
          if (pinnedSupported) ...[
            Card(
              child: SwitchListTile(
                title: const Text('Pinned Mode (Screen Pinning)'),
                subtitle: const Text('Start/Stop Android built-in Task Lock mode'),
                value: pinnedOn,
                onChanged: (value) async {
                  try {
                    if (value) {
                      await kiosk.startPinnedMode();
                    } else {
                      await kiosk.stopPinnedMode();
                    }
                    await _loadState();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update Pinned Mode: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Permissions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      needUsageStat ? Icons.warning : Icons.check_circle,
                      color: needUsageStat ? Colors.amber : Colors.green,
                    ),
                    title: const Text('Usage Statistics Permission'),
                    subtitle: Text(
                      needUsageStat
                          ? 'Needed to monitor active packages'
                          : 'Granted successfully',
                    ),
                    trailing: needUsageStat
                        ? ElevatedButton(
                            onPressed: () async {
                              await kiosk.requestPermissionForUsageStat();
                            },
                            child: const Text('Grant'),
                          )
                        : null,
                  ),
                  ListTile(
                    leading: Icon(
                      needOverlay ? Icons.warning : Icons.check_circle,
                      color: needOverlay ? Colors.amber : Colors.green,
                    ),
                    title: const Text('Overlay Permission'),
                    subtitle: Text(
                      needOverlay
                          ? 'Needed to draw overlays on system screens'
                          : 'Granted successfully',
                    ),
                    trailing: needOverlay
                        ? ElevatedButton(
                            onPressed: () async {
                              await kiosk.requestOverlayPermission();
                            },
                            child: const Text('Grant'),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Configuration Panel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiosk Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _packageController,
                    decoration: const InputDecoration(
                      labelText: 'Target Package Name',
                      hintText: 'e.g. com.example.tekartik_kiosk_app',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _delayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Watchdog Delay (ms)',
                      hintText: '400',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _allowedController,
                    decoration: const InputDecoration(
                      labelText: 'Extra Allowed Packages (comma separated)',
                      hintText: 'com.android.settings, com.android.systemui',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Launch on Boot'),
                    subtitle: const Text('Restart target package when device boots up'),
                    value: bootReceiverEnabled,
                    onChanged: (value) async {
                      try {
                        String? pkg;
                        if (value) {
                          pkg = _packageController.text.trim();
                          if (pkg.isEmpty) {
                            var selfInfo = await kiosk.getPackageInfo();
                            pkg = selfInfo.package;
                          }
                        }
                        await kiosk.setBootReceiverOptions(
                          BootReceiverOptions()..package = pkg,
                        );
                        await _loadState();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to set Boot Options: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Start/Stop Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: kioskOn ? null : _startKiosk,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START KIOSK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: kioskOn ? _stopKiosk : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP KIOSK'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecorderTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info header
          // Info header
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This screen polls the foreground package name in the background and records any change, letting you verify which apps gain focus and test kiosk watchdog performance.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Control row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleRecording(!_isRecording),
                  icon: Icon(_isRecording ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRecording ? 'PAUSE RECORDER' : 'START RECORDER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _recordedLogs.clear();
                  });
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('CLEAR LOGS'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable log list
          Expanded(
            child: Card(
              child: _recordedLogs.isEmpty
                  ? const Center(
                      child: Text('No logs recorded yet. Press START to record.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _recordedLogs.length,
                      reverse: true, // Show newest logs first
                      itemBuilder: (context, index) {
                        // Reverse index
                        var log = _recordedLogs[_recordedLogs.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessesTab() {
    return FutureBuilder<List<RunningProcessInfo>>(
      future: kiosk.getRunningProcesses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to get running processes: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        var processes = snapshot.data ?? [];
        // Sort processes by importance (lower is more active/foreground)
        processes.sort((a, b) => (a.importance ?? 1000).compareTo(b.importance ?? 1000));

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${processes.length} Running Processes',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => setState(() {}),
                    tooltip: 'Refresh Process List',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: processes.length,
                itemBuilder: (_, index) {
                  var proc = processes[index];
                  var isSelf = proc.packages?.contains(_packageController.text) ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: isSelf ? Colors.indigo.shade50 : null,
                    child: ListTile(
                      title: Text(
                        proc.processName ?? 'Unknown Process',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelf ? Colors.indigo.shade800 : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Importance: ${_getImportanceLabel(proc.importance)} (${proc.importance})'),
                          if (proc.packages != null && proc.packages!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Packages: ${proc.packages!.join(', ')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ]
                        ],
                      ),
                      trailing: proc.packages != null && proc.packages!.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.launch),
                              onPressed: () async {
                                try {
                                  await kiosk.launch(packageName: proc.packages!.first);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to launch: $e')),
                                  );
                                }
                              },
                              tooltip: 'Launch Package',
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getImportanceLabel(int? importance) {
    if (importance == null) return 'Unknown';
    if (importance <= 100) return 'Foreground App';
    if (importance <= 125) return 'Foreground Service';
    if (importance <= 200) return 'Visible';
    if (importance <= 230) return 'Perceptible';
    if (importance <= 300) return 'Service';
    if (importance <= 400) return 'Cached';
    return 'Background';
  }

  Widget _buildAppsTab() {
    return FutureBuilder<List<PackageInfo>>(
      future: kiosk.getInstalledPackageInfos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to get apps: ${snapshot.error}'));
        }

        var apps = snapshot.data ?? [];
        if (_appSearchQuery.isNotEmpty) {
          apps = apps
              .where((app) =>
                  (app.name?.toLowerCase().contains(_appSearchQuery.toLowerCase()) ?? false) ||
                  (app.package?.toLowerCase().contains(_appSearchQuery.toLowerCase()) ?? false))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search Installed Apps',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setState(() {
                    _appSearchQuery = val;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (_, index) {
                  var app = apps[index];
                  var isTarget = _packageController.text == app.package;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: app.user ?? false ? Colors.orange.shade100 : Colors.blue.shade100,
                      child: Text(
                        (app.name ?? '?').isNotEmpty ? app.name![0].toUpperCase() : '?',
                        style: TextStyle(
                          color: app.user ?? false ? Colors.orange.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ),
                    title: Text(app.name ?? 'Unknown App'),
                    subtitle: Text(app.package ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTarget)
                          const Chip(
                            label: Text('Target'),
                            backgroundColor: Colors.indigo,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            setState(() {
                              _packageController.text = app.package ?? '';
                              _currentIndex = 0; // go back to dashboard
                            });
                          },
                          tooltip: 'Set as target package',
                        ),
                        if (app.launchable ?? false)
                          IconButton(
                            icon: const Icon(Icons.launch),
                            onPressed: () async {
                              try {
                                await kiosk.launch(packageName: app.package);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to launch: $e')),
                                  );
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

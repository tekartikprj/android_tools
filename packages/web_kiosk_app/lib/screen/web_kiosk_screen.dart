import 'package:material_ui/material_ui.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';
import 'package:tekartik_kiosk/tekartik_kiosk_api.dart';
import 'package:tekartik_web_kiosk_app/screen/start_screen.dart';
import 'package:tekartik_web_kiosk_app/sembast/sembast.dart';
import 'package:tekartik_web_kiosk_app/utils/passcode.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Start screen
class WebKioskScreen extends StatefulWidget {
  /// Constructor
  const WebKioskScreen({super.key});

  @override
  State<WebKioskScreen> createState() => _WebKioskScreenState();
}

/// Test url
var _defaultUrl = 'https://www.google.com';

class _WebKioskScreenState extends State<WebKioskScreen> {
  var firstStart = true;

  var ready = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    () async {
      var prefs = globalWebKioskDb.getGeneral();
      _controller = WebViewController();
      await _controller.setJavaScriptMode(
        JavaScriptMode.unrestricted,
      ); // Enable JavaScript
      try {
        await _controller.loadRequest(Uri.parse(prefs.url.v ?? _defaultUrl));
      } catch (e) {
        // ignore: avoid_print
        print('error: $e');
        await _controller.loadRequest(Uri.parse(_defaultUrl));
      }
      if (prefs.on.v ?? false) {
        await tekartikKioskPlugin.startPinnedMode();
        await tekartikKioskPlugin.startKioskMode();
        await tekartikKioskPlugin.setBootReceiverOptions(
          BootReceiverOptions(
            package: (await tekartikKioskPlugin.getPackageInfo()).package,
          ),
        );
      }
      setState(() {
        ready = true;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) async {
        if (didPop) {
          return;
        }
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) {
            if (await checkPasscode(context)) {
              await tekartikKioskPlugin.stopKioskMode();
              await tekartikKioskPlugin.stopPinnedMode();
              await tekartikKioskPlugin.setBootReceiverOptions(
                BootReceiverOptions(),
              );
              if (context.mounted) {
                await popAllToStartScreen(context, noAutoStart: true);
              }
            }
          }
        }
      },
      child: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}

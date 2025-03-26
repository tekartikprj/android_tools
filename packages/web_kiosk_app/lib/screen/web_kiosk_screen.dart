import 'package:flutter/material.dart';
import 'package:tekartik_kiosk/tekartik_kiosk.dart';

import 'package:tekartik_web_kiosk_app/import/import_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'web_kiosk_screen_bloc.dart';

/// Start screen
class WebKioskScreen extends StatefulWidget {
  /// Constructor
  const WebKioskScreen({super.key});

  @override
  State<WebKioskScreen> createState() => _WebKioskScreenState();
}

/// Test url
var url = 'https://notelio.web.app'; // 'https://www.google.com';

class _WebKioskScreenState extends State<WebKioskScreen> {
  var firstStart = true;

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
          ..loadRequest(Uri.parse(url));
    () async {
      await tekartikKioskPlugin.startPinnedMode();
      await tekartikKioskPlugin.startKioskMode();
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
            Navigator.of(context).pop(result);
          }
        }
      },
      child: Scaffold(
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
    // ignore: dead_code
    var bloc = BlocProvider.of<WebKioskScreenBloc>(context);
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ValueStreamBuilder(
            stream: bloc.state,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 16),
                    IntrinsicWidth(
                      child: Column(
                        //crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Confdigure'.toUpperCase()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Start'.toUpperCase()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

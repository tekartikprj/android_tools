import 'package:flutter/material.dart';

import 'package:tekartik_web_kiosk_app/import/import_flutter.dart';
import 'package:tekartik_web_kiosk_app/screen/settings_screen.dart';
import 'package:tekartik_web_kiosk_app/screen/start_screen_bloc.dart';
import 'package:tekartik_web_kiosk_app/screen/web_kiosk_screen.dart';
import 'package:tekartik_web_kiosk_app/screen/web_kiosk_screen_bloc.dart';

/// Start screen
class StartScreen extends StatefulWidget {
  /// Constructor
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  var firstStart = true;
  @override
  Widget build(BuildContext context) {
    var bloc = BlocProvider.of<StartScreenBloc>(context);
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
                              onPressed: () {
                                _goToSettingsScreen(context);
                              },
                              child: Text('Configure'.toUpperCase()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () {
                                _goToWebKioskScreen(context);
                              },
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

  Future<void> _goToWebKioskScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (context) => BlocProvider(
              blocBuilder: () => WebKioskScreenBloc(),
              child: const WebKioskScreen(),
            ),
      ),
    );
  }

  Future<void> _goToSettingsScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SettingsScreen()),
    );
  }
}

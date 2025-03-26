import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tekartik_web_kiosk_app/screen/start_screen.dart';
import 'package:tekartik_web_kiosk_app/screen/start_screen_bloc.dart';
import 'package:tkcms_user_app/theme/theme1.dart';
import 'package:tkcms_user_app/tkcms_audi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WebKioskApp());
}

/// App
class WebKioskApp extends StatelessWidget {
  /// Constructor
  const WebKioskApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web kiosk',
      theme: themeData1(textTheme: GoogleFonts.poppinsTextTheme()),

      home: BlocProvider(
        blocBuilder: () => StartScreenBloc(),
        child: const StartScreen(),
      ),
    );
  }
}

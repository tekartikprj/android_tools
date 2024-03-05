// ignore_for_file: avoid_print

import 'package:tekartik_android_utils/bin/kill_emu.dart' as kill_emu;
import 'package:tk_adb_app/bloc/avd_manager_bloc.dart';
import 'package:tk_adb_app/page/adb_devices_page.dart';
import 'package:tk_adb_app/page/avd_manager_page.dart';

import 'import.dart';

void main() async {
  await appMain();
}

Future<void> appMain() async {
  await initAndroidBuildEnvironment();
  // ignore: unnecessary_statements
  adbDevicesBloc;
  // ignore: unnecessary_statements
  avdManagerBloc;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADB tools',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'ADB tools'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title!),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              title: const Text('AVD manager'),
              onTap: () => goToAvdManagerPage(context),
            ),
            ListTile(
              title: const Text('ADB devices'),
              onTap: () => goToAdbDevicesPage(context),
            ),
            ListTile(
              title: const Text('adb kill-server'),
              onTap: () async {
                await run('adb kill-server');
                print('done');
              },
            ),
            ListTile(
              title: const Text('adb connect 192.168.1.23'),
              onTap: () async {
                await run('adb connect 192.168.1.23');
                print('done');
              },
            ),
            ListTile(
              title: const Text('kill all emu'),
              onTap: () async {
                await kill_emu.main(<String>[]);
                print('done');
              },
            ),
          ],
        ),
      ),
    );
  }
}
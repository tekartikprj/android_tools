import 'build_menu.dart';

Future<void> main(List<String> arguments) async {
  await appLauncher.buildIfNeededAndRun(arguments: arguments, rebuild: true);
}

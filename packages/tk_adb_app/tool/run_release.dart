import 'build_menu.dart';

/// Runs the deployed release, built first when missing.
Future<void> main(List<String> arguments) async {
  await appLauncher.buildIfNeededAndRun(arguments: arguments);
}

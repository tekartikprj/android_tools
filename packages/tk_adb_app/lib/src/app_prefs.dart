import 'package:festenao_theme/design.dart';
import 'package:festenao_theme/switcher.dart';
import 'package:tekartik_app_prefs/app_prefs.dart';

/// The festenao presets the app offers, the first being the default: the
/// neutral one, a calm tool, a dark one and the high contrast one.
final tkAdbThemePresets = festenaoThemePresetsByIds([
  'festenao',
  'ardoise',
  'obsidian',
  'contrast',
]);

/// The app preferences (theme, system packages shown), null until
/// [tkAdbPrefsInit] (and in tests): the defaults then apply.
Prefs? tkAdbPrefs;

/// The key of the theme choice.
const tkAdbThemePrefsKey = 'theme';

/// The key of the system packages shown in the device page.
const tkAdbShowSystemPackagesPrefsKey = 'show_system_packages';

/// Opens [tkAdbPrefs].
Future<void> tkAdbPrefsInit() async {
  tkAdbPrefs = await getPrefsFactory(packageName: 'com.tekartik.tk_adb_app')
      .openPreferences('tk_adb_app_prefs.db');
}

/// The theme of the app, chosen among [tkAdbThemePresets], kept in
/// [tkAdbPrefs].
FestenaoThemeController tkAdbThemeController() => FestenaoThemeController(
  presets: tkAdbThemePresets,
  store: FestenaoThemeStore.from(
    read: () => tkAdbPrefs?.getString(tkAdbThemePrefsKey),
    write: (value) => tkAdbPrefs?.setString(tkAdbThemePrefsKey, value),
  ),
);

/// True when the device page lists the system packages too.
bool get tkAdbShowSystemPackages =>
    tkAdbPrefs?.getBool(tkAdbShowSystemPackagesPrefsKey) ?? false;

set tkAdbShowSystemPackages(bool value) =>
    tkAdbPrefs?.setBool(tkAdbShowSystemPackagesPrefsKey, value);

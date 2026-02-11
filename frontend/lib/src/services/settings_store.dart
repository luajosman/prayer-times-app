import 'package:frontend/src/core/prayer_constants.dart';
import 'package:frontend/src/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const String _methodKey = 'settings.method';
  static const String _schoolKey = 'settings.school';
  static const String _useDeviceLocationKey = 'settings.useDeviceLocation';
  static const String _manualLatitudeKey = 'settings.manualLatitude';
  static const String _manualLongitudeKey = 'settings.manualLongitude';
  static const String _manualLabelKey = 'settings.manualLabel';

  Future<AppSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final int method = prefs.getInt(_methodKey) ?? AppSettings.defaults.method;
    final int school = prefs.getInt(_schoolKey) ?? AppSettings.defaults.school;
    final bool useDeviceLocation =
        prefs.getBool(_useDeviceLocationKey) ??
            AppSettings.defaults.useDeviceLocation;

    final double manualLatitude =
        prefs.getDouble(_manualLatitudeKey) ?? fallbackLatitude;
    final double manualLongitude =
        prefs.getDouble(_manualLongitudeKey) ?? fallbackLongitude;
    final String manualLabel =
        prefs.getString(_manualLabelKey) ?? AppSettings.defaults.manualLabel;

    return AppSettings(
      method: methodLabels.containsKey(method) ? method : AppSettings.defaults.method,
      school: schoolLabels.containsKey(school) ? school : AppSettings.defaults.school,
      useDeviceLocation: useDeviceLocation,
      manualLatitude: manualLatitude,
      manualLongitude: manualLongitude,
      manualLabel: manualLabel,
    );
  }

  Future<void> save(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_methodKey, settings.method);
    await prefs.setInt(_schoolKey, settings.school);
    await prefs.setBool(_useDeviceLocationKey, settings.useDeviceLocation);
    await prefs.setDouble(_manualLatitudeKey, settings.manualLatitude);
    await prefs.setDouble(_manualLongitudeKey, settings.manualLongitude);
    await prefs.setString(_manualLabelKey, settings.manualLabel);
  }
}

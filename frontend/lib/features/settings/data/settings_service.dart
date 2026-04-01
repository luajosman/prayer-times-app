import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int method; // AlAdhan method
  final int school; // 0 = Shafi, 1 = Hanafi

  const AppSettings({required this.method, required this.school});

  AppSettings copyWith({int? method, int? school}) =>
      AppSettings(method: method ?? this.method, school: school ?? this.school);
}

class SettingsService {
  static const _kMethod = 'settings.method';
  static const _kSchool = 'settings.school';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getInt(_kMethod) ?? 2;
    final school = prefs.getInt(_kSchool) ?? 0;
    return AppSettings(method: method, school: school);
  }

  Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMethod, s.method);
    await prefs.setInt(_kSchool, s.school);
  }
}

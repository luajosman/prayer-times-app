import 'package:frontend/src/core/prayer_constants.dart';

class AppSettings {
  const AppSettings({
    required this.method,
    required this.school,
    required this.useDeviceLocation,
    required this.manualLatitude,
    required this.manualLongitude,
    required this.manualLabel,
  });

  final int method;
  final int school;
  final bool useDeviceLocation;
  final double manualLatitude;
  final double manualLongitude;
  final String manualLabel;

  AppSettings copyWith({
    int? method,
    int? school,
    bool? useDeviceLocation,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLabel,
  }) {
    return AppSettings(
      method: method ?? this.method,
      school: school ?? this.school,
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
      manualLatitude: manualLatitude ?? this.manualLatitude,
      manualLongitude: manualLongitude ?? this.manualLongitude,
      manualLabel: manualLabel ?? this.manualLabel,
    );
  }

  static const AppSettings defaults = AppSettings(
    method: 2,
    school: 0,
    useDeviceLocation: true,
    manualLatitude: fallbackLatitude,
    manualLongitude: fallbackLongitude,
    manualLabel: 'Manuelle Koordinaten',
  );
}

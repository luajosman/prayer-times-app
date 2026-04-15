import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/utils/prayer_time_utils.dart';

PrayerPhase resolvePrayerPhase(Map<String, String> times, DateTime now) {
  final DateTime? fajr = _parse(times['Fajr'], now);
  final DateTime? sunrise = _parse(times['Sunrise'], now);
  final DateTime? dhuhr = _parse(times['Dhuhr'], now);
  final DateTime? asr = _parse(times['Asr'], now);
  final DateTime? maghrib = _parse(times['Maghrib'], now);
  final DateTime? isha = _parse(times['Isha'], now);

  if (fajr == null ||
      sunrise == null ||
      dhuhr == null ||
      asr == null ||
      maghrib == null ||
      isha == null) {
    return fallbackPrayerPhaseFor(now);
  }

  if (now.isBefore(fajr)) {
    return PrayerPhase.fajr;
  }
  if (now.isBefore(sunrise)) {
    return PrayerPhase.fajr;
  }
  if (now.isBefore(dhuhr)) {
    return PrayerPhase.sunrise;
  }
  if (now.isBefore(asr)) {
    return PrayerPhase.dhuhr;
  }
  if (now.isBefore(maghrib)) {
    return PrayerPhase.asr;
  }
  if (now.isBefore(isha)) {
    return PrayerPhase.maghrib;
  }

  return PrayerPhase.isha;
}

PrayerPhase fallbackPrayerPhaseFor(DateTime now) {
  final int hour = now.hour;
  if (hour < 6) {
    return PrayerPhase.fajr;
  }
  if (hour < 11) {
    return PrayerPhase.sunrise;
  }
  if (hour < 15) {
    return PrayerPhase.dhuhr;
  }
  if (hour < 19) {
    return PrayerPhase.asr;
  }
  if (hour < 22) {
    return PrayerPhase.maghrib;
  }
  return PrayerPhase.isha;
}

DateTime? _parse(String? raw, DateTime now) {
  if (raw == null) {
    return null;
  }
  return parseApiTimeToDateTime(raw, now);
}

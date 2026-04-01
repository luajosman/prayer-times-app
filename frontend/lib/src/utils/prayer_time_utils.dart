import 'package:frontend/src/core/prayer_constants.dart';

class PrayerEvent {
  const PrayerEvent({
    required this.key,
    required this.at,
  });

  final String key;
  final DateTime at;
}

DateTime? parseApiTimeToDateTime(String rawTime, DateTime baseDate) {
  final RegExpMatch? match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(rawTime);
  if (match == null) {
    return null;
  }

  final int? hour = int.tryParse(match.group(1) ?? '');
  final int? minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }

  return DateTime(
    baseDate.year,
    baseDate.month,
    baseDate.day,
    hour,
    minute,
  );
}

PrayerEvent? findNextPrayer(Map<String, String> times, DateTime now) {
  for (final String prayerName in dailyPrayerOrder) {
    final String? raw = times[prayerName];
    if (raw == null) {
      continue;
    }

    final DateTime? parsed = parseApiTimeToDateTime(raw, now);
    if (parsed == null) {
      continue;
    }

    if (!parsed.isBefore(now)) {
      return PrayerEvent(key: prayerName, at: parsed);
    }
  }

  final String? nextFajrRaw = times['Fajr'];
  if (nextFajrRaw == null) {
    return null;
  }

  final DateTime tomorrow = now.add(const Duration(days: 1));
  final DateTime? nextFajr = parseApiTimeToDateTime(nextFajrRaw, tomorrow);
  if (nextFajr == null) {
    return null;
  }

  return PrayerEvent(key: 'Fajr', at: nextFajr);
}

String formatCountdown(Duration duration) {
  if (duration.isNegative) {
    return 'Jetzt';
  }

  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  final int seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} h';
  }

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min';
}

Map<String, String> filterPrayerTimes(Map<String, String> source) {
  final Map<String, String> filtered = <String, String>{};
  for (final String prayerName in canonicalPrayerOrder) {
    final String? value = source[prayerName];
    if (value != null) {
      filtered[prayerName] = value;
    }
  }
  return filtered;
}

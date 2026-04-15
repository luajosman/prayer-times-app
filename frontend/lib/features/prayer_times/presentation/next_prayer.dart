class NextPrayer {
  final String name;
  final DateTime at;

  NextPrayer(this.name, this.at);
}

NextPrayer computeNextPrayer(Map<String, String> times) {
  final now = DateTime.now();

  DateTime toToday(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return DateTime(now.year, now.month, now.day, h, m);
  }

  final order = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

  for (final k in order) {
    final v = times[k];
    if (v == null) continue;
    final dt = toToday(v);
    if (dt.isAfter(now)) return NextPrayer(k, dt);
  }

  final fajr = times['fajr'] ?? '05:00';
  final t = fajr.split(':');
  final h = int.parse(t[0]);
  final m = int.parse(t[1]);

  final tomorrow = DateTime(now.year, now.month, now.day + 1, h, m);
  return NextPrayer('fajr', tomorrow);
}

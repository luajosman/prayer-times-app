class PrayerTimesResponse {
  const PrayerTimesResponse({
    required this.date,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.school,
    required this.times,
  });

  final String date;
  final String timezone;
  final double latitude;
  final double longitude;
  final int method;
  final int school;
  final Map<String, String> times;

  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> location =
        (json['location'] as Map<String, dynamic>? ?? <String, dynamic>{});

    final dynamic rawTimes = json['times'];
    final Map<String, String> normalizedTimes = <String, String>{};
    if (rawTimes is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in rawTimes.entries) {
        normalizedTimes[entry.key] = entry.value?.toString() ?? '--:--';
      }
    }

    return PrayerTimesResponse(
      date: (json['date'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lon'] as num?)?.toDouble() ?? 0,
      method: (json['method'] as num?)?.toInt() ?? 2,
      school: (json['school'] as num?)?.toInt() ?? 0,
      times: normalizedTimes,
    );
  }
}

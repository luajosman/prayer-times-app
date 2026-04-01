class PrayerTimesModel {
  final String date;
  final String? timezone;
  final double lat;
  final double lon;
  final int method;
  final int school;
  final Map<String, String> times;

  PrayerTimesModel({
    required this.date,
    required this.timezone,
    required this.lat,
    required this.lon,
    required this.method,
    required this.school,
    required this.times,
  });

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    final loc = (json['location'] as Map).cast<String, dynamic>();
    final timesJson = (json['times'] as Map).cast<String, dynamic>();

    return PrayerTimesModel(
      date: json['date'] as String,
      timezone: json['timezone'] as String?,
      lat: (loc['lat'] as num).toDouble(),
      lon: (loc['lon'] as num).toDouble(),
      method: (json['method'] as num).toInt(),
      school: (json['school'] as num).toInt(),
      times: timesJson.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'timezone': timezone,
        'location': {'lat': lat, 'lon': lon},
        'method': method,
        'school': school,
        'times': times,
      };
}

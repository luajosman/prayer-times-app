import 'dart:math' as math;

const double kaabaLatitude = 21.422487;
const double kaabaLongitude = 39.826206;
const double _earthRadiusKm = 6371.0;

class GeoCoordinate {
  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

double calculateQiblaBearing({
  required double latitude,
  required double longitude,
}) {
  final double userLatitudeRad = _degToRad(latitude);
  final double userLongitudeRad = _degToRad(longitude);
  final double kaabaLatitudeRad = _degToRad(kaabaLatitude);
  final double deltaLongitude = _degToRad(kaabaLongitude) - userLongitudeRad;

  final double y = math.sin(deltaLongitude);
  final double x = math.cos(userLatitudeRad) * math.tan(kaabaLatitudeRad) -
      math.sin(userLatitudeRad) * math.cos(deltaLongitude);

  final double bearing = _radToDeg(math.atan2(y, x));
  return normalizeAngle(bearing);
}

double normalizeAngle(double angle) {
  final double normalized = angle % 360;
  if (normalized < 0) {
    return normalized + 360;
  }
  return normalized;
}

double smallestAngleDifference(double from, double to) {
  final double delta = normalizeAngle(to - from);
  if (delta > 180) {
    return delta - 360;
  }
  return delta;
}

double distanceToKaabaKm({
  required double latitude,
  required double longitude,
}) {
  return greatCircleDistanceKm(
    startLatitude: latitude,
    startLongitude: longitude,
    endLatitude: kaabaLatitude,
    endLongitude: kaabaLongitude,
  );
}

double greatCircleDistanceKm({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
}) {
  final double lat1 = _degToRad(startLatitude);
  final double lon1 = _degToRad(startLongitude);
  final double lat2 = _degToRad(endLatitude);
  final double lon2 = _degToRad(endLongitude);

  final double dLat = lat2 - lat1;
  final double dLon = lon2 - lon1;

  final double a = math.pow(math.sin(dLat / 2), 2).toDouble() +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2).toDouble();

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusKm * c;
}

List<GeoCoordinate> buildGeodesicPathToKaaba({
  required double latitude,
  required double longitude,
  int segments = 160,
}) {
  return buildGeodesicPath(
    startLatitude: latitude,
    startLongitude: longitude,
    endLatitude: kaabaLatitude,
    endLongitude: kaabaLongitude,
    segments: segments,
  );
}

List<GeoCoordinate> buildGeodesicPath({
  required double startLatitude,
  required double startLongitude,
  required double endLatitude,
  required double endLongitude,
  int segments = 160,
}) {
  final double lat1 = _degToRad(startLatitude);
  final double lon1 = _degToRad(startLongitude);
  final double lat2 = _degToRad(endLatitude);
  final double lon2 = _degToRad(endLongitude);

  final double angularDistance = _angularDistance(
    lat1: lat1,
    lon1: lon1,
    lat2: lat2,
    lon2: lon2,
  );

  if (angularDistance == 0) {
    return <GeoCoordinate>[
      GeoCoordinate(latitude: startLatitude, longitude: startLongitude),
      GeoCoordinate(latitude: endLatitude, longitude: endLongitude),
    ];
  }

  final List<GeoCoordinate> points = <GeoCoordinate>[];
  for (int i = 0; i <= segments; i++) {
    final double fraction = i / segments;
    final double a = math.sin((1 - fraction) * angularDistance) /
        math.sin(angularDistance);
    final double b = math.sin(fraction * angularDistance) / math.sin(angularDistance);

    final double x = a * math.cos(lat1) * math.cos(lon1) +
        b * math.cos(lat2) * math.cos(lon2);
    final double y = a * math.cos(lat1) * math.sin(lon1) +
        b * math.cos(lat2) * math.sin(lon2);
    final double z = a * math.sin(lat1) + b * math.sin(lat2);

    final double lat = math.atan2(z, math.sqrt(x * x + y * y));
    final double lon = math.atan2(y, x);

    points.add(
      GeoCoordinate(
        latitude: _radToDeg(lat),
        longitude: _normalizeLongitude(_radToDeg(lon)),
      ),
    );
  }

  return points;
}

double _angularDistance({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  final double dLat = lat2 - lat1;
  final double dLon = lon2 - lon1;

  final double a = math.pow(math.sin(dLat / 2), 2).toDouble() +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2).toDouble();
  return 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _normalizeLongitude(double value) {
  final double wrapped = (value + 540) % 360;
  return wrapped - 180;
}

double _degToRad(double degrees) => degrees * (math.pi / 180);

double _radToDeg(double radians) => radians * (180 / math.pi);

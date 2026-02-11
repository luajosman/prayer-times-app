import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Standortdienste sind deaktiviert. Aktiviere GPS oder nutze manuelle Koordinaten.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationServiceException(
        'Standortberechtigung wurde abgelehnt.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Standortberechtigung dauerhaft abgelehnt. Bitte in den Systemeinstellungen erlauben.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } on Exception {
      throw LocationServiceException(
        'Standort konnte nicht ermittelt werden. Prüfe Signal oder nutze manuelle Koordinaten.',
      );
    }
  }
}

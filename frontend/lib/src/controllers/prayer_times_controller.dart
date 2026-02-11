import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/src/core/prayer_constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:frontend/src/models/app_settings.dart';
import 'package:frontend/src/models/prayer_times_response.dart';
import 'package:frontend/src/services/location_service.dart';
import 'package:frontend/src/services/prayer_api_client.dart';
import 'package:frontend/src/services/settings_store.dart';
import 'package:frontend/src/utils/prayer_time_utils.dart';

class PrayerTimesController extends ChangeNotifier {
  PrayerTimesController({
    PrayerApiClient? apiClient,
    LocationService? locationService,
    SettingsStore? settingsStore,
  })  : _apiClient = apiClient ?? PrayerApiClient(),
        _locationService = locationService ?? LocationService(),
        _settingsStore = settingsStore ?? SettingsStore();

  final PrayerApiClient _apiClient;
  final LocationService _locationService;
  final SettingsStore _settingsStore;

  AppSettings _settings = AppSettings.defaults;
  PrayerTimesResponse? _response;
  Map<String, String> _visibleTimes = <String, String>{};
  String? _errorMessage;
  bool _isBusy = false;
  bool _isInitialized = false;
  DateTime _now = DateTime.now();
  DateTime? _lastUpdatedAt;
  String? _liveLocationLabel;
  Timer? _ticker;

  AppSettings get settings => _settings;
  PrayerTimesResponse? get response => _response;
  Map<String, String> get visibleTimes => _visibleTimes;
  String? get errorMessage => _errorMessage;
  DateTime get now => _now;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  bool get isLoading => !_isInitialized || (_isBusy && _response == null);
  bool get isRefreshing => _isBusy && _response != null;

  List<int> get availableMethods =>
      methodLabels.keys.toList()..sort((int a, int b) => a.compareTo(b));

  List<int> get availableSchools =>
      schoolLabels.keys.toList()..sort((int a, int b) => a.compareTo(b));

  PrayerEvent? get nextPrayer {
    final PrayerTimesResponse? data = _response;
    if (data == null) {
      return null;
    }
    return findNextPrayer(data.times, _now);
  }

  Duration? get nextPrayerIn {
    final PrayerEvent? event = nextPrayer;
    if (event == null) {
      return null;
    }
    return event.at.difference(_now);
  }

  String get locationSummary {
    if (_settings.useDeviceLocation) {
      if (_liveLocationLabel != null && _liveLocationLabel!.trim().isNotEmpty) {
        return _liveLocationLabel!;
      }
      if (_response != null) {
        return '${_response!.latitude.toStringAsFixed(4)}, ${_response!.longitude.toStringAsFixed(4)}';
      }
      return 'Live-Standort';
    }

    if (_settings.manualLabel.trim().isNotEmpty) {
      return _settings.manualLabel.trim();
    }

    return 'Manuelle Koordinaten';
  }

  Future<void> initialize() async {
    _startTicker();
    _settings = await _settingsStore.load();
    _settings = await _maybeRepairManualLocation(_settings);
    _isInitialized = true;
    notifyListeners();
    await refresh(showGlobalLoader: true);
  }

  Future<void> refresh({bool showGlobalLoader = false}) async {
    if (_isBusy) {
      return;
    }

    _isBusy = true;
    if (showGlobalLoader) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final _Coordinates coordinates = await _resolveCoordinates();

      final PrayerTimesResponse loaded = await _apiClient.fetchPrayerTimes(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        method: _settings.method,
        school: _settings.school,
      );

      _response = loaded;
      if (_settings.useDeviceLocation) {
        _liveLocationLabel = await _resolveLocationLabel(
          coordinates.latitude,
          coordinates.longitude,
        );
      } else {
        _liveLocationLabel = null;
      }
      _visibleTimes = filterPrayerTimes(loaded.times);
      _errorMessage = null;
      _lastUpdatedAt = DateTime.now();
    } on LocationServiceException catch (error) {
      _errorMessage = error.message;
    } on PrayerApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unerwarteter Fehler beim Laden der Gebetszeiten.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateMethod(int method) async {
    if (_settings.method == method) {
      return;
    }

    _settings = _settings.copyWith(method: method);
    await _settingsStore.save(_settings);
    notifyListeners();
    await refresh();
  }

  Future<void> updateSchool(int school) async {
    if (_settings.school == school) {
      return;
    }

    _settings = _settings.copyWith(school: school);
    await _settingsStore.save(_settings);
    notifyListeners();
    await refresh();
  }

  Future<void> setUseDeviceLocation(bool useDeviceLocation) async {
    if (_settings.useDeviceLocation == useDeviceLocation) {
      return;
    }

    _settings = _settings.copyWith(useDeviceLocation: useDeviceLocation);
    if (!useDeviceLocation) {
      _liveLocationLabel = null;
    }
    await _settingsStore.save(_settings);
    notifyListeners();
    await refresh();
  }

  Future<void> saveManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    _settings = _settings.copyWith(
      useDeviceLocation: false,
      manualLatitude: latitude,
      manualLongitude: longitude,
      manualLabel: label.trim().isEmpty ? 'Manuelle Koordinaten' : label.trim(),
    );
    _liveLocationLabel = null;

    await _settingsStore.save(_settings);
    notifyListeners();
    await refresh();
  }

  _Coordinates _manualCoordinates() {
    return _Coordinates(
      latitude: _settings.manualLatitude,
      longitude: _settings.manualLongitude,
    );
  }

  Future<_Coordinates> _resolveCoordinates() async {
    if (!_settings.useDeviceLocation) {
      _settings = await _maybeRepairManualLocation(_settings);
      return _manualCoordinates();
    }

    try {
      final position = await _locationService.getCurrentPosition();
      return _Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceException {
      if (_response != null) {
        return _Coordinates(
          latitude: _response!.latitude,
          longitude: _response!.longitude,
        );
      }
      rethrow;
    }
  }

  Future<AppSettings> _maybeRepairManualLocation(AppSettings settings) async {
    if (settings.useDeviceLocation) {
      return settings;
    }

    if (!_isFallbackCoordinates(
      settings.manualLatitude,
      settings.manualLongitude,
    )) {
      return settings;
    }

    final String label = settings.manualLabel.trim();
    if (label.isEmpty || _isGenericManualLabel(label)) {
      return settings;
    }

    try {
      final GeocodeResult resolved = await _apiClient.geocodeLocation(label);
      final AppSettings updated = settings.copyWith(
        manualLatitude: resolved.latitude,
        manualLongitude: resolved.longitude,
      );
      await _settingsStore.save(updated);
      return updated;
    } on PrayerApiException {
      return settings;
    } catch (_) {
      return settings;
    }
  }

  bool _isFallbackCoordinates(double latitude, double longitude) {
    const double epsilon = 0.0001;
    return (latitude - fallbackLatitude).abs() <= epsilon &&
        (longitude - fallbackLongitude).abs() <= epsilon;
  }

  bool _isGenericManualLabel(String label) {
    final String normalized = label.trim().toLowerCase();
    return normalized == 'manuelle koordinaten' ||
        normalized == 'manual coordinates' ||
        normalized == 'new york';
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<String?> _resolveLocationLabel(
      double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isEmpty) {
        return null;
      }

      final Placemark place = placemarks.first;
      final String? city = _firstNonEmpty(<String?>[
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]);
      final String? country = _firstNonEmpty(<String?>[place.country]);

      if (city != null && country != null) {
        return '$city, $country';
      }
      return city ?? country;
    } catch (_) {
      return null;
    }
  }

  String? _firstNonEmpty(List<String?> candidates) {
    for (final String? candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }
}

class _Coordinates {
  const _Coordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/src/core/prayer_constants.dart';
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
      final String? detailedLiveLabel = _liveLocationLabel?.trim();
      if (detailedLiveLabel != null && detailedLiveLabel.isNotEmpty) {
        return detailedLiveLabel;
      }
      if (_response != null) {
        return '${_response!.latitude.toStringAsFixed(4)}, ${_response!.longitude.toStringAsFixed(4)}';
      }
      return 'Live-Standort';
    }

    if (_settings.manualLabel.trim().isNotEmpty) {
      final String manualLabel = _settings.manualLabel.trim();
      if (!_isGenericManualLabel(manualLabel)) {
        return manualLabel;
      }
    }

    final String? resolvedManualLabel = _resolvedManualLocationLabel();
    if (resolvedManualLabel != null) {
      return resolvedManualLabel;
    }

    if (_settings.manualLabel.trim().isNotEmpty) {
      return _settings.manualLabel.trim();
    }

    return 'Manuelle Koordinaten';
  }

  String get locationHeadline {
    if (_settings.useDeviceLocation) {
      final String? liveCity = _response?.locationCity?.trim();
      if (liveCity != null && liveCity.isNotEmpty) {
        return liveCity;
      }
      final String? liveLabel = _liveLocationLabel?.trim();
      if (liveLabel != null && liveLabel.isNotEmpty) {
        return liveLabel;
      }
      if (_response != null) {
        return '${_response!.latitude.toStringAsFixed(4)}, ${_response!.longitude.toStringAsFixed(4)}';
      }
      return 'Live-Standort';
    }

    final String manualLabel = _settings.manualLabel.trim();
    if (manualLabel.isNotEmpty && !_isGenericManualLabel(manualLabel)) {
      return manualLabel;
    }

    final String? manualCity = _resolvedManualLocationCity();
    if (manualCity != null) {
      return manualCity;
    }

    final String? manualResolvedLabel = _resolvedManualLocationLabel();
    if (manualResolvedLabel != null) {
      return manualResolvedLabel;
    }

    if (manualLabel.isNotEmpty) {
      return manualLabel;
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

      final PrayerTimesResponse loaded =
          await _loadPrayerTimesForCoordinates(coordinates);

      _response = loaded;
      if (_settings.useDeviceLocation) {
        _liveLocationLabel = loaded.locationLabel?.trim();
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
    if (_settings.method == method && !_settings.useAutoMethod) {
      return;
    }

    _settings = _settings.copyWith(
      method: method,
      useAutoMethod: false,
    );
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

    final position = await _locationService.getCurrentPosition();
    return _Coordinates(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<PrayerTimesResponse> _loadPrayerTimesForCoordinates(
    _Coordinates coordinates,
  ) async {
    final PrayerTimesResponse initial = await _fetchPrayerTimes(
      coordinates: coordinates,
      method: _settings.method,
    );

    if (!_settings.useAutoMethod) {
      return initial;
    }

    final int? recommendedMethod = _recommendedMethodFor(initial);
    if (recommendedMethod == null || recommendedMethod == _settings.method) {
      return initial;
    }

    final int previousMethod = _settings.method;
    _settings = _settings.copyWith(method: recommendedMethod);
    await _settingsStore.save(_settings);

    try {
      return await _fetchPrayerTimes(
        coordinates: coordinates,
        method: recommendedMethod,
      );
    } on PrayerApiException {
      _settings = _settings.copyWith(method: previousMethod);
      await _settingsStore.save(_settings);
      return initial;
    }
  }

  Future<PrayerTimesResponse> _fetchPrayerTimes({
    required _Coordinates coordinates,
    required int method,
  }) {
    return _apiClient.fetchPrayerTimes(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      method: method,
      school: _settings.school,
    );
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

  int? _recommendedMethodFor(PrayerTimesResponse data) {
    final String country = (data.locationCountry ?? '').trim().toLowerCase();
    final String timezone = data.timezone.trim();

    if (_matchesCountry(country, <String>{'germany', 'deutschland'})) {
      return 13;
    }
    if (_matchesCountry(country, <String>{'turkey', 'turkiye', 'türkiye'})) {
      return 13;
    }
    if (_matchesCountry(country, <String>{'france'})) {
      return 12;
    }
    if (_matchesCountry(country, <String>{'russia', 'russian federation'})) {
      return 14;
    }
    if (timezone.startsWith('Europe/')) {
      return 1;
    }
    if (timezone.startsWith('America/')) {
      return 2;
    }

    return null;
  }

  bool _matchesCountry(String country, Set<String> candidates) {
    if (country.isEmpty) {
      return false;
    }
    return candidates.contains(country);
  }

  String? _resolvedManualLocationLabel() {
    final PrayerTimesResponse? data = _response;
    if (data == null || !_matchesManualCoordinates(data)) {
      return null;
    }

    final String? label = data.locationLabel?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }

    return label;
  }

  String? _resolvedManualLocationCity() {
    final PrayerTimesResponse? data = _response;
    if (data == null || !_matchesManualCoordinates(data)) {
      return null;
    }

    final String? city = data.locationCity?.trim();
    if (city == null || city.isEmpty) {
      return null;
    }

    return city;
  }

  bool _matchesManualCoordinates(PrayerTimesResponse data) {
    const double epsilon = 0.0001;
    return (data.latitude - _settings.manualLatitude).abs() <= epsilon &&
        (data.longitude - _settings.manualLongitude).abs() <= epsilon;
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
}

class _Coordinates {
  const _Coordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

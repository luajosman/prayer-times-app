import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import 'prayer_times_model.dart';

class PrayerTimesApi {
  final Dio _dio;

  PrayerTimesApi([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                // Dio v5 expects Duration-based timeouts:
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 10),
              ),
            ) {
    // Helpful runtime diagnostics (shows the REAL baseUrl used on the emulator)
    debugPrint('API_BASE_URL = ${AppConfig.apiBaseUrl}');
    debugPrint('Dio baseUrl  = ${_dio.options.baseUrl}');
    debugPrint('connectTimeout = ${_dio.options.connectTimeout}');
    debugPrint('receiveTimeout = ${_dio.options.receiveTimeout}');

    // Log requests/responses to quickly see what URL is called and what comes back.
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  Future<PrayerTimesModel> fetch({
    required double lat,
    required double lon,
    int method = 2,
    int school = 0,
  }) async {
    // If your baseUrl is .../api/v1 then you can use '/prayer-times' here.
    // To stay compatible with both styles, we keep the full path:
    final res = await _dio.get(
      '/api/v1/prayer-times',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'method': method,
        'school': school,
      },
    );

    return PrayerTimesModel.fromJson(res.data as Map<String, dynamic>);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/src/models/prayer_times_response.dart';

class PrayerApiException implements Exception {
  PrayerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrayerApiClient {
  PrayerApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _resolveBaseUrl(),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 12),
                sendTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  static String _resolveBaseUrl() {
    const String configured = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  Future<PrayerTimesResponse> fetchPrayerTimes({
    required double latitude,
    required double longitude,
    required int method,
    required int school,
  }) async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/api/v1/prayer-times',
        queryParameters: <String, dynamic>{
          'lat': latitude,
          'lon': longitude,
          'method': method,
          'school': school,
        },
      );

      final dynamic body = response.data;
      if (response.statusCode != 200 || body is! Map<String, dynamic>) {
        throw PrayerApiException('Unerwartete API-Antwort vom Backend.');
      }

      return PrayerTimesResponse.fromJson(body);
    } on DioException catch (error) {
      final String serverMessage =
          error.response?.data is Map<String, dynamic>
              ? (error.response?.data['detail']?.toString() ?? '')
              : '';

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw PrayerApiException(
          'Zeitüberschreitung beim Backend. Bitte erneut versuchen.',
        );
      }

      throw PrayerApiException(
        serverMessage.isNotEmpty
            ? serverMessage
            : 'Backend nicht erreichbar. Prüfe API-URL und Server-Status.',
      );
    } on PrayerApiException {
      rethrow;
    } catch (_) {
      throw PrayerApiException('Unbekannter Fehler beim Laden der Gebetszeiten.');
    }
  }
}

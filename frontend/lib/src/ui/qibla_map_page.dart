import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/ui/widgets/context_chip.dart';
import 'package:frontend/src/ui/widgets/section_header.dart';
import 'package:frontend/src/utils/qibla_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class QiblaMapPage extends StatelessWidget {
  const QiblaMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    this.phaseStyle,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;
  final PrayerPhaseStyle? phaseStyle;

  @override
  Widget build(BuildContext context) {
    final PrayerPhaseStyle resolvedPhase =
        phaseStyle ?? prayerPhaseStyleOf(PrayerPhase.dhuhr);
    final List<GeoCoordinate> path = buildGeodesicPathToKaaba(
      latitude: latitude,
      longitude: longitude,
    );
    final List<LatLng> polylinePoints = path
        .map((GeoCoordinate point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);

    final LatLng userPoint = LatLng(latitude, longitude);
    const LatLng kaabaPoint = LatLng(kaabaLatitude, kaabaLongitude);
    final _GeoBounds bounds = _computeBounds(<LatLng>[userPoint, kaabaPoint]);
    final double distanceKm =
        distanceToKaabaKm(latitude: latitude, longitude: longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Route'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInGoogleMaps(context),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('Google Maps'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.overlay(
                resolvedPhase.qiblaAmbient,
                AppColors.background,
                0.14,
              ),
              AppColors.background,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeader(
                      label: 'Luftlinie zur Kaaba',
                      accentColor: AppColors.gold,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        ContextChip(
                          icon: Icons.my_location_rounded,
                          label: locationLabel,
                        ),
                        const ContextChip(
                          icon: Icons.mosque_rounded,
                          label: 'Kaaba, Makkah',
                          accentColor: AppColors.gold,
                        ),
                        ContextChip(
                          icon: Icons.route_rounded,
                          label: '${distanceKm.toStringAsFixed(0)} km',
                          accentColor: resolvedPhase.accentSoft,
                          emphasized: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _initialCenter(bounds),
                        initialZoom: _initialZoom(bounds),
                      ),
                      children: <Widget>[
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.frontend',
                        ),
                        PolylineLayer(
                          polylines: _buildRoutePolylines(polylinePoints),
                        ),
                        MarkerLayer(
                          markers: <Marker>[
                            Marker(
                              width: 34,
                              height: 34,
                              point: userPoint,
                              child: const _MapMarker(isDestination: false),
                            ),
                            const Marker(
                              width: 34,
                              height: 34,
                              point: kaabaPoint,
                              child: _MapMarker(isDestination: true),
                            ),
                          ],
                        ),
                        const RichAttributionWidget(
                          attributions: <SourceAttribution>[
                            TextSourceAttribution('OpenStreetMap contributors'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Polyline> _buildRoutePolylines(List<LatLng> points) {
    return _splitAtDateline(points)
        .where((List<LatLng> segment) => segment.length >= 2)
        .map(
          (List<LatLng> segment) => Polyline(
            points: segment,
            strokeWidth: 3.4,
            color: AppColors.gold.withValues(alpha: 0.88),
          ),
        )
        .toList(growable: false);
  }

  List<List<LatLng>> _splitAtDateline(List<LatLng> points) {
    if (points.length < 2) {
      return <List<LatLng>>[points];
    }

    final List<List<LatLng>> segments = <List<LatLng>>[
      <LatLng>[points.first],
    ];

    for (int i = 1; i < points.length; i++) {
      final bool jumps =
          (points[i - 1].longitude - points[i].longitude).abs() > 180;
      if (jumps) {
        segments.add(<LatLng>[points[i]]);
      } else {
        segments.last.add(points[i]);
      }
    }

    return segments;
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$latitude,$longitude'
      '&destination=$kaabaLatitude,$kaabaLongitude'
      '&travelmode=walking',
    );

    for (final LaunchMode mode in <LaunchMode>[
      LaunchMode.platformDefault,
      LaunchMode.externalApplication,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        if (await launchUrl(mapsUri, mode: mode)) {
          return;
        }
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: mapsUri.toString()));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Google Maps konnte nicht geöffnet werden. Link kopiert.'),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.isDestination});

  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final Color background =
        isDestination ? AppColors.gold : AppColors.surfaceStrong;
    final Color foreground =
        isDestination ? AppColors.goldTint : AppColors.primarySoft;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(
          color: isDestination ? AppColors.goldSoft : AppColors.border,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        isDestination ? Icons.mosque_rounded : Icons.my_location_rounded,
        color: foreground,
        size: 16,
      ),
    );
  }
}

class _GeoBounds {
  const _GeoBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;
}

_GeoBounds _computeBounds(List<LatLng> points) {
  return _GeoBounds(
    minLatitude: points.map((LatLng point) => point.latitude).reduce(math.min),
    maxLatitude: points.map((LatLng point) => point.latitude).reduce(math.max),
    minLongitude:
        points.map((LatLng point) => point.longitude).reduce(math.min),
    maxLongitude:
        points.map((LatLng point) => point.longitude).reduce(math.max),
  );
}

LatLng _initialCenter(_GeoBounds bounds) {
  return LatLng(
    (bounds.minLatitude + bounds.maxLatitude) / 2,
    _midLongitude(bounds.minLongitude, bounds.maxLongitude),
  );
}

double _midLongitude(double min, double max) {
  if ((max - min).abs() <= 180) {
    return (min + max) / 2;
  }
  final double wrappedMin = min < 0 ? min + 360 : min;
  final double wrappedMax = max < 0 ? max + 360 : max;
  final double midpoint = (wrappedMin + wrappedMax) / 2;
  return midpoint > 180 ? midpoint - 360 : midpoint;
}

double _initialZoom(_GeoBounds bounds) {
  final double latDiff = (bounds.maxLatitude - bounds.minLatitude).abs();
  double lonDiff = (bounds.maxLongitude - bounds.minLongitude).abs();
  if (lonDiff > 180) {
    lonDiff = 360 - lonDiff;
  }
  final double largestDiff = math.max(latDiff, lonDiff);

  if (largestDiff > 140) {
    return 1.4;
  }
  if (largestDiff > 100) {
    return 1.9;
  }
  if (largestDiff > 60) {
    return 2.4;
  }
  if (largestDiff > 25) {
    return 3.2;
  }
  if (largestDiff > 10) {
    return 4.0;
  }
  return 5.2;
}

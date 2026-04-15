import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/utils/qibla_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class QiblaMapPage extends StatelessWidget {
  const QiblaMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final List<GeoCoordinate> path = buildGeodesicPathToKaaba(
      latitude: latitude,
      longitude: longitude,
    );

    final List<LatLng> polylinePoints = path
        .map((GeoCoordinate p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    final LatLng userPoint = LatLng(latitude, longitude);
    const LatLng kaabaPoint = LatLng(kaabaLatitude, kaabaLongitude);
    final _GeoBounds bounds =
        _computeBounds(<LatLng>[userPoint, kaabaPoint]);

    final double distanceKm =
        distanceToKaabaKm(latitude: latitude, longitude: longitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Qibla · Luftlinie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInGoogleMaps(context),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('In Google Maps öffnen'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: <Widget>[
          // Info card
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: <Widget>[
                  _MapInfoItem(
                    icon: Icons.my_location_rounded,
                    label: 'Start',
                    value: locationLabel,
                  ),
                  const _MapInfoItem(
                    icon: Icons.mosque_rounded,
                    label: 'Ziel',
                    value: 'Kaaba, Makkah',
                    color: AppColors.gold,
                  ),
                  _MapInfoItem(
                    icon: Icons.route_rounded,
                    label: 'Entfernung',
                    value:
                        '${distanceKm.toStringAsFixed(0)} km',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Map
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppRadius.xl),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _initialCenter(bounds),
                    initialZoom: _initialZoom(bounds),
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'com.example.frontend',
                    ),
                    PolylineLayer(
                      polylines:
                          _buildRoutePolylines(polylinePoints),
                    ),
                    MarkerLayer(
                      markers: <Marker>[
                        Marker(
                          width: 32,
                          height: 32,
                          point: userPoint,
                          child:
                              const _MapMarker(isDestination: false),
                        ),
                        const Marker(
                          width: 32,
                          height: 32,
                          point: kaabaPoint,
                          child: _MapMarker(isDestination: true),
                        ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: <SourceAttribution>[
                        TextSourceAttribution(
                            'OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Polyline> _buildRoutePolylines(List<LatLng> points) {
    return _splitAtDateline(points)
        .where((List<LatLng> seg) => seg.length >= 2)
        .map(
          (List<LatLng> seg) => Polyline(
            points: seg,
            strokeWidth: 3,
            color: AppColors.primaryLight.withValues(alpha: 0.85),
          ),
        )
        .toList(growable: false);
  }

  List<List<LatLng>> _splitAtDateline(List<LatLng> points) {
    if (points.length < 2) return <List<LatLng>>[points];

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

  _GeoBounds _computeBounds(List<LatLng> points) {
    return _GeoBounds(
      minLatitude:
          points.map((LatLng p) => p.latitude).reduce(math.min),
      maxLatitude:
          points.map((LatLng p) => p.latitude).reduce(math.max),
      minLongitude:
          points.map((LatLng p) => p.longitude).reduce(math.min),
      maxLongitude:
          points.map((LatLng p) => p.longitude).reduce(math.max),
    );
  }

  LatLng _initialCenter(_GeoBounds b) {
    return LatLng(
      (b.minLatitude + b.maxLatitude) / 2,
      _midLongitude(b.minLongitude, b.maxLongitude),
    );
  }

  double _midLongitude(double min, double max) {
    if ((max - min).abs() <= 180) return (min + max) / 2;
    final double wMin = min < 0 ? min + 360 : min;
    final double wMax = max < 0 ? max + 360 : max;
    final double mid = (wMin + wMax) / 2;
    return mid > 180 ? mid - 360 : mid;
  }

  double _initialZoom(_GeoBounds b) {
    final double latD = (b.maxLatitude - b.minLatitude).abs();
    double lonD = (b.maxLongitude - b.minLongitude).abs();
    if (lonD > 180) lonD = 360 - lonD;
    final double d = latD > lonD ? latD : lonD;

    if (d > 140) return 1.4;
    if (d > 100) return 1.9;
    if (d > 60) return 2.4;
    if (d > 25) return 3.2;
    if (d > 10) return 4.0;
    return 5.2;
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
        if (await launchUrl(mapsUri, mode: mode)) return;
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: mapsUri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Google Maps konnte nicht geöffnet werden. Link kopiert.'),
      ),
    );
  }
}

// ── Map info item ─────────────────────────────────────────────────────────────

class _MapInfoItem extends StatelessWidget {
  const _MapInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primaryLight,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Map marker ────────────────────────────────────────────────────────────────

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.isDestination});

  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    final Color bg = isDestination
        ? AppColors.gold.withValues(alpha: 0.92)
        : AppColors.surface.withValues(alpha: 0.95);
    final Color fg =
        isDestination ? const Color(0xFF2A1F08) : AppColors.primaryLight;
    final Color border = isDestination
        ? AppColors.goldLight
        : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        isDestination
            ? Icons.mosque_rounded
            : Icons.my_location_rounded,
        size: 14,
        color: fg,
      ),
    );
  }
}

// ── Geo bounds ────────────────────────────────────────────────────────────────

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

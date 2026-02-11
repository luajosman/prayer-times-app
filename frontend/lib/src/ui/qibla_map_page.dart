import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
        .map((GeoCoordinate point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final List<Polyline> routePolylines = _buildRoutePolylines(polylinePoints);

    final LatLng userPoint = LatLng(latitude, longitude);
    final LatLng kaabaPoint = const LatLng(kaabaLatitude, kaabaLongitude);
    final _GeoBounds bounds = _computeBounds(<LatLng>[userPoint, kaabaPoint]);
    final double distanceKm = distanceToKaabaKm(
      latitude: latitude,
      longitude: longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Linienansicht'),
        actions: <Widget>[
          IconButton(
            tooltip: 'In Google Maps öffnen',
            onPressed: () => _openInGoogleMaps(context),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MiniInfo(
                  icon: Icons.place_rounded,
                  label: 'Start',
                  value:
                      '$locationLabel · ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                ),
                _MiniInfo(
                  icon: Icons.mosque_rounded,
                  label: 'Ziel',
                  value: 'Kaaba, Makkah',
                ),
                _MiniInfo(
                  icon: Icons.route_rounded,
                  label: 'Luftlinie',
                  value: '${distanceKm.toStringAsFixed(1)} km',
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
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
                      polylines: routePolylines,
                    ),
                    MarkerLayer(
                      markers: <Marker>[
                        Marker(
                          width: 30,
                          height: 30,
                          point: userPoint,
                          child: const _MapPointMarker(
                            icon: Icons.my_location_rounded,
                          ),
                        ),
                        Marker(
                          width: 30,
                          height: 30,
                          point: kaabaPoint,
                          child: const _MapPointMarker(
                            icon: Icons.mosque_rounded,
                            isDestination: true,
                          ),
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
        ],
      ),
    );
  }

  List<Polyline> _buildRoutePolylines(List<LatLng> points) {
    final List<List<LatLng>> segments = _splitAtDateline(points);
    return segments
        .where((List<LatLng> segment) => segment.length >= 2)
        .map(
          (List<LatLng> segment) => Polyline(
            points: segment,
            strokeWidth: 4,
            color: const Color(0xFF64E0D6),
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
      final LatLng previous = points[i - 1];
      final LatLng current = points[i];
      final bool jumpsDateline =
          (previous.longitude - current.longitude).abs() > 180;

      if (jumpsDateline) {
        segments.add(<LatLng>[current]);
      } else {
        segments.last.add(current);
      }
    }

    return segments;
  }

  _GeoBounds _computeBounds(List<LatLng> points) {
    final double minLat =
        points.map((LatLng point) => point.latitude).reduce(math.min);
    final double maxLat =
        points.map((LatLng point) => point.latitude).reduce(math.max);
    final double minLon =
        points.map((LatLng point) => point.longitude).reduce(math.min);
    final double maxLon =
        points.map((LatLng point) => point.longitude).reduce(math.max);

    return _GeoBounds(
      minLatitude: minLat,
      maxLatitude: maxLat,
      minLongitude: minLon,
      maxLongitude: maxLon,
    );
  }

  LatLng _initialCenter(_GeoBounds bounds) {
    return LatLng(
      (bounds.minLatitude + bounds.maxLatitude) / 2,
      _midLongitude(bounds.minLongitude, bounds.maxLongitude),
    );
  }

  double _midLongitude(double minLongitude, double maxLongitude) {
    if ((maxLongitude - minLongitude).abs() <= 180) {
      return (minLongitude + maxLongitude) / 2;
    }

    final double wrappedMin =
        minLongitude < 0 ? minLongitude + 360 : minLongitude;
    final double wrappedMax =
        maxLongitude < 0 ? maxLongitude + 360 : maxLongitude;
    final double wrappedMid = (wrappedMin + wrappedMax) / 2;
    return wrappedMid > 180 ? wrappedMid - 360 : wrappedMid;
  }

  double _initialZoom(_GeoBounds bounds) {
    final double latDelta = (bounds.maxLatitude - bounds.minLatitude).abs();
    double lonDelta = (bounds.maxLongitude - bounds.minLongitude).abs();
    if (lonDelta > 180) {
      lonDelta = 360 - lonDelta;
    }
    final double maxDelta = latDelta > lonDelta ? latDelta : lonDelta;

    if (maxDelta > 140) {
      return 1.4;
    }
    if (maxDelta > 100) {
      return 1.9;
    }
    if (maxDelta > 60) {
      return 2.4;
    }
    if (maxDelta > 25) {
      return 3.2;
    }
    if (maxDelta > 10) {
      return 4.0;
    }
    return 5.2;
  }

  Future<void> _openInGoogleMaps(BuildContext context) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$latitude,$longitude&destination=$kaabaLatitude,$kaabaLongitude&travelmode=walking',
    );

    final List<LaunchMode> modes = <LaunchMode>[
      LaunchMode.platformDefault,
      LaunchMode.externalApplication,
      LaunchMode.inAppBrowserView,
    ];

    for (final LaunchMode mode in modes) {
      try {
        final bool opened = await launchUrl(mapsUri, mode: mode);
        if (opened) {
          return;
        }
      } catch (_) {
        // Try next launch mode before reporting failure.
      }
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: const Color(0xFF64E0D6)),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _MapPointMarker extends StatelessWidget {
  const _MapPointMarker({
    required this.icon,
    this.isDestination = false,
  });

  final IconData icon;
  final bool isDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDestination
            ? const Color(0xFFFFD166).withOpacity(0.95)
            : const Color(0xFF1D2637).withOpacity(0.95),
        border: Border.all(
          color: isDestination
              ? const Color(0xFFFFD166)
              : Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 14,
        color: isDestination ? const Color(0xFF2E3A52) : Colors.white,
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

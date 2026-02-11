import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:frontend/src/ui/qibla_map_page.dart';
import 'package:frontend/src/utils/qibla_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class QiblaCompassCard extends StatelessWidget {
  const QiblaCompassCard({
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
    final double qiblaBearing = calculateQiblaBearing(
      latitude: latitude,
      longitude: longitude,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.explore_rounded, color: Color(0xFF64E0D6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Qibla Kompass',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Kartenansicht',
                  onPressed: () => _openMapView(context),
                  icon: const Icon(Icons.alt_route_rounded,
                      color: Color(0xFF64E0D6)),
                ),
                IconButton(
                  tooltip: 'In Google Maps öffnen',
                  onPressed: () => _openInGoogleMaps(context),
                  icon:
                      const Icon(Icons.map_outlined, color: Color(0xFF64E0D6)),
                ),
                Text(
                  '${qiblaBearing.toStringAsFixed(0)}°',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF64E0D6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Standort: $locationLabel',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              'Richtung zur Kaaba relativ zu Norden.',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.68)),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe auf den Kompass für Google Maps. Die In-App-Luftlinie öffnest du über das Routen-Icon.',
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.68)),
            ),
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                onTap: () => _openInGoogleMaps(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _CompassBody(qiblaBearing: qiblaBearing),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        content: Text(
          'Google Maps konnte nicht geöffnet werden. Link wurde kopiert.',
        ),
      ),
    );
  }

  void _openMapView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QiblaMapPage(
          latitude: latitude,
          longitude: longitude,
          locationLabel: locationLabel,
        ),
      ),
    );
  }
}

class _CompassBody extends StatelessWidget {
  const _CompassBody({required this.qiblaBearing});

  final double qiblaBearing;

  @override
  Widget build(BuildContext context) {
    final Stream<CompassEvent>? stream = _safeCompassStream();
    if (stream == null) {
      return _CompassUnavailable(
        message: 'Kompass wird auf diesem Gerät aktuell nicht unterstützt.',
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<CompassEvent> snapshot) {
        if (snapshot.hasError) {
          return _CompassUnavailable(
            message:
                'Kompass konnte nicht geladen werden. Sensorzugriff prüfen.',
          );
        }

        final double? rawHeading = snapshot.data?.heading;
        if (rawHeading == null || rawHeading.isNaN) {
          return _CompassUnavailable(
            message:
                'Keine Kompassdaten verfügbar. Gerät in Form einer 8 bewegen und erneut versuchen.',
          );
        }

        final double heading = normalizeAngle(rawHeading);
        final double relativeDirection = normalizeAngle(qiblaBearing - heading);
        final double delta =
            smallestAngleDifference(heading, qiblaBearing).abs();
        final bool aligned = delta <= 8;

        return Column(
          children: <Widget>[
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.03),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                  Container(
                    width: 184,
                    height: 184,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  _CompassMark(
                    alignment: Alignment.topCenter,
                    label: 'N',
                    color: const Color(0xFFFFD166),
                  ),
                  const _CompassMark(
                    alignment: Alignment.centerRight,
                    label: 'E',
                  ),
                  const _CompassMark(
                    alignment: Alignment.bottomCenter,
                    label: 'S',
                  ),
                  const _CompassMark(
                    alignment: Alignment.centerLeft,
                    label: 'W',
                  ),
                  Transform.rotate(
                    angle: _degToRad(relativeDirection),
                    child: Transform.translate(
                      offset: const Offset(0, -72),
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 68,
                        color: aligned
                            ? const Color(0xFF5BE39C)
                            : const Color(0xFFFF7A8A),
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF64E0D6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _CompassInfoChip(
                  label: 'Qibla',
                  value: '${qiblaBearing.toStringAsFixed(0)}°',
                ),
                _CompassInfoChip(
                  label: 'Gerät',
                  value: '${heading.toStringAsFixed(0)}°',
                ),
                _CompassInfoChip(
                  label: aligned ? 'Ausrichtung' : 'Abweichung',
                  value:
                      aligned ? 'Ausgerichtet' : '${delta.toStringAsFixed(0)}°',
                  isPositive: aligned,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Stream<CompassEvent>? _safeCompassStream() {
    try {
      return FlutterCompass.events;
    } catch (_) {
      return null;
    }
  }
}

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.explore_off_rounded, color: Color(0xFFFFD166)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              )
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.84)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassMark extends StatelessWidget {
  const _CompassMark({
    required this.alignment,
    required this.label,
    this.color = Colors.white,
  });

  final Alignment alignment;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CompassInfoChip extends StatelessWidget {
  const _CompassInfoChip({
    required this.label,
    required this.value,
    this.isPositive = false,
  });

  final String label;
  final String value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF5BE39C).withOpacity(0.14)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF5BE39C).withOpacity(0.6)
              : Colors.white.withOpacity(0.14),
        ),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isPositive ? const Color(0xFFB6FFDA) : Colors.white,
            ),
      ),
    );
  }
}

double _degToRad(double degrees) => degrees * (math.pi / 180);

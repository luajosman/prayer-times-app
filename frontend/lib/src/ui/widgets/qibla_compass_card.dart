import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:frontend/src/core/design_tokens.dart';
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header row
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Qibla',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locationLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Bearing badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.navigation_rounded,
                      size: 11,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${qiblaBearing.toStringAsFixed(0)}°',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.goldLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Compass
          Center(
            child: _CompassBody(
              qiblaBearing: qiblaBearing,
              latitude: latitude,
              longitude: longitude,
              locationLabel: locationLabel,
            ),
          ),
          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMapView(context),
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: const Text('Luftlinie'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openInGoogleMaps(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Google Maps'),
                ),
              ),
            ],
          ),
        ],
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

// ── Compass body ──────────────────────────────────────────────────────────────

class _CompassBody extends StatelessWidget {
  const _CompassBody({
    required this.qiblaBearing,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
  });

  final double qiblaBearing;
  final double latitude;
  final double longitude;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final Stream<CompassEvent>? stream = _safeStream();

    if (stream == null) {
      return const _CompassUnavailable(
        message: 'Kompass wird auf diesem Gerät nicht unterstützt.',
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (BuildContext ctx, AsyncSnapshot<CompassEvent> snap) {
        if (snap.hasError) {
          return const _CompassUnavailable(
            message: 'Kompass konnte nicht geladen werden.',
          );
        }

        final double? rawHeading = snap.data?.heading;
        if (rawHeading == null || rawHeading.isNaN) {
          return const _CompassUnavailable(
            message: 'Keine Sensordaten. Gerät in Form einer 8 bewegen.',
          );
        }

        final double heading = normalizeAngle(rawHeading);
        final double relativeDir =
            normalizeAngle(qiblaBearing - heading);
        final double delta =
            smallestAngleDifference(heading, qiblaBearing).abs();

        final bool aligned = delta <= 8;
        final bool close = delta <= 30;

        final Color needleColor = aligned
            ? AppColors.gold
            : close
                ? AppColors.warning
                : AppColors.primaryLight;

        return Column(
          children: <Widget>[
            SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Outer ring
                  Container(
                    width: 224,
                    height: 224,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceHigh,
                      border: Border.all(
                          color: AppColors.border, width: 1.5),
                    ),
                  ),
                  // Inner ring
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.borderSubtle, width: 1),
                    ),
                  ),
                  // Cardinal marks
                  const _CardinalMark(
                    alignment: Alignment.topCenter,
                    label: 'N',
                    color: AppColors.gold,
                  ),
                  const _CardinalMark(
                    alignment: Alignment.centerRight,
                    label: 'O',
                  ),
                  const _CardinalMark(
                    alignment: Alignment.bottomCenter,
                    label: 'S',
                  ),
                  const _CardinalMark(
                    alignment: Alignment.centerLeft,
                    label: 'W',
                  ),
                  // Compass needle
                  Transform.rotate(
                    angle: _toRad(relativeDir),
                    child: SizedBox(
                      width: 16,
                      height: 148,
                      child: CustomPaint(
                        painter: _NeedlePainter(
                          northColor: needleColor,
                          southColor: AppColors.textTertiary
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                  // Center dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                          color: AppColors.border, width: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Info chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _CompassChip(
                  label: 'Qibla',
                  value: '${qiblaBearing.toStringAsFixed(0)}°',
                  color: AppColors.gold,
                ),
                _CompassChip(
                  label: 'Gerät',
                  value: '${heading.toStringAsFixed(0)}°',
                ),
                _CompassChip(
                  label: aligned ? '✓ Ausgerichtet' : 'Abweichung',
                  value: aligned
                      ? ''
                      : '${delta.toStringAsFixed(0)}°',
                  color: aligned
                      ? AppColors.success
                      : close
                          ? AppColors.warning
                          : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Stream<CompassEvent>? _safeStream() {
    try {
      return FlutterCompass.events;
    } catch (_) {
      return null;
    }
  }
}

// ── Compass unavailable state ─────────────────────────────────────────────────

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.explore_off_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cardinal mark ─────────────────────────────────────────────────────────────

class _CardinalMark extends StatelessWidget {
  const _CardinalMark({
    required this.alignment,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final Alignment alignment;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

// ── Compass info chip ─────────────────────────────────────────────────────────

class _CompassChip extends StatelessWidget {
  const _CompassChip({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolvedColor = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: resolvedColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        value.isEmpty ? label : '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: resolvedColor.withValues(alpha: 0.9),
            ),
      ),
    );
  }
}

// ── Needle painter ────────────────────────────────────────────────────────────

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({
    required this.northColor,
    required this.southColor,
  });

  final Color northColor;
  final Color southColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // North half — points toward Qibla direction
    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..lineTo(cx + 5.5, cy - 6)
        ..lineTo(cx, cy)
        ..lineTo(cx - 5.5, cy - 6)
        ..close(),
      Paint()
        ..color = northColor
        ..style = PaintingStyle.fill,
    );

    // South half — counterbalance
    canvas.drawPath(
      Path()
        ..moveTo(cx, size.height)
        ..lineTo(cx + 5.5, cy + 6)
        ..lineTo(cx, cy)
        ..lineTo(cx - 5.5, cy + 6)
        ..close(),
      Paint()
        ..color = southColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) =>
      old.northColor != northColor || old.southColor != southColor;
}

double _toRad(double deg) => deg * (math.pi / 180);

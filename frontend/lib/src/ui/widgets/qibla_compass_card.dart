import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/ui/qibla_map_page.dart';
import 'package:frontend/src/utils/qibla_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class QiblaCompassCard extends StatelessWidget {
  const QiblaCompassCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.phaseStyle,
  });

  final double latitude;
  final double longitude;
  final String locationLabel;
  final PrayerPhaseStyle phaseStyle;

  @override
  Widget build(BuildContext context) {
    final double qiblaBearing = calculateQiblaBearing(
      latitude: latitude,
      longitude: longitude,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.panel,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -18,
            right: -8,
            child: _AmbientOrb(
              color: AppColors.overlay(
                phaseStyle.qiblaAmbient,
                AppColors.gold,
                0.18,
              ),
              size: 118,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Qibla',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          locationLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _BearingBadge(bearing: qiblaBearing),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: _CompassBody(
                  qiblaBearing: qiblaBearing,
                  latitude: latitude,
                  longitude: longitude,
                  locationLabel: locationLabel,
                  phaseStyle: phaseStyle,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openMapView(context),
                      icon: const Icon(Icons.alt_route_rounded, size: 16),
                      label: const Text('Luftlinie'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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
          phaseStyle: phaseStyle,
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
        content: Text(
          'Google Maps konnte nicht geöffnet werden. Link kopiert.',
        ),
      ),
    );
  }
}

class _BearingBadge extends StatelessWidget {
  const _BearingBadge({required this.bearing});

  final double bearing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldTint,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.goldSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.navigation_rounded,
            size: 14,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${bearing.toStringAsFixed(0)}°',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.gold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompassBody extends StatelessWidget {
  const _CompassBody({
    required this.qiblaBearing,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.phaseStyle,
  });

  final double qiblaBearing;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final PrayerPhaseStyle phaseStyle;

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
      builder: (BuildContext context, AsyncSnapshot<CompassEvent> snapshot) {
        if (snapshot.hasError) {
          return const _CompassUnavailable(
            message: 'Kompass konnte nicht geladen werden.',
          );
        }

        final double? rawHeading = snapshot.data?.heading;
        if (rawHeading == null || rawHeading.isNaN) {
          return const _CompassUnavailable(
            message: 'Keine Sensordaten. Gerät in Form einer 8 bewegen.',
          );
        }

        final double heading = normalizeAngle(rawHeading);
        final double relativeDir = normalizeAngle(qiblaBearing - heading);
        final double delta =
            smallestAngleDifference(heading, qiblaBearing).abs();
        final bool aligned = delta <= 8;
        final bool close = delta <= 30;

        final Color needleColor = aligned
            ? AppColors.gold
            : close
                ? AppColors.warning
                : phaseStyle.accentSoft;

        return Column(
          children: <Widget>[
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 226,
                    height: 226,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.overlay(
                        phaseStyle.qiblaAmbient,
                        AppColors.surfaceStrong,
                        0.24,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  Container(
                    width: 176,
                    height: 176,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderSubtle,
                      ),
                    ),
                  ),
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
                  Transform.rotate(
                    angle: _toRad(relativeDir),
                    child: SizedBox(
                      width: 18,
                      height: 156,
                      child: CustomPaint(
                        painter: _NeedlePainter(
                          northColor: needleColor,
                          southColor: AppColors.textTertiary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceStrong,
                      border: Border.all(
                        color: AppColors.border,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
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
                  color: phaseStyle.accentSoft,
                ),
                _CompassChip(
                  label: aligned ? 'Ausrichtung' : 'Abweichung',
                  value: aligned ? 'ok' : '${delta.toStringAsFixed(0)}°',
                  color: aligned
                      ? AppColors.success
                      : close
                          ? AppColors.warning
                          : AppColors.textSecondary,
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

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.explore_off_rounded,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
              ),
        ),
      ),
    );
  }
}

class _CompassChip extends StatelessWidget {
  const _CompassChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.overlay(color, AppColors.surfaceStrong, 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
            ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

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

    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..lineTo(cx + 6, cy - 8)
        ..lineTo(cx, cy)
        ..lineTo(cx - 6, cy - 8)
        ..close(),
      Paint()
        ..color = northColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx, size.height)
        ..lineTo(cx + 6, cy + 8)
        ..lineTo(cx, cy)
        ..lineTo(cx - 6, cy + 8)
        ..close(),
      Paint()
        ..color = southColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) {
    return oldDelegate.northColor != northColor ||
        oldDelegate.southColor != southColor;
  }
}

double _toRad(double deg) => deg * (math.pi / 180);

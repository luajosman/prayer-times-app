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
    final AppPalette palette = AppPalette.of(context);
    final double qiblaBearing = calculateQiblaBearing(
      latitude: latitude,
      longitude: longitude,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
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
                palette.gold,
                0.18,
              ),
              size: 118,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Qibla',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${qiblaBearing.toStringAsFixed(0)}° zur Kaaba',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.gold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                locationLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: _CompassPanel(
                  qiblaBearing: qiblaBearing,
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
                      label: const Text('Qibla-Karte'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openInGoogleMaps(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('In Google Maps'),
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

class _CompassPanel extends StatelessWidget {
  const _CompassPanel({
    required this.qiblaBearing,
    required this.phaseStyle,
  });

  final double qiblaBearing;
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
        final double relativeDirection = normalizeAngle(qiblaBearing - heading);
        final double delta =
            smallestAngleDifference(heading, qiblaBearing).abs();
        final bool aligned = delta <= 8;
        final bool close = delta <= 30;
        final Color toneColor = aligned
            ? AppColors.success
            : close
                ? AppColors.warning
                : phaseStyle.accentSoft;

        final String statusLabel = aligned
            ? 'Ausrichtung gut'
            : close
                ? 'Noch ${delta.toStringAsFixed(0)}° bis Qibla'
                : '${delta.toStringAsFixed(0)}° Abweichung';
        final String detailLabel =
            aligned ? 'Sensor aktiv' : 'Gerät ${heading.toStringAsFixed(0)}°';

        return Column(
          children: <Widget>[
            _CompassDial(
              relativeDirection: relativeDirection,
              phaseStyle: phaseStyle,
              needleColor: toneColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            _QiblaStatusRow(
              statusLabel: statusLabel,
              detailLabel: detailLabel,
              toneColor: toneColor,
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

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.relativeDirection,
    required this.phaseStyle,
    required this.needleColor,
  });

  final double relativeDirection;
  final PrayerPhaseStyle phaseStyle;
  final Color needleColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      width: 270,
      height: 270,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(color: palette.border),
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
                palette.surfaceStrong,
                0.24,
              ),
              border: Border.all(color: palette.border),
            ),
          ),
          Container(
            width: 176,
            height: 176,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.borderSubtle),
            ),
          ),
          _CardinalMark(
            alignment: Alignment.topCenter,
            label: 'N',
            color: palette.gold,
          ),
          _CardinalMark(
            alignment: Alignment.centerRight,
            label: 'O',
            color: palette.textSecondary,
          ),
          _CardinalMark(
            alignment: Alignment.bottomCenter,
            label: 'S',
            color: palette.textSecondary,
          ),
          _CardinalMark(
            alignment: Alignment.centerLeft,
            label: 'W',
            color: palette.textSecondary,
          ),
          Transform.rotate(
            angle: _toRad(relativeDirection),
            child: SizedBox(
              width: 18,
              height: 156,
              child: CustomPaint(
                painter: _NeedlePainter(
                  northColor: needleColor,
                  southColor: palette.textTertiary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceStrong,
              border: Border.all(
                color: palette.border,
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QiblaStatusRow extends StatelessWidget {
  const _QiblaStatusRow({
    required this.statusLabel,
    required this.detailLabel,
    required this.toneColor,
  });

  final String statusLabel;
  final String detailLabel;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceStrong,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: toneColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$statusLabel · $detailLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.explore_off_rounded,
            color: palette.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                  ),
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
    required this.color,
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
    final Paint northPaint = Paint()
      ..color = northColor
      ..style = PaintingStyle.fill;
    final Paint southPaint = Paint()
      ..color = southColor
      ..style = PaintingStyle.fill;

    final Path northPath = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(0, size.height * 0.6)
      ..close();

    final Path southPath = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(size.width / 2, size.height * 0.58)
      ..lineTo(0, size.height * 0.4)
      ..close();

    canvas.drawShadow(northPath, northColor.withValues(alpha: 0.28), 8, false);
    canvas.drawPath(northPath, northPaint);
    canvas.drawPath(southPath, southPaint);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter oldDelegate) {
    return oldDelegate.northColor != northColor ||
        oldDelegate.southColor != southColor;
  }
}

double _toRad(double degrees) => degrees * (math.pi / 180);

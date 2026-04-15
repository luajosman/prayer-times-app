import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/src/controllers/prayer_times_controller.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_constants.dart';
import 'package:frontend/src/ui/widgets/qibla_compass_card.dart';
import 'package:frontend/src/ui/widgets/prayer_time_tile.dart';
import 'package:frontend/src/utils/prayer_time_utils.dart';

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({
    super.key,
    this.autoLoad = true,
    this.controller,
  });

  final bool autoLoad;
  final PrayerTimesController? controller;

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  late final PrayerTimesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? PrayerTimesController();
    if (widget.autoLoad) {
      unawaited(_controller.initialize());
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final PrayerEvent? next = _controller.nextPrayer;
        final Duration? countdown = _controller.nextPrayerIn;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: RefreshIndicator(
                  onRefresh: () => _controller.refresh(),
                  color: AppColors.primaryLight,
                  backgroundColor: AppColors.surfaceHigh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
                    children: <Widget>[
                      _buildAppHeader(),
                      const SizedBox(height: 12),
                      _buildTrustBar(),
                      const SizedBox(height: 16),
                      _buildNextPrayerCard(context, next, countdown),
                      if (_controller.errorMessage != null) ...<Widget>[
                        const SizedBox(height: 10),
                        _buildErrorBanner(),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionLabel(
                        context,
                        'Gebetszeiten',
                        trailing: _controller.response?.date,
                      ),
                      const SizedBox(height: 10),
                      if (_controller.isLoading)
                        _buildLoadingShimmer()
                      else
                        ..._buildPrayerTiles(context, next),
                      const SizedBox(height: 28),
                      _buildSectionLabel(context, 'Qibla'),
                      const SizedBox(height: 10),
                      _buildAnimated(index: 14, child: _buildQiblaCard()),
                      const SizedBox(height: 28),
                      _buildSectionLabel(context, 'Einstellungen'),
                      const SizedBox(height: 10),
                      _buildAnimated(
                          index: 20, child: _buildControlCard(context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── App header ─────────────────────────────────────────────────────────────

  Widget _buildAppHeader() {
    return Row(
      children: <Widget>[
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.explore_rounded,
            color: AppColors.gold,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Salah Navigator',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _controller.isRefreshing
              ? null
              : () => unawaited(_controller.refresh()),
          icon: AnimatedRotation(
            duration: const Duration(milliseconds: 400),
            turns: _controller.isRefreshing ? 1.0 : 0.0,
            child: const Icon(Icons.refresh_rounded, size: 20),
          ),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
          ),
          tooltip: 'Aktualisieren',
        ),
      ],
    );
  }

  // ── Trust context bar ──────────────────────────────────────────────────────

  Widget _buildTrustBar() {
    final String? tz = _controller.response?.timezone.trim();
    final int method = _controller.settings.method;
    final int school = _controller.settings.school;

    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _TrustChip(
            icon: Icons.place_outlined,
            label: _controller.locationHeadline,
          ),
          if (tz != null && tz.isNotEmpty) ...<Widget>[
            const SizedBox(width: 6),
            _TrustChip(icon: Icons.public_rounded, label: tz),
          ],
          const SizedBox(width: 6),
          _TrustChip(
            icon: Icons.tune_rounded,
            label: 'Methode $method',
          ),
          const SizedBox(width: 6),
          _TrustChip(
            icon: Icons.school_outlined,
            label: schoolLabels[school] ?? school.toString(),
          ),
          if (_controller.lastUpdatedAt != null) ...<Widget>[
            const SizedBox(width: 6),
            _TrustChip(
              icon: Icons.schedule_rounded,
              label: _lastUpdatedLabel(_controller.lastUpdatedAt),
            ),
          ],
        ],
      ),
    );
  }

  // ── Next prayer hero card ──────────────────────────────────────────────────

  Widget _buildNextPrayerCard(
    BuildContext context,
    PrayerEvent? next,
    Duration? countdown,
  ) {
    return _buildAnimated(
      index: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: next != null
                ? AppColors.gold.withValues(alpha: 0.28)
                : AppColors.border,
          ),
        ),
        child: _controller.isLoading
            ? _buildHeroLoading()
            : _buildHeroContent(context, next, countdown),
      ),
    );
  }

  Widget _buildHeroLoading() {
    return const SizedBox(
      height: 96,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryLight,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildHeroContent(
    BuildContext context,
    PrayerEvent? next,
    Duration? countdown,
  ) {
    if (next == null || countdown == null) {
      return _buildHeroEmpty(context);
    }

    final String nextLabel = prayerLabelsDe[next.key] ?? next.key;
    final String timeStr = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(next.at),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NÄCHSTES GEBET',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.gold.withValues(alpha: 0.75),
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    nextLabel,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatCountdown(countdown),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'verbleibend',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Keine Gebetszeiten verfügbar',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return _buildAnimated(
      index: 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Fehler beim Laden',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.error.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _controller.errorMessage ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_controller.refresh()),
                    icon: const Icon(Icons.replay_rounded, size: 15),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(
    BuildContext context,
    String label, {
    String? trailing,
  }) {
    return Row(
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
          ),
        ],
      ],
    );
  }

  // ── Prayer tiles ───────────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryLight,
          strokeWidth: 2,
        ),
      ),
    );
  }

  List<Widget> _buildPrayerTiles(BuildContext context, PrayerEvent? next) {
    if (_controller.visibleTimes.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Keine Gebetszeiten verfügbar. Prüfe Backend und Standort.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ];
    }

    final List<Widget> items = <Widget>[];
    int index = 0;

    for (final String key in canonicalPrayerOrder) {
      final String? rawTime = _controller.visibleTimes[key];
      if (rawTime == null) continue;

      final String label = prayerLabelsDe[key] ?? key;
      final String formattedTime = _formatApiTime(context, rawTime);
      final bool isNext = next?.key == key;

      items.add(
        _buildAnimated(
          index: index + 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PrayerTimeTile(
              prayerKey: key,
              title: label,
              time: formattedTime,
              isNext: isNext,
            ),
          ),
        ),
      );
      index++;
    }

    return items;
  }

  // ── Qibla card ─────────────────────────────────────────────────────────────

  Widget _buildQiblaCard() {
    final double latitude =
        _controller.response?.latitude ?? _controller.settings.manualLatitude;
    final double longitude =
        _controller.response?.longitude ?? _controller.settings.manualLongitude;

    return QiblaCompassCard(
      latitude: latitude,
      longitude: longitude,
      locationLabel: _controller.locationSummary,
    );
  }

  // ── Control / settings card ────────────────────────────────────────────────

  Widget _buildControlCard(BuildContext context) {
    final bool useLive = _controller.settings.useDeviceLocation;

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
          // Location mode toggle
          _SettingsRow(
            label: 'Standortmodus',
            child: Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Live-GPS'),
                  selected: useLive,
                  onSelected: (_) =>
                      unawaited(_controller.setUseDeviceLocation(true)),
                ),
                ChoiceChip(
                  label: const Text('Manuell'),
                  selected: !useLive,
                  onSelected: (_) =>
                      unawaited(_controller.setUseDeviceLocation(false)),
                ),
              ],
            ),
          ),
          if (!useLive) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _openManualLocationSheet(context),
              icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
              label: const Text('Koordinaten bearbeiten'),
            ),
          ],
          const _SettingsDivider(),

          // Calculation method
          _SettingsRow(
            label: 'Berechnungsmethode',
            child: DropdownButtonFormField<int>(
              value: _controller.settings.method,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              dropdownColor: AppColors.surfaceHigh,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              items: _controller.availableMethods
                  .map((int m) => DropdownMenuItem<int>(
                        value: m,
                        child: Text(
                          '$m · ${methodLabels[m]}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ))
                  .toList(),
              selectedItemBuilder: (BuildContext ctx) =>
                  _controller.availableMethods
                      .map((int m) => Text(
                            '$m · ${methodLabels[m]}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ))
                      .toList(),
              onChanged: (int? value) {
                if (value != null) unawaited(_controller.updateMethod(value));
              },
            ),
          ),
          const _SettingsDivider(),

          // Madhhab / school
          _SettingsRow(
            label: 'Rechtsschule (Asr)',
            child: Wrap(
              spacing: 8,
              children: _controller.availableSchools.map((int s) {
                return ChoiceChip(
                  label: Text(schoolLabels[s] ?? s.toString()),
                  selected: _controller.settings.school == s,
                  onSelected: (_) => unawaited(_controller.updateSchool(s)),
                );
              }).toList(),
            ),
          ),

          // Coordinate context
          if (_controller.response != null ||
              !_controller.settings.useDeviceLocation) ...<Widget>[
            const _SettingsDivider(),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatCoordinates(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Manual location bottom sheet ───────────────────────────────────────────

  Future<void> _openManualLocationSheet(BuildContext context) async {
    final double seedLat =
        _controller.response?.latitude ?? _controller.settings.manualLatitude;
    final double seedLon =
        _controller.response?.longitude ?? _controller.settings.manualLongitude;

    final String liveLabel = _controller.locationSummary.trim();
    final String seedLabel = _controller.settings.useDeviceLocation &&
            liveLabel.isNotEmpty &&
            liveLabel != 'Live-Standort'
        ? liveLabel
        : _controller.settings.manualLabel;

    final TextEditingController labelCtrl =
        TextEditingController(text: seedLabel);
    final TextEditingController latCtrl =
        TextEditingController(text: seedLat.toStringAsFixed(6));
    final TextEditingController lonCtrl =
        TextEditingController(text: seedLon.toStringAsFixed(6));

    String? inlineError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setModal) {
            final EdgeInsets insets = MediaQuery.of(ctx2).viewInsets;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + insets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Manueller Standort',
                      style: Theme.of(ctx2).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Fallback, wenn GPS oder Berechtigungen fehlen.',
                    style: Theme.of(ctx2).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Bezeichnung (z. B. Berlin)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration:
                              const InputDecoration(labelText: 'Latitude'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: lonCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration:
                              const InputDecoration(labelText: 'Longitude'),
                        ),
                      ),
                    ],
                  ),
                  if (inlineError != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      inlineError!,
                      style: Theme.of(ctx2).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final double? lat = _safeParse(latCtrl.text);
                        final double? lon = _safeParse(lonCtrl.text);

                        if (lat == null || lon == null) {
                          setModal(() =>
                              inlineError = 'Bitte gültige Zahlen eingeben.');
                          return;
                        }
                        if (lat < -90 || lat > 90) {
                          setModal(() => inlineError =
                              'Latitude muss zwischen −90 und 90 liegen.');
                          return;
                        }
                        if (lon < -180 || lon > 180) {
                          setModal(() => inlineError =
                              'Longitude muss zwischen −180 und 180 liegen.');
                          return;
                        }

                        await _controller.saveManualLocation(
                          latitude: lat,
                          longitude: lon,
                          label: labelCtrl.text,
                        );

                        if (!ctx2.mounted) return;
                        Navigator.of(ctx2).pop();
                      },
                      child: const Text('Speichern und aktualisieren'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    labelCtrl.dispose();
    latCtrl.dispose();
    lonCtrl.dispose();
  }

  // ── Animation helper ───────────────────────────────────────────────────────

  Widget _buildAnimated({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index * 55)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext ctx, double v, Widget? inner) {
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 16),
            child: inner,
          ),
        );
      },
      child: child,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatApiTime(BuildContext context, String rawTime) {
    final DateTime? parsed = parseApiTimeToDateTime(rawTime, DateTime.now());
    if (parsed == null) return rawTime;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(parsed),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String _lastUpdatedLabel(DateTime? at) {
    if (at == null) return 'Noch nicht geladen';
    final int minutes = DateTime.now().difference(at).inMinutes;
    if (minutes <= 0) return 'Gerade eben';
    if (minutes == 1) return 'Vor 1 Min.';
    return 'Vor $minutes Min.';
  }

  String _formatCoordinates() {
    final data = _controller.response;
    if (data != null) {
      return '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    }
    return '${_controller.settings.manualLatitude.toStringAsFixed(4)}, '
        '${_controller.settings.manualLongitude.toStringAsFixed(4)}';
  }

  double? _safeParse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
}

// ── Trust chip ────────────────────────────────────────────────────────────────

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 11, color: AppColors.primaryLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Settings helpers ──────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/src/controllers/prayer_times_controller.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_constants.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/ui/widgets/home_app_bar.dart';
import 'package:frontend/src/ui/widgets/next_prayer_hero.dart';
import 'package:frontend/src/ui/widgets/prayer_time_tile.dart';
import 'package:frontend/src/ui/widgets/qibla_compass_card.dart';
import 'package:frontend/src/ui/widgets/section_header.dart';
import 'package:frontend/src/ui/widgets/status_banner.dart';
import 'package:frontend/src/ui/widgets/trust_context_strip.dart';
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

class _PrayerHomePageState extends State<PrayerHomePage>
    with WidgetsBindingObserver {
  late final PrayerTimesController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? PrayerTimesController();
    if (widget.autoLoad) {
      unawaited(_controller.initialize());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.autoLoad) {
      unawaited(_controller.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final PrayerEvent? next = _controller.nextPrayer;
        final Duration? countdown = _controller.nextPrayerIn;
        final PrayerPhaseStyle phaseStyle = _controller.phaseStyle;

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.overlay(
                    phaseStyle.tint,
                    AppColors.background,
                    0.06,
                  ),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: RefreshIndicator(
                    onRefresh: () => _controller.refresh(),
                    color: AppColors.primarySoft,
                    backgroundColor: AppColors.surfaceStrong,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.section,
                      ),
                      children: <Widget>[
                        _buildAnimated(
                          index: 0,
                          child: HomeAppBar(
                            phaseStyle: phaseStyle,
                            refreshing: _controller.isRefreshing,
                            onRefresh: () => unawaited(_controller.refresh()),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAnimated(
                          index: 1,
                          child: NextPrayerHero(
                            phaseStyle: phaseStyle,
                            loading: _controller.isLoading,
                            prayerLabel: next == null
                                ? null
                                : (prayerLabelsDe[next.key] ?? next.key),
                            timeLabel: next == null
                                ? null
                                : _formatTime(context, next.at),
                            countdownLabel: countdown == null
                                ? null
                                : formatCountdown(countdown),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAnimated(
                          index: 2,
                          child: _buildTrustStrip(phaseStyle),
                        ),
                        if (_controller.errorMessage != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          _buildAnimated(
                            index: 3,
                            child: StatusBanner(
                              title: 'Fehler beim Laden',
                              message: _controller.errorMessage ?? '',
                              icon: Icons.error_outline_rounded,
                              tone: StatusBannerTone.error,
                              actionLabel: 'Erneut versuchen',
                              onAction: () => unawaited(_controller.refresh()),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        SectionHeader(
                          label: 'Gebetszeiten',
                          trailing: _controller.response?.date,
                          accentColor: phaseStyle.sectionAccent,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_controller.isLoading)
                          _buildLoadingCard()
                        else
                          ..._buildPrayerTiles(next, phaseStyle),
                        const SizedBox(height: AppSpacing.xxl),
                        const SectionHeader(
                          label: 'Qibla',
                          accentColor: AppColors.gold,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAnimated(index: 12, child: _buildQiblaCard()),
                        const SizedBox(height: AppSpacing.xxl),
                        SectionHeader(
                          label: 'Einstellungen',
                          accentColor: phaseStyle.sectionAccent,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAnimated(
                          index: 16,
                          child: _buildSettingsCard(phaseStyle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrustStrip(PrayerPhaseStyle phaseStyle) {
    final String? timezone = _controller.response?.timezone.trim();
    final String methodLabel =
        '${_controller.settings.method} · ${methodLabels[_controller.settings.method] ?? 'Methode'}';
    final String schoolLabel =
        'Asr · ${schoolLabels[_controller.settings.school] ?? _controller.settings.school.toString()}';

    return TrustContextStrip(
      location: _controller.locationHeadline,
      timezone: timezone,
      methodLabel: methodLabel,
      schoolLabel: schoolLabel,
      phaseStyle: phaseStyle,
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primarySoft,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Gebetszeiten werden geladen …',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPrayerTiles(
    PrayerEvent? next,
    PrayerPhaseStyle phaseStyle,
  ) {
    if (_controller.visibleTimes.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Keine Gebetszeiten verfügbar. Prüfe Backend, Standort oder Berechtigungen.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ];
    }

    final List<Widget> items = <Widget>[];

    for (int i = 0; i < canonicalPrayerOrder.length; i++) {
      final String key = canonicalPrayerOrder[i];
      final String? rawTime = _controller.visibleTimes[key];
      if (rawTime == null) {
        continue;
      }

      items.add(
        _buildAnimated(
          index: i + 4,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: PrayerTimeTile(
              prayerKey: key,
              title: prayerLabelsDe[key] ?? key,
              time: _formatApiTime(context, rawTime),
              isNext: next?.key == key,
              phaseStyle: phaseStyle,
            ),
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildQiblaCard() {
    final double latitude =
        _controller.response?.latitude ?? _controller.settings.manualLatitude;
    final double longitude =
        _controller.response?.longitude ?? _controller.settings.manualLongitude;

    return QiblaCompassCard(
      latitude: latitude,
      longitude: longitude,
      locationLabel: _controller.locationSummary,
      phaseStyle: _controller.phaseStyle,
    );
  }

  Widget _buildSettingsCard(PrayerPhaseStyle phaseStyle) {
    final bool useLive = _controller.settings.useDeviceLocation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.panel,
      ),
      child: Column(
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
                      'Berechnung und Standort',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Stabile Defaults, klare Transparenz und manuelle Kontrolle bei Bedarf.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (_controller.settings.useAutoMethod)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlay(
                      phaseStyle.accent,
                      AppColors.surfaceStrong,
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: phaseStyle.accent.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Text(
                    'Auto nach Region',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: phaseStyle.accentSoft,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsGroup(
            label: 'Standortmodus',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
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
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _openManualLocationSheet(context),
              icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
              label: const Text('Koordinaten bearbeiten'),
            ),
          ],
          const _SettingsDivider(),
          _SettingsGroup(
            label: 'Berechnungsmethode',
            child: DropdownButtonFormField<int>(
              key: ValueKey<int>(_controller.settings.method),
              initialValue: _controller.settings.method,
              decoration: const InputDecoration(
                labelText: 'Calculation method',
              ),
              dropdownColor: AppColors.surfaceStrong,
              isExpanded: true,
              items: _controller.availableMethods
                  .map(
                    (int method) => DropdownMenuItem<int>(
                      value: method,
                      child: Text(
                        '$method · ${methodLabels[method] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (int? value) {
                if (value != null) {
                  unawaited(_controller.updateMethod(value));
                }
              },
            ),
          ),
          const _SettingsDivider(),
          _SettingsGroup(
            label: 'Rechtsschule (Asr)',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _controller.availableSchools.map((int school) {
                return ChoiceChip(
                  label: Text(schoolLabels[school] ?? school.toString()),
                  selected: _controller.settings.school == school,
                  onSelected: (_) =>
                      unawaited(_controller.updateSchool(school)),
                );
              }).toList(),
            ),
          ),
          const _SettingsDivider(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.location_searching_rounded,
                  color: phaseStyle.accentSoft,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Aktive Koordinaten',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatCoordinates(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            final EdgeInsets insets = MediaQuery.of(modalContext).viewInsets;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl + insets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Manueller Standort',
                    style: Theme.of(modalContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Fallback, wenn GPS oder Berechtigungen fehlen.',
                    style: Theme.of(modalContext).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: labelCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Bezeichnung',
                      hintText: 'z. B. Berlin',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      const SizedBox(width: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      inlineError!,
                      style:
                          Theme.of(modalContext).textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                              ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final double? lat = _safeParse(latCtrl.text);
                        final double? lon = _safeParse(lonCtrl.text);

                        if (lat == null || lon == null) {
                          setModalState(
                            () =>
                                inlineError = 'Bitte gültige Zahlen eingeben.',
                          );
                          return;
                        }
                        if (lat < -90 || lat > 90) {
                          setModalState(() {
                            inlineError =
                                'Latitude muss zwischen −90 und 90 liegen.';
                          });
                          return;
                        }
                        if (lon < -180 || lon > 180) {
                          setModalState(() {
                            inlineError =
                                'Longitude muss zwischen −180 und 180 liegen.';
                          });
                          return;
                        }

                        await _controller.saveManualLocation(
                          latitude: lat,
                          longitude: lon,
                          label: labelCtrl.text,
                        );

                        if (!modalContext.mounted) {
                          return;
                        }
                        Navigator.of(modalContext).pop();
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

  Widget _buildAnimated({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  String _formatApiTime(BuildContext context, String rawTime) {
    final DateTime? parsed = parseApiTimeToDateTime(rawTime, DateTime.now());
    if (parsed == null) {
      return rawTime;
    }
    return _formatTime(context, parsed);
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String _formatCoordinates() {
    final data = _controller.response;
    if (data != null) {
      return '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    }
    return '${_controller.settings.manualLatitude.toStringAsFixed(4)}, ${_controller.settings.manualLongitude.toStringAsFixed(4)}';
  }

  double? _safeParse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Divider(height: 1),
    );
  }
}

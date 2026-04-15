import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/src/controllers/prayer_times_controller.dart';
import 'package:frontend/src/core/app_theme_preference.dart';
import 'package:frontend/src/core/design_tokens.dart';
import 'package:frontend/src/core/prayer_constants.dart';
import 'package:frontend/src/core/prayer_phase_style.dart';
import 'package:frontend/src/ui/widgets/home_app_bar.dart';
import 'package:frontend/src/ui/widgets/next_prayer_hero.dart';
import 'package:frontend/src/ui/widgets/prayer_time_tile.dart';
import 'package:frontend/src/ui/widgets/qibla_compass_card.dart';
import 'package:frontend/src/ui/widgets/segmented_setting.dart';
import 'package:frontend/src/ui/widgets/section_header.dart';
import 'package:frontend/src/ui/widgets/status_banner.dart';
import 'package:frontend/src/ui/widgets/trust_context_strip.dart';
import 'package:frontend/src/utils/prayer_time_utils.dart';

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({
    super.key,
    this.autoLoad = true,
    this.controller,
    this.onThemeModeChanged,
    this.onPrayerPhaseChanged,
  });

  final bool autoLoad;
  final PrayerTimesController? controller;
  final ValueChanged<AppThemePreference>? onThemeModeChanged;
  final ValueChanged<PrayerPhase>? onPrayerPhaseChanged;

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage>
    with WidgetsBindingObserver {
  late final PrayerTimesController _controller;
  late final bool _ownsController;
  AppThemePreference? _lastReportedThemeMode;
  PrayerPhase? _lastReportedPrayerPhase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? PrayerTimesController();
    _controller.addListener(_syncAppState);
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
    _controller.removeListener(_syncAppState);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _syncAppState() {
    final AppThemePreference themeMode = _controller.settings.themePreference;
    if (_lastReportedThemeMode != themeMode) {
      _lastReportedThemeMode = themeMode;
      widget.onThemeModeChanged?.call(themeMode);
    }

    final PrayerPhase phase = _controller.prayerPhase;
    if (_lastReportedPrayerPhase != phase) {
      _lastReportedPrayerPhase = phase;
      widget.onPrayerPhaseChanged?.call(phase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final PrayerEvent? next = _controller.nextPrayer;
        final Duration? countdown = _controller.nextPrayerIn;
        final PrayerPhaseStyle phaseStyle = _controller.phaseStyle;
        final AppPalette palette = AppPalette.of(context);

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  AppColors.overlay(
                    phaseStyle.tint,
                    palette.background,
                    0.06,
                  ),
                  palette.background,
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
                    backgroundColor: palette.surfaceStrong,
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
                          child: _buildSettingsPanel(context, phaseStyle),
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
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.primarySoft,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Gebetszeiten werden geladen …',
              style: TextStyle(
                color: palette.textSecondary,
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
    final AppPalette palette = AppPalette.of(context);

    if (_controller.visibleTimes.isEmpty) {
      return <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            'Keine Gebetszeiten verfügbar. Prüfe Backend, Standort oder Berechtigungen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textSecondary,
                ),
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

  Widget _buildSettingsPanel(
    BuildContext context,
    PrayerPhaseStyle phaseStyle,
  ) {
    final AppPalette palette = AppPalette.of(context);
    final bool useLive = _controller.settings.useDeviceLocation;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
        boxShadow: AppShadows.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SettingsSection(
            icon: useLive
                ? Icons.my_location_rounded
                : Icons.edit_location_alt_rounded,
            title: 'Standort',
            trailing: _SettingsStatusBadge(
              label: useLive ? 'Live' : 'Manuell',
              color: phaseStyle.accentSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SegmentedSetting<bool>(
                  value: useLive,
                  accentColor: phaseStyle.accentSoft,
                  onChanged: (bool value) {
                    unawaited(_controller.setUseDeviceLocation(value));
                  },
                  options: const <SegmentedSettingOption<bool>>[
                    SegmentedSettingOption<bool>(
                      value: true,
                      label: 'Live-GPS',
                    ),
                    SegmentedSettingOption<bool>(
                      value: false,
                      label: 'Manuell',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsSummaryRow(
                  icon: useLive
                      ? Icons.location_searching_rounded
                      : Icons.pin_drop_outlined,
                  label: useLive ? 'Aktiver Standort' : 'Manueller Standort',
                  value: _controller.locationHeadline,
                  meta: _formatCoordinates(),
                  action: !useLive
                      ? TextButton.icon(
                          onPressed: () => _openManualLocationSheet(context),
                          icon: const Icon(
                            Icons.edit_location_alt_rounded,
                            size: 16,
                          ),
                          label: const Text('Bearbeiten'),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const _SettingsPanelDivider(),
          _SettingsSection(
            icon: Icons.tune_rounded,
            title: 'Berechnung',
            trailing: _controller.settings.useAutoMethod
                ? _SettingsStatusBadge(
                    label: 'Auto',
                    color: phaseStyle.accentSoft,
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<int>(
                  key: ValueKey<int>(_controller.settings.method),
                  initialValue: _controller.settings.method,
                  decoration: const InputDecoration(
                    labelText: 'Berechnungsmethode',
                  ),
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
                  onChanged: _controller.settings.useAutoMethod
                      ? null
                      : (int? value) {
                          if (value != null) {
                            unawaited(_controller.updateMethod(value));
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                _SettingsSwitchRow(
                  title: 'Auto nach Region',
                  subtitle: _controller.settings.useAutoMethod
                      ? 'Land und Zeitzone wählen die Methode automatisch.'
                      : 'Deine manuelle Methode bleibt aktiv.',
                  value: _controller.settings.useAutoMethod,
                  onChanged: (bool value) {
                    unawaited(_controller.setUseAutoMethod(value));
                  },
                ),
              ],
            ),
          ),
          const _SettingsPanelDivider(),
          _SettingsSection(
            icon: Icons.school_outlined,
            title: 'Asr-Regel',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SegmentedSetting<int>(
                  value: _controller.settings.school,
                  accentColor: phaseStyle.accentSoft,
                  onChanged: (int school) {
                    unawaited(_controller.updateSchool(school));
                  },
                  options: _controller.availableSchools
                      .map(
                        (int school) => SegmentedSettingOption<int>(
                          value: school,
                          label: schoolLabels[school] ?? school.toString(),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Shafi ist Standard, Hanafi verschiebt Asr etwas später.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const _SettingsPanelDivider(),
          _SettingsSection(
            icon: Icons.palette_outlined,
            title: 'Darstellung',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SegmentedSetting<AppThemePreference>(
                  value: _controller.settings.themePreference,
                  accentColor: phaseStyle.accentSoft,
                  onChanged: (AppThemePreference value) {
                    unawaited(_controller.updateThemePreference(value));
                  },
                  options: const <SegmentedSettingOption<AppThemePreference>>[
                    SegmentedSettingOption<AppThemePreference>(
                      value: AppThemePreference.light,
                      label: 'Hell',
                    ),
                    SegmentedSettingOption<AppThemePreference>(
                      value: AppThemePreference.dark,
                      label: 'Dunkel',
                    ),
                    SegmentedSettingOption<AppThemePreference>(
                      value: AppThemePreference.prayerBased,
                      label: 'Gebetszeit',
                      semanticLabel: 'Automatisch nach Gebetszeit',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Gebetszeit ändert das Theme nur bei Start, Refresh oder Resume.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManualLocationSheet(BuildContext context) async {
    final AppPalette palette = AppPalette.of(context);
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
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            final EdgeInsets insets = MediaQuery.of(modalContext).viewInsets;
            final AppPalette modalPalette = AppPalette.of(modalContext);
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
                        color: modalPalette.border,
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
                          color: modalPalette.textSecondary,
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
                                color: modalPalette.error,
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
    if (data != null && _controller.settings.useDeviceLocation) {
      return '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    }

    if (data != null &&
        !_controller.settings.useDeviceLocation &&
        (data.latitude - _controller.settings.manualLatitude).abs() <= 0.0001 &&
        (data.longitude - _controller.settings.manualLongitude).abs() <=
            0.0001) {
      return '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    }

    return '${_controller.settings.manualLatitude.toStringAsFixed(4)}, ${_controller.settings.manualLongitude.toStringAsFixed(4)}';
  }

  double? _safeParse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              size: 16,
              color: palette.primarySoft,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _SettingsSummaryRow extends StatelessWidget {
  const _SettingsSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.meta,
    this.action,
  });

  final IconData icon;
  final String label;
  final String value;
  final String meta;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: palette.surfaceStrong,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.borderSubtle),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: palette.primarySoft,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                meta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textTertiary,
                    ),
              ),
            ],
          ),
        ),
        if (action != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          action!,
        ],
      ],
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: palette.primarySoft,
          activeTrackColor: AppColors.overlay(
            palette.primarySoft,
            palette.surfaceStrong,
            0.38,
          ),
        ),
      ],
    );
  }
}

class _SettingsPanelDivider extends StatelessWidget {
  const _SettingsPanelDivider();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Divider(
        height: 1,
        color: palette.borderSubtle,
      ),
    );
  }
}

class _SettingsStatusBadge extends StatelessWidget {
  const _SettingsStatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.overlay(color, palette.surfaceStrong, 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
            ),
      ),
    );
  }
}

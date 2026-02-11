import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/src/controllers/prayer_times_controller.dart';
import 'package:frontend/src/core/prayer_constants.dart';
import 'package:frontend/src/ui/widgets/prayer_time_tile.dart';
import 'package:frontend/src/utils/prayer_time_utils.dart';

class PrayerHomePage extends StatefulWidget {
  const PrayerHomePage({super.key});

  @override
  State<PrayerHomePage> createState() => _PrayerHomePageState();
}

class _PrayerHomePageState extends State<PrayerHomePage> {
  late final PrayerTimesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrayerTimesController();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
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
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFF122138),
                  Color(0xFF0E2E3B),
                  Color(0xFF283A59),
                ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -80,
                  right: -50,
                  child: _GlowCircle(
                    size: 220,
                    color: const Color(0xFF64E0D6).withOpacity(0.24),
                  ),
                ),
                Positioned(
                  bottom: -100,
                  left: -80,
                  child: _GlowCircle(
                    size: 280,
                    color: const Color(0xFFFFD166).withOpacity(0.18),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: RefreshIndicator(
                        onRefresh: () => _controller.refresh(),
                        color: const Color(0xFF64E0D6),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          children: <Widget>[
                            _buildAnimatedSection(
                              index: 0,
                              child: _buildHeaderCard(next, countdown),
                            ),
                            const SizedBox(height: 14),
                            if (_controller.errorMessage != null)
                              _buildAnimatedSection(
                                index: 1,
                                child: _buildErrorCard(),
                              ),
                            if (_controller.errorMessage != null)
                              const SizedBox(height: 14),
                            _buildAnimatedSection(
                              index: 2,
                              child: _buildTimesHeader(),
                            ),
                            const SizedBox(height: 10),
                            if (_controller.isLoading)
                              _buildLoadingCard()
                            else
                              ..._buildPrayerTiles(context, next),
                            const SizedBox(height: 18),
                            _buildAnimatedSection(
                              index: 20,
                              child: _buildControlCard(context),
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
      },
    );
  }

  Widget _buildHeaderCard(PrayerEvent? next, Duration? countdown) {
    final String? nextLabel = next == null ? null : prayerLabelsDe[next.key];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                        'Prayer Compass',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Saubere Gebetszeiten mit Live-Standort, manueller Fallback und Countdown.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: _controller.isRefreshing
                      ? null
                      : () => unawaited(_controller.refresh()),
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 320),
                    turns: _controller.isRefreshing ? 1.0 : 0,
                    child: const Icon(Icons.refresh_rounded),
                  ),
                  label: const Text('Aktualisieren'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoChip(
                  icon: Icons.place_outlined,
                  label: _controller.locationSummary,
                ),
                if ((_controller.response?.timezone.trim().isNotEmpty ?? false))
                  _InfoChip(
                    icon: Icons.public_rounded,
                    label: _controller.response!.timezone,
                  ),
                _InfoChip(
                  icon: Icons.schedule,
                  label: _lastUpdatedLabel(_controller.lastUpdatedAt),
                ),
              ],
            ),
            if (nextLabel != null && countdown != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: <Color>[
                      const Color(0xFFFFD166).withOpacity(0.18),
                      const Color(0xFF64E0D6).withOpacity(0.14),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFFFD166),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF283A59),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Nächstes Gebet: $nextLabel',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'In ${formatCountdown(countdown)}',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFFFE7A9),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard(BuildContext context) {
    final bool useDeviceLocation = _controller.settings.useDeviceLocation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Einstellungen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Methodik, Madhhab und Standort lassen sich direkt hier anpassen.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Live-Standort'),
                  selected: useDeviceLocation,
                  onSelected: (_) =>
                      unawaited(_controller.setUseDeviceLocation(true)),
                ),
                ChoiceChip(
                  label: const Text('Manuell'),
                  selected: !useDeviceLocation,
                  onSelected: (_) =>
                      unawaited(_controller.setUseDeviceLocation(false)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openManualLocationSheet(context),
                  icon: const Icon(Icons.edit_location_alt_rounded),
                  label: const Text('Koordinaten setzen'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _controller.settings.method,
                    decoration: const InputDecoration(
                      labelText: 'Berechnungsmethode',
                    ),
                    items: _controller.availableMethods
                        .map(
                          (int method) => DropdownMenuItem<int>(
                            value: method,
                            child: Text('$method · ${methodLabels[method]}'),
                          ),
                        )
                        .toList(),
                    onChanged: (int? value) {
                      if (value == null) {
                        return;
                      }
                      unawaited(_controller.updateMethod(value));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _controller.availableSchools.map((int school) {
                return ChoiceChip(
                  selected: _controller.settings.school == school,
                  label: Text(schoolLabels[school] ?? school.toString()),
                  onSelected: (_) => unawaited(_controller.updateSchool(school)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Koordinaten: ${_formatCoordinates()}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.72)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFBA3A4D).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBA3A4D).withOpacity(0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFFFA6B2)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Fehler beim Laden',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: const Color(0xFFFFCDD6)),
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.errorMessage ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: const Color(0xFFFFCDD6)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_controller.refresh()),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesHeader() {
    final String dateLabel = _controller.response?.date ?? 'Heute';

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Gebetszeiten · $dateLabel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Text(
          _controller.visibleTimes.length.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF64E0D6),
              ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        color: Colors.white.withOpacity(0.04),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF64E0D6),
        ),
      ),
    );
  }

  List<Widget> _buildPrayerTiles(BuildContext context, PrayerEvent? nextPrayer) {
    final List<Widget> items = <Widget>[];

    int index = 0;
    for (final String key in canonicalPrayerOrder) {
      final String? rawTime = _controller.visibleTimes[key];
      if (rawTime == null) {
        continue;
      }

      final String label = prayerLabelsDe[key] ?? key;
      final String formattedTime = _formatApiTime(context, rawTime);
      final bool isNext = nextPrayer?.key == key;

      items.add(
        _buildAnimatedSection(
          index: index + 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PrayerTimeTile(
              title: label,
              time: formattedTime,
              isNext: isNext,
            ),
          ),
        ),
      );
      index += 1;
    }

    if (items.isEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            'Keine Gebetszeiten verfügbar. Prüfe Backend und Standort.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? innerChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: innerChild,
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

    final TimeOfDay timeOfDay = TimeOfDay.fromDateTime(parsed);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String _lastUpdatedLabel(DateTime? at) {
    if (at == null) {
      return 'Noch nicht aktualisiert';
    }

    final int minutes = DateTime.now().difference(at).inMinutes;
    if (minutes <= 0) {
      return 'Gerade eben';
    }
    if (minutes == 1) {
      return 'Vor 1 Minute';
    }
    return 'Vor $minutes Minuten';
  }

  String _formatCoordinates() {
    final data = _controller.response;
    if (data != null) {
      return '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}';
    }

    return '${_controller.settings.manualLatitude.toStringAsFixed(4)}, ${_controller.settings.manualLongitude.toStringAsFixed(4)}';
  }

  Future<void> _openManualLocationSheet(BuildContext context) async {
    final TextEditingController labelController = TextEditingController(
      text: _controller.settings.manualLabel,
    );
    final TextEditingController latController = TextEditingController(
      text: _controller.settings.manualLatitude.toStringAsFixed(6),
    );
    final TextEditingController lonController = TextEditingController(
      text: _controller.settings.manualLongitude.toStringAsFixed(6),
    );

    String? inlineError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A263A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final EdgeInsets insets = MediaQuery.of(context).viewInsets;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 22 + insets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Manueller Standort',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ideal als Fallback, falls GPS oder Berechtigungen nicht funktionieren.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: labelController,
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
                          controller: latController,
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
                          controller: lonController,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFFA6B2),
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final double? latitude = _safeParse(latController.text);
                        final double? longitude = _safeParse(lonController.text);

                        if (latitude == null || longitude == null) {
                          setModalState(() {
                            inlineError =
                                'Bitte gültige Zahlen für Latitude und Longitude eingeben.';
                          });
                          return;
                        }

                        if (latitude < -90 || latitude > 90) {
                          setModalState(() {
                            inlineError =
                                'Latitude muss zwischen -90 und 90 liegen.';
                          });
                          return;
                        }

                        if (longitude < -180 || longitude > 180) {
                          setModalState(() {
                            inlineError =
                                'Longitude muss zwischen -180 und 180 liegen.';
                          });
                          return;
                        }

                        await _controller.saveManualLocation(
                          latitude: latitude,
                          longitude: longitude,
                          label: labelController.text,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
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

    labelController.dispose();
    latController.dispose();
    lonController.dispose();
  }

  double? _safeParse(String value) {
    final String normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, Colors.transparent],
            stops: const <double>[0.2, 1],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64E0D6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.88),
                ),
          ),
        ],
      ),
    );
  }
}

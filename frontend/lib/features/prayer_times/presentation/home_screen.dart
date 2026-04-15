import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading.dart';
import '../../settings/data/settings_service.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/location_service.dart';
import '../data/prayer_times_api.dart';
import '../data/prayer_times_cache.dart';
import '../data/prayer_times_model.dart';
import 'next_prayer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _location = LocationService();
  final _api = PrayerTimesApi();
  final _cache = PrayerTimesCache();
  final _settingsService = SettingsService();

  AppSettings? _settings;
  PrayerTimesModel? _data;
  String? _error;
  bool _loading = false;

  NextPrayer? _next;
  Duration? _countdown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final s = await _settingsService.load();
    setState(() => _settings = s);

    final cached = await _cache.load();
    if (cached != null) {
      setState(() => _data = cached);
      _recomputeNext();
      _startTimer();
    }

    await _loadFresh();
  }

  Future<void> _loadFresh() async {
    final s = _settings ?? const AppSettings(method: 2, school: 0);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = await _location.getCurrent();
      final data = await _api.fetch(
        lat: pos.latitude,
        lon: pos.longitude,
        method: s.method,
        school: s.school,
      );

      setState(() => _data = data);
      await _cache.save(data);

      _recomputeNext();
      _startTimer();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _recomputeNext() {
    final data = _data;
    if (data == null) return;
    final next = computeNextPrayer(data.times);
    setState(() {
      _next = next;
      _countdown = next.at.difference(DateTime.now());
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = _next;
      if (n == null) return;
      final diff = n.at.difference(DateTime.now());
      setState(() => _countdown = diff.isNegative ? Duration.zero : diff);
    });
  }

  String _fmt(Duration d) {
    final s = d.inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  Future<void> _openSettings() async {
    final current = _settings ?? const AppSettings(method: 2, school: 0);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          initial: current,
          onSaved: (s) async {
            await _settingsService.save(s);
            setState(() => _settings = s);
          },
        ),
      ),
    );

    await _loadFresh();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading && data == null) const SizedBox(height: 240, child: LoadingView()),
            if (_error != null) SizedBox(height: 240, child: ErrorView(message: _error!, onRetry: _loadFresh)),
            if (data != null) ...[
              _NextPrayerCard(
                nextName: _next?.name ?? '-',
                countdown: _countdown != null ? _fmt(_countdown!) : '--:--:--',
                date: data.date,
                method: data.method,
                school: data.school,
              ),
              const SizedBox(height: 12),
              Text('Times', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ...data.times.entries.map(
                (e) => Card(
                  child: ListTile(
                    title: Text(e.key.toUpperCase()),
                    trailing: Text(e.value, style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
              ),
            ],
            if (!_loading && _error == null && data == null)
              const SizedBox(height: 240, child: Center(child: Text('Pull to refresh'))),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.nextName,
    required this.countdown,
    required this.date,
    required this.method,
    required this.school,
  });

  final String nextName;
  final String countdown;
  final String date;
  final int method;
  final int school;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next prayer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(nextName.toUpperCase(), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('in $countdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Date: $date • method: $method • school: ${school == 1 ? 'Hanafi' : 'Shafi'}'),
          ],
        ),
      ),
    );
  }
}

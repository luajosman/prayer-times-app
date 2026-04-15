import 'package:flutter/material.dart';
import '../data/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.initial, required this.onSaved});

  final AppSettings initial;
  final ValueChanged<AppSettings> onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int method;
  late int school;

  final methods = const [2, 3, 4, 5, 7, 8, 12];

  @override
  void initState() {
    super.initState();
    method = widget.initial.method;
    school = widget.initial.school;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: method,
              decoration: const InputDecoration(labelText: 'Calculation method'),
              items: methods
                  .map((m) => DropdownMenuItem(value: m, child: Text('Method $m')))
                  .toList(),
              onChanged: (v) => setState(() => method = v ?? method),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hanafi (affects Asr)'),
              value: school == 1,
              onChanged: (v) => setState(() => school = v ? 1 : 0),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSaved(AppSettings(method: method, school: school));
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

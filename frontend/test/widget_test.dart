import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.useDeviceLocation': false,
      'settings.manualLatitude': 52.52,
      'settings.manualLongitude': 13.405,
      'settings.manualLabel': 'Berlin',
    });
  });

  testWidgets('renders redesigned prayer app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PrayerTimesApp());

    expect(find.text('Prayer Compass'), findsOneWidget);
    expect(find.text('Einstellungen'), findsOneWidget);
    expect(find.textContaining('Gebetszeiten'), findsOneWidget);
  });
}

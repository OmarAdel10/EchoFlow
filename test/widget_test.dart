// Smoke test: app boots and renders the home page.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant_gui/main.dart';
import 'package:voice_assistant_gui/services/cli_service.dart';
import 'package:voice_assistant_gui/services/settings_service.dart';

class FakeCliService extends CliService {
  @override
  Future<void> start() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app renders home page', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final settings = SettingsService();
    await settings.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CliService>(create: (_) => FakeCliService()),
          ChangeNotifierProvider<SettingsService>.value(value: settings),
        ],
        child: const VoiceAssistantApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Voice Assistant'), findsOneWidget);
  });
}

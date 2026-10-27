// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/cli_service.dart';
import 'services/settings_service.dart';
import 'services/audio_player.dart';
import 'services/chat_service.dart';
import 'ui/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CliService>(create: (_) => CliService()),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<AudioPlayerService>(
          create: (_) => AudioPlayerService(),
        ),
        ChangeNotifierProvider<ChatService>(create: (_) => ChatService()),
      ],
      child: const VoiceAssistantApp(),
    ),
  );
}

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Voice Assistant',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US'), Locale('ar', 'EG')],
      locale: settings.language == 'system'
          ? null
          : Locale(settings.language == 'ar' ? 'ar' : 'en'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: settings.theme == 'dark'
          ? ThemeMode.dark
          : settings.theme == 'light'
          ? ThemeMode.light
          : ThemeMode.system,
      home: const HomePage(),
    );
  }
}

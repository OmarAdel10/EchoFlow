// lib/services/settings_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _inputGainKey = 'stt_input_gain';
  static const String _autoGainKey = 'stt_auto_gain';
  static const String _languageKey = 'ui_language';
  static const String _themeKey = 'theme_mode';
  static const String _cliPathKey = 'cli_path';
  static const String _autoStartKey = 'auto_start';

  static const double _defaultInputGain = 1.0;
  static const bool _defaultAutoGain = false;
  static const String _defaultLanguage = 'system';
  static const String _defaultTheme = 'system';
  static const String _defaultCliPath = 'voice-assistant';
  static const bool _defaultAutoStart = false;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Input Gain
  double get inputGain => _prefs?.getDouble(_inputGainKey) ?? _defaultInputGain;
  Future<void> setInputGain(double gain) async {
    await _prefs?.setDouble(_inputGainKey, gain);
    notifyListeners();
  }

  // Auto Gain
  bool get autoGain => _prefs?.getBool(_autoGainKey) ?? _defaultAutoGain;
  Future<void> setAutoGain(bool enabled) async {
    await _prefs?.setBool(_autoGainKey, enabled);
    notifyListeners();
  }

  // Language
  String get language => _prefs?.getString(_languageKey) ?? _defaultLanguage;
  Future<void> setLanguage(String lang) async {
    await _prefs?.setString(_languageKey, lang);
    notifyListeners();
  }

  // Theme
  String get theme => _prefs?.getString(_themeKey) ?? _defaultTheme;
  Future<void> setTheme(String theme) async {
    await _prefs?.setString(_themeKey, theme);
    notifyListeners();
  }

  // CLI Path
  String get cliPath => _prefs?.getString(_cliPathKey) ?? _defaultCliPath;
  Future<void> setCliPath(String path) async {
    await _prefs?.setString(_cliPathKey, path);
    notifyListeners();
  }

  // Auto Start
  bool get autoStart => _prefs?.getBool(_autoStartKey) ?? _defaultAutoStart;
  Future<void> setAutoStart(bool enabled) async {
    await _prefs?.setBool(_autoStartKey, enabled);
    notifyListeners();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await _prefs?.remove(_inputGainKey);
    await _prefs?.remove(_autoGainKey);
    await _prefs?.remove(_languageKey);
    await _prefs?.remove(_themeKey);
    await _prefs?.remove(_cliPathKey);
    await _prefs?.remove(_autoStartKey);
    notifyListeners();
  }
}

// lib/utils/json_protocol.dart

import 'dart:convert';

/// JSON protocol definitions for CLI-GUI communication

abstract class CliMessageType {
  static const String voiceCommand = 'voice_command';
  static const String textCommand = 'text_command';
  static const String enroll = 'enroll';
  static const String testMic = 'test_mic';
  static const String settings = 'settings';

  static const String transcription = 'transcription';
  static const String response = 'response';
  static const String error = 'error';
  static const String micTestResult = 'mic_test_result';
  static const String ttsPlaying = 'tts_playing';
  static const String status = 'status';
}

/// CLI → Flutter messages (stdin)
class CliToFlutter {
  static const Map<String, String> commandTypes = {
    'voice_command': 'voice_command',
    'text_command': 'text_command',
    'enroll': 'enroll',
    'test_mic': 'test_mic',
    'settings': 'settings',
  };

  static Map<String, dynamic> voiceCommand({String mode = 'once'}) {
    return {'type': 'voice_command', 'mode': mode};
  }

  static Map<String, dynamic> textCommand(String text, {String? lang}) {
    final map = {'type': 'text_command', 'text': text};
    if (lang != null) map['lang'] = lang;
    return map;
  }

  static Map<String, dynamic> enroll() {
    return {'type': 'enroll'};
  }

  static Map<String, dynamic> testMic({double duration = 3.0, double? gain}) {
    return {'type': 'test_mic', 'duration': duration, 'gain': ?gain};
  }

  static Map<String, dynamic> settings({
    double? inputGain,
    bool? autoGain,
    String? language,
  }) {
    return {
      'type': 'settings',
      'input_gain': ?inputGain,
      'auto_gain': ?autoGain,
      'language': ?language,
    };
  }
}

/// Flutter → CLI messages (stdout)
class FlutterToCli {
  static const Map<String, String> responseTypes = {
    'transcription': 'transcription',
    'response': 'response',
    'error': 'error',
    'mic_test_result': 'mic_test_result',
    'tts_playing': 'tts_playing',
    'status': 'status',
  };

  static Map<String, dynamic> transcription({
    required String text,
    required String lang,
    double? confidence,
  }) {
    return {
      'type': 'transcription',
      'text': text,
      'lang': lang,
      'confidence': ?confidence,
    };
  }

  static Map<String, dynamic> response({
    required String text,
    required String lang,
  }) {
    return {'type': 'response', 'text': text, 'lang': lang};
  }

  static Map<String, dynamic> error(String message) {
    return {'type': 'error', 'message': message};
  }

  static Map<String, dynamic> micTestResult({
    required double duration,
    required double rms,
    required double peak,
    required int clippedSamples,
    required int totalSamples,
    required double clippingPercentage,
    required String detectedLanguage,
    required String transcription,
    required String assessment,
    required double suggestedGain,
  }) {
    return {
      'type': 'mic_test_result',
      'duration': duration,
      'rms': rms,
      'peak': peak,
      'clipped_samples': clippedSamples,
      'total_samples': totalSamples,
      'clipping_percentage': clippingPercentage,
      'detected_language': detectedLanguage,
      'transcription': transcription,
      'assessment': assessment,
      'suggested_gain': suggestedGain,
    };
  }

  static Map<String, dynamic> ttsPlaying(String text) {
    return {'type': 'tts_playing', 'text': text};
  }

  static Map<String, dynamic> status(String status) {
    return {'type': 'status', 'status': status};
  }
}

/// JSON helpers
class JsonProtocol {
  static String encode(Object object) {
    return jsonEncode(object);
  }

  static Map<String, dynamic> decode(String json) {
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static String getType(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map['type'] as String? ?? 'unknown';
  }
}

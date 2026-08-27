// lib/services/cli_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:voice_assistant_gui/models/command.dart';
import 'package:voice_assistant_gui/models/enroll_state.dart' as enroll;
import 'package:voice_assistant_gui/models/response.dart' as resp;
import 'package:voice_assistant_gui/models/mic_test_result.dart' as mic;
import 'package:voice_assistant_gui/utils/arabic_utils.dart';

class CliService extends ChangeNotifier {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final _responseController = StreamController<resp.VoiceResponse>.broadcast();
  final _micTestController = StreamController<mic.MicTestResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _enrollController = StreamController<enroll.EnrollState>.broadcast();

  Stream<resp.VoiceResponse> get responses => _responseController.stream;
  Stream<mic.MicTestResult> get micTestResults => _micTestController.stream;
  Stream<String> get statusUpdates => _statusController.stream;
  Stream<enroll.EnrollState> get enrollStates => _enrollController.stream;

  bool _isRunning = false;
  bool _isUserSpeaking = false;
  bool _isAssistantSpeaking = false;
  String? _lastTtsText;
  Timer? _ttsTimer;
  Timer? _responseTimer;
  String _cliPath = 'voice-assistant';
  String _workingDirectory = '/home/omaradel/Desktop/VoiceAssistant';
  bool _disposed = false;

  static const Duration _responseTimeout = Duration(seconds: 30);

  String get cliPath => _cliPath;
  set cliPath(String path) {
    _cliPath = path;
    notifyListeners();
  }

  String get workingDirectory => _workingDirectory;
  set workingDirectory(String path) {
    _workingDirectory = path;
    notifyListeners();
  }

  bool get isRunning => _isRunning;
  bool get isUserSpeaking => _isUserSpeaking;
  bool get isAssistantSpeaking => _isAssistantSpeaking;
  String? get lastTtsText => _lastTtsText;

  /// Read .env file from working directory and return key-value pairs
  Map<String, String> _loadEnvFile() {
    final envFile = File('$_workingDirectory/.env');
    final envVars = <String, String>{};

    debugPrint('CLI Service: Looking for .env at: $_workingDirectory/.env');
    debugPrint('CLI Service: .env exists: ${envFile.existsSync()}');

    if (envFile.existsSync()) {
      try {
        final content = envFile.readAsStringSync();
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          final eqIndex = trimmed.indexOf('=');
          if (eqIndex > 0) {
            final key = trimmed.substring(0, eqIndex).trim();
            final value = trimmed.substring(eqIndex + 1).trim();
            envVars[key] = value;
          }
        }
        debugPrint('CLI Service: Loaded .env vars: ${envVars.keys.toList()}');
        if (envVars.containsKey('GROQ_API_KEY')) {
          debugPrint(
            'CLI Service: GROQ_API_KEY found (length: ${envVars['GROQ_API_KEY']!.length})',
          );
        } else {
          debugPrint('CLI Service: GROQ_API_KEY NOT found in .env');
        }
      } catch (e) {
        debugPrint('Failed to load .env file: $e');
      }
    } else {
      debugPrint('CLI Service: .env file NOT FOUND at $_workingDirectory/.env');
    }
    return envVars;
  }

  /// Start the voice assistant CLI process in GUI mode
  Future<void> start() async {
    if (_isRunning) return;

    // CUDA 12 library path (from Ollama installation) for faster-whisper GPU support
    const cudaLibPath = '/usr/local/lib/ollama/cuda_v12';

    // Build environment: inherit system env + load .env file + add CUDA path
    final env = Map<String, String>.from(Platform.environment);

    // Load GROQ_API_KEY (and other vars) from .env file in working directory
    final dotEnvVars = _loadEnvFile();
    env.addAll(dotEnvVars);

    env['LD_LIBRARY_PATH'] = cudaLibPath;

    debugPrint(
      'CLI Service: Final env GROQ_API_KEY present: ${env.containsKey('GROQ_API_KEY')}',
    );
    debugPrint('CLI Service: Working directory: $_workingDirectory');
    debugPrint('CLI Service: CLI path: $_cliPath');

    try {
      _process = await Process.start(
        _cliPath,
        ['--gui-mode'],
        runInShell: true,
        workingDirectory: _workingDirectory,
        environment: env,
      );

      _isRunning = true;
      _statusController.add('connected');
      notifyListeners();

      // Listen to stdout
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleStdoutLine, onError: _handleError);

      // Listen to stderr
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleStderrLine);

      // Handle process exit
      _process!.exitCode.then((exitCode) {
        if (!_disposed) {
          _isRunning = false;
          _statusController.add('disconnected (exit code: $exitCode)');
          notifyListeners();
          _cleanup();
        }
      });
    } catch (e) {
      _statusController.add('Failed to start: $e');
      rethrow;
    }
  }

  /// Exposed for parser unit tests only.
  @visibleForTesting
  void handleStdoutLine(String line) => _handleStdoutLine(line);

  void _handleStdoutLine(String line) {
    if (line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line);
      final type = json['type'] as String?;

      switch (type) {
        case 'transcription':
          _isUserSpeaking = true;
          _isAssistantSpeaking = false;
          _ttsTimer?.cancel();
          notifyListeners();
          _responseController.add(
            resp.VoiceResponse(
              type: 'transcription',
              text: json['text'] as String?,
              lang: json['lang'] as String?,
              confidence: (json['confidence'] as num?)?.toDouble(),
            ),
          );
          break;
        case 'response':
          _responseTimer?.cancel();
          _isUserSpeaking = false;
          notifyListeners();
          _responseController.add(
            resp.VoiceResponse(
              type: 'response',
              text: json['text'] as String?,
              lang: json['lang'] as String?,
            ),
          );
          break;
        case 'error':
          _responseTimer?.cancel();
          _isUserSpeaking = false;
          _isAssistantSpeaking = false;
          _ttsTimer?.cancel();
          notifyListeners();
          _responseController.add(
            resp.VoiceResponse(
              type: 'error',
              message: json['message'] as String?,
            ),
          );
          break;
        case 'mic_test_result':
          _micTestController.add(mic.MicTestResult.fromJson(json));
          break;
        case 'tts_playing':
          _isUserSpeaking = false;
          _isAssistantSpeaking = true;
          _lastTtsText = json['text'] as String?;
          _startTtsTimer(_lastTtsText ?? '');
          notifyListeners();
          _responseController.add(
            resp.VoiceResponse(
              type: 'tts_playing',
              text: json['text'] as String?,
            ),
          );
          break;
        case 'status':
          _statusController.add(json['status'] as String? ?? 'unknown');
          break;
        case 'enroll_state':
          _enrollController.add(enroll.EnrollState.fromJson(json));
          break;
        default:
          debugPrint('Unknown response type: $type');
      }
    } catch (e) {
      debugPrint('Failed to parse CLI output: $line - $e');
    }
  }

  void _handleStderrLine(String line) {
    debugPrint('[CLI stderr] $line');
  }

  void _handleError(Object error) {
    debugPrint('CLI stdout error: $error');
    _statusController.add('Error: $error');
  }

  /// Send a command to the CLI
  void sendCommand(dynamic command) {
    if (!_isRunning || _process == null) return;

    try {
      final json = jsonEncode(command.toJson());
      _process!.stdin.writeln(json);
    } catch (e) {
      debugPrint('Failed to send command: $e');
    }
  }

  void _startResponseTimer() {
    _responseTimer?.cancel();
    _responseTimer = Timer(_responseTimeout, _handleTimeout);
  }

  void _handleTimeout() {
    if (_isRunning) {
      _statusController.add('Request timed out');
      _responseController.add(
        resp.VoiceResponse(
          type: 'error',
          message: 'Request timed out. You can try again now.',
        ),
      );
    }
  }

  /// Send voice command (voice mode)
  void sendVoiceCommand({String mode = 'once'}) {
    _startResponseTimer();
    sendCommand(VoiceCommand.voice(mode: mode));
  }

  /// Send text command
  void sendTextCommand(String text) {
    final lang = ArabicUtils.detectLanguage(text);
    _startResponseTimer();
    sendCommand(VoiceCommand.text(text, lang: lang));
  }

  /// Open an interactive enrollment session
  void sendEnrollStart() {
    _sendRaw({'type': 'enroll_start'});
  }

  /// Record the current enrollment phrase
  void sendEnrollRecord() {
    _sendRaw({'type': 'enroll_record'});
  }

  /// Cancel the interactive enrollment session
  void sendEnrollCancel() {
    _sendRaw({'type': 'enroll_cancel'});
  }

  void _sendRaw(Map<String, dynamic> payload) {
    if (!_isRunning || _process == null) return;

    try {
      _process!.stdin.writeln(jsonEncode(payload));
    } catch (e) {
      debugPrint('Failed to send command: $e');
    }
  }

  /// Send test mic command
  void sendTestMicCommand({double duration = 3.0, double? gain}) {
    sendCommand(VoiceCommand.testMic(duration: duration, gain: gain));
  }

  /// Send settings command
  void sendSettingsCommand({
    double? inputGain,
    bool? autoGain,
    String? language,
  }) {
    final cmd = SettingsCommand(
      type: 'settings',
      inputGain: inputGain,
      autoGain: autoGain,
      language: language,
    );
    sendCommand(cmd);
  }

  /// Stop the CLI process
  Future<void> stop() async {
    if (!_isRunning || _process == null) return;

    try {
      _process!.kill();
      await _process!.exitCode.timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Error stopping CLI: $e');
    } finally {
      _cleanup();
    }
  }

  void _cleanup() {
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;
    _process = null;
    _isRunning = false;
    _isUserSpeaking = false;
    _isAssistantSpeaking = false;
    _ttsTimer?.cancel();
    _ttsTimer = null;
    _responseTimer?.cancel();
    _responseTimer = null;
    notifyListeners();
  }

  void _startTtsTimer(String text) {
    _ttsTimer?.cancel();
    // Estimate TTS duration: ~50ms per character + 500ms base, minimum 1s
    final estimatedMs = (text.length * 50 + 500).clamp(1000, 30000);
    _ttsTimer = Timer(Duration(milliseconds: estimatedMs + 600), () {
      if (!_disposed) {
        _isAssistantSpeaking = false;
        _lastTtsText = null;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _responseController.close();
    _micTestController.close();
    _statusController.close();
    _enrollController.close();
    super.dispose();
  }
}

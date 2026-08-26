// lib/services/cli_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:voice_assistant_gui/models/command.dart';
import 'package:voice_assistant_gui/models/response.dart' as resp;
import 'package:voice_assistant_gui/models/mic_test_result.dart' as mic;

class CliService extends ChangeNotifier {
  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final _responseController = StreamController<resp.VoiceResponse>.broadcast();
  final _micTestController = StreamController<mic.MicTestResult>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<resp.VoiceResponse> get responses => _responseController.stream;
  Stream<mic.MicTestResult> get micTestResults => _micTestController.stream;
  Stream<String> get statusUpdates => _statusController.stream;

  bool _isRunning = false;
  String _cliPath = 'voice-assistant';
  bool _disposed = false;

  String get cliPath => _cliPath;
  set cliPath(String path) {
    _cliPath = path;
    notifyListeners();
  }

  bool get isRunning => _isRunning;

  /// Start the voice assistant CLI process in GUI mode
  Future<void> start() async {
    if (_isRunning) return;

    try {
      _process = await Process.start(_cliPath, [
        '--gui-mode',
      ], runInShell: true);

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

  void _handleStdoutLine(String line) {
    if (line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line);
      final type = json['type'] as String?;

      switch (type) {
        case 'transcription':
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
          _responseController.add(
            resp.VoiceResponse(
              type: 'response',
              text: json['text'] as String?,
              lang: json['lang'] as String?,
            ),
          );
          break;
        case 'error':
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

  /// Send voice command (voice mode)
  void sendVoiceCommand({String mode = 'once'}) {
    sendCommand(VoiceCommand.voice(mode: mode));
  }

  /// Send text command
  void sendTextCommand(String text) {
    sendCommand(VoiceCommand.text(text));
  }

  /// Send enroll command
  void sendEnrollCommand() {
    sendCommand(VoiceCommand.enroll());
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
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    _responseController.close();
    _micTestController.close();
    _statusController.close();
    super.dispose();
  }
}

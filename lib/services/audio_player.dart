// lib/services/audio_player.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Play audio from a file path
  Future<void> playFromFile(String filePath) async {
    try {
      await _player.stop();
      _isPlaying = true;
      notifyListeners();
      await _player.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Play audio from bytes (e.g., TTS output)
  Future<void> playFromBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      _isPlaying = true;
      notifyListeners();
      await _player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('Error playing audio from bytes: $e');
    }
  }

  /// Play audio from a URL
  Future<void> playFromUrl(String url) async {
    try {
      await _player.stop();
      _isPlaying = true;
      notifyListeners();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing audio from URL: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

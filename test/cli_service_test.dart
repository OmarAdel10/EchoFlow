// Unit tests for CliService JSON-line parsing against the Python CLI
// --gui-mode protocol (voice_assistant/gui_mode.py).

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_assistant_gui/models/response.dart' as resp;
import 'package:voice_assistant_gui/services/cli_service.dart';

void main() {
  late CliService service;
  final responses = <resp.VoiceResponse>[];
  final statuses = <String>[];

  setUp(() {
    service = CliService();
    responses.clear();
    statuses.clear();
    service.responses.listen(responses.add);
    service.statusUpdates.listen(statuses.add);
  });

  tearDown(() {
    service.dispose();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('transcription events', () {
    test('parses text, lang and confidence', () async {
      service.handleStdoutLine(
        '{"type": "transcription", "text": "hello", "lang": "en", '
        '"confidence": 0.93}',
      );
      await flush();

      expect(responses.length, 1);
      final r = responses.single;
      expect(r.isTranscription, isTrue);
      expect(r.text, 'hello');
      expect(r.lang, 'en');
      expect(r.confidence, closeTo(0.93, 1e-9));
      expect(statuses, isEmpty);
    });

    test('missing confidence yields null', () async {
      service.handleStdoutLine(
        '{"type": "transcription", "text": "مرحبا", "lang": "ar"}',
      );
      await flush();

      expect(responses.single.confidence, isNull);
      expect(responses.single.text, 'مرحبا');
    });
  });

  group('response events', () {
    test('parses assistant reply text', () async {
      service.handleStdoutLine(
        '{"type": "response", "text": "It is 3 PM", "lang": "en"}',
      );
      await flush();

      final r = responses.single;
      expect(r.isResponse, isTrue);
      expect(r.text, 'It is 3 PM');
      expect(r.lang, 'en');
    });
  });

  group('error events', () {
    test('parses message', () async {
      service.handleStdoutLine(
        '{"type": "error", "message": "mic unavailable"}',
      );
      await flush();

      final r = responses.single;
      expect(r.isError, isTrue);
      expect(r.message, 'mic unavailable');
    });
  });

  group('tts_playing events', () {
    test('marks spoken response', () async {
      service.handleStdoutLine('{"type": "tts_playing", "text": "It is 3 PM"}');
      await flush();

      final r = responses.single;
      expect(r.isTtsPlaying, isTrue);
      expect(r.text, 'It is 3 PM');
    });
  });

  group('status events', () {
    test('emits status value', () async {
      service.handleStdoutLine('{"type": "status", "status": "listening"}');
      await flush();

      expect(statuses, ['listening']);
    });

    test('falls back to unknown when status missing', () async {
      service.handleStdoutLine('{"type": "status"}');
      await flush();

      expect(statuses, ['unknown']);
    });
  });

  group('mic_test_result events', () {
    test('maps snake_case fields to model', () async {
      final results = <Map<String, dynamic>>[];
      service.micTestResults.listen((r) => results.add(r.toJson()));

      service.handleStdoutLine(
        '{"type": "mic_test_result", "duration": 3.0, "rms": 0.02, '
        '"peak": 0.55, "clipped_samples": 4, "total_samples": 48000, '
        '"clipping_percentage": 0.5, "detected_language": "en", '
        '"transcription": "test one two", "assessment": "good levels", '
        '"suggested_gain": 1.2, "confidence": null}',
      );
      await flush();

      expect(results.length, 1);
      final r = results.single;
      expect(r['duration'], 3.0);
      expect(r['peak'], 0.55);
      expect(r['clipped_samples'], 4);
      expect(r['total_samples'], 48000);
      expect(r['clipping_percentage'], 0.5);
      expect(r['detected_language'], 'en');
      expect(r['transcription'], 'test one two');
      expect(r['assessment'], 'good levels');
      expect(r['suggested_gain'], 1.2);
    });
  });

  group('resilience', () {
    test('malformed JSON does not emit and does not throw', () async {
      service.handleStdoutLine('not-json-at-all {{{');
      await flush();

      expect(responses, isEmpty);
      expect(statuses, isEmpty);
    });

    test('blank lines are ignored', () async {
      service.handleStdoutLine('');
      service.handleStdoutLine('   ');
      await flush();

      expect(responses, isEmpty);
      expect(statuses, isEmpty);
    });

    test('unknown type is ignored without crash', () async {
      service.handleStdoutLine('{"type": "future_event", "x": 1}');
      await flush();

      expect(responses, isEmpty);
      expect(statuses, isEmpty);
    });

    test('session survives garbage between valid events', () async {
      service.handleStdoutLine('garbage');
      service.handleStdoutLine('{"type": "status", "status": "ready"}');
      await flush();

      expect(statuses, ['ready']);
    });
  });
}

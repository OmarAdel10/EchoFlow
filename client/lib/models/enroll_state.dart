// lib/models/enroll_state.dart

/// Typed view of the CLI's `enroll_state` event frame.
///
/// Phases:
/// - started   : session opened, [phrase] is the first prompt
/// - captured  : current phrase recorded OK, advanced to next [phrase]
/// - no_speech : nothing heard, stay on the same phrase
/// - complete  : all phrases captured and saved ([phrase] is null)
/// - cancelled : session aborted, captures discarded
class EnrollState {
  final String phase;
  final int index;
  final int total;
  final String? phrase;
  final String? transcription;
  final int captured;
  final List<String> phrases;

  const EnrollState({
    required this.phase,
    required this.index,
    required this.total,
    this.phrase,
    this.transcription,
    required this.captured,
    this.phrases = const [],
  });

  factory EnrollState.fromJson(Map<String, dynamic> json) {
    return EnrollState(
      phase: json['phase'] as String? ?? 'unknown',
      index: (json['index'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      phrase: json['phrase'] as String?,
      transcription: json['transcription'] as String?,
      captured: (json['captured'] as num?)?.toInt() ?? 0,
      phrases:
          (json['phrases'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
    );
  }

  bool get isStarted => phase == 'started';
  bool get isCaptured => phase == 'captured';
  bool get isNoSpeech => phase == 'no_speech';
  bool get isComplete => phase == 'complete';
  bool get isCancelled => phase == 'cancelled';
}

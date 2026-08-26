// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceResponse _$VoiceResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VoiceResponse', json, ($checkedConvert) {
  final val = VoiceResponse(
    type: $checkedConvert('type', (v) => v as String),
    status: $checkedConvert('status', (v) => v as String?),
    text: $checkedConvert('text', (v) => v as String?),
    lang: $checkedConvert('lang', (v) => v as String?),
    confidence: $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
    message: $checkedConvert('message', (v) => v as String?),
    micTestResult: $checkedConvert(
      'micTestResult',
      (v) =>
          v == null ? null : MicTestResult.fromJson(v as Map<String, dynamic>),
    ),
    ttsPlaying: $checkedConvert(
      'ttsPlaying',
      (v) => v == null ? null : TtsPlaying.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$VoiceResponseToJson(VoiceResponse instance) =>
    <String, dynamic>{
      'type': instance.type,
      'status': ?instance.status,
      'text': ?instance.text,
      'lang': ?instance.lang,
      'confidence': ?instance.confidence,
      'message': ?instance.message,
      'micTestResult': ?instance.micTestResult?.toJson(),
      'ttsPlaying': ?instance.ttsPlaying?.toJson(),
    };

MicTestResult _$MicTestResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MicTestResult', json, ($checkedConvert) {
  final val = MicTestResult(
    type: $checkedConvert('type', (v) => v as String),
    duration: $checkedConvert('duration', (v) => (v as num).toDouble()),
    rms: $checkedConvert('rms', (v) => (v as num).toDouble()),
    peak: $checkedConvert('peak', (v) => (v as num).toDouble()),
    clippedSamples: $checkedConvert(
      'clippedSamples',
      (v) => (v as num).toInt(),
    ),
    totalSamples: $checkedConvert('totalSamples', (v) => (v as num).toInt()),
    clippingPercentage: $checkedConvert(
      'clippingPercentage',
      (v) => (v as num).toDouble(),
    ),
    detectedLanguage: $checkedConvert('detectedLanguage', (v) => v as String),
    transcription: $checkedConvert('transcription', (v) => v as String),
    assessment: $checkedConvert('assessment', (v) => v as String),
    suggestedGain: $checkedConvert(
      'suggestedGain',
      (v) => (v as num).toDouble(),
    ),
    confidence: $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
  );
  return val;
});

Map<String, dynamic> _$MicTestResultToJson(MicTestResult instance) =>
    <String, dynamic>{
      'type': instance.type,
      'duration': instance.duration,
      'rms': instance.rms,
      'peak': instance.peak,
      'clippedSamples': instance.clippedSamples,
      'totalSamples': instance.totalSamples,
      'clippingPercentage': instance.clippingPercentage,
      'detectedLanguage': instance.detectedLanguage,
      'transcription': instance.transcription,
      'assessment': instance.assessment,
      'suggestedGain': instance.suggestedGain,
      'confidence': ?instance.confidence,
    };

TtsPlaying _$TtsPlayingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TtsPlaying', json, ($checkedConvert) {
      final val = TtsPlaying(
        type: $checkedConvert('type', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TtsPlayingToJson(TtsPlaying instance) =>
    <String, dynamic>{'type': instance.type, 'text': instance.text};

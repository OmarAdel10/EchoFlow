// lib/models/mic_test_result.dart

class MicTestResult {
  final double duration;
  final double rms;
  final double peak;
  final int clippedSamples;
  final int totalSamples;
  final double clippingPercentage;
  final String detectedLanguage;
  final String transcription;
  final String assessment;
  final double suggestedGain;

  MicTestResult({
    required this.duration,
    required this.rms,
    required this.peak,
    required this.clippedSamples,
    required this.totalSamples,
    required this.clippingPercentage,
    required this.detectedLanguage,
    required this.transcription,
    required this.assessment,
    required this.suggestedGain,
  });

  factory MicTestResult.fromJson(Map<String, dynamic> json) {
    return MicTestResult(
      duration: (json['duration'] as num).toDouble(),
      rms: (json['rms'] as num).toDouble(),
      peak: (json['peak'] as num).toDouble(),
      clippedSamples: json['clipped_samples'] as int,
      totalSamples: json['total_samples'] as int,
      clippingPercentage: (json['clipping_percentage'] as num).toDouble(),
      detectedLanguage: json['detected_language'] as String,
      transcription: json['transcription'] as String,
      assessment: json['assessment'] as String,
      suggestedGain: (json['suggested_gain'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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

  String getFormattedClipping() {
    return '${clippingPercentage.toStringAsFixed(1)}%';
  }

  bool get hasHighClipping => clippingPercentage > 5.0;
  bool get hasSomeClipping => clippingPercentage > 1.0;
  bool get hasGoodLevels => !hasSomeClipping && !hasHighClipping;
}

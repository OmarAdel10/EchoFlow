// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceCommand _$VoiceCommandFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VoiceCommand', json, ($checkedConvert) {
      final val = VoiceCommand(
        type: $checkedConvert('type', (v) => v as String),
        mode: $checkedConvert('mode', (v) => v as String?),
        text: $checkedConvert('text', (v) => v as String?),
        lang: $checkedConvert('lang', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$VoiceCommandToJson(VoiceCommand instance) =>
    <String, dynamic>{
      'type': instance.type,
      'mode': ?instance.mode,
      'text': ?instance.text,
      'lang': ?instance.lang,
    };

SettingsCommand _$SettingsCommandFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SettingsCommand', json, ($checkedConvert) {
      final val = SettingsCommand(
        type: $checkedConvert('type', (v) => v as String),
        inputGain: $checkedConvert('inputGain', (v) => (v as num?)?.toDouble()),
        autoGain: $checkedConvert('autoGain', (v) => v as bool?),
        language: $checkedConvert('language', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SettingsCommandToJson(SettingsCommand instance) =>
    <String, dynamic>{
      'type': instance.type,
      'inputGain': ?instance.inputGain,
      'autoGain': ?instance.autoGain,
      'language': ?instance.language,
    };

// lib/services/chat_service.dart

import 'package:flutter/material.dart';
import 'package:voice_assistant_gui/utils/arabic_utils.dart';

enum MessageType { user, assistant, loading }

class ChatMessage {
  final String text;
  final bool isUser;
  final String language;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.language,
    required this.timestamp,
    this.type = MessageType.user,
  });

  factory ChatMessage.user(String text, String language) => ChatMessage(
    text: text,
    isUser: true,
    language: language,
    timestamp: DateTime.now(),
    type: MessageType.user,
  );

  factory ChatMessage.assistant(String text, String language) => ChatMessage(
    text: text,
    isUser: false,
    language: language,
    timestamp: DateTime.now(),
    type: MessageType.assistant,
  );

  factory ChatMessage.loading() => ChatMessage(
    text: '',
    isUser: false,
    language: 'en',
    timestamp: DateTime.now(),
    type: MessageType.loading,
  );

  factory ChatMessage.error(String text) => ChatMessage(
    text: text,
    isUser: false,
    language: 'en',
    timestamp: DateTime.now(),
    type: MessageType.assistant,
  );
}

class ChatService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  String? _lastUserLanguage;
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get lastUserLanguage => _lastUserLanguage;
  bool get isProcessing => _isProcessing;

  void addUserMessage(String text) {
    final lang = ArabicUtils.detectLanguage(text);
    _lastUserLanguage = lang;
    _messages.add(ChatMessage.user(text, lang));
    notifyListeners();
  }

  void addAssistantMessage(String text, {String? cliLanguage}) {
    final lang = _lastUserLanguage ?? cliLanguage ?? 'en';
    _messages.add(ChatMessage.assistant(text, lang));
    notifyListeners();
  }

  void addTranscription(String text, String lang) {
    _lastUserLanguage = lang;
    _messages.add(ChatMessage.user(text, lang));
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void addLoadingMessage() {
    _messages.add(ChatMessage.loading());
    notifyListeners();
  }

  void removeLoadingMessage() {
    if (_messages.isNotEmpty && _messages.last.type == MessageType.loading) {
      _messages.removeLast();
      notifyListeners();
    }
  }

  void replaceLoadingWithResponse(String text, {String? cliLanguage}) {
    removeLoadingMessage();
    _isProcessing = false;
    addAssistantMessage(text, cliLanguage: cliLanguage);
  }

  void replaceLoadingWithError(String text) {
    removeLoadingMessage();
    _isProcessing = false;
    _messages.add(ChatMessage.error(text));
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    _lastUserLanguage = null;
    _isProcessing = false;
    notifyListeners();
  }
}

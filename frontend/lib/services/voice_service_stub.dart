import 'package:flutter/foundation.dart';

class VoiceServiceImpl {
  bool get isSupported => false;
  bool isListening = false;
  bool isSpeaking = false;

  bool startListening({
    required Function(String text, bool isFinal) onResult,
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String error)? onError,
  }) {
    onError?.call('Nền tảng này chưa hỗ trợ nhận diện giọng nói.');
    return false;
  }

  void stopListening() {
    isListening = false;
  }

  bool speak(String text, {VoidCallback? onStart, VoidCallback? onEnd, Function(String error)? onError}) {
    onError?.call('Nền tảng này chưa hỗ trợ đọc văn bản.');
    return false;
  }

  void stopSpeaking() {
    isSpeaking = false;
  }
}

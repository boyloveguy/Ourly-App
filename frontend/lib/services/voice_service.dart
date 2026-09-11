import 'package:flutter/foundation.dart';
import 'voice_service_stub.dart'
    if (dart.library.js) 'voice_service_web.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final VoiceServiceImpl _impl = VoiceServiceImpl();

  bool get isSupported => _impl.isSupported;
  bool get isListening => _impl.isListening;
  bool get isSpeaking => _impl.isSpeaking;

  bool startListening({
    required Function(String text, bool isFinal) onResult,
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String error)? onError,
  }) {
    return _impl.startListening(
      onResult: onResult,
      onStart: onStart,
      onEnd: onEnd,
      onError: onError,
    );
  }

  void stopListening() {
    _impl.stopListening();
  }

  bool speak(String text, {VoidCallback? onStart, VoidCallback? onEnd, Function(String error)? onError}) {
    return _impl.speak(
      text,
      onStart: onStart,
      onEnd: onEnd,
      onError: onError,
    );
  }

  void stopSpeaking() {
    _impl.stopSpeaking();
  }
}

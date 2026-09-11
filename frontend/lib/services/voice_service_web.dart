// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class VoiceServiceImpl {
  bool get isSupported => html.window.speechSynthesis != null;
  bool isListening = false;
  bool isSpeaking = false;

  Function(String text, bool isFinal)? _onResult;
  VoidCallback? _onStartListening;
  VoidCallback? _onEndListening;
  Function(String error)? _onErrorListening;

  VoidCallback? _onStartSpeaking;
  VoidCallback? _onEndSpeaking;
  Function(String error)? _onErrorSpeaking;

  VoiceServiceImpl() {
    _initListeners();
  }

  void _initListeners() {
    html.window.addEventListener('ourly_speech_result', (html.Event event) {
      if (event is html.CustomEvent && event.detail != null) {
        final data = event.detail;
        if (data is Map) {
          final text = data['text']?.toString() ?? '';
          final isFinal = data['isFinal'] == true;
          _onResult?.call(text, isFinal);
        }
      }
    });

    html.window.addEventListener('ourly_speech_start', (_) {
      isListening = true;
      _onStartListening?.call();
    });

    html.window.addEventListener('ourly_speech_end', (_) {
      isListening = false;
      _onEndListening?.call();
    });

    html.window.addEventListener('ourly_speech_error', (html.Event event) {
      isListening = false;
      String err = 'Lỗi nhận diện giọng nói';
      if (event is html.CustomEvent && event.detail != null) {
        err = event.detail.toString();
      }
      _onErrorListening?.call(err);
    });

    html.window.addEventListener('ourly_speaking_start', (_) {
      isSpeaking = true;
      _onStartSpeaking?.call();
    });

    html.window.addEventListener('ourly_speaking_end', (_) {
      isSpeaking = false;
      _onEndSpeaking?.call();
    });

    html.window.addEventListener('ourly_speaking_error', (html.Event event) {
      isSpeaking = false;
      String err = 'Lỗi phát giọng nói';
      if (event is html.CustomEvent && event.detail != null) {
        err = event.detail.toString();
      }
      _onErrorSpeaking?.call(err);
    });
  }

  bool startListening({
    required Function(String text, bool isFinal) onResult,
    VoidCallback? onStart,
    VoidCallback? onEnd,
    Function(String error)? onError,
  }) {
    _onResult = onResult;
    _onStartListening = onStart;
    _onEndListening = onEnd;
    _onErrorListening = onError;

    final event = html.CustomEvent('ourly_start_listening', detail: {'lang': 'vi-VN'});
    html.window.dispatchEvent(event);
    return true;
  }

  void stopListening() {
    html.window.dispatchEvent(html.CustomEvent('ourly_stop_listening'));
    isListening = false;
  }

  bool speak(String text, {VoidCallback? onStart, VoidCallback? onEnd, Function(String error)? onError}) {
    _onStartSpeaking = onStart;
    _onEndSpeaking = onEnd;
    _onErrorSpeaking = onError;

    final event = html.CustomEvent('ourly_speak', detail: {'text': text, 'lang': 'vi-VN'});
    html.window.dispatchEvent(event);
    return true;
  }

  void stopSpeaking() {
    html.window.dispatchEvent(html.CustomEvent('ourly_stop_speaking'));
    isSpeaking = false;
  }
}

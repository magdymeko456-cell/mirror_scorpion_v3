import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  TTSService() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text, {String lang = 'ar-SA'}) async {
    if (text.trim().isEmpty) return;
    await _tts.setLanguage(lang);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

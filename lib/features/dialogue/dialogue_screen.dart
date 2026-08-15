import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/services/tts_service.dart';
import '../../core/services/translation_service.dart';

class DialogueScreen extends StatefulWidget {
  const DialogueScreen({super.key});

  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = "اضغط على المايك وابدأ الحديث...";
  String _translatedText = "";
  bool _isTranslating = false;

  void _toggleListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (val) => setState(() => _isListening = false),
        onStatus: (val) {
          if (val == 'done') setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'ar_SA',
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
              if (val.finalResult) {
                _isListening = false;
                _processTranslationAndSpeech(_recognizedText);
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processTranslationAndSpeech(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _isTranslating = true);
    final transService = context.read<TranslationService>();
    final ttsService = context.read<TTSService>();

    final result = await transService.translate(text, from: 'ar', to: 'en');
    setState(() {
      _translatedText = result;
      _isTranslating = false;
    });

    await ttsService.speak(result, lang: 'en-US');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحوار المترجم الفوري'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('النص المسموع (عربي):', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(_recognizedText, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                      const Divider(),
                      const Text('الترجمة والنطق (English):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _isTranslating
                              ? const Center(child: CircularProgressIndicator())
                              : SelectableText(_translatedText, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FloatingActionButton.large(
              onPressed: _toggleListen,
              backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF00B4D8),
              child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _isListening ? 'جاري الاستماع...' : 'اضغط للتحدث',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

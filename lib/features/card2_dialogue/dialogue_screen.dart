import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/tts_service.dart';
import '../../services/language_service.dart';
import '../../services/audio_file_service.dart';

class DialogueTranslationScreen extends StatefulWidget {
  const DialogueTranslationScreen({super.key});

  @override
  State<DialogueTranslationScreen> createState() =>
      _DialogueTranslationScreenState();
}

class _DialogueTranslationScreenState extends State<DialogueTranslationScreen> {
  final TextEditingController _upperController = TextEditingController();
  final TextEditingController _lowerController = TextEditingController();
  late stt.SpeechToText _speechToText;
  String _rightLang = 'ar';
  String _leftLang = 'en';
  bool _isListening = false;
  bool _isTranslating = false;
  bool _hasResult = false;

  final Map<String, String> _languages = {
    'af': 'Afrikaans', 'sq': 'Albanian', 'ar': 'العربية', 'hy': 'Armenian',
    'az': 'Azerbaijani', 'eu': 'Basque', 'be': 'Belarusian', 'bn': 'Bengali',
    'bs': 'Bosnian', 'bg': 'Bulgarian', 'ca': 'Catalan', 'zh': '中文',
    'co': 'Corsican', 'hr': 'Croatian', 'cs': 'Czech', 'da': 'Danish',
    'nl': 'Dutch', 'en': 'English', 'et': 'Estonian', 'tl': 'Filipino',
    'fi': 'Finnish', 'fr': 'Français', 'ka': 'Georgian', 'de': 'Deutsch',
    'el': 'Greek', 'gu': 'Gujarati', 'hi': 'Hindi', 'hu': 'Hungarian',
    'is': 'Icelandic', 'id': 'Indonesian', 'ga': 'Irish', 'it': 'Italiano',
    'ja': '日本語', 'kn': 'Kannada', 'kk': 'Kazakh', 'ko': '한국어',
    'ku': 'Kurdish', 'lv': 'Latvian', 'lt': 'Lithuanian', 'mk': 'Macedonian',
    'ms': 'Malay', 'ml': 'Malayalam', 'mt': 'Maltese', 'mr': 'Marathi',
    'mn': 'Mongolian', 'ne': 'Nepali', 'no': 'Norwegian', 'ps': 'Pashto',
    'fa': 'فارسی', 'pl': 'Polish', 'pt': 'Português', 'pa': 'Punjabi',
    'ro': 'Română', 'ru': 'Русский', 'sr': 'Српски', 'sd': 'Sindhi',
    'si': 'Sinhala', 'sk': 'Slovak', 'sl': 'Slovenian', 'so': 'Somali',
    'es': 'Español', 'sw': 'Kiswahili', 'sv': 'Svenska', 'tg': 'Tajik',
    'ta': 'தமிழ்', 'te': 'తెలుగు', 'th': 'ไทย', 'tr': 'Türkçe',
    'uk': 'Українська', 'ur': 'اردو', 'ug': 'ئۇيغۇرچە', 'uz': "O'zbek",
    'vi': 'Tiếng Việt', 'cy': 'Cymraeg', 'yi': 'יידיש', 'yo': 'Yorùbá',
    'zu': 'isiZulu',
  };

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _loadSavedLanguages();
  }

  Future _loadSavedLanguages() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final right = await langService.getLanguageForScreen('dialogue_right');
    final left = await langService.getLanguageForScreen('dialogue_left');
    setState(() {
      if (right.isNotEmpty && _languages.containsKey(right)) _rightLang = right;
      if (left.isNotEmpty && _languages.containsKey(left)) _leftLang = left;
    });
  }

  @override
  void dispose() {
    _upperController.dispose();
    _lowerController.dispose();
    super.dispose();
  }

  Future<void> _handleMic() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
      setState(() {});
      if (_upperController.text.isNotEmpty) {
        _translateSpeech();
      }
      return;
    }

    bool available = await _speechToText.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) {
        if (s == 'done') {
          setState(() => _isListening = false);
          if (_upperController.text.isNotEmpty) _translateSpeech();
        }
      },
    );

    if (available) {
      setState(() {
        _upperController.clear();
        _lowerController.clear();
        _hasResult = false;
        _isListening = true;
      });
      await _speechToText.listen(
        onResult: (r) {
          if (r.finalResult) {
            setState(() {
              _upperController.text = r.recognizedWords;
              _isListening = false;
            });
            if (_upperController.text.isNotEmpty) _translateSpeech();
          } else {
            setState(() {
              _upperController.text = r.recognizedWords;
            });
          }
        },
        localeId: _rightLang == 'ar' ? 'ar_SA' : 'en_US',
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _translateSpeech() async {
    if (_upperController.text.trim().isEmpty) return;
    setState(() => _isTranslating = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(_upperController.text)}&langpair=$_rightLang|$_leftLang'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _lowerController.text = data['responseData']['translatedText'] ?? '';
          _isTranslating = false;
          _hasResult = true;
        });
      } else {
        setState(() {
          _lowerController.text = 'ترجمة: ${_upperController.text}';
          _isTranslating = false;
          _hasResult = true;
        });
      }
    } catch (e) {
      setState(() {
        _lowerController.text = 'ترجمة: ${_upperController.text}';
        _isTranslating = false;
        _hasResult = true;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _rightLang;
      _rightLang = _leftLang;
      _leftLang = temp;
      _upperController.clear();
      _lowerController.clear();
      _hasResult = false;
    });
    final langService = Provider.of<LanguageService>(context, listen: false);
    langService.saveLanguageForScreen('dialogue_right', _rightLang);
    langService.saveLanguageForScreen('dialogue_left', _leftLang);
  }

  void _speakTranslation() {
    if (_lowerController.text.isNotEmpty) {
      Provider.of<TTSService>(context, listen: false)
          .speak(_lowerController.text, language: _leftLang);
    }
  }

  Future<void> _pickAudioForDialogue() async {
    final audioService = Provider.of<AudioFileService>(context, listen: false);
    final file = await audioService.pickAudioFile();
    if (file != null) {
      setState(() {
        _upperController.text = '🎵 ملف صوتي: ${file.path.split('/').last}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم رفع الملف: ${file.path.split('/').last}، جاري الترجمة...'),
        ),
      );
      _translateSpeech();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حوار مترجم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.push_pin, color: Colors.orangeAccent),
            tooltip: 'رفع ملف صوتي للترجمة',
            onPressed: _pickAudioForDialogue,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // المحرر العلوي (المصدر - يستخدم لغة الزر اليمين دائماً)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _upperController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: 'الكلام الملتقط من المايك يظهر هنا...',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                              border: InputBorder.none,
                            ),
                            readOnly: true,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            'المصدر: ${_languages[_rightLang] ?? _rightLang}',
                            style: TextStyle(
                                color: Colors.blueAccent.withOpacity(0.6),
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // أزرار اللغة + المايك + التبديل
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الزر الأيسر (الهدف - للمحرر السفلي)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _leftLang,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1B2838),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                              items: _languages.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _leftLang = v);
                                Provider.of<LanguageService>(context, listen: false)
                                    .saveLanguageForScreen('dialogue_left', v);
                              },
                            ),
                          ),
                        ),
                      ),

                      // تبديل
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: Colors.amber, size: 28),
                        onPressed: _swapLanguages,
                        tooltip: 'تبديل اللغات',
                      ),

                      // المايك (حجم كبير)
                      GestureDetector(
                        onTap: _handleMic,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.redAccent : Colors.blueAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : Colors.blue)
                                    .withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),

                      // الزر الأيمن (المصدر - للمحرر العلوي دائماً)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _rightLang,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF1B2838),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                              items: _languages.entries
                                  .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _rightLang = v);
                                Provider.of<LanguageService>(context, listen: false)
                                    .saveLanguageForScreen('dialogue_right', v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // المحرر السفلي (الترجمة)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lowerController,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: 'الترجمة تظهر هنا...',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_isTranslating)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.blueAccent, strokeWidth: 2),
                              ),
                            // دبوس رفع ملفات
                            IconButton(
                              icon: const Icon(Icons.push_pin,
                                  color: Colors.orangeAccent, size: 22),
                              onPressed: _pickAudioForDialogue,
                              tooltip: 'رفع ملف صوتي',
                            ),
                            const Spacer(),
                            // سبيكر نطق الترجمة
                            IconButton(
                              icon: const Icon(Icons.volume_up,
                                  color: Colors.blueAccent, size: 28),
                              onPressed: _speakTranslation,
                              tooltip: 'نطق الترجمة',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: 0.3,
                  child: const Text(
                    "Mirror Scorpion Dialogue",
                    style: TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

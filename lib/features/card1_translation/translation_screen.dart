import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/tts_service.dart';
import '../../services/language_service.dart';
import '../../services/audio_file_service.dart';
import '../../services/database_service.dart';

class TextTranslationScreen extends StatefulWidget {
  const TextTranslationScreen({super.key});

  @override
  State<TextTranslationScreen> createState() => _TextTranslationScreenState();
}

class _TextTranslationScreenState extends State<TextTranslationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();
  late stt.SpeechToText _speechToText;
  late AnimationController _scorpionController;
  String _selectedLanguage = 'ar';
  bool _isListening = false;
  bool _isTranslating = false;
  bool _clearOnNextInput = false;

  final Map<String, String> _hundredLanguages = {
    'af': 'Afrikaans', 'sq': 'Shqip', 'am': 'አማርኛ', 'ar': 'العربية',
    'hy': 'Հայերեն', 'az': 'Azərbaycan', 'eu': 'Euskara', 'be': 'Беларуская',
    'bn': 'বাংলা', 'bs': 'Bosanski', 'bg': 'Български', 'ca': 'Català',
    'ceb': 'Cebuano', 'ny': 'Chichewa', 'zh': '中文', 'co': 'Corsu',
    'hr': 'Hrvatski', 'cs': 'Čeština', 'da': 'Dansk', 'nl': 'Nederlands',
    'en': 'English', 'eo': 'Esperanto', 'et': 'Eesti', 'tl': 'Filipino',
    'fi': 'Suomi', 'fr': 'Français', 'fy': 'Frysk', 'gl': 'Galego',
    'ka': 'ქართული', 'de': 'Deutsch', 'el': 'Ελληνικά', 'gu': 'ગુજરાતી',
    'ht': 'Kreyòl', 'ha': 'Hausa', 'haw': 'Hawaiʻi', 'iw': 'עברית',
    'hi': 'हिन्दी', 'hmn': 'Hmong', 'hu': 'Magyar', 'is': 'Íslenska',
    'ig': 'Igbo', 'id': 'Bahasa Indonesia', 'ga': 'Gaeilge', 'it': 'Italiano',
    'ja': '日本語', 'jw': 'Basa Jawa', 'kn': 'ಕನ್ನಡ', 'kk': 'Қазақ',
    'km': 'ខ្មែរ', 'rw': 'Kinyarwanda', 'ko': '한국어', 'ku': 'Kurdî',
    'ky': 'Кыргызча', 'lo': 'ລາວ', 'la': 'Latina', 'lv': 'Latviešu',
    'lt': 'Lietuvių', 'lb': 'Lëtzebuergesch', 'mk': 'Македонски',
    'mg': 'Malagasy', 'ms': 'Bahasa Melayu', 'ml': 'മലയാളം', 'mt': 'Malti',
    'mi': 'Māori', 'mr': 'मराठी', 'mn': 'Монгол', 'my': 'မြန်မာ',
    'ne': 'नेपाली', 'no': 'Norsk', 'or': 'ଓଡ଼ିଆ', 'ps': 'پښتو',
    'fa': 'فارسی', 'pl': 'Polski', 'pt': 'Português', 'pa': 'ਪੰਜਾਬੀ',
    'ro': 'Română', 'ru': 'Русский', 'sm': 'Samoa', 'gd': 'Gàidhlig',
    'sr': 'Српски', 'st': 'Sesotho', 'sn': 'Shona', 'sd': 'سنڌي',
    'si': 'සිංහල', 'sk': 'Slovenčina', 'sl': 'Slovenščina', 'so': 'Soomaali',
    'es': 'Español', 'su': 'Basa Sunda', 'sw': 'Kiswahili', 'sv': 'Svenska',
    'tg': 'Тоҷикӣ', 'ta': 'தமிழ்', 'tt': 'Татар', 'te': 'తెలుగు',
    'th': 'ไทย', 'tr': 'Türkçe', 'tk': 'Türkmen', 'ug': 'ئۇيغۇرچە',
    'uk': 'Українська', 'ur': 'اردو', 'uz': "O'zbek", 'vi': 'Tiếng Việt',
    'cy': 'Cymraeg', 'xh': 'isiXhosa', 'yi': 'יידיש', 'yo': 'Yorùbá',
    'zu': 'isiZulu',
  };

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _scorpionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadLastLanguage();
  }

  Future _loadLastLanguage() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final lastLang = await langService.getLanguageForScreen('translation');
    if (lastLang.isNotEmpty && _hundredLanguages.containsKey(lastLang)) {
      setState(() => _selectedLanguage = lastLang);
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _translatedController.dispose();
    _scorpionController.dispose();
    super.dispose();
  }

  void _handleInputClearCheck() {
    if (_clearOnNextInput) {
      _clearOnNextInput = false;
    }
  }

  Future<void> _handleMic() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
      setState(() {});
      if (_sourceController.text.isNotEmpty) {
        _translate();
      }
      return;
    }

    bool available = await _speechToText.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) {
        if (s == 'done') {
          setState(() => _isListening = false);
          if (_sourceController.text.isNotEmpty) _translate();
        }
      },
    );

    if (available) {
      setState(() {
        if (_clearOnNextInput) {
          _sourceController.clear();
          _translatedController.clear();
          _clearOnNextInput = false;
        }
        _isListening = true;
      });
      await _speechToText.listen(
        onResult: (r) {
          if (r.finalResult) {
            setState(() {
              _sourceController.text = r.recognizedWords;
              _isListening = false;
            });
            if (_sourceController.text.isNotEmpty) _translate();
          } else {
            setState(() {
              _sourceController.text = r.recognizedWords;
            });
          }
        },
        localeId: 'ar_SA',
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  Future<void> _translate() async {
    if (_sourceController.text.trim().isEmpty) return;
    setState(() => _isTranslating = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(_sourceController.text)}&langpair=ar|$_selectedLanguage'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['responseData']['translatedText'] ?? '';
        setState(() {
          _translatedController.text = translated;
          _isTranslating = false;
        });
        // حفظ في تاريخ الترجمة
        Provider.of<DatabaseService>(context, listen: false).saveTranslation(
          _sourceController.text,
          translated,
          sourceLang: 'ar',
          targetLang: _selectedLanguage,
        );
      } else {
        setState(() => _isTranslating = false);
      }
    } catch (e) {
      // fallback محلي
      setState(() {
        _translatedController.text = 'ترجمة: ${_sourceController.text}';
        _isTranslating = false;
      });
    }
  }

  void _copyText() {
    if (_translatedController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translatedController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم نسخ النص المترجم')),
    );
  }

  Future<void> _shareAudioWithSignature() async {
    if (_translatedController.text.isEmpty) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mirror_translation.txt');
      await file.writeAsString(
        '$_translatedController.text\n\n- ترجم بواسطة ميرور سكربيون',
      );
      await SharePlus.instance.share(
        ShareParams(
          text: _translatedController.text,
          subject: 'ترجمة ميرور سكربيون',
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  Future<void> _pickAudioFile() async {
    final audioService = Provider.of<AudioFileService>(context, listen: false);
    final file = await audioService.pickAudioFile();
    if (file != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم رفع الملف الصوتي: ${file.path.split('/').last}')),
      );
      _sourceController.text = '🎵 ملف صوتي: ${file.path.split('/').last}\nجارٍ معالجة المحتوى الصوتي...';
      _translate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('ترجمة نصية', style: TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.cyanAccent),
            tooltip: 'رفع ملف صوتي',
            onPressed: _pickAudioFile,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // شعار العقرب
              AnimatedBuilder(
                animation: _scorpionController,
                builder: (context, child) {
                  return Column(
                    children: [
                      Opacity(
                        opacity: 0.85,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/scorpion_icon.jpeg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 120, height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.cyanAccent.withOpacity(0.4), Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // اختيار اللغة
              Center(
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2838),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4), width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1B2838),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                      items: _hundredLanguages.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedLanguage = v);
                        final langService =
                            Provider.of<LanguageService>(context, listen: false);
                        await langService.saveLanguageForScreen('translation', v);
                        if (_sourceController.text.isNotEmpty) _translate();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // المحرر العلوي (مصدر النص)
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isListening ? Colors.redAccent.withOpacity(0.5) : Colors.white12,
                  ),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _sourceController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                      decoration: const InputDecoration(
                        hintText: 'ابدأ بالكتابة أو اضغط المايك للتحدث...',
                        hintStyle: TextStyle(color: Colors.white30, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _handleInputClearCheck(),
                      onTap: () {
                        if (_clearOnNextInput) {
                          _clearOnNextInput = false;
                        }
                      },
                    ),
                    Positioned(
                      bottom: 0, left: 0,
                      child: GestureDetector(
                        onTap: _handleMic,
                        child: CircleAvatar(
                          backgroundColor: _isListening
                              ? Colors.redAccent
                              : Colors.blueAccent.withOpacity(0.2),
                          radius: 22,
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    if (_sourceController.text.isNotEmpty && !_isTranslating)
                      Positioned(
                        bottom: 0, right: 0,
                        child: TextButton.icon(
                          onPressed: _translate,
                          icon: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                          label: const Text('ترجم الآن',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Indication
              if (_isTranslating)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                      color: Colors.cyanAccent, backgroundColor: Colors.white12),
                ),

              // المحرر السفلي (الترجمة)
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _translatedController,
                        maxLines: 5,
                        readOnly: true,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'الترجمة تظهر هنا...',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // نسخ
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white60, size: 20),
                          onPressed: _copyText,
                          tooltip: 'نسخ النص المترجم',
                        ),
                        // دبوس رفع ملفات صوتية
                        IconButton(
                          icon: const Icon(Icons.push_pin, color: Colors.orangeAccent, size: 20),
                          onPressed: _pickAudioFile,
                          tooltip: 'رفع ملف صوتي للترجمة',
                        ),
                        const Spacer(),
                        // مشاركة
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.greenAccent, size: 20),
                          onPressed: _shareAudioWithSignature,
                          tooltip: 'مشاركة مع توقيع ميرور سكربيون',
                        ),
                        // نطق الترجمة
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.cyanAccent, size: 24),
                          onPressed: () {
                            if (_translatedController.text.isNotEmpty) {
                              Provider.of<TTSService>(context, listen: false)
                                  .speak(_translatedController.text, language: _selectedLanguage);
                            }
                          },
                          tooltip: 'نطق الترجمة',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Opacity(
                opacity: 0.2,
                child: Text(
                  "Mirror Scorpion • 100 لغة",
                  style: TextStyle(color: Colors.white, fontSize: 11, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

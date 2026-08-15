#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - DIALOGUE & SPEECH ACTIVATION (ALL-IN-ONE)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[DIALOGUE]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء تفعيل كرت الحوار المترجم وخدمات السمع والنطق..."

# 1. إنشاء المجلدات
mkdir -p "$WORKDIR/lib/core/services"
mkdir -p "$WORKDIR/lib/features/dialogue"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 2. تحديث pubspec.yaml لإضافة حزم الصوت كاملة
cat << 'EOPUB' > pubspec.yaml
name: mirror_scorpion_v3
description: "Mirror Scorpion v3 - البداية الذهبية النظيفة"
publish_to: 'none'
version: 1.3.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.5+1
  shared_preferences: ^2.5.5
  intl: ^0.20.2
  http: ^1.2.1
  flutter_tts: ^4.2.2
  speech_to_text: ^7.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOPUB
ok "تم تحديث pubspec.yaml بـ flutter_tts و speech_to_text"

# 3. إنشاء خدمة النطق الصوتي (TTSService)
cat << 'EOTTS' > lib/core/services/tts_service.dart
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
EOTTS
ok "تم إنشاء TTSService"

# 4. إنشاء شاشة الحوار المترجم (DialogueScreen)
cat << 'EODIA' > lib/features/dialogue/dialogue_screen.dart
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
EODIA
ok "تم إنشاء DialogueScreen"

# 5. تحديث HomeScreen لربط كرت الحوار بالشاشة الجديدة
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';
import '../translation/translation_screen.dart';
import '../dialogue/dialogue_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final bubbleService = Provider.of<FloatingBubbleService>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.isDarkMode 
              ? [const Color(0xFF0D1B2A), const Color(0xFF1B263B)]
              : [const Color(0xFFF5F5F5), const Color(0xFFE0E1DD)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.security, size: 80, color: Color(0xFF00B4D8)),
                      const SizedBox(height: 16),
                      const Text(
                        'ميرور سكربيون',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8)),
                      ),
                      const Text(
                        'حيث تُصنع البدايات',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.isDarkMode ? Colors.white10 : Colors.black12,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bubble_chart, color: Color(0xFF00B4D8)),
                            const SizedBox(width: 10),
                            const Text('تفعيل الفقاعة العائمة'),
                            const SizedBox(width: 10),
                            Switch(
                              value: bubbleService.isEnabled,
                              onChanged: (v) => bubbleService.toggleBubble(v),
                              activeColor: const Color(0xFF00B4D8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      Icons.translate, 
                      'ترجمة نصية', 
                      'لغة + مايك 100', 
                      Colors.blueAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslationScreen()))
                    ),
                    _buildFeatureCard(
                      Icons.forum, 
                      'حوار مترجم', 
                      'محادثة ثنائية فورية', 
                      Colors.cyanAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialogueScreen()))
                    ),
                    _buildFeatureCard(Icons.document_scanner, 'مستندات وعدسة', 'ترجمة صور وملفات', Colors.tealAccent, () {}),
                    _buildFeatureCard(Icons.auto_stories, 'قصص وإلهام', 'مكتبة ذكية متكاملة', Colors.orangeAccent, () {}),
                    _buildFeatureCard(Icons.sports_esports, 'ألعاب 3D', 'شطرنج + روبيك', Colors.purpleAccent, () {}),
                    _buildFeatureCard(Icons.settings, 'الإعدادات', 'تخصيص وترقية برو', Colors.blueGrey, () {}),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
EOH
ok "تم ربط كرت الحوار بـ HomeScreen"

# 6. تحديث main.dart لإدراج TTSService
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';
import 'core/services/floating_bubble_service.dart';
import 'core/services/translation_service.dart';
import 'core/services/tts_service.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => FloatingBubbleService()),
        ChangeNotifierProvider(create: (_) => TranslationService()),
        ChangeNotifierProvider(create: (_) => TTSService()),
      ],
      child: const MirrorScorpionApp(),
    ),
  );
}

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Mirror Scorpion v3',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      locale: const Locale('ar', ''),
      home: const HomeScreen(),
    );
  }
}
EOMAIN
ok "تم تحديث main.dart بـ TTSService"

# 7. الرفع التلقائي إلى GitHub
log "جاري رفع كرت الحوار المترجم وخدمات الصوت إلى GitHub..."
git add .
git commit -m "feat(dialogue): activate dialogue screen and speech services" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تم تفعيل كرت الحوار بنجاح يا تامر! 🦂🎙️✨"

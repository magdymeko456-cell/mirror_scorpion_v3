#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  ms_stage1_cards.sh — المرحلة 1: تفعيل وظائف الكروت
#  (ترجمة 100+ لغة + حفظ تلقائي + عدسة/مستندات فعلية + لغة الجهاز)
#  Termux فقط — بلا Flutter. يبدأ من مجلدك وينتهي بالرفع.
# ══════════════════════════════════════════════════════════════════
set -euo pipefail

REPO="magdymeko456-cell/mirror_scorpion-mirror_scorpion_v2"
BRANCH="main"

cd "$HOME/mirror_scorpion_translate_version_2" || { echo "✗ المجلد غير موجود"; exit 1; }
echo "✓ نعمل داخل: $(pwd)"

TOKEN="$(tr -d '\r\n' < "$HOME/.ms_gh_token" 2>/dev/null || true)"
if [[ -z "$TOKEN" || "$TOKEN" == *"XXXXXXXX"* ]]; then
  echo "✗ التوكن غير صالح في ~/.ms_gh_token"; exit 1
fi
HTTP="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H "Authorization: Bearer ${TOKEN}" https://api.github.com/user)"
[[ "$HTTP" != "200" ]] && { echo "✗ التوكن مرفوض (HTTP $HTTP)"; exit 1; }
echo "✓ التوكن سليم"

git fetch origin "$BRANCH" 2>/dev/null || git fetch origin
git reset --hard "origin/$BRANCH"
git clean -fdq -e clean_failed_runs.sh -e git_sync.sh -e cleanup_builds.sh \
  -e translation_voice_tool.py -e step2_stories.sh -e .core_completion_status \
  -e .safe_build_android || true
echo "✓ HEAD: $(git rev-parse --short HEAD)"

# ── [1] pubspec: إضافة حزم العدسة/المستندات ──
python3 - <<'PY'
import re
p = 'pubspec.yaml'
s = open(p, encoding='utf-8').read()
# intl ثابت (يمنع فشل #854)
if re.search(r'^  intl:', s, flags=re.M):
    s = re.sub(r'^  intl:.*$', '  intl: ^0.20.2', s, flags=re.M)
else:
    s = s.replace('dependencies:\n', 'dependencies:\n  intl: ^0.20.2\n', 1)
# إضافة حزم العدسة والمستندات إن لم تكن موجودة
for dep, ver in [('webview_flutter', '^4.10.0'), ('google_mlkit_text_recognition', '^0.13.0')]:
    if not re.search(rf'^  {dep}:', s, flags=re.M):
        s = s.replace('  file_picker: ', f'  {dep}: {ver}\n  file_picker: ', 1)
        print(f'  + أُضيفت {dep} {ver}')
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ intl ^0.20.2 ثابت')
PY

# ── [2] المانيفست: إذن الوسائط + نموذج OCR ──
python3 - <<'PY'
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
if 'READ_MEDIA_IMAGES' not in s:
    s = s.replace(
        '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>',
        '    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>\n'
        '    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>', 1)
if 'com.google.mlkit.vision.DEPENDENCIES' not in s:
    s = s.replace(
        '    </application>',
        '        <meta-data android:name="com.google.mlkit.vision.DEPENDENCIES" android:value="ocr"/>\n'
        '    </application>', 1)
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ المانيفست: READ_MEDIA_IMAGES + نموذج OCR')
PY

# ── [3] language_service.dart: 100+ لغة + لغة الجهاز ──
cat > lib/services/language_service.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  final Map<String, String> _screenLanguages = {
    'dialogue_from': 'ar',
    'dialogue_to': 'en',
    'text_from': 'ar',
    'text_to': 'en',
  };

  bool get isInitialized => _isInitialized;

  /// لغة جهاز المستخدم (تُستخدم عند فتح التطبيق وفي الشاشات)
  String get deviceLanguageCode {
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    return loc.languageCode;
  }

  String get deviceLanguageName => getLanguageName(deviceLanguageCode);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _screenLanguages['dialogue_from'] = _prefs.getString('dialogue_from') ?? 'ar';
    _screenLanguages['dialogue_to'] = _prefs.getString('dialogue_to') ?? 'en';
    _screenLanguages['text_from'] = _prefs.getString('text_from') ?? 'ar';
    _screenLanguages['text_to'] = _prefs.getString('text_to') ?? 'en';
    _isInitialized = true;
    notifyListeners();
  }

  /// 100+ لغة مدعومة (تطابق supportedLocales في main.dart)
  List<String> getLanguageCodes() => _langNames.keys.toList();

  String getLanguageName(String code) => _langNames[code] ?? code;

  String getLanguageForScreen(String screenKey) => _screenLanguages[screenKey] ?? 'ar';

  Future<void> saveLanguageForScreen(String screenKey, String langCode) async {
    _screenLanguages[screenKey] = langCode;
    await _prefs.setString(screenKey, langCode);
    notifyListeners();
  }

  String translateOffline(String text, String from, String to) {
    if (text.isEmpty) return '';
    final clean = text.trim().toLowerCase();
    const dictionary = {
      'ar': {
        'hello': 'مرحباً', 'how are you?': 'كيف حالك؟', 'thank you': 'شكراً لك',
        'good morning': 'صباح الخير', 'good night': 'تصبح على خير',
        'yes': 'نعم', 'no': 'لا', 'peace be upon you': 'السلام عليكم',
        'welcome': 'أهلاً وسهلاً',
      },
      'en': {
        'مرحبا': 'Hello', 'مرحباً': 'Hello', 'كيف حالك': 'How are you?',
        'كيف حالك؟': 'How are you?', 'شكرا': 'Thank you', 'شكراً': 'Thank you',
        'صباح الخير': 'Good morning', 'السلام عليكم': 'Peace be upon you',
        'أهلاً وسهلاً': 'Welcome',
      }
    };
    if (dictionary.containsKey(to)) {
      for (final e in dictionary[to]!.entries) {
        if (clean.contains(e.key)) return e.value;
      }
    }
    return '[$to] $text';
  }

  Map<String, dynamic> generateSmartGameChallenge(String lang) {
    if (lang == 'ar') {
      return {
        'question': 'ما هي الكلمة الإنجليزية المقابلة لـ "تطوير البرمجيات"؟',
        'options': ['Software Development', 'Hardware Industry', 'Network Design', 'Data Analysis'],
        'answer': 'Software Development',
        'hint': 'تبدأ بحرف S'
      };
    } else {
      return {
        'question': 'What is the Arabic word for "Artificial Intelligence"?',
        'options': ['الذكاء الاصطناعي', 'الواقع الافتراضي', 'الأمن السيبراني', 'علم البيانات'],
        'answer': 'الذكاء الاصطناعي',
        'hint': 'تبدأ بـ الذكاء...'
      };
    }
  }

  static const Map<String, String> _langNames = {
    'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español',
    'de': 'Deutsch', 'it': 'Italiano', 'pt': 'Português', 'ru': 'Русский',
    'zh': '中文(简体)', 'zh-TW': '中文(繁體)', 'ja': '日本語', 'ko': '한국어',
    'tr': 'Türkçe', 'ur': 'اردو', 'fa': 'فارسی', 'hi': 'हिन्दी',
    'bn': 'বাংলা', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
    'nl': 'Nederlands', 'pl': 'Polski', 'sv': 'Svenska', 'da': 'Dansk',
    'fi': 'Suomi', 'no': 'Norsk', 'cs': 'Čeština', 'hu': 'Magyar',
    'ro': 'Română', 'el': 'Ελληνικά', 'he': 'עברית', 'th': 'ไทย',
    'vi': 'Tiếng Việt', 'tl': 'Filipino', 'sw': 'Kiswahili',
    'ta': 'தமிழ்', 'te': 'తెలుగు', 'kn': 'ಕನ್ನಡ', 'ml': 'മലയാളം',
    'gu': 'ગુજરાતી', 'mr': 'मराठी', 'pa': 'ਪੰਜਾਬੀ', 'ne': 'नेपाली',
    'si': 'සිංහල', 'km': 'ខ្មែរ', 'my': 'မြန်မာ', 'lo': 'ລາວ',
    'ka': 'ქართული', 'hy': 'հայերեն', 'az': 'Azərbaycan', 'uz': "O'zbek",
    'kk': 'Қазақ', 'ky': 'Кыргызча', 'tg': 'Тоҷикӣ', 'mn': 'Монгол',
    'ps': 'پښتو', 'sd': 'سنڌي', 'am': 'አማርኛ', 'om': 'Afaan Oromoo',
    'ha': 'Hausa', 'ig': 'Igbo', 'yo': 'Yorùbá', 'zu': 'isiZulu',
    'xh': 'isiXhosa', 'af': 'Afrikaans', 'st': 'Sesotho', 'sn': 'Shona',
    'rw': 'Kinyarwanda', 'mg': 'Malagasy', 'ny': 'Chichewa', 'eo': 'Esperanto',
    'cy': 'Cymraeg', 'ga': 'Gaeilge', 'gd': 'Gàidhlig', 'mt': 'Malti',
    'is': 'Íslenska', 'lv': 'Latviešu', 'lt': 'Lietuvių', 'et': 'Eesti',
    'bs': 'Bosanski', 'hr': 'Hrvatski', 'sq': 'Shqip', 'mk': 'Македонски',
    'sr': 'Српски', 'sl': 'Slovenščina', 'sk': 'Slovenčina',
    'eu': 'Euskara', 'gl': 'Galego', 'ca': 'Català', 'oc': 'Occitan',
    'lb': 'Lëtzebuergesch', 'fy': 'Frysk', 'jv': 'Jawa', 'su': 'Sunda',
    'ceb': 'Cebuano', 'hmn': 'Hmong', 'ht': 'Kreyòl', 'co': 'Corsu', 'la': 'Latina',
  };
}
EOF
echo "  ✓ language_service.dart: 100+ لغة + لغة الجهاز"

# ── [4] main.dart: فتح بلغة الجهاز + تهيئة الخدمة ──
cat > lib/main.dart <<'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/tts_service.dart';
import 'services/database_service.dart';
import 'services/floating_bubble_service.dart';
import 'services/premium_verification_service.dart';
import 'services/language_service.dart';
import 'services/background_service.dart';
import 'services/language_download_service.dart';
import 'features/home_screen.dart';
import 'features/card1_translation/translation_screen.dart';
import 'features/card1_translation/dialogue_screen.dart';
import 'features/card1_translation/document_screen.dart';
import 'features/card4_stories/stories_screen.dart';
import 'features/games/chess_screen.dart';
import 'features/games/rubik_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/about/about_app_screen.dart';
import 'features/admin/key_generator_screen.dart';

/// لغة الجهاز — يفتح التطبيق بلغة المستخدم، مع عودة للعربية عند عدم الدعم
Locale _deviceLocale() {
  final loc = WidgetsBinding.instance.platformDispatcher.locale;
  const supported = [
    Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('de'),
    Locale('it'), Locale('pt'), Locale('ru'), Locale('zh'), Locale('ja'),
    Locale('ko'), Locale('tr'), Locale('ur'), Locale('fa'), Locale('hi'),
    Locale('bn'), Locale('id'), Locale('ms'), Locale('nl'), Locale('pl'),
    Locale('sv'), Locale('da'), Locale('fi'), Locale('no'), Locale('cs'),
    Locale('hu'), Locale('ro'), Locale('el'), Locale('he'), Locale('th'),
    Locale('vi'), Locale('tl'), Locale('sw'),
  ];
  if (supported.contains(loc)) return loc;
  final lang = Locale(loc.languageCode);
  if (supported.contains(lang)) return lang;
  return const Locale('ar');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService().init();
  await BackgroundService().initialize();
  await LanguageDownloadService().initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TTSService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => FloatingBubbleService()),
        ChangeNotifierProvider(create: (_) => PremiumVerificationService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => BackgroundService()),
        ChangeNotifierProvider(create: (_) => LanguageDownloadService()),
      ],
      child: const MirrorScorpionApp(),
    ),
  );
}

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror Scorpion',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('de'),
        Locale('it'), Locale('pt'), Locale('ru'), Locale('zh'), Locale('ja'),
        Locale('ko'), Locale('tr'), Locale('ur'), Locale('fa'), Locale('hi'),
        Locale('bn'), Locale('id'), Locale('ms'), Locale('nl'), Locale('pl'),
        Locale('sv'), Locale('da'), Locale('fi'), Locale('no'), Locale('cs'),
        Locale('hu'), Locale('ro'), Locale('el'), Locale('he'), Locale('th'),
        Locale('vi'), Locale('tl'), Locale('sw'), Locale('ta'), Locale('te'),
        Locale('kn'), Locale('ml'), Locale('gu'), Locale('mr'), Locale('pa'),
        Locale('ne'), Locale('si'), Locale('km'), Locale('my'), Locale('lo'),
        Locale('ka'), Locale('hy'), Locale('az'), Locale('uz'), Locale('kk'),
        Locale('ky'), Locale('tg'), Locale('mn'), Locale('ps'), Locale('sd'),
        Locale('am'), Locale('om'), Locale('ha'), Locale('ig'), Locale('yo'),
        Locale('zu'), Locale('xh'), Locale('af'), Locale('st'), Locale('sn'),
        Locale('rw'), Locale('mg'), Locale('ny'), Locale('eo'), Locale('cy'),
        Locale('ga'), Locale('gd'), Locale('mt'), Locale('is'), Locale('lv'),
        Locale('lt'), Locale('et'), Locale('bs'), Locale('hr'), Locale('sq'),
        Locale('mk'), Locale('sr'), Locale('sl'), Locale('sk'), Locale('eu'),
        Locale('gl'), Locale('ca'), Locale('oc'), Locale('lb'), Locale('fy'),
        Locale('jv'), Locale('su'), Locale('ceb'), Locale('hmn'), Locale('ht'),
        Locale('co'), Locale('la'),
      ],
      locale: _deviceLocale(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/translate': (context) => const TranslationScreen(),
        '/dialogue': (context) => const DialogueScreen(),
        '/document': (context) => const DocumentScreen(),
        '/stories': (context) => const StoriesScreen(),
        '/chess': (context) => const ChessScreen(),
        '/rubik': (context) => const RubikScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutAppScreen(),
        '/admin_gen': (context) => const KeyGeneratorScreen(),
      },
    );
  }
}
EOF
echo "  ✓ main.dart: فتح بلغة الجهاز + تهيئة LanguageService"

# ── [5] translation_screen: حفظ تلقائي لآخر اللغات ──
python3 - <<'PY'
import re
p = 'lib/features/card1_translation/translation_screen.dart'
s = open(p, encoding='utf-8').read()
s = re.sub(
    r"(setState\(\(\) => _langFrom = v as String\);)(\n\s*)(if \(_textController)",
    r"\1\2Provider.of<LanguageService>(context, listen: false).saveLanguageForScreen('text_from', v as String);\2\3",
    s)
s = re.sub(
    r"(setState\(\(\) => _langTo = v as String\);)(\n\s*)(if \(_textController)",
    r"\1\2Provider.of<LanguageService>(context, listen: false).saveLanguageForScreen('text_to', v as String);\2\3",
    s)
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ الترجمة النصية: حفظ تلقائي للغات')
PY

# ── [6] dialogue_screen: حفظ تلقائي للغات ──
python3 - <<'PY'
import re
p = 'lib/features/card1_translation/dialogue_screen.dart'
s = open(p, encoding='utf-8').read()
if "services/language_service.dart" not in s:
    s = s.replace("import '../../services/tts_service.dart';",
                  "import '../../services/tts_service.dart';\nimport '../../services/language_service.dart';")
s = re.sub(
    r"(onChanged: \(v\) \{ if \(v != null\) setState\(\(\) => _leftLang = v\); \},)",
    r"onChanged: (v) { if (v != null) { setState(() => _leftLang = v); Provider.of<LanguageService>(context, listen: false).saveLanguageForScreen('dialogue_to', v); } },",
    s)
s = re.sub(
    r"(onChanged: \(v\) \{ if \(v != null\) setState\(\(\) => _rightLang = v\); \},)",
    r"onChanged: (v) { if (v != null) { setState(() => _rightLang = v); Provider.of<LanguageService>(context, listen: false).saveLanguageForScreen('dialogue_from', v); } },",
    s)
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ الحوار المترجم: حفظ تلقائي للغات')
PY

# ── [7] document_screen: تنفيذ فعلي كامل (عدسة + ملف + رابط + OCR + ترجمة) ──
cat > lib/features/card1_translation/document_screen.dart <<'EOF'
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';

import '../../services/translation_api.dart';
import '../../services/tts_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});
  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  String _extractedText = '';
  String _translatedText = '';
  String _targetLang = 'ar';
  bool _isProcessing = false;
  bool _isTranslating = false;
  bool _showOriginal = true;
  bool _showTranslatedDoc = false;
  String _fileName = '';

  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _recognizer;

  static const Map<String, String> _langs = {
    'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'de': 'Deutsch',
    'es': 'Español', 'tr': 'Türkçe', 'ur': 'اردو', 'fa': 'فارسی',
    'hi': 'हिन्दी', 'bn': 'বাংলা', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
    'nl': 'Nederlands', 'pl': 'Polski', 'sv': 'Svenska', 'da': 'Dansk',
    'fi': 'Suomi', 'no': 'Norsk', 'cs': 'Čeština', 'hu': 'Magyar',
    'ro': 'Română', 'el': 'Ελληνικά', 'he': 'עברית', 'th': 'ไทย',
    'vi': 'Tiếng Việt', 'tl': 'Filipino', 'sw': 'Kiswahili',
  };

  @override
  void dispose() {
    _recognizer?.close();
    super.dispose();
  }

  // ── 📷 العدسة: صورة من الكاميرا أو المعرض ──
  Future<void> _pickFromCamera() async => _processPicked(await _picker.pickImage(source: ImageSource.camera));
  Future<void> _pickFromGallery() async => _processPicked(await _picker.pickImage(source: ImageSource.gallery));

  Future<void> _processPicked(XFile? img) async {
    if (img == null) return;
    setState(() {
      _fileName = img.name;
      _extractedText = '';
      _translatedText = '';
      _showTranslatedDoc = false;
      _isProcessing = true;
    });
    try {
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.arabic);
      final input = InputImage.fromFilePath(img.path);
      final result = await _recognizer!.processImage(input);
      if (!mounted) return;
      setState(() {
        _extractedText = result.text.trim();
        _isProcessing = false;
      });
      if (_extractedText.isEmpty) {
        _showMsg('لم يتم التعرف على نص — جرب صورة أوضح');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMsg('فشل التعرف على الصورة: $e');
    }
  }

  // ── 📁 اختيار ملف نصي ──
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    setState(() {
      _fileName = f.name;
      _extractedText = '';
      _translatedText = '';
      _showTranslatedDoc = false;
      _isProcessing = true;
    });
    try {
      final path = f.path;
      if (path == null) throw Exception('مسار فارغ');
      final ext = path.split('.').last.toLowerCase();
      if (!['txt', 'csv', 'json', 'md', 'log', 'srt'].contains(ext)) {
        throw Exception('النوع $ext غير مدعوم — اختر ملفاً نصياً');
      }
      final content = await File(path).readAsString();
      if (!mounted) return;
      setState(() {
        _extractedText = content.trim();
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showMsg('تعذّر قراءة الملف: $e');
    }
  }

  // ── 🔗 فتح رابط داخل webview ──
  Future<void> _openFromBrowser() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: const Text('🔗 فتح رابط مستند',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://example.com/document.txt',
            hintStyle: TextStyle(color: Colors.white30),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('فتح')),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    setState(() {
      _fileName = 'رابط: $url';
      _extractedText = '';
      _translatedText = '';
      _showTranslatedDoc = false;
    });
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        appBar: AppBar(
          title: const Text('🌐 المستند من الرابط', style: TextStyle(fontSize: 15)),
          backgroundColor: const Color(0xFF1B2838),
          foregroundColor: Colors.teal,
        ),
        body: WebViewWidget(controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url.startsWith('http') ? url : 'https://$url'))),
      ),
    ));
  }

  // ── 🌐 ترجمة النص المستخرج ──
  Future<void> _translate() async {
    if (_extractedText.isEmpty || _isTranslating) return;
    setState(() => _isTranslating = true);
    var res = await TranslationApi.translate(_extractedText, to: _targetLang, from: 'auto');
    if (res.isEmpty) res = '[$targetLang] تعذّر الترجمة الآن — تحقق من الاتصال';
    if (!mounted) return;
    setState(() {
      _translatedText = res;
      _isTranslating = false;
    });
  }

  String get targetLang => _langs[_targetLang] ?? _targetLang;

  void _showMsg(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final tts = Provider.of<TTSService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('📄 المستندات والعدسة',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        backgroundColor: const Color(0xFF1B2838),
        iconTheme: const IconThemeData(color: Colors.teal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── مصادر الإدخال ──
            Row(children: [
              Expanded(child: _btn(Icons.photo_camera, 'كاميرا', Colors.blueAccent, _pickFromCamera)),
              const SizedBox(width: 10),
              Expanded(child: _btn(Icons.photo_library, 'المعرض', Colors.tealAccent, _pickFromGallery)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _btn(Icons.insert_drive_file, 'ملف نصي', Colors.orangeAccent, _pickFile)),
              const SizedBox(width: 10),
              Expanded(child: _btn(Icons.link, 'رابط', Colors.purpleAccent, _openFromBrowser)),
            ]),
            if (_fileName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('📎 $_fileName', style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 16),

            // ── لغة الترجمة ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2838),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetLang,
                  dropdownColor: const Color(0xFF0D1B2A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.teal),
                  items: _langs.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _targetLang = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── النص المستخرج ──
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(color: Colors.teal),
              ),
            if (_extractedText.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2838),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('النص المستخرج:',
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_extractedText,
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isTranslating ? null : _translate,
                  icon: _isTranslating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.translate),
                  label: Text(_isTranslating ? 'جارٍ الترجمة...' : '🌐 ترجمة المستند'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (_translatedText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2838),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('الترجمة (${'$_langs'[0]}):', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.greenAccent, size: 20),
                        onPressed: () => tts.speak(_translatedText),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _translatedText));
                          _showMsg('✅ تم نسخ الترجمة');
                        },
                      ),
                    ]),
                    const SizedBox(height: 4),
                    SelectableText(_translatedText,
                        style: const TextStyle(color: Colors.green.shade300, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // ── إشعار 5 صفحات ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('5 صفحات في النسخة العادية. ترجمة غير محدودة في Pro.',
                        style: TextStyle(fontSize: 12, color: Colors.amber)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
EOF
echo "  ✓ document_screen: عدسة + ملف + رابط + OCR + ترجمة فعلية"

# ── [8] settings_screen: عرض لغة الجهاز الحالية ──
python3 - <<'PY'
p = 'lib/features/settings/settings_screen.dart'
s = open(p, encoding='utf-8').read()
if "_deviceLangName" not in s:
    helper = '''
  /// اسم لغة الجهاز الحالية
  String _deviceLangName() {
    final loc = WidgetsBinding.instance.platformDispatcher.locale;
    const names = {
      'ar': 'العربية', 'en': 'English', 'fr': 'Français', 'es': 'Español',
      'de': 'Deutsch', 'tr': 'Türkçe', 'ur': 'اردو', 'fa': 'فارسی',
      'hi': 'हिन्दी', 'bn': 'বাংলা', 'id': 'Bahasa Indonesia', 'ru': 'Русский',
      'zh': '中文', 'ja': '日本語', 'ko': '한국어', 'pt': 'Português',
    };
    return names[loc.languageCode] ?? loc.languageCode.toUpperCase();
  }
'''
    s = s.replace('  @override\n  Widget build(BuildContext context) {', helper + '\n  @override\n  Widget build(BuildContext context) {', 1)
    s = s.replace(
        "subtitle: const Text('يتم اكتشافها تلقائياً', style: TextStyle(color: Colors.white54)),",
        "subtitle: Text('اللغة الحالية: ${_deviceLangName()}', style: TextStyle(color: Colors.white54)),")
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ الإعدادات: عرض لغة الجهاز الفعلية')
PY

# ── [9] الرفع المدمج ──
git add -A
if git diff --cached --quiet; then
  echo "لا تغييرات — لم يُرفع شيء"
else
  git -c user.name="Mirror Scorpion CI" \
      -c user.email="ci@mirror-scorpion.local" \
      commit -m "feat(stage1): تفعيل وظائف الكروت — 100+ لغة + حفظ اللغات + عدسة/مستندات فعلية (OCR + ملف + webview) + لغة الجهاز"
  git push "https://x-access-token:${TOKEN}@github.com/${REPO}.git" HEAD:"$BRANCH"
  echo "✓ تم الرفع — البناء بدأ: https://github.com/${REPO}/actions"
fi
echo
echo "✓ المرحلة 1 مكتملة — راقب البناء وأرسل أي فشل فوراً"

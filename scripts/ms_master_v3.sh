#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - ALL IN ONE MASTER SCRIPT
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[MASTER-V3]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء التأسيس الشامل لمشروع Mirror Scorpion v3..."

mkdir -p "$WORKDIR/lib/core/theme"
mkdir -p "$WORKDIR/lib/core/services"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 1. pubspec.yaml
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

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOPUB
ok "تم إنشاء pubspec.yaml"

# 2. ThemeProvider
cat << 'EOTHEME' > lib/core/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isOn);
  }

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00B4D8),
      secondary: Color(0xFF1B263B),
      surface: Color(0xFF1B263B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B263B),
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0077B6),
      secondary: Colors.teal,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.black,
    ),
  );
}
EOTHEME
ok "تم إنشاء ThemeProvider"

# 3. LanguageService
cat << 'EOLANG' > lib/core/services/language_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageModel {
  final String code;
  final String name;
  final bool isDownloaded;

  LanguageModel({
    required this.code,
    required this.name,
    this.isDownloaded = false,
  });

  LanguageModel copyWith({bool? isDownloaded}) {
    return LanguageModel(
      code: code,
      name: name,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

class LanguageService extends ChangeNotifier {
  static const String _downloadedKey = 'downloaded_languages';

  List<LanguageModel> _supportedLanguages = [
    LanguageModel(code: 'ar', name: 'العربية', isDownloaded: true),
    LanguageModel(code: 'en', name: 'English', isDownloaded: true),
    LanguageModel(code: 'tr', name: 'Türkçe', isDownloaded: false),
    LanguageModel(code: 'fr', name: 'Français', isDownloaded: false),
    LanguageModel(code: 'de', name: 'Deutsch', isDownloaded: false),
  ];

  List<LanguageModel> get supportedLanguages => _supportedLanguages;

  LanguageService() {
    _loadDownloadedLanguages();
  }

  Future<void> _loadDownloadedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedCodes = prefs.getStringList(_downloadedKey) ?? ['ar', 'en'];

    _supportedLanguages = _supportedLanguages.map((lang) {
      return lang.copyWith(isDownloaded: downloadedCodes.contains(lang.code));
    }).toList();

    notifyListeners();
  }

  Future<void> toggleLanguageDownload(String code) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> downloadedCodes = prefs.getStringList(_downloadedKey) ?? ['ar', 'en'];

    if (downloadedCodes.contains(code)) {
      if (code != 'ar' && code != 'en') {
        downloadedCodes.remove(code);
      }
    } else {
      downloadedCodes.add(code);
    }

    await prefs.setStringList(_downloadedKey, downloadedCodes);
    await _loadDownloadedLanguages();
  }
}
EOLANG
ok "تم إنشاء LanguageService"

# 4. main.dart
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🦂 Mirror Scorpion v3'),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            activeColor: Colors.amber,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.security, size: 70, color: Color(0xFF00B4D8)),
            ),
            const SizedBox(height: 15),
            Text(
              'مرحباً بك يا تامر في النسخة v3',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'اللغات المتاحة للترجمة (الأوفلاين):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: langService.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final lang = langService.supportedLanguages[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(lang.name),
                      subtitle: Text('كود اللغة: ${lang.code}'),
                      trailing: IconButton(
                        icon: Icon(
                          lang.isDownloaded ? Icons.check_circle : Icons.download,
                          color: lang.isDownloaded ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => langService.toggleLanguageDownload(lang.code),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOMAIN
ok "تم تحديث main.dart بالكامل"

# 5. الرفع إلى GitHub
log "جاري رفع التحديث الشامل..."
git add .
git commit -m "feat(v3): master baseline with Theme & Language services" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تم كل شيء في خطوة واحدة بنجاح يا تامر! 🦂✨"

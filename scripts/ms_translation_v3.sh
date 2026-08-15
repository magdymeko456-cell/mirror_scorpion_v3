#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - TRANSLATION FEATURE ACTIVATION (ALL-IN-ONE)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[TRANSLATION]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء تفعيل كرت الترجمة النصية وربطه بالنظام..."

# 1. إنشاء المجلدات
mkdir -p "$WORKDIR/lib/core/services"
mkdir -p "$WORKDIR/lib/features/translation"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 2. تحديث pubspec.yaml لإضافة حزمة http
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

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOPUB
ok "تم تحديث pubspec.yaml بـ http"

# 3. إنشاء خدمة الترجمة (TranslationService)
cat << 'EOT' > lib/core/services/translation_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslationService extends ChangeNotifier {
  Future<String> translate(String text, {String from = 'auto', String to = 'ar'}) async {
    if (text.trim().isEmpty) return '';
    try {
      final url = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data[0][0][0].toString();
      }
      return 'خطأ في الاتصال بالسيرفر';
    } catch (e) {
      return 'فشل الاتصال بالشباكة';
    }
  }
}
EOT
ok "تم إنشاء TranslationService"

# 4. إنشاء شاشة الترجمة (TranslationScreen)
cat << 'EOTS' > lib/features/translation/translation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _isLoading = false;
  String _targetLang = 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الترجمة النصية الفورية'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ترجمة إلى:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _targetLang,
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _targetLang = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'ادخل النص هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      final res = await context.read<TranslationService>().translate(
                            _controller.text,
                            to: _targetLang,
                          );
                      setState(() {
                        _result = res;
                        _isLoading = false;
                      });
                    },
              icon: const Icon(Icons.translate),
              label: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('ترجم الآن', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            if (_result.isNotEmpty)
              Card(
                color: Theme.of(context).cardColor,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'النتيجة:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4D8)),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
EOTS
ok "تم إنشاء TranslationScreen"

# 5. تحديث HomeScreen لربط كرت الترجمة بالشاشة الجديدة
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';
import '../translation/translation_screen.dart';

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
                    _buildFeatureCard(Icons.forum, 'حوار مترجم', 'محادثة ثنائية فورية', Colors.cyanAccent, () {}),
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
ok "تم ربط كرت الترجمة بـ HomeScreen"

# 6. تحديث main.dart لإدراج TranslationService
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';
import 'core/services/floating_bubble_service.dart';
import 'core/services/translation_service.dart';
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
ok "تم تحديث main.dart بـ TranslationService"

# 7. الرفع التلقائي لـ GitHub
log "جاري رفع كرت الترجمة والخدمات إلى GitHub..."
git add .
git commit -m "feat(translation): activate translation screen and service" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تم تفعيل كرت الترجمة والرفع بنجاح يا تامر! 🦂🚀"

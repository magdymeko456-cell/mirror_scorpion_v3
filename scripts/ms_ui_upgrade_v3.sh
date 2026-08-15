#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - UI UPGRADE & DASHBOARD RESTORATION (ALL-IN-ONE)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[UI-UPGRADE]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء ترقية الواجهة واستعادة لوحة التحكم الاحترافية..."

mkdir -p "$WORKDIR/lib/core/services"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 1. إنشاء خدمة الفقاعة العائمة (FloatingBubbleService)
cat << 'EOM' > lib/core/services/floating_bubble_service.dart
import 'package:flutter/material.dart';

class FloatingBubbleService extends ChangeNotifier {
  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  void toggleBubble(bool value) {
    _isEnabled = value;
    notifyListeners();
  }
}
EOM
ok "تم إنشاء FloatingBubbleService"

# 2. إنشاء شاشة HomeScreen الاحترافية (6 كروت + تصميم ملكي)
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';

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
              // --- Header Section ---
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

              // --- Grid Section (6 Cards) ---
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
                    _buildFeatureCard(Icons.translate, 'ترجمة نصية', 'لغة + مايك 100', Colors.blueAccent, () {}),
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
ok "تم إنشاء HomeScreen الاحترافية"

# 3. تحديث main.dart
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';
import 'core/services/floating_bubble_service.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => FloatingBubbleService()),
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
ok "تم تحديث main.dart"

# 4. الرفع المباشر إلى GitHub
log "جاري رفع ترقية الواجهة لـ GitHub..."
git add .
git commit -m "feat(ui): restore professional dashboard & floating bubble switch" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تمت ترقية الواجهة والرفع بنجاح يا تامر! 🦂✨"

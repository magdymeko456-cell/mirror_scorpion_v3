#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - FINAL SETTINGS & PRO ACTIVATION
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[SETTINGS]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء تفعيل كرت الإعدادات والنسخة برو..."

mkdir -p "$WORKDIR/lib/features/settings"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 1. إنشاء شاشة الإعدادات والبرو (SettingsScreen)
cat << 'EOS' > lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والترقية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.amber),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 50),
                  SizedBox(height: 10),
                  Text('Mirror Scorpion Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('تمتع بكافة المميزات الصوتية ومحركات الترجمة بدون حدود', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('الوضع المظلم'),
            trailing: Switch(
              value: theme.isDarkMode,
              onChanged: (v) => theme.toggleTheme(v),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('الإصدار'),
            subtitle: Text('v3.0.0 (النسخة الذهبية)'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('المطور'),
            subtitle: Text('tetocollctionway'),
          ),
        ],
      ),
    );
  }
}
EOS
ok "تم إنشاء SettingsScreen بنجاح"

# 2. إعادة كتابة HomeScreen بالكامل لربط كرت الإعدادات وإكتمال الواجهة
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';
import '../translation/translation_screen.dart';
import '../dialogue/dialogue_screen.dart';
import '../documents/document_screen.dart';
import '../stories/stories_screen.dart';
import '../games/games_screen.dart';
import '../settings/settings_screen.dart';

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
                    _buildFeatureCard(
                      Icons.document_scanner, 
                      'مستندات وعدسة', 
                      'ترجمة صور وملفات', 
                      Colors.tealAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentScreen()))
                    ),
                    _buildFeatureCard(
                      Icons.auto_stories, 
                      'قصص وإلهام', 
                      'مكتبة ذكية متكاملة', 
                      Colors.orangeAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoriesScreen()))
                    ),
                    _buildFeatureCard(
                      Icons.sports_esports, 
                      'ألعاب 3D', 
                      'شطرنج + روبيك', 
                      Colors.purpleAccent, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()))
                    ),
                    _buildFeatureCard(
                      Icons.settings, 
                      'الإعدادات', 
                      'تخصيص وترقية برو', 
                      Colors.blueGrey, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                    ),
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
ok "تم ربط كرت الإعدادات بالكامل في الشاشة الرئيسية"

# 3. الرفع النهائي إلى GitHub
log "جاري الرفع النهائي للوحدة المكتملة إلى GitHub..."
git add .
git commit -m "feat(settings): complete dashboard and activate settings screen" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تهانينا يا تامر! اكتمل بناء مشروع Mirror Scorpion v3 بنجاح تام! 🦂🏆✨"

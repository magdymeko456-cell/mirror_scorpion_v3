#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - STORIES & INSPIRATION ACTIVATION (ALL-IN-ONE)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[STORIES]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء تفعيل كرت القصص والإلهام..."

mkdir -p "$WORKDIR/lib/core/services"
mkdir -p "$WORKDIR/lib/features/stories"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 1. إنشاء خدمة القصص (StoriesService)
cat << 'EOT' > lib/core/services/stories_service.dart
import 'package:flutter/material.dart';

class StoryItem {
  final String title;
  final String content;
  final String category;
  StoryItem({required this.title, required this.content, required this.category});
}

class StoriesService extends ChangeNotifier {
  final List<StoryItem> _items = [
    StoryItem(category: 'قصص', title: 'الإصرار والنجاح', content: 'النجاح ليس نهاية، والفشل ليس قاتلاً؛ إنما الشجاعة للاستمرار هي ما يهم.'),
    StoryItem(category: 'أحاديث', title: 'فضل العلم', content: 'عن النبي ﷺ قال: "من سلك طريقاً يلتمس فيه علماً سهل الله له به طريقاً إلى الجنة".'),
    StoryItem(category: 'إلهام', title: 'حكمة اليوم', content: 'المستقبل ينتمي لأولئك الذين يؤمنون بجمال أحلامهم.'),
  ];
  List<StoryItem> getItemsByCategory(String cat) => _items.where((i) => i.category == cat).toList();
}
EOT
ok "تم إنشاء StoriesService"

# 2. إنشاء شاشة القصص (StoriesScreen)
cat << 'EOT' > lib/features/stories/stories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/stories_service.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<StoriesService>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قصص وإلهام'),
          bottom: const TabBar(tabs: [Tab(text: 'قصص'), Tab(text: 'أحاديث'), Tab(text: 'إلهام')]),
        ),
        body: TabBarView(children: [
          _buildList(service, 'قصص'),
          _buildList(service, 'أحاديث'),
          _buildList(service, 'إلهام'),
        ]),
      ),
    );
  }
  Widget _buildList(StoriesService service, String cat) {
    final items = service.getItemsByCategory(cat);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (c, i) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          title: Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: [Padding(padding: const EdgeInsets.all(16), child: Text(items[i].content))],
        ),
      ),
    );
  }
}
EOT
ok "تم إنشاء StoriesScreen"

# 3. تحديث HomeScreen لربط كرت القصص والإلهام
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';
import '../translation/translation_screen.dart';
import '../dialogue/dialogue_screen.dart';
import '../documents/document_screen.dart';
import '../stories/stories_screen.dart';

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
ok "تم ربط كرت القصص بـ HomeScreen"

# 4. تحديث main.dart لتسجيل StoriesService
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';
import 'core/services/floating_bubble_service.dart';
import 'core/services/translation_service.dart';
import 'core/services/tts_service.dart';
import 'core/services/stories_service.dart';
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
        ChangeNotifierProvider(create: (_) => StoriesService()),
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
ok "تم تحديث main.dart بـ StoriesService"

# 5. الرفع إلى GitHub
log "جاري رفع كرت القصص والإلهام إلى GitHub..."
git add .
git commit -m "feat(stories): activate stories and inspiration feature" || echo "لا تغييرات"
git push origin main || echo "فشل الرفع"

ok "تم تفعيل كرت القصص والإلهام بنجاح يا تامر! 🦂📚✨"

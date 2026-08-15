#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - VISION & OCR ACTIVATION (ALL-IN-ONE)
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[VISION]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
log "بدء تفعيل كرت المستندات والعدسة (OCR)..."

mkdir -p "$WORKDIR/lib/features/documents"
mkdir -p "$WORKDIR/lib/features/home"
cd "$WORKDIR"

# 1. تحديث pubspec.yaml لإضافة حزم الرؤية والملفات
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
  image_picker: ^1.1.2
  google_mlkit_text_recognition: ^0.13.0
  file_picker: ^8.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
EOPUB
ok "تم تحديث pubspec.yaml بحزم الرؤية والملفات"

# 2. إنشاء شاشة المستندات والعدسة (DocumentScreen) مع تصحيح appBar
cat << 'EODOC' > lib/features/documents/document_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../../core/services/translation_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});
  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String _extractedText = "";
  String _translatedText = "";
  bool _isProcessing = false;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _processImage(image.path);
    }
  }

  Future<void> _processImage(String path) async {
    setState(() => _isProcessing = true);
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    setState(() {
      _extractedText = recognizedText.text;
      _isProcessing = false;
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      setState(() => _extractedText = content);
    }
  }

  void _translateText() async {
    if (_extractedText.isEmpty) return;
    setState(() => _isProcessing = true);
    final trans = context.read<TranslationService>();
    final result = await trans.translate(_extractedText, to: 'ar');
    setState(() {
      _translatedText = result;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستندات والعدسة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('كاميرا')),
                ElevatedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.file_present), label: const Text('ملف نصي')),
              ],
            ),
            const SizedBox(height: 20),
            if (_isProcessing) const CircularProgressIndicator(),
            if (_extractedText.isNotEmpty) ...[
              const Text("النص المستخرج:", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black12,
                child: Text(_extractedText),
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _translateText, child: const Text("ترجمة النص")),
            ],
            if (_translatedText.isNotEmpty) ...[
              const Divider(),
              const Text("الترجمة:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              Text(_translatedText),
            ]
          ],
        ),
      ),
    );
  }
}
EODOC
ok "تم إنشاء DocumentScreen بنجاح"

# 3. إعادة كتابة HomeScreen بالكامل لربط كرت المستندات ونظافة الكود
cat << 'EOH' > lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/floating_bubble_service.dart';
import '../translation/translation_screen.dart';
import '../dialogue/dialogue_screen.dart';
import '../documents/document_screen.dart';

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
ok "تم ربط كرت المستندات في الشاشة الرئيسية بنجاح"

# 4. الرفع إلى GitHub
log "جاري رفع التحديثات إلى GitHub..."
git add .
git commit -m "feat(v3): activate Document & Lens (OCR) feature" || echo "لا تغييرات"
git push origin main

ok "تم تفعيل كرت العدسة والمستندات بنجاح يا تامر! 🦂👁️📄"

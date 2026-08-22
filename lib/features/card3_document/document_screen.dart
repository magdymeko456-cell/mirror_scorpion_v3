import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'document_lens.dart';
import '../../services/ai_service.dart';
import '../../services/language_service.dart';
import '../../services/premium_verification_service.dart';

class DocumentTranslationScreen extends StatefulWidget {
  const DocumentTranslationScreen({super.key});

  @override
  State<DocumentTranslationScreen> createState() =>
      _DocumentTranslationScreenState();
}

class _DocumentTranslationScreenState extends State<DocumentTranslationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String _extractedText = '';
  String _translatedText = '';
  String _selectedLanguage = 'ar';
  bool _isProcessing = false;
  bool _showOriginal = false;
  int _pageCount = 0;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> _languages = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'ja': 'Japanese',
    'zh': '中文',
    'ko': '한국어',
    'tr': 'Türkçe',
  };

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _loadLastLanguage();
  }

  Future _loadLastLanguage() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final lastLang = await langService.getLanguageForScreen('document');
    if (lastLang.isNotEmpty && _languages.containsKey(lastLang)) {
      setState(() => _selectedLanguage = lastLang);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isProcessing = true;
          _urlController.text = image.path;
        });
        _extractTextFromImage();
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _extractTextFromImage() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.arabic);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String text = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          text += '${line.text}\n';
        }
      }

      setState(() {
        _extractedText = text.isNotEmpty ? text : 'لم يتم التعرف على نصوص في الصورة';
        _isProcessing = false;
      });

      await textRecognizer.close();
    } catch (e) {
      debugPrint('Text recognition error: $e');
      setState(() {
        _extractedText = 'خطأ في التعرف على النص: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _translateDocument() async {
    if (_extractedText.trim().isEmpty) return;

    final isPremium = Provider.of<PremiumVerificationService>(context, listen: false).isPremium;
    if (!isPremium && _pageCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 الترجمة محدودة بـ 5 صفحات في النسخة المجانية. ترقية إلى Pro!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // تقسيم النص إلى صفحات تقريبية
      final pages = _extractedText.split('\n\n');
      _pageCount += pages.length;

      final response = await http.get(
        Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(_extractedText.substring(0, _extractedText.length.clamp(0, 5000)))}&langpair=ar|$_selectedLanguage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _translatedText = data['responseData']['translatedText'] ?? _extractedText;
          _isProcessing = false;
        });
        _slideController.forward(from: 0.0);
      } else {
        setState(() {
          _translatedText = _extractedText; // fallback
          _isProcessing = false;
        });
        _slideController.forward(from: 0.0);
      }
    } catch (e) {
      setState(() {
        _translatedText = _extractedText;
        _isProcessing = false;
      });
      _slideController.forward(from: 0.0);
    }
  }

  void _shareTranslatedDocument() {
    if (_translatedText.isEmpty) return;
    final isPremium = Provider.of<PremiumVerificationService>(context, listen: false).isPremium;

    String shareText = _translatedText;
    if (!isPremium) {
      shareText += '\n\nترجم هذا المستند بواسطة ميرور سكربيون';
    }

    SharePlus.instance.share(ShareParams(text: shareText));
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<PremiumVerificationService>(context).isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text('مستندات وعدسة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D1B2A),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // زر العدسة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DocumentLensScreen()),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text('الدخول إلى العدسة (Google Lens)',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // حقل الرابط
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'رابط الملف أو مساره...',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () async {
                          if (_urlController.text.isNotEmpty) {
                            // محاولة تحميل من رابط
                            final url = _urlController.text.trim();
                            if (url.startsWith('http')) {
                              try {
                                final response = await http.get(Uri.parse(url));
                                setState(() {
                                  _extractedText = response.body;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('📄 تم جلب المحتوى من الرابط')),
                                );
                              } catch (e) {
                                setState(() {
                                  _extractedText = url;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('⚠️ تم استخدام الرابط كنص')),
                                );
                              }
                            } else {
                              setState(() {
                                _extractedText = url;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // زر فتح من المستعرض
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('فتح من المستعرض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                // عرض النص المستخرج إن وجد
                if (_extractedText.isNotEmpty && _translatedText.isEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📄 النص المستخرج (${_extractedText.length} حرف)',
                          style: const TextStyle(
                              color: Colors.cyanAccent, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _extractedText.length > 200
                              ? '${_extractedText.substring(0, 200)}...'
                              : _extractedText,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // اختيار اللغة
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: const Color(0xFF1B2838),
                        icon:
                            const Icon(Icons.language, color: Colors.amber),
                        items: _languages.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value,
                                      style:
                                          const TextStyle(color: Colors.white, fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedLanguage = v);
                          Provider.of<LanguageService>(context, listen: false)
                              .saveLanguageForScreen('document', v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // زر الترجمة
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: (_isProcessing ||
                            (_extractedText.isEmpty &&
                                _urlController.text.isEmpty))
                        ? null
                        : _translateDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('ترجمة',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),

                if (_extractedText.isNotEmpty && _translatedText.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'تم استخراج النص. اضغط ترجمة للمتابعة',
                      style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.7), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!isPremium)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'ترجمة محدودة لـ 5 صفحات. اشترك Pro للمزيد',
                      style: TextStyle(
                          color: Colors.orangeAccent.withOpacity(0.7), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          // شاشة الترجمة النهائية
          if (_translatedText.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onLongPressStart: (_) => setState(() => _showOriginal = true),
                onLongPressEnd: (_) => setState(() => _showOriginal = false),
                child: Container(
                  color: const Color(0xFF0D1B2A),
                  padding: const EdgeInsets.all(10),
                  child: Stack(
                    children: [
                      _buildDocumentPaper(
                          _extractedText, Colors.white.withOpacity(0.1), Colors.white70),
                      if (!_showOriginal)
                        SlideTransition(
                          position: _slideAnimation,
                          child: _buildDocumentPaper(
                            _translatedText,
                            Colors.white,
                            Colors.black87,
                            hasWatermark: !isPremium,
                          ),
                        ),
                      Positioned(
                        top: 40,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () {
                            setState(() {
                              _translatedText = '';
                              _slideController.reset();
                            });
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: FloatingActionButton(
                          heroTag: 'share_doc_btn',
                          backgroundColor: Colors.blueAccent,
                          child: const Icon(Icons.share, color: Colors.white),
                          onPressed: _shareTranslatedDocument,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // مؤشر التحميل
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 20),
                    Text('جاري المعالجة والترجمة...',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentPaper(
      String text, Color bgColor, Color textColor,
      {bool hasWatermark = false}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
      ),
      child: Stack(
        children: [
          if (hasWatermark)
            Center(
              child: Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: -130 * 3.14 / 180,
                  child: const Text(
                    'ترجم هذا المستند بواسطة ميرور سكربيون',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          SingleChildScrollView(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16, height: 1.5),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

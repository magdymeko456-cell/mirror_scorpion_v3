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
    FilePickerResult? result = await FilePicker.instance.pickFiles(
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

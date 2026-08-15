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

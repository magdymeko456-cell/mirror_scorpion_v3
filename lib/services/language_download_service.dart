import 'dart:io';  
import 'package:flutter/material.dart';  
import 'package:shared_preferences/shared_preferences.dart';  
import 'package:path_provider/path_provider.dart';  
import 'premium_verification_service.dart';  
  
/// خدمة تنزيل اللغات أوفلاين للنسخة البرو  
class LanguageDownloadService extends ChangeNotifier {  
  static final LanguageDownloadService _instance = LanguageDownloadService._internal();  
    
  factory LanguageDownloadService() => _instance;  
  LanguageDownloadService._internal();  
    
  late SharedPreferences _prefs;  
  final PremiumVerificationService _premiumService = PremiumVerificationService();  
    
  Map<String, bool> _downloadedLanguages = {};  
  bool _isInitialized = false;  
    
  // اللغات المتاحة للتنزيل  
  static const Map<String, String> availableLanguages = {  
    'ar': 'العربية',  
    'en': 'English',  
    'fr': 'Français',  
    'de': 'Deutsch',  
    'es': 'Español',  
    'it': 'Italiano',  
    'pt': 'Português',  
    'ru': 'Русский',  
    'zh': '中文',  
    'ja': '日本語',  
    'ko': '한국어',  
    'hi': 'हिन्दी',  
    'tr': 'Türkçe',  
    'fa': 'فارسی',  
    'ur': 'اردو',  
  };  
    
  Future<void> initialize() async {  
    if (_isInitialized) return;  
      
    _prefs = await SharedPreferences.getInstance();  
    await _loadDownloadedLanguages();  
    _isInitialized = true;  
    notifyListeners();  
  }  
    
  Future<void> _loadDownloadedLanguages() async {  
    final saved = _prefs.getString('downloaded_languages') ?? '{}';  
    try {  
      _downloadedLanguages = Map<String, bool>.from(  
        Map<String, dynamic>.from(  
          _parseJson(saved)  
        )  
      );  
    } catch (e) {  
      _downloadedLanguages = {};  
    }  
  }  
    
  Map<String, dynamic> _parseJson(String jsonString) {  
    // Simple JSON parser for basic objects  
    final result = <String, dynamic>{};  
    jsonString = jsonString.trim();  
    if (jsonString.startsWith('{') && jsonString.endsWith('}')) {  
      final content = jsonString.substring(1, jsonString.length - 1);  
      final pairs = content.split(',');  
      for (final pair in pairs) {  
        final parts = pair.split(':');  
        if (parts.length == 2) {  
          final key = parts[0].trim().replaceAll('"', '').replaceAll("'", '');  
          final value = parts[1].trim().replaceAll('"', '').replaceAll("'", '');  
          result[key] = value == 'true';  
        }  
      }  
    }  
    return result;  
  }  
    
  // التحقق من أن المستخدم لديه نسخة برو  
  Future<bool> isPremiumUser() async {  
    return _premiumService.isPremium;  
  }  
    
  // تنزيل لغة (للنسخة البرو فقط)  
  Future<bool> downloadLanguage(String languageCode) async {  
    final isPremium = await isPremiumUser();  
    if (!isPremium) {  
      return false; // غير مسموح للنسخة العادية  
    }  
      
    try {  
      // محاكاة تنزيل اللغة - في الواقع سيتم تنزيل ملفات الترجمة  
      await Future.delayed(const Duration(seconds: 2));  
        
      _downloadedLanguages[languageCode] = true;  
      await _saveDownloadedLanguages();  
      notifyListeners();  
      return true;  
    } catch (e) {  
      return false;  
    }  
  }  
    
  // حذف لغة  
  Future<bool> deleteLanguage(String languageCode) async {  
    try {  
      _downloadedLanguages.remove(languageCode);  
      await _saveDownloadedLanguages();  
      notifyListeners();  
      return true;  
    } catch (e) {  
      return false;  
    }  
  }  
    
  Future<void> _saveDownloadedLanguages() async {  
    final jsonString = _downloadedLanguages.toString();  
    await _prefs.setString('downloaded_languages', jsonString);  
  }  
    
  // التحقق من أن اللغة متاحة أوفلاين  
  bool isLanguageDownloaded(String languageCode) {  
    return _downloadedLanguages[languageCode] ?? false;  
  }  
    
  // الحصول على قائمة اللغات المتاحة  
  Map<String, String> getAvailableLanguages() {  
    return availableLanguages;  
  }  
    
  // الحصول على اللغات المحملة  
  Map<String, bool> get downloadedLanguages => _downloadedLanguages;  
    
  // الحصول على عدد اللغات المحملة  
  int get downloadedCount => _downloadedLanguages.length;  
}  

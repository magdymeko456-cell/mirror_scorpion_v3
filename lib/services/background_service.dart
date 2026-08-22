import 'dart:io';  
import 'package:flutter/material.dart';  
import 'package:shared_preferences/shared_preferences.dart';  
import 'package:image_picker/image_picker.dart';  
import 'package:path_provider/path_provider.dart';  
  
/// خدمة إدارة الخلفية المخصصة للكروت  
class BackgroundService extends ChangeNotifier {  
  static final BackgroundService _instance = BackgroundService._internal();  
    
  factory BackgroundService() => _instance;  
  BackgroundService._internal();  
    
  late SharedPreferences _prefs;  
  String? _customBackgroundPath;  
  bool _isInitialized = false;  
    
  Future<void> initialize() async {  
    if (_isInitialized) return;  
      
    _prefs = await SharedPreferences.getInstance();  
    _customBackgroundPath = _prefs.getString('custom_background_path');  
    _isInitialized = true;  
    notifyListeners();  
  }  
    
  // اختيار صورة من المعرض  
  Future<bool> pickBackground() async {  
    try {  
      final picker = ImagePicker();  
      final XFile? image = await picker.pickImage(  
        source: ImageSource.gallery,  
        maxWidth: 1920,  
        maxHeight: 1080,  
        imageQuality: 85,  
      );  
        
      if (image == null) return false;  
        
      // حفظ الصورة في مجلد التطبيق  
      final directory = await getApplicationDocumentsDirectory();  
      final fileName = 'custom_background_${DateTime.now().millisecondsSinceEpoch}.jpg';  
      final savedImage = await File(image.path).copy('${directory.path}/$fileName');  
        
      _customBackgroundPath = savedImage.path;  
      await _prefs.setString('custom_background_path', _customBackgroundPath!);  
      notifyListeners();  
      return true;  
    } catch (e) {  
      return false;  
    }  
  }  
    
  // إزالة الخلفية المخصصة  
  Future<bool> removeBackground() async {  
    try {  
      if (_customBackgroundPath != null) {  
        final file = File(_customBackgroundPath!);  
        if (await file.exists()) {  
          await file.delete();  
        }  
      }  
        
      _customBackgroundPath = null;  
      await _prefs.remove('custom_background_path');  
      notifyListeners();  
      return true;  
    } catch (e) {  
      return false;  
    }  
  }  
    
  // الحصول على مسار الخلفية المخصصة  
  String? get customBackgroundPath => _customBackgroundPath;  
    
  // التحقق من وجود خلفية مخصصة  
  bool get hasCustomBackground => _customBackgroundPath != null;  
}  

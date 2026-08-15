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

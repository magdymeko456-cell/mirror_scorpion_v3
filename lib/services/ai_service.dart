import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الذكاء الاصطناعي المتقدمة - ميرور سكربيون
/// تدعم Gemini API و OpenAI API
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // API Keys - يتم تحميلها من SharedPreferences أو استخدام القيم الافتراضية
  String _geminiApiKey = '';
  String _openaiApiKey = '';
  bool _useGemini = true;

  final Random _random = Random();

  // سجل المحادثة للإلهام
  final Map<String, List<Map<String, String>>> _userSessions = {};

  // قائمة الرسائل الملهمة الأساسية - backup عند فشل API
  static const List<String> _fallbackMessages = [
    "لا تيأس، فالله معك. كل انكسار هو بداية انطلاقة أعظم.",
    "الوقت هو العملة الأغلى، استثمر كل ثانية في بناء نفسك.",
    "الماضي ليس للمحو بل للتعلم، والمستقبل هو ما يستحق انتباهك الآن.",
    "قوتك الحقيقية تكمن في قدرتك على النهوض بعد كل سقوط.",
    "لا تقارن نفسك بالآخرين، فلك طريقك الخاص الذي يميزك.",
    "الصبر مفتاح الفرج، وكل ضيق يأتي بعده فرج عظيم.",
    "أنت أقوى مما تتصور، وأعظم مما تتخيل.",
    "اليوم هو فرصة جديدة لبداية جديدة.",
  ];

  /// تهيئة الخدمة وتحميل المفاتيح المخزنة
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString('gemini_api_key') ?? '';
    _openaiApiKey = prefs.getString('openai_api_key') ?? '';
    _useGemini = prefs.getBool('use_gemini') ?? true;
  }

  /// حفظ مفتاح Gemini API
  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }

  /// حفظ مفتاح OpenAI API
  Future<void> setOpenaiApiKey(String key) async {
    _openaiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', key);
  }

  /// تغيير مزود الذكاء الاصطناعي
  Future<void> setProvider(bool useGemini) async {
    _useGemini = useGemini;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_gemini', useGemini);
  }

  /// إنشاء رسالة ملهمة بناءً على حالة المستخدم
  Future<String> generateInspiration({
    required String userMood,
    required String context,
    String? userId,
  }) async {
    // محاولة استخدام API أولاً
    if (_geminiApiKey.isNotEmpty || _openaiApiKey.isNotEmpty) {
      try {
        final prompt = _buildInspirationPrompt(userMood, context);
        final result = await _callAI(prompt);
        if (result.isNotEmpty) return result;
      } catch (e) {
        print('AI API error: $e');
      }
    }

    // API غير متاح أو فشل → استخدم المنطق المحلي المتقدم
    return _generateLocalInspiration(userMood, userId);
  }

  /// بناء prompt مخصص للإلهام
  String _buildInspirationPrompt(String userMood, String context) {
    return '''
أنت مستشار روحي ونفسي في تطبيق "ميرور سكربيون". مهمتك تقديم كلمات ملهمة ومؤثرة.

حالة المستخدم: "${userMood.isNotEmpty ? userMood : 'يبحث عن الإلهام'}"
السياق: $context

تعليمات:
1. اجعل الرسالة قصيرة ومؤثرة (جملتين إلى 4 جمل كحد أقصى)
2. استخدم لغة عربية فصيحة ولكن سهلة
3. إذا كان المستخدم حزيناً، قدم تعزية وأمل
4. إذا كان المستخدم فرحاناً، ذكّره بالتواضع والشكر
5. إذا كان يقرأ قصة، اربط الرسالة بعبرة من القصة
6. يمكنك الاستشهاد بآية قرآنية أو حديث مناسب إذا كان السياق يسمح
7. لا تقدم وعوداً كاذبة، كن واقعياً وملهماً
8. اختِم الرسالة بتوقيع: ✨ مانوس
''';
  }

  /// استدعاء API الذكاء الاصطناعي
  Future<String> _callAI(String prompt) async {
    if (_useGemini && _geminiApiKey.isNotEmpty) {
      return _callGeminiApi(prompt);
    } else if (_openaiApiKey.isNotEmpty) {
      return _callOpenaiApi(prompt);
    }
    return '';
  }

  /// استدعاء Gemini API
  Future<String> _callGeminiApi(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        return text.toString().trim();
      }
    } catch (e) {
      print('Gemini API error: $e');
    }
    return '';
  }

  /// استدعاء OpenAI API
  Future<String> _callOpenaiApi(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'أنت مساعد روحي ملهم في تطبيق ميرور سكربيون.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? '';
        return text.toString().trim();
      }
    } catch (e) {
      print('OpenAI API error: $e');
    }
    return '';
  }

  /// توليد رسالة محلية متقدمة بناءً على حالة المستخدم
  String _generateLocalInspiration(String userMood, String? userId) {
    if (userMood.isEmpty) {
      return _fallbackMessages[_random.nextInt(_fallbackMessages.length)];
    }

    // تحليل الحالة
    if (_containsAny(userMood, ['حزين', 'تعبان', 'ضيق', 'تعب', 'حزينة', 'متعب', 'مكتئب', 'انهيار'])) {
      return 'أعلم أن الأوقات صعبة، ولكن تذكر أن الله لا يكلف نفساً إلا وسعها. '
             'أنت قادر على تخطي هذه المحنة، وستخرج منها أقوى مما كنت. '
             '﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾ ✨ مانوس';
    }

    if (_containsAny(userMood, ['فرح', 'سعيد', 'نجاح', 'فرحة', 'سعيدة', 'إنجاز', 'نجحت'])) {
      return 'الحمد لله على نعمة الفرح والنجاح. تذكر أن تبقى متواضعاً، '
             'وأن تشكر الله على ما أعطاك. الفرح الحقيقي في مشاركته مع الآخرين. '
             '﴿وَأَمَّا بِنِعْمَةِ رَبِّكَ فَحَدِّثْ﴾ ✨ مانوس';
    }

    if (_containsAny(userMood, ['خائف', 'قلق', 'توتر', 'خايف', 'قلقة', 'خوف'])) {
      return 'لا تخف، فالله معك. التوتر الطبيعي دليل على اهتمامك، '
             'لكن لا تدعه يسيطر عليك. كل أمر بقضاء الله وقدره. '
             '﴿وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾ ✨ مانوس';
    }

    if (_containsAny(userMood, ['وحيد', 'وحيدة', 'وحدة', 'عزلة', 'لوحدي'])) {
      return 'لست وحدك أبداً. الله معك، ونحن هنا في ميرور سكربيون. '
             'الوحدة فرصة للتعرف على نفسك بعمق أكبر. '
             'استغل هذا الوقت في بناء ذاتك. ✨ مانوس';
    }

    return _fallbackMessages[_random.nextInt(_fallbackMessages.length)];
  }

  /// التحقق من وجود كلمة في النص
  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// توليد رسالة مخصصة لمستخدم معين (مع الذاكرة)
  Future<String> generatePersonalizedMessage(String userId) async {
    // استرجاع جلسة المستخدم
    final session = _userSessions.putIfAbsent(userId, () => []);

    // إذا كان للمستخدم تاريخ، استخدمه للتخصيص
    if (session.isNotEmpty) {
      final lastMood = session.last['mood'] ?? '';
      return generateInspiration(
        userMood: lastMood,
        context: 'رسالة مخصصة لمستخدم متابع',
        userId: userId,
      );
    }

    // مستخدم جديد → رسالة ترحيبية
    return 'مرحباً بك في ميرور سكربيون! 🌟\n\n'
           'هنا حيث تُصنع البدايات. كل يوم هو فرصة جديدة '
           'لتبدأ رحلة التعلم والنمو.\n\n'
           'تذكر: قصتك لا تزال تُكتب. ✨ مانوس';
  }

  /// تسجيل حالة المستخدم في الجلسة
  Future<void> logUserMood(String userId, String mood, String context) async {
    final session = _userSessions.putIfAbsent(userId, () => []);
    session.add({
      'mood': mood,
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // الاحتفاظ بآخر 10 تفاعلات فقط
    if (session.length > 10) {
      session.removeAt(0);
    }
  }

  /// توليد مقدمة قصة
  Future<String> generateStoryIntro(String storyTitle) async {
    // محاولة API
    if (_geminiApiKey.isNotEmpty || _openaiApiKey.isNotEmpty) {
      try {
        final prompt = 'اكتب مقدمة مشوقة من 3 جمل لقصة "$storyTitle" '
                       'تكون مناسبة لتحويلها إلى فيديو قصير ملهم.';
        final result = await _callAI(prompt);
        if (result.isNotEmpty) return result;
      } catch (e) {}
    }

    return 'قصة $storyTitle: رحلة مليئة بالعبر والدروس المستفادة. '
           'تأمل في هذه القصة واستلهم منها معاني الصبر والإيمان.';
  }

  /// ترجمة نص باستخدام AI
  Future<String> translateText(String text, String targetLang) async {
    if (_geminiApiKey.isNotEmpty || _openaiApiKey.isNotEmpty) {
      try {
        final prompt = 'ترجم النص التالي إلى اللغة $targetLang:\n\n$text';
        final result = await _callAI(prompt);
        if (result.isNotEmpty) return result;
      } catch (e) {}
    }

    // Fallback: استخدم Google Translate (موجود في screens)
    return text; // سيتم التعامل معه في الـ screens
  }

  /// تحليل النص لاستخراج المشاعر
  Future<Map<String, double>> analyzeSentiment(String text) async {
    // تحليل أساسي للمشاعر
    double positive = 0.0;
    double negative = 0.0;
    double spiritual = 0.0;

    final words = text.split(' ');

    for (final word in words) {
      if (_containsAny(word, ['فرح', 'سعد', 'حب', 'خير', 'نور', 'أمل'])) {
        positive += 0.2;
      }
      if (_containsAny(word, ['حزن', 'خوف', 'ضيق', 'تعب', 'ألم', 'ظلم'])) {
        negative += 0.2;
      }
      if (_containsAny(word, ['الله', 'رب', 'إيمان', 'دعاء', 'صلاة', 'قرآن', 'ذكر'])) {
        spiritual += 0.3;
      }
    }

    return {
      'positive': positive.clamp(0.0, 1.0),
      'negative': negative.clamp(0.0, 1.0),
      'spiritual': spiritual.clamp(0.0, 1.0),
    };
  }
}

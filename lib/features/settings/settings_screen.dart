import 'package:flutter/material.dart';  
import 'package:shared_preferences/shared_preferences.dart';  
import 'package:provider/provider.dart';  
import 'package:image_picker/image_picker.dart';  
import '../../services/tts_service.dart';  
import '../../services/floating_bubble_service.dart';  
import '../../services/premium_verification_service.dart';  
import '../../services/background_service.dart';  
import '../../services/language_download_service.dart';  
import '../about/about_app_screen.dart';  
import '../../core/theme/theme_provider.dart';  
import 'package:flutter/services.dart';  
  
class SettingsScreen extends StatefulWidget {  
  const SettingsScreen({super.key});  
  
  @override  
  State<SettingsScreen> createState() => _SettingsScreenState();  
}  
  
class _SettingsScreenState extends State<SettingsScreen> {  
  late SharedPreferences _prefs;  
  bool _notificationsEnabled = true;  
  bool _soundEnabled = true;  
  bool _isPremium = false;  
  String _selectedVoice = 'voice_1_female';  
  bool _bubbleEnabled = false;  
  double _bubbleOpacity = 0.8;  
  int _bubbleSize = 120;  
  bool _bubbleAutoTranslate = true;  
  
  final List<Map<String, String>> _voices = [  
    {'id': 'voice_1_female', 'name': 'سلمى'},  
    {'id': 'voice_2_male', 'name': 'سيف'},  
    {'id': 'voice_3_female_warm', 'name': 'سما'},  
    {'id': 'voice_4_male_deep', 'name': 'ساره'},  
    {'id': 'voice_5_premium_ai', 'name': 'صوت المستخدم (نسخ)'},  
  ];  
  
  @override  
  void initState() {  
    super.initState();  
    _loadSettings();  
  }  
  
  Future<void> _loadSettings() async {  
    _prefs = await SharedPreferences.getInstance();  
    setState(() {  
      _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;  
      _soundEnabled = _prefs.getBool('soundEnabled') ?? true;  
      _isPremium = _prefs.getBool('isPremium') ?? false;  
      _selectedVoice = _prefs.getString('selectedVoice') ?? 'voice_1_female';  
      _bubbleEnabled = _prefs.getBool('bubble_enabled') ?? false;  
      _bubbleOpacity = _prefs.getDouble('bubble_opacity') ?? 0.8;  
      _bubbleSize = _prefs.getInt('bubble_size') ?? 120;  
      _bubbleAutoTranslate = _prefs.getBool('bubble_auto_translate') ?? true;  
    });  
  }  
  
  Future<void> _saveSetting(String key, dynamic value) async {  
    if (value is bool) {  
      await _prefs.setBool(key, value);  
    } else if (value is String) {  
      await _prefs.setString(key, value);  
    } else if (value is double) {  
      await _prefs.setDouble(key, value);  
    } else if (value is int) {  
      await _prefs.setInt(key, value);  
    }  
  }  
  
  @override  
  Widget build(BuildContext context) {  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),  
        backgroundColor: const Color(0xFF0D1B2A),  
        elevation: 0,  
        iconTheme: const IconThemeData(color: Colors.white),  
      ),  
      body: Container(  
        decoration: const BoxDecoration(  
          gradient: LinearGradient(  
            begin: Alignment.topCenter,  
            end: Alignment.bottomCenter,  
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)]  
          )  
        ),  
        child: ListView(  
          padding: const EdgeInsets.all(16),  
          children: [  
            // Display Settings  
            _buildSectionTitle('عرض التطبيق'),  
            _buildSettingTile(  
              'الوضع المظلم',  
              'استخدم الوضع المظلم لحماية العينين',  
              Provider.of<ThemeProvider>(context).isDarkMode,  
              (value) {  
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);  
              },  
            ),  
            const SizedBox(height: 20),  
  
            // Background Settings  
            _buildSectionTitle('🎨 تخصيص الواجهة'),  
            _buildBackgroundTile(),  
            const SizedBox(height: 20),  
  
            // Notification Settings  
            _buildSectionTitle('الإشعارات'),  
            _buildSettingTile(  
              'تفعيل الإشعارات',  
              'استقبل إشعارات يومية مع الرسائل الملهمة',  
              _notificationsEnabled,  
              (value) {  
                setState(() => _notificationsEnabled = value);  
                _saveSetting('notificationsEnabled', value);  
              },  
            ),  
            const SizedBox(height: 20),  
  
            // Voice Selection  
            _buildSectionTitle('اختيار الصوت (4 أصوات + نسخ الصوت)'),  
            Container(  
              padding: const EdgeInsets.symmetric(horizontal: 12),  
              decoration: BoxDecoration(  
                color: Colors.white.withOpacity(0.05),  
                borderRadius: BorderRadius.circular(12),  
                border: Border.all(color: Colors.white.withOpacity(0.1)),  
              ),  
              child: DropdownButtonHideUnderline(  
                child: DropdownButton<String>(  
                  value: _selectedVoice,  
                  isExpanded: true,  
                  dropdownColor: const Color(0xFF1B2838),  
                  icon: const Icon(Icons.record_voice_over, color: Colors.blue),  
                  style: const TextStyle(color: Colors.white, fontSize: 14),  
                  items: _voices.map((voice) {  
                    bool isPremiumVoice = voice['id'] == 'voice_5_premium_ai';  
                    return DropdownMenuItem(  
                      value: voice['id'],  
                      child: Row(  
                        children: [  
                          Text(voice['name']!),  
                          if (isPremiumVoice) ...[  
                            const SizedBox(width: 8),  
                            const Icon(Icons.star, color: Colors.amber, size: 14),  
                          ]  
                        ],  
                      ),  
                    );  
                  }).toList(),  
                  onChanged: (value) {  
                    if (value != null) {  
                      if (value == 'voice_5_premium_ai' && !_isPremium) {  
                        ScaffoldMessenger.of(context).showSnackBar(  
                          const SnackBar(content: Text('نسخ الصوت متاح فقط في النسخة البرو')),  
                        );  
                        return;  
                      }  
                      setState(() => _selectedVoice = value);  
                      _saveSetting('selectedVoice', value);  
                      Provider.of<TTSService>(context, listen: false).setVoice(value);  
                    }  
                  },  
                ),  
              ),  
            ),  
            const SizedBox(height: 20),  
  
            // Floating Bubble Settings  
            _buildSectionTitle('🫧 الفقاعة العائمة'),  
            _buildSettingTile(  
              'تفعيل الفقاعة العائمة',  
              'ترجمة فورية مع فقاعة عائمة فوق التطبيقات',  
              _bubbleEnabled,  
              (value) async {  
                setState(() => _bubbleEnabled = value);  
                _saveSetting('bubble_enabled', value);  
                await Provider.of<FloatingBubbleService>(context, listen: false).toggleBubble(context, value);  
              },  
            ),  
            if (_bubbleEnabled) ...[  
              const SizedBox(height: 12),  
              _buildSliderTile('الشفافية', _bubbleOpacity, 0.3, 1.0, (value) {  
                setState(() => _bubbleOpacity = value);  
                _saveSetting('bubble_opacity', value);  
                Provider.of<FloatingBubbleService>(context, listen: false).setOpacity(value);  
              }),  
            ],  
            const SizedBox(height: 20),  
  
            // Language Download Settings (Premium Only)  
            if (_isPremium) ...[  
              _buildSectionTitle('🌍 تنزيل اللغات أوفلاين (برو)'),  
              _buildLanguageDownloadTile(),  
              const SizedBox(height: 20),  
            ],  
  
            // Premium Section  
            if (!_isPremium)  
              _buildPremiumCard()  
            else  
              _buildPremiumActiveCard(),  
            const SizedBox(height: 20),  
  
            // About Section  
            _buildSectionTitle('عن التطبيق'),  
            _buildAboutTile(),
            const SizedBox(height: 20),  
  
            // Footer  
            Center(  
              child: Column(  
                children: [  
                  Text(  
                    'ميرور سكربيون',  
                    style: TextStyle(  
                      color: Colors.white.withOpacity(0.5),  
                      fontSize: 14,  
                      fontWeight: FontWeight.bold,  
                    ),  
                  ),  
                  const SizedBox(height: 4),  
                  Text(  
                    'v2.0 Stable Build',  
                    style: TextStyle(  
                      color: Colors.white.withOpacity(0.3),  
                      fontSize: 10,  
                    ),  
                  ),  
                ],  
              ),  
            ),  
          ],  
        ),  
      ),  
    );  
  }  
  
  Widget _buildSectionTitle(String title) {  
    return Padding(  
      padding: const EdgeInsets.only(bottom: 12),  
      child: Text(  
        title,  
        style: TextStyle(  
          color: Colors.amber.shade300,  
          fontSize: 16,  
          fontWeight: FontWeight.bold,  
        ),  
      ),  
    );  
  }  
  
  Widget _buildSettingTile(String title, String subtitle, bool value, Function(bool) onChanged) {  
    return Container(  
      padding: const EdgeInsets.all(12),  
      margin: const EdgeInsets.only(bottom: 8),  
      decoration: BoxDecoration(  
        color: value ? Colors.blue.withOpacity(0.1) : Colors.white.withOpacity(0.05),  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(color: value ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1)),  
      ),  
      child: Row(  
        mainAxisAlignment: MainAxisAlignment.spaceBetween,  
        children: [  
          Expanded(  
            child: Column(  
              crossAxisAlignment: CrossAxisAlignment.start,  
              children: [  
                Text(  
                  title,  
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),  
                ),  
                const SizedBox(height: 4),  
                Text(  
                  subtitle,  
                  style: const TextStyle(color: Colors.white70, fontSize: 12),  
                ),  
              ],  
            ),  
          ),  
          Switch(  
            value: value,  
            onChanged: onChanged,  
            activeColor: Colors.blueAccent,  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildSliderTile(String title, double value, double min, double max, Function(double) onChanged) {  
    return Container(  
      padding: const EdgeInsets.all(12),  
      decoration: BoxDecoration(  
        color: Colors.white.withOpacity(0.05),  
        borderRadius: BorderRadius.circular(12),  
      ),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),  
          Slider(  
            value: value,  
            min: min,  
            max: max,  
            onChanged: onChanged,  
            activeColor: Colors.blueAccent,  
          ),  
        ],  
      ),  
    );  
  }  
  
  Widget _buildBackgroundTile() {  
    return Container(  
      padding: const EdgeInsets.all(12),  
      decoration: BoxDecoration(  
        color: Colors.white.withOpacity(0.05),  
        borderRadius: BorderRadius.circular(12),  
      ),  
      child: Row(  
        mainAxisAlignment: MainAxisAlignment.spaceBetween,  
        children: [  
          const Text('تغيير خلفية الكروت', style: TextStyle(color: Colors.white)),  
          Row(  
            children: [  
              IconButton(  
                icon: const Icon(Icons.image, color: Colors.blueAccent),  
                onPressed: () async {
                  await Provider.of<BackgroundService>(context, listen: false).pickBackground();
                },  
              ),  
              IconButton(  
                icon: const Icon(Icons.restore, color: Colors.redAccent),  
                onPressed: () async {
                  await Provider.of<BackgroundService>(context, listen: false).removeBackground();
                },  
              ),  
            ],  
          ),  
        ],  
      ),  
    );  
  }  

  Widget _buildLanguageDownloadTile() {
    final languageService = Provider.of<LanguageDownloadService>(context);
    final downloadedLanguages = languageService.downloadedLanguages;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اللغات المُنزلة للعمل بدون إنترنت:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          if (downloadedLanguages.isEmpty)
            const Text('لا توجد لغات منزلة', style: TextStyle(color: Colors.white24, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              children: downloadedLanguages.keys.map((l) => Chip(label: Text(l), onDeleted: () => languageService.deleteLanguage(l))).toList(),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showLanguageDownloadDialog(),
            child: const Text('تنزيل لغة جديدة'),
          )
        ],
      ),
    );
  }

  void _showLanguageDownloadDialog() {
    final langs = ['العربية', 'English', 'Français', 'Español', 'Deutsch'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر لغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs.map((l) => ListTile(title: Text(l), onTap: () {
            Provider.of<LanguageDownloadService>(context, listen: false).downloadLanguage(l);
            Navigator.pop(ctx);
          })).toList(),
        ),
      ),
    );
  }

  Widget _buildAboutTile() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutAppScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('عن التطبيق والإهداء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumCard() {  
    final premiumService = Provider.of<PremiumVerificationService>(context);  
    final TextEditingController _codeController = TextEditingController();  
  
    return Container(  
      padding: const EdgeInsets.all(20),  
      decoration: BoxDecoration(  
        gradient: LinearGradient(  
          colors: [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.05)],  
          begin: Alignment.topLeft,  
          end: Alignment.bottomRight,  
        ),  
        borderRadius: BorderRadius.circular(20),  
        border: Border.all(color: Colors.amber.withOpacity(0.3)),  
      ),  
      child: Column(  
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [  
          const Row(  
            children: [  
              Icon(Icons.workspace_premium, color: Colors.amber, size: 28),  
              SizedBox(width: 12),  
              Text('تفعيل النسخة البرو (PRO)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),  
            ],  
          ),  
          const SizedBox(height: 20),  
            
          const Text('معرف الجهاز (ID):', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),  
          const SizedBox(height: 8),  
          Container(  
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),  
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),  
            child: Row(  
              children: [  
                Expanded(child: Text(premiumService.encryptedDeviceId, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'))),  
                IconButton(  
                  icon: const Icon(Icons.copy, color: Colors.amber, size: 20),  
                  onPressed: () {  
                    Clipboard.setData(ClipboardData(text: premiumService.encryptedDeviceId));  
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ معرف الجهاز')));  
                  },  
                ),  
              ],  
            ),  
          ),  
            
          const SizedBox(height: 20),  
          const Text('ألصق كود التفعيل:', style: TextStyle(color: Colors.white70, fontSize: 14)),  
          const SizedBox(height: 8),  
          Row(
            children: [
              Expanded(
                child: TextField(  
                  controller: _codeController,  
                  style: const TextStyle(color: Colors.white),  
                  decoration: InputDecoration(  
                    hintText: 'باتش التفعيل...',  
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),  
                    filled: true,  
                    fillColor: Colors.black26,  
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),  
                  ),  
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.paste, color: Colors.amber),
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data != null) _codeController.text = data.text!;
                },
              ),
            ],
          ),  
          const SizedBox(height: 16),  
          SizedBox(  
            width: double.infinity,  
            child: ElevatedButton(  
              onPressed: () async {  
                final success = await premiumService.activatePremium(_codeController.text);  
                if (success) {  
                  setState(() => _isPremium = true);  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل النسخة الاحترافية بنجاح')));  
                } else {  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كود التفعيل غير صحيح')));  
                }  
              },  
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),  
              child: const Text('تفعيل الآن', style: TextStyle(fontWeight: FontWeight.bold)),  
            ),  
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const Text('معلومات الاتصال للحصول على الكود:', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          const Text('واتساب: 01017341250 / 01031680816 / 01558203456', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const Text('إيميل: dosoky.server@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],  
      ),  
    );  
  }  
  
  Widget _buildPremiumActiveCard() {  
    return Container(  
      padding: const EdgeInsets.all(16),  
      decoration: BoxDecoration(  
        gradient: LinearGradient(colors: [Colors.green.shade700.withOpacity(0.2), Colors.teal.withOpacity(0.1)]),  
        borderRadius: BorderRadius.circular(12),  
        border: Border.all(color: Colors.green.shade600.withOpacity(0.3)),  
      ),  
      child: const Row(  
        children: [  
          Icon(Icons.verified, color: Colors.green, size: 24),  
          SizedBox(width: 12),  
          Text('النسخة البرو مفعلة بنجاح ✅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),  
        ],  
      ),  
    );  
  }  
}

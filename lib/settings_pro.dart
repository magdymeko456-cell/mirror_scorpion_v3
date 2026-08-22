import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsAndProScreen extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isPro;
  final ValueChanged<String> onVoiceChanged;
  
  const SettingsAndProScreen({
    super.key, 
    required this.prefs, 
    required this.isPro, 
    required this.onVoiceChanged
  });

  @override
  State<SettingsAndProScreen> createState() => _SettingsAndProScreenState();
}

class _SettingsAndProScreenState extends State<SettingsAndProScreen> {
  late String currentVoice;
  late bool isDarkMode;
  final TextEditingController _patchController = TextEditingController();
  final String fakeDeviceID = "TAMER-ELDOSOKY-SECURE-2026";

  @override
  void initState() {
    super.initState();
    currentVoice = widget.prefs.getString('selected_voice') ?? 'سيف';
    isDarkMode = widget.prefs.getBool('is_dark_mode') ?? true;
  }

  @override
  void dispose() {
    _patchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإعدادات ومحرك الصوت برو"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "محرك الأصوات المشترك وتنسيق النطق", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildVoiceRadio("سيف (صوت رجالي خشن)"),
                  _buildVoiceRadio("سلمى (صوت نسائي هادئ)"),
                  _buildVoiceRadio("سما (صوت نبرة سريعة للتواصل)"),
                  _buildVoiceRadio("سارة (صوت متزن للمستندات)"),
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.amber),
                    title: const Text("صوت المستخدم (استنساخ ذكي عالي الدقة)"),
                    subtitle: const Text("متاح فقط في النسخة المدفوعة PRO"),
                    trailing: widget.isPro ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "المظهر العام", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
          ),
          Card(
            elevation: 2,
            child: SwitchListTile(
              title: const Text("الوضع المظلم (Dark Mode)"),
              value: isDarkMode,
              activeColor: Colors.amber,
              onChanged: (val) {
                setState(() => isDarkMode = val);
                widget.prefs.setBool('is_dark_mode', val);
              },
            ),
          ),
          const SizedBox(height: 25),
          Card(
            color: Colors.green.withOpacity(0.08),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.green.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "تواصل مع المطور تامر الدسوقي", 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: Icon(Icons.whatsapp, color: Colors.green, size: 28),
                    title: Text("واتساب (خط المساعدة الدائم)", style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text("01017341250\n01031680816\n01558203456", style: TextStyle(fontSize: 14, height: 1.4)),
                    ),
                  ),
                  Divider(color: Colors.green.withOpacity(0.2)),
                  const ListTile(
                    leading: Icon(Icons.email, color: Colors.blue, size: 26),
                    title: Text("البريد الإلكتروني الرسمي"),
                    subtitle: Text("dosoky.server@gmail.com"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "ترقية الحساب وتفعيل ميرور برو 👑", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14)
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.amber.withOpacity(0.05),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.amber.withOpacity(0.3))),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "النسخة البرو تمنحك: ترجمة مستندات بلا حدود، استنساخ صوتك، تشغيل الترجمة أوفلاين، وتحويل الإلهام والقصص لفيديوهات مبهرة!",
                    style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "معرف الجهاز الفريد (Device ID)",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.amber),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("تم نسخ معرف الجهاز بنجاح!")),
                          );
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: fakeDeviceID),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _patchController,
                    decoration: const InputDecoration(
                      labelText: "أدخل باتش التفعيل المشفر هنا",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.paste, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      if (_patchController.text.isNotEmpty) {
                        widget.prefs.setBool('is_pro_version', true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم تفعيل النسخة PRO بنجاح مدى الحياة باسم تامر الدسوقي! 🎉")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("تفعيل الآن", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildVoiceRadio(String voiceName) {
    String shortName = voiceName.split(' ')[0];
    return RadioListTile<String>(
      title: Text(voiceName, style: const TextStyle(fontSize: 14)),
      value: shortName,
      groupValue: currentVoice,
      activeColor: Colors.amber,
      onChanged: (value) {
        if (value != null) {
          setState(() => currentVoice = value);
          widget.prefs.setString('selected_voice', value);
          widget.onVoiceChanged(value);
        }
      },
    );
  }
}

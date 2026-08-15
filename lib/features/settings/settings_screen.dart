import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والترقية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.amber),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.stars, color: Colors.amber, size: 50),
                  SizedBox(height: 10),
                  Text('Mirror Scorpion Pro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('تمتع بكافة المميزات الصوتية ومحركات الترجمة بدون حدود', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('الوضع المظلم'),
            trailing: Switch(
              value: theme.isDarkMode,
              onChanged: (v) => theme.toggleTheme(v),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('الإصدار'),
            subtitle: Text('v3.0.0 (النسخة الذهبية)'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('المطور'),
            subtitle: Text('tetocollctionway'),
          ),
        ],
      ),
    );
  }
}

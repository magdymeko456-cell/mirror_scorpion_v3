import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/language_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: const MirrorScorpionApp(),
    ),
  );
}

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Mirror Scorpion v3',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', ''), Locale('en', '')],
      locale: const Locale('ar', ''),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langService = Provider.of<LanguageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🦂 Mirror Scorpion v3'),
        actions: [
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) => themeProvider.toggleTheme(value),
            activeColor: Colors.amber,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.security, size: 70, color: Color(0xFF00B4D8)),
            ),
            const SizedBox(height: 15),
            Text(
              'مرحباً بك يا تامر في النسخة v3',
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'اللغات المتاحة للترجمة (الأوفلاين):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: langService.supportedLanguages.length,
                itemBuilder: (context, index) {
                  final lang = langService.supportedLanguages[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(lang.name),
                      subtitle: Text('كود اللغة: ${lang.code}'),
                      trailing: IconButton(
                        icon: Icon(
                          lang.isDownloaded ? Icons.check_circle : Icons.download,
                          color: lang.isDownloaded ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => langService.toggleLanguageDownload(lang.code),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

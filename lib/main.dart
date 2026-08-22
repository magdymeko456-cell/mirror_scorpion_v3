import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/home_screen.dart';
import 'features/card1_translation/translation_screen.dart';
import 'features/card2_dialogue/dialogue_screen.dart';
import 'features/card3_document/document_screen.dart';
import 'features/card4_stories/stories_screen.dart';
import 'features/games/chess/chess_game.dart';
import 'features/games/rubik_cube/rubik_cube_screen_enhanced.dart';
import 'features/settings/settings_screen.dart';

import 'services/language_service.dart';
import 'services/floating_bubble_service.dart';
import 'services/tts_service.dart';
import 'services/premium_verification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final languageService = LanguageService();
  await languageService.initialize();

  final premiumService = PremiumVerificationService();
  await premiumService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageService),
        ChangeNotifierProvider(create: (_) => FloatingBubbleService()),
        ChangeNotifierProvider(create: (_) => TTSService()),
        ChangeNotifierProvider.value(value: premiumService),
      ],
      child: const MirrorScorpionApp(),
    ),
  );
}

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langService = context.watch<LanguageService>();
    final deviceLang = langService.getDeviceLanguage();

    return MaterialApp(
      title: 'Mirror Scorpion',
      locale: Locale(deviceLang),
      supportedLocales: const [
        Locale('ar'), Locale('en'), Locale('fr'), Locale('de'),
        Locale('es'), Locale('tr'), Locale('fa'), Locale('ur'),
      ],
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/translate': (context) => const TranslationScreen(),
        '/dialogue': (context) => const DialogueScreen(),
        '/document': (context) => const DocumentScreen(),
        '/stories': (context) => const StoriesScreen(),
        '/chess': (context) => const ChessGame(),
        '/rubik': (context) => const RubikCubeScreenEnhanced(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

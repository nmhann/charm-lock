// lib/main.dart
//
// The entry point. It only sets up the app-wide look (colors, fonts) and
// opens the start screen. No game logic lives here.

import 'package:flutter/material.dart';

import 'screens/start_screen.dart';
import 'services/gem_bank.dart';
import 'services/sound_service.dart';
import 'theme.dart';

Future<void> main() async {
  // Needed before using plugins (like saved settings) in main().
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.instance.load(); // remembers if sound was turned off
  await GemBank.instance.load(); // the saved gem total
  runApp(const CharmLockApp());
}

class CharmLockApp extends StatelessWidget {
  const CharmLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charm Lock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.moss,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.pine,
          surface: AppColors.linen,
        ),
        fontFamily: 'Nunito', // bundled font, see pubspec.yaml
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.bark,
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: body(13, color: AppColors.linen),
        ),
      ),
      // Respect the player's text-size setting, but cap it at 1.3x so very
      // large text can't break the layout.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
      home: const StartScreen(),
    );
  }
}

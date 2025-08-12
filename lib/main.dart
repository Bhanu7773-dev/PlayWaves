import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'services/custom_theme_provider.dart'; // <-- Import your custom theme provider

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
        ChangeNotifierProvider(create: (_) => PitchBlackThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => CustomThemeProvider(),
        ), // <-- Add this line
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();

    // Don't break pitch black, always override with black background if enabled
    Color scaffoldColor = isPitchBlack
        ? Colors.black
        : (customTheme.customColorsEnabled
              ? customTheme.secondaryColor
              : const Color(0xFF16213e));

    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'PlayWaves',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: scaffoldColor,
        // Other theme customizations can use customTheme.primaryColor if needed
      ),
      home: const HomePage(),
    );
  }
}

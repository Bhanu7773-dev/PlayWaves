import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'services/custom_theme_provider.dart';

void main() {
  // Add error handling for native crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
        ChangeNotifierProvider(create: (_) => PitchBlackThemeProvider()),
        ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
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

    Color scaffoldColor = isPitchBlack
        ? Colors.black
        : (customTheme.customColorsEnabled
              ? customTheme.secondaryColor
              : const Color(0xFF16213e));

    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'PlayWaves',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: scaffoldColor),
      home: const HomePage(),
    );
  }
}

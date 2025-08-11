import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import '../services/player_state_provider.dart'; // Create this file as shown previously
import '../services/pitch_black_theme_provider.dart'; // <-- Import the pitch black provider

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
        ChangeNotifierProvider(
          create: (_) => PitchBlackThemeProvider(),
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
    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'PlayWaves',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: isPitchBlack
            ? Colors.black
            : const Color(0xFF16213e),
        // You can customize other theme aspects here if desired
      ),
      home: const HomePage(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/homepage.dart';
import '../services/player_state_provider.dart'; // Create this file as shown previously

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerStateProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      title: 'PlayWaves',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

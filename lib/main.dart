import 'package:flutter/material.dart';
import '../screens/homepage.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MyApp());
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
      home: HomePage(),
    );
  }
}

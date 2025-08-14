import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart'; // <-- Add this import!
import 'models/liked_song.dart';
import 'models/playlist_song.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'services/custom_theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LikedSongAdapter());
  Hive.registerAdapter(PlaylistSongAdapter());
  await Hive.openBox<LikedSong>('likedSongs');
  await Hive.openBox<PlaylistSong>('playlistSongs');

  // Add error handling for native crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  final audioPlayer = AudioPlayer(); // <-- Create a single instance!

  runApp(
    MultiProvider(
      providers: [
        Provider<AudioPlayer>.value(
          value: audioPlayer,
        ), // <-- Provide globally!
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

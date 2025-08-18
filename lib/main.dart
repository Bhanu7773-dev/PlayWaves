import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models/liked_song.dart';
import 'models/playlist_song.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'services/custom_theme_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive database
  await Hive.initFlutter();
  Hive.registerAdapter(LikedSongAdapter());
  Hive.registerAdapter(PlaylistSongAdapter());
  await Hive.openBox<LikedSong>('likedSongs');
  await Hive.openBox<PlaylistSong>('playlistSongs');
  // Initialize JustAudioBackground for background playback and notifications
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  // Create a single global instance of AudioPlayer
  final audioPlayer = AudioPlayer();

  runApp(
    MultiProvider(
      providers: [
        Provider<AudioPlayer>.value(value: audioPlayer),
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

    final Color scaffoldColor = isPitchBlack
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

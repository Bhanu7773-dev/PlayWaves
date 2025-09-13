import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/liked_song.dart';
import 'models/playlist_song.dart';
import 'models/theme_provider.dart';
import 'models/theme_model.dart';
import 'screens/Welcome_page.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'services/custom_theme_provider.dart';
import 'services/playlist_sync_service.dart';
import 'services/liked_songs_sync_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive database
  await Hive.initFlutter();
  Hive.registerAdapter(LikedSongAdapter());
  Hive.registerAdapter(PlaylistSongAdapter());
  Hive.registerAdapter(ThemeModelAdapter());
  await Hive.openBox<LikedSong>('likedSongs');
  await Hive.openBox<PlaylistSong>('playlistSongs');
  await Hive.openBox<ThemeModel>('theme_settings');

  // Initialize sync services
  await PlaylistSyncService.initialize();
  await LikedSongSyncService.initializeSync();

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
    ProviderScope(
      child: pv.MultiProvider(
        providers: [
          pv.Provider<AudioPlayer>.value(value: audioPlayer),
          pv.ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
          pv.ChangeNotifierProvider(create: (_) => PitchBlackThemeProvider()),
          pv.ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isPitchBlack = pv.Provider.of<PitchBlackThemeProvider>(
          context,
        ).isPitchBlack;
        final customTheme = pv.Provider.of<CustomThemeProvider>(context);
        final themeSettings = ref.watch(themeSettingsProvider);
        final flexScheme = themeSettings.flexSchemeEnum;

        ThemeData lightTheme = ThemeData.dark();
        ThemeData darkTheme = ThemeData.dark();

        if (customTheme.useDynamicColors) {
          // Use FlexColorScheme preset from Riverpod
          lightTheme = FlexThemeData.light(scheme: flexScheme);
          darkTheme = FlexThemeData.dark(scheme: flexScheme);
        } else if (customTheme.customColorsEnabled) {
          lightTheme = ThemeData.dark().copyWith(
            scaffoldBackgroundColor: customTheme.secondaryColor,
            colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: customTheme.primaryColor,
              secondary: customTheme.secondaryColor,
            ),
          );
          darkTheme = lightTheme;
        } else if (isPitchBlack) {
          lightTheme = ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.black,
          );
          darkTheme = lightTheme;
        }

        return MaterialApp(
          color: Colors.transparent,
          debugShowCheckedModeBanner: false,
          title: 'PlayWaves',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _previousUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Handle auth state changes for sync services
        final currentUser = snapshot.data;
        if (_previousUser == null && currentUser != null) {
          // User just logged in
          print('🔄 USER LOGIN: Initializing sync services...');
          PlaylistSyncService.onUserLogin();
          LikedSongSyncService.onUserLogin();
        } else if (_previousUser != null && currentUser == null) {
          // User just logged out
          print('🔄 USER LOGOUT: Cleaning up sync services...');
          PlaylistSyncService.onUserLogout();
          LikedSongSyncService.onUserLogout();
        }
        _previousUser = currentUser;

        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AuthLoadingScreen();
        }

        // If user is logged in, show HomePage
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // If user is not logged in, show WelcomePage
        return const WelcomePage();
      },
    );
  }
}

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PlayWaves',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:playwaves/models/theme_provider.dart';
import 'package:provider/provider.dart' as provider;
import 'package:dynamic_color/dynamic_color.dart';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/dynamic_theme_data.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models/liked_song.dart';
import 'models/playlist_song.dart';
import 'screens/homepage.dart';
import 'services/player_state_provider.dart';
import 'services/pitch_black_theme_provider.dart';
import 'services/custom_theme_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/theme_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(LikedSongAdapter());
  Hive.registerAdapter(PlaylistSongAdapter());
  Hive.registerAdapter(ThemeModelAdapter());
  await Hive.openBox<LikedSong>('likedSongs');
  Hive.openBox<ThemeModel>('theme_settings');
  await Hive.openBox<PlaylistSong>('playlistSongs');
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  final audioPlayer = AudioPlayer();

  // No need to load theme settings here anymore. The provider handles it.

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.Provider<AudioPlayer>.value(value: audioPlayer),
          provider.ChangeNotifierProvider(create: (_) => PlayerStateProvider()),
          provider.ChangeNotifierProvider(
            create: (_) => PitchBlackThemeProvider(),
          ),
          provider.ChangeNotifierProvider(create: (_) => CustomThemeProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsProvider);
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final customTheme = context.watch<CustomThemeProvider>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final ColorScheme? harmonizedLight = lightDynamic?.harmonized();
        final ColorScheme? harmonizedDark = darkDynamic?.harmonized();

        ThemeData lightTheme;
        ThemeData darkTheme;

        if (customTheme.customColorsEnabled) {
          lightTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: customTheme.primaryColor,
              primary: customTheme.primaryColor,
              secondary: customTheme.secondaryColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: customTheme.secondaryColor,
          );
          darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: customTheme.primaryColor,
              primary: customTheme.primaryColor,
              secondary: customTheme.secondaryColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: customTheme.secondaryColor,
          );
        } else if (harmonizedLight != null || harmonizedDark != null) {
          lightTheme = dynamicThemeData(harmonizedLight ?? ColorScheme.light());
          darkTheme = dynamicThemeData(harmonizedDark ?? ColorScheme.dark());
        } else {
          lightTheme = ThemeData.light();
          darkTheme = ThemeData.dark().copyWith(
            scaffoldBackgroundColor: isPitchBlack
                ? Colors.black
                : const Color(0xFF16213e),
          );
        }

        return MaterialApp(
          theme: FlexThemeData.light(
            swapColors: theme.swapColors,
            blendLevel: theme.blendLevel,
            scheme: theme.flexSchemeEnum,
          ),
          darkTheme: FlexThemeData.dark(
            swapColors: theme.swapColors,
            blendLevel: theme.blendLevel,
            scheme: theme.flexSchemeEnum,
            darkIsTrueBlack: theme.amoled,
          ),
          themeMode: theme.themeMode == 'light'
              ? ThemeMode.light
              : theme.themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
          home: const HomePage(),
        );
      },
    );
  }
}

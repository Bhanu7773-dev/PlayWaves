import 'package:flutter/material.dart';

ThemeData dynamicThemeData(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.background,
    cardColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      iconTheme: IconThemeData(color: scheme.primary),
      titleTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: scheme.onSurface),
      bodyMedium: TextStyle(color: scheme.onSurface),
      bodySmall: TextStyle(color: scheme.onSurface),
      headlineLarge: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(color: scheme.primary),
      headlineSmall: TextStyle(color: scheme.primary),
      titleLarge: TextStyle(
        color: scheme.secondary,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(color: scheme.secondary),
      titleSmall: TextStyle(color: scheme.secondary),
      labelLarge: TextStyle(color: scheme.tertiary),
      labelMedium: TextStyle(color: scheme.tertiary),
      labelSmall: TextStyle(color: scheme.tertiary),
      displayLarge: TextStyle(color: scheme.onBackground),
      displayMedium: TextStyle(color: scheme.onBackground),
      displaySmall: TextStyle(color: scheme.onBackground),
    ),
    iconTheme: IconThemeData(
      color: scheme.primary, // Accent for important icons
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurface.withOpacity(0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceVariant,
      hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: scheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(),
    // Add more themed widgets as your app grows!
  );
}

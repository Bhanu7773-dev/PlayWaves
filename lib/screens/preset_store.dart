import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playwaves/models/theme_provider.dart';
import 'package:provider/provider.dart';
import '../services/custom_theme_provider.dart';
import '../services/pitch_black_theme_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import '../models/theme_model.dart';

class ColorPresetPage extends ConsumerStatefulWidget {
  const ColorPresetPage({Key? key}) : super(key: key);

  @override
  ConsumerState<ColorPresetPage> createState() => _ColorPresetPageState();
}

class _ColorPresetPageState extends ConsumerState<ColorPresetPage> {
  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final isPitchBlack = context.watch<PitchBlackThemeProvider>().isPitchBlack;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isPitchBlack ? Colors.black : scheme.background,
      appBar: AppBar(
        backgroundColor: isPitchBlack
            ? Colors.black
            : scheme.surface.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Color Presets',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: isPitchBlack
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.surface.withOpacity(0.3), scheme.background],
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: FlexScheme.values.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final flexScheme = FlexScheme.values[index];
              final lightColorScheme = FlexThemeData.light(
                scheme: flexScheme,
                blendLevel: themeSettings.blendLevel,
                swapColors: themeSettings.swapColors,
              ).colorScheme;
              final darkColorScheme = FlexThemeData.dark(
                scheme: flexScheme,
                blendLevel: themeSettings.blendLevel,
                swapColors: themeSettings.swapColors,
              ).colorScheme;
              final currentColorScheme =
                  Theme.of(context).brightness == Brightness.dark
                  ? darkColorScheme
                  : lightColorScheme;
              final isSelected = themeSettings.flexScheme == flexScheme.name;

              return _PresetCard(
                name: _formatSchemeName(flexScheme.name),
                lightScheme: lightColorScheme,
                darkScheme: darkColorScheme,
                isSelected: isSelected,
                onTap: () {
                  // Update the theme using your existing updateSettings method
                  ref
                      .read(themeSettingsProvider.notifier)
                      .updateSettings(
                        (currentSettings) => currentSettings.copyWith(
                          flexScheme: flexScheme.name,
                        ),
                      );

                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.palette, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Applied "${_formatSchemeName(flexScheme.name)}" theme',
                          ),
                        ],
                      ),
                      backgroundColor: currentColorScheme.primary.withOpacity(
                        0.9,
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatSchemeName(String name) {
    // Convert camelCase to Title Case with special handling for common abbreviations
    final formatted = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();

    // Handle special cases
    return formatted
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          // Handle abbreviations like 'M3' or 'Ios'
          if (word.toLowerCase() == 'ios') return 'iOS';
          if (word.toLowerCase() == 'm3') return 'M3';
          if (word.toLowerCase() == 'hc') return 'HC';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

class _PresetCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme lightScheme;
  final ColorScheme darkScheme;
  final String name;

  const _PresetCard({
    required this.isSelected,
    required this.onTap,
    required this.lightScheme,
    required this.darkScheme,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scheme = isDarkMode ? darkScheme : lightScheme;
    final currentScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: currentScheme.surface,
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : currentScheme.outline.withOpacity(0.2),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? scheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(isDarkMode ? 0.4 : 0.08),
              blurRadius: isSelected ? 15 : 8,
              spreadRadius: isSelected ? 1 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            children: [
              // Color preview section
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      // Primary color section
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: scheme.primary,
                          child: Center(
                            child: isSelected
                                ? Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: scheme.onPrimary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: scheme.onPrimary,
                                      size: 20,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      // Secondary and tertiary colors
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Expanded(child: Container(color: scheme.secondary)),
                            Expanded(child: Container(color: scheme.tertiary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Name section
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: currentScheme.surface,
                    border: isSelected
                        ? Border(
                            top: BorderSide(
                              color: scheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? scheme.primary
                              : currentScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 2,
                          width: 20,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

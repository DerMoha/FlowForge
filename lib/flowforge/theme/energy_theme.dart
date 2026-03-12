import 'package:flutter/material.dart';

import 'typography.dart';

class EnergyPalette {
  const EnergyPalette({
    required this.gradientStart,
    required this.gradientEnd,
    required this.glow,
    required this.accent,
    required this.accentStrong,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.seedColor,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color glow;
  final Color accent;
  final Color accentStrong;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color seedColor;

  static EnergyPalette lerp(EnergyPalette a, EnergyPalette b, double t) {
    return EnergyPalette(
      gradientStart: Color.lerp(a.gradientStart, b.gradientStart, t)!,
      gradientEnd: Color.lerp(a.gradientEnd, b.gradientEnd, t)!,
      glow: Color.lerp(a.glow, b.glow, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      accentStrong: Color.lerp(a.accentStrong, b.accentStrong, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceHigh: Color.lerp(a.surfaceHigh, b.surfaceHigh, t)!,
      outline: Color.lerp(a.outline, b.outline, t)!,
      seedColor: Color.lerp(a.seedColor, b.seedColor, t)!,
    );
  }
}

class EnergyTheme {
  EnergyTheme._();

  // ---- Dark palettes (energy 25 / 45 / 65 / 85) ----
  static const _darkLow = EnergyPalette(
    gradientStart: Color(0xFF1A2530),
    gradientEnd: Color(0xFF1E2E3D),
    glow: Color(0xFF2F5164),
    accent: Color(0xFF7BA3B8),
    accentStrong: Color(0xFFA3CBDE),
    surface: Color(0xFF1F2B36),
    surfaceHigh: Color(0xFF263846),
    outline: Color(0xFF57717E),
    seedColor: Color(0xFF5F7A8A),
  );

  static const _darkWarm = EnergyPalette(
    gradientStart: Color(0xFF1A2B20),
    gradientEnd: Color(0xFF213828),
    glow: Color(0xFF2F6841),
    accent: Color(0xFF6FAF7E),
    accentStrong: Color(0xFF97D6A6),
    surface: Color(0xFF1E2E22),
    surfaceHigh: Color(0xFF294030),
    outline: Color(0xFF5C8668),
    seedColor: Color(0xFF4F8A63),
  );

  static const _darkSteady = EnergyPalette(
    gradientStart: Color(0xFF2A2118),
    gradientEnd: Color(0xFF362A1A),
    glow: Color(0xFF7F531F),
    accent: Color(0xFFD4943E),
    accentStrong: Color(0xFFE7B264),
    surface: Color(0xFF2C2419),
    surfaceHigh: Color(0xFF3C3223),
    outline: Color(0xFF9E7641),
    seedColor: Color(0xFFBA7A32),
  );

  static const _darkSurging = EnergyPalette(
    gradientStart: Color(0xFF2A1815),
    gradientEnd: Color(0xFF3A1E18),
    glow: Color(0xFF7B2D21),
    accent: Color(0xFFBF5E42),
    accentStrong: Color(0xFFDC866B),
    surface: Color(0xFF2E1C17),
    surfaceHigh: Color(0xFF3D251E),
    outline: Color(0xFF995444),
    seedColor: Color(0xFF8F3A2A),
  );

  // ---- Light palettes (energy 25 / 45 / 65 / 85) ----
  static const _lightLow = EnergyPalette(
    gradientStart: Color(0xFFE8EEF2),
    gradientEnd: Color(0xFFDDE6ED),
    glow: Color(0xFFA9C6D6),
    accent: Color(0xFF4A7085),
    accentStrong: Color(0xFF2E5A71),
    surface: Color(0xFFF0F4F7),
    surfaceHigh: Color(0xFFF8FBFD),
    outline: Color(0xFF9FB5C2),
    seedColor: Color(0xFF5F7A8A),
  );

  static const _lightWarm = EnergyPalette(
    gradientStart: Color(0xFFE8F0EA),
    gradientEnd: Color(0xFFDDE9DF),
    glow: Color(0xFFA7D1B2),
    accent: Color(0xFF3D7A50),
    accentStrong: Color(0xFF2D633F),
    surface: Color(0xFFF0F5F1),
    surfaceHigh: Color(0xFFF9FCFA),
    outline: Color(0xFF9FBCAA),
    seedColor: Color(0xFF4F8A63),
  );

  static const _lightSteady = EnergyPalette(
    gradientStart: Color(0xFFF2ECE2),
    gradientEnd: Color(0xFFEDE4D5),
    glow: Color(0xFFE4C08E),
    accent: Color(0xFFAA6B22),
    accentStrong: Color(0xFF8D5517),
    surface: Color(0xFFF7F1E8),
    surfaceHigh: Color(0xFFFDF9F2),
    outline: Color(0xFFCBB085),
    seedColor: Color(0xFFBA7A32),
  );

  static const _lightSurging = EnergyPalette(
    gradientStart: Color(0xFFF2E6E2),
    gradientEnd: Color(0xFFEDDAD5),
    glow: Color(0xFFE0A18E),
    accent: Color(0xFF9F3C28),
    accentStrong: Color(0xFF852B1B),
    surface: Color(0xFFF7EEEB),
    surfaceHigh: Color(0xFFFDF8F6),
    outline: Color(0xFFC9988D),
    seedColor: Color(0xFF8F3A2A),
  );

  static const _darkPalettes = [_darkLow, _darkWarm, _darkSteady, _darkSurging];
  static const _lightPalettes = [
    _lightLow,
    _lightWarm,
    _lightSteady,
    _lightSurging,
  ];
  static const _energyStops = [25.0, 45.0, 65.0, 85.0];

  static EnergyPalette palette(double energy, Brightness brightness) {
    final palettes = brightness == Brightness.dark
        ? _darkPalettes
        : _lightPalettes;

    if (energy <= _energyStops.first) return palettes.first;
    if (energy >= _energyStops.last) return palettes.last;

    for (var i = 0; i < _energyStops.length - 1; i++) {
      if (energy >= _energyStops[i] && energy <= _energyStops[i + 1]) {
        final t =
            (energy - _energyStops[i]) /
            (_energyStops[i + 1] - _energyStops[i]);
        return EnergyPalette.lerp(palettes[i], palettes[i + 1], t);
      }
    }

    return palettes.last;
  }

  static ThemeData buildTheme(double energy, Brightness brightness) {
    final p = palette(energy, brightness);
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: p.seedColor,
      brightness: brightness,
    );
    final colorScheme = base.copyWith(
      primary: p.accentStrong,
      secondary: p.accent,
      tertiary: Color.alphaBlend(
        p.glow.withValues(alpha: isDark ? 0.28 : 0.16),
        p.surfaceHigh,
      ),
      surface: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceHigh,
      surfaceContainerHigh: Color.alphaBlend(
        p.accent.withValues(alpha: isDark ? 0.1 : 0.06),
        p.surfaceHigh,
      ),
      surfaceContainerHighest: Color.alphaBlend(
        p.accentStrong.withValues(alpha: isDark ? 0.16 : 0.1),
        p.surfaceHigh,
      ),
      outline: p.outline,
      outlineVariant: p.outline.withValues(alpha: 0.6),
      primaryContainer: Color.alphaBlend(
        p.accentStrong.withValues(alpha: isDark ? 0.22 : 0.14),
        p.surfaceHigh,
      ),
      secondaryContainer: Color.alphaBlend(
        p.accent.withValues(alpha: isDark ? 0.2 : 0.12),
        p.surfaceHigh,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: FlowForgeTypography.primaryTextTheme(brightness).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.88),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        modalBackgroundColor: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.82 : 0.92,
        ),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ).copyWith(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class EnergyPalette {
  const EnergyPalette({
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    required this.surface,
    required this.seedColor,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final Color surface;
  final Color seedColor;

  static EnergyPalette lerp(EnergyPalette a, EnergyPalette b, double t) {
    return EnergyPalette(
      gradientStart: Color.lerp(a.gradientStart, b.gradientStart, t)!,
      gradientEnd: Color.lerp(a.gradientEnd, b.gradientEnd, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
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
    accent: Color(0xFF7BA3B8),
    surface: Color(0xFF1F2B36),
    seedColor: Color(0xFF5F7A8A),
  );

  static const _darkWarm = EnergyPalette(
    gradientStart: Color(0xFF1A2B20),
    gradientEnd: Color(0xFF213828),
    accent: Color(0xFF6FAF7E),
    surface: Color(0xFF1E2E22),
    seedColor: Color(0xFF4F8A63),
  );

  static const _darkSteady = EnergyPalette(
    gradientStart: Color(0xFF2A2118),
    gradientEnd: Color(0xFF362A1A),
    accent: Color(0xFFD4943E),
    surface: Color(0xFF2C2419),
    seedColor: Color(0xFFBA7A32),
  );

  static const _darkSurging = EnergyPalette(
    gradientStart: Color(0xFF2A1815),
    gradientEnd: Color(0xFF3A1E18),
    accent: Color(0xFFBF5E42),
    surface: Color(0xFF2E1C17),
    seedColor: Color(0xFF8F3A2A),
  );

  // ---- Light palettes (energy 25 / 45 / 65 / 85) ----
  static const _lightLow = EnergyPalette(
    gradientStart: Color(0xFFE8EEF2),
    gradientEnd: Color(0xFFDDE6ED),
    accent: Color(0xFF4A7085),
    surface: Color(0xFFF0F4F7),
    seedColor: Color(0xFF5F7A8A),
  );

  static const _lightWarm = EnergyPalette(
    gradientStart: Color(0xFFE8F0EA),
    gradientEnd: Color(0xFFDDE9DF),
    accent: Color(0xFF3D7A50),
    surface: Color(0xFFF0F5F1),
    seedColor: Color(0xFF4F8A63),
  );

  static const _lightSteady = EnergyPalette(
    gradientStart: Color(0xFFF2ECE2),
    gradientEnd: Color(0xFFEDE4D5),
    accent: Color(0xFFAA6B22),
    surface: Color(0xFFF7F1E8),
    seedColor: Color(0xFFBA7A32),
  );

  static const _lightSurging = EnergyPalette(
    gradientStart: Color(0xFFF2E6E2),
    gradientEnd: Color(0xFFEDDAD5),
    accent: Color(0xFF9F3C28),
    surface: Color(0xFFF7EEEB),
    seedColor: Color(0xFF8F3A2A),
  );

  static const _darkPalettes = [_darkLow, _darkWarm, _darkSteady, _darkSurging];
  static const _lightPalettes = [_lightLow, _lightWarm, _lightSteady, _lightSurging];
  static const _energyStops = [25.0, 45.0, 65.0, 85.0];

  static EnergyPalette palette(double energy, Brightness brightness) {
    final palettes =
        brightness == Brightness.dark ? _darkPalettes : _lightPalettes;

    if (energy <= _energyStops.first) return palettes.first;
    if (energy >= _energyStops.last) return palettes.last;

    for (var i = 0; i < _energyStops.length - 1; i++) {
      if (energy >= _energyStops[i] && energy <= _energyStops[i + 1]) {
        final t =
            (energy - _energyStops[i]) / (_energyStops[i + 1] - _energyStops[i]);
        return EnergyPalette.lerp(palettes[i], palettes[i + 1], t);
      }
    }

    return palettes.last;
  }

  static ThemeData buildTheme(double energy, Brightness brightness) {
    final p = palette(energy, brightness);
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: p.seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared typography system for FlowForge & AI Tutor.
///
/// Fonts:
/// - Space Grotesk: headings, labels, buttons
/// - Plus Jakarta Sans: body text
/// - JetBrains Mono: timers, monospace UI
class AppTypography {
  AppTypography._();

  static TextTheme primaryTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final bodyTheme = GoogleFonts.plusJakartaSansTextTheme(baseTheme);

    return bodyTheme.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -2.4,
        ),
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.8,
        ),
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
        ),
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
        ),
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        textStyle: bodyTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static TextStyle accentStyle(TextStyle base) {
    return GoogleFonts.spaceGrotesk(textStyle: base);
  }

  static TextStyle monoStyle(TextStyle base) {
    return GoogleFonts.jetBrainsMono(textStyle: base);
  }

  static TextStyle displayNumber(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.jetBrainsMono(
      textStyle: theme.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -2,
        color: color,
      ),
    );
  }

  static TextStyle heading(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.spaceGrotesk(
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.plusJakartaSans(
      textStyle: theme.textTheme.bodyLarge?.copyWith(color: color),
    );
  }

  static TextStyle timerDisplay(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.jetBrainsMono(
      textStyle: theme.textTheme.displayLarge?.copyWith(
        fontSize: 64,
        fontWeight: FontWeight.w600,
        letterSpacing: -3,
        height: 1,
        color: color,
      ),
    );
  }

  static TextStyle timerDisplayCompact(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.jetBrainsMono(
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        color: color,
      ),
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.spaceGrotesk(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.spaceGrotesk(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

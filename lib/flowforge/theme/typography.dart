import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FlowForge typography system
class FlowForgeTypography {
  FlowForgeTypography._();

  /// Primary font: Inter - clean, modern, highly legible
  static TextTheme primaryTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return GoogleFonts.interTextTheme(baseTheme);
  }

  /// Accent font: Manrope - friendly, geometric, for emphasis
  static TextStyle accentStyle(TextStyle base) {
    return GoogleFonts.manrope(textStyle: base);
  }

  /// Monospace font: JetBrains Mono - for timer display
  static TextStyle monoStyle(TextStyle base) {
    return GoogleFonts.jetBrainsMono(textStyle: base);
  }

  /// Get display text style (for big numbers, timers)
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

  /// Get heading style with accent font
  static TextStyle heading(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.manrope(
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  /// Get body text with primary font
  static TextStyle body(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.inter(
      textStyle: theme.textTheme.bodyLarge?.copyWith(
        color: color,
      ),
    );
  }

  /// Timer display style (large monospace)
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

  /// Compact timer display (for smaller spaces)
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

  /// Label style with accent font
  static TextStyle label(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.manrope(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }

  /// Button text style
  static TextStyle button(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return GoogleFonts.manrope(
      textStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

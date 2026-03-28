import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class TutorTheme {
  TutorTheme._();

  static const _seedColor = Color(0xFF4A90D9); // Scholar blue

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.primaryTextTheme(Brightness.light),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.primaryTextTheme(Brightness.dark),
    );
  }
}

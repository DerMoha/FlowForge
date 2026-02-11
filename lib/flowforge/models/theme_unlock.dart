import 'package:flutter/material.dart';

class ThemeUnlock {
  const ThemeUnlock({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.gradientColors,
  });

  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final List<Color>? gradientColors;

  bool isUnlocked(int currentLevel) {
    return currentLevel >= requiredLevel;
  }
}

/// Predefined unlockable themes
class UnlockableThemes {
  UnlockableThemes._();

  static const defaultTheme = ThemeUnlock(
    id: 'default',
    name: 'Default',
    description: 'The classic FlowForge palette',
    requiredLevel: 1,
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF1976D2),
    accentColor: Color(0xFF448AFF),
  );

  static const midnight = ThemeUnlock(
    id: 'midnight',
    name: 'Midnight',
    description: 'Deep purples and blacks for night owls',
    requiredLevel: 5,
    primaryColor: Color(0xFF1A0033),
    secondaryColor: Color(0xFF4A148C),
    accentColor: Color(0xFF7B1FA2),
    gradientColors: [
      Color(0xFF1A0033),
      Color(0xFF4A148C),
      Color(0xFF7B1FA2),
    ],
  );

  static const sunrise = ThemeUnlock(
    id: 'sunrise',
    name: 'Sunrise',
    description: 'Warm pinks and oranges for morning energy',
    requiredLevel: 10,
    primaryColor: Color(0xFFFF6B6B),
    secondaryColor: Color(0xFFFFAA4C),
    accentColor: Color(0xFFFF8A80),
    gradientColors: [
      Color(0xFFFF6B6B),
      Color(0xFFFFAA4C),
      Color(0xFFFEF0B1),
    ],
  );

  static const ocean = ThemeUnlock(
    id: 'ocean',
    name: 'Ocean',
    description: 'Calming teals and blues for deep focus',
    requiredLevel: 20,
    primaryColor: Color(0xFF006064),
    secondaryColor: Color(0xFF00838F),
    accentColor: Color(0xFF00ACC1),
    gradientColors: [
      Color(0xFF006064),
      Color(0xFF00838F),
      Color(0xFF4DD0E1),
    ],
  );

  static const forest = ThemeUnlock(
    id: 'forest',
    name: 'Forest',
    description: 'Natural greens and browns for grounded work',
    requiredLevel: 30,
    primaryColor: Color(0xFF1B5E20),
    secondaryColor: Color(0xFF2E7D32),
    accentColor: Color(0xFF43A047),
    gradientColors: [
      Color(0xFF1B5E20),
      Color(0xFF388E3C),
      Color(0xFF66BB6A),
    ],
  );

  static const cosmic = ThemeUnlock(
    id: 'cosmic',
    name: 'Cosmic',
    description: 'Legendary galaxy gradient for masters',
    requiredLevel: 50,
    primaryColor: Color(0xFF0D1B2A),
    secondaryColor: Color(0xFF1B263B),
    accentColor: Color(0xFF415A77),
    gradientColors: [
      Color(0xFF0D1B2A),
      Color(0xFF1B263B),
      Color(0xFF415A77),
      Color(0xFF778DA9),
      Color(0xFFE0E1DD),
    ],
  );

  static const all = [
    defaultTheme,
    midnight,
    sunrise,
    ocean,
    forest,
    cosmic,
  ];

  static ThemeUnlock? getById(String id) {
    try {
      return all.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ThemeUnlock> getUnlocked(int currentLevel) {
    return all.where((theme) => theme.isUnlocked(currentLevel)).toList();
  }

  static List<ThemeUnlock> getLocked(int currentLevel) {
    return all.where((theme) => !theme.isUnlocked(currentLevel)).toList();
  }
}

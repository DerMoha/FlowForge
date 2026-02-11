import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

import '../models/user_profile.dart';
import '../models/achievement.dart';

/// Service for exporting and sharing progress cards
class ExportService {
  ExportService._();

  static final instance = ExportService._();

  /// Generate a shareable image from a widget
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Share an image with text
  Future<void> shareImage(Uint8List imageBytes, String text) async {
    try {
      final xFile = XFile.fromData(
        imageBytes,
        mimeType: 'image/png',
        name: 'flowforge_progress.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: text,
        subject: 'FlowForge Progress',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  /// Generate progress card data
  Map<String, dynamic> generateWeeklySummary({
    required int sessions,
    required int minutes,
    required int tasksCompleted,
    required int streak,
  }) {
    return {
      'sessions': sessions,
      'minutes': minutes,
      'hours': (minutes / 60).toStringAsFixed(1),
      'tasks': tasksCompleted,
      'streak': streak,
      'title': 'Weekly Progress',
    };
  }

  /// Generate achievement unlock card data
  Map<String, dynamic> generateAchievementCard(Achievement achievement) {
    return {
      'title': achievement.title,
      'description': achievement.description,
      'rarity': achievement.rarity.label,
      'category': achievement.category.name,
    };
  }

  /// Generate level up card data
  Map<String, dynamic> generateLevelUpCard(UserProfile profile) {
    return {
      'level': profile.level,
      'title': profile.title,
      'xp': profile.totalXP,
      'nextLevelXP': profile.nextLevelXP,
      'progress': profile.levelProgress,
    };
  }

  /// Generate streak milestone card data
  Map<String, dynamic> generateStreakCard(int streak) {
    String message;
    if (streak >= 365) {
      message = 'Legendary Streak!';
    } else if (streak >= 100) {
      message = 'Unstoppable!';
    } else if (streak >= 30) {
      message = 'Dedicated!';
    } else if (streak >= 7) {
      message = 'Committed!';
    } else {
      message = 'Keep It Up!';
    }

    return {
      'streak': streak,
      'message': message,
      'title': '$streak Day Streak',
    };
  }

  /// Export data as JSON string
  String exportDataAsJson(Map<String, dynamic> data) {
    // In a real implementation, use json.encode
    return data.toString();
  }

  /// Generate QR code data for device transfer
  String generateTransferCode(Map<String, dynamic> data) {
    // In a real implementation, encode data to base64
    return 'transfer_code_placeholder';
  }
}

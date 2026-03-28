import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting and sharing progress cards
class ExportService {
  ExportService._();

  static final instance = ExportService._();

  /// Generate a shareable image from a widget
  Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

  String formatWeeklySummaryText(Map<String, dynamic> summary) {
    return 'My FlowForge Progress\n'
        '${summary['sessions']} sessions completed\n'
        '${summary['hours']} hours focused\n'
        '${summary['tasks']} tasks finished\n'
        '${summary['streak']}-day streak';
  }

  /// Export data as JSON string
  String exportDataAsJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Generate QR code data for device transfer
  String generateTransferCode(Map<String, dynamic> data) {
    return base64UrlEncode(utf8.encode(exportDataAsJson(data)));
  }
}

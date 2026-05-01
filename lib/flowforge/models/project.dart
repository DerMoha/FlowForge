import 'package:flutter/material.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.deadline,
    this.description,
  });

  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final DateTime createdAt;
  final DateTime? deadline;
  final String? description;

  Project copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    DateTime? createdAt,
    DateTime? deadline,
    String? description,
    bool clearDeadline = false,
    bool clearDescription = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      description: clearDescription ? null : (description ?? this.description),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
      'icon': icon.codePoint,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'description': description,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int? ?? 0xFF2196F3),
      icon: _getIconData(json['icon'] as int?),
      createdAt: DateTime.parse(json['created_at'] as String),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  static IconData _getIconData(int? codePoint) {
    if (codePoint == null) return ProjectIcons.folder;

    // Find the matching predefined constant icon to preserve tree-shaking
    for (final icon in ProjectIcons.all) {
      if (icon.codePoint == codePoint) {
        return icon;
      }
    }

    // Fallback if not found in our constants
    return ProjectIcons.folder;
  }
}

/// Predefined project colors
class ProjectColors {
  ProjectColors._();

  static const blue = Color(0xFF2196F3);
  static const red = Color(0xFFE53935);
  static const green = Color(0xFF43A047);
  static const orange = Color(0xFFFF9800);
  static const purple = Color(0xFF9C27B0);
  static const teal = Color(0xFF00897B);
  static const pink = Color(0xFFE91E63);
  static const indigo = Color(0xFF3F51B5);
  static const amber = Color(0xFFFFC107);
  static const cyan = Color(0xFF00BCD4);

  static const List<Color> all = [
    blue,
    red,
    green,
    orange,
    purple,
    teal,
    pink,
    indigo,
    amber,
    cyan,
  ];
}

/// Predefined project icons
class ProjectIcons {
  ProjectIcons._();

  static const folder = Icons.folder_rounded;
  static const work = Icons.work_rounded;
  static const school = Icons.school_rounded;
  static const home = Icons.home_rounded;
  static const fitness = Icons.fitness_center_rounded;
  static const code = Icons.code_rounded;
  static const design = Icons.palette_rounded;
  static const writing = Icons.edit_rounded;
  static const music = Icons.music_note_rounded;
  static const shopping = Icons.shopping_cart_rounded;

  static const List<IconData> all = [
    folder,
    work,
    school,
    home,
    fitness,
    code,
    design,
    writing,
    music,
    shopping,
  ];
}

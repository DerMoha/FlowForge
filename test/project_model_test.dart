import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowforge/flowforge/models/project.dart';

void main() {
  test('Project.fromJson restores known icon constants', () {
    final project = Project.fromJson({
      'id': 'project-1',
      'name': 'Code',
      'color': ProjectColors.blue.toARGB32(),
      'icon': ProjectIcons.code.codePoint,
      'created_at': DateTime(2026, 3, 13).toIso8601String(),
    });

    expect(identical(project.icon, ProjectIcons.code), isTrue);
  });

  test('Project.fromJson falls back to folder for unknown icons', () {
    final project = Project.fromJson({
      'id': 'project-2',
      'name': 'Unknown',
      'color': ProjectColors.green.toARGB32(),
      'icon': Icons.abc.codePoint,
      'created_at': DateTime(2026, 3, 13).toIso8601String(),
    });

    expect(identical(project.icon, ProjectIcons.folder), isTrue);
  });
}

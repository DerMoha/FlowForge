import 'package:flutter/material.dart';

enum TaskEnergyRequirement { low, medium, high, deep }

extension TaskEnergyRequirementX on TaskEnergyRequirement {
  String get label {
    switch (this) {
      case TaskEnergyRequirement.low:
        return 'Low';
      case TaskEnergyRequirement.medium:
        return 'Medium';
      case TaskEnergyRequirement.high:
        return 'High';
      case TaskEnergyRequirement.deep:
        return 'Deep';
    }
  }

  int get minEnergy {
    switch (this) {
      case TaskEnergyRequirement.low:
        return 20;
      case TaskEnergyRequirement.medium:
        return 45;
      case TaskEnergyRequirement.high:
        return 65;
      case TaskEnergyRequirement.deep:
        return 80;
    }
  }

  IconData get icon {
    switch (this) {
      case TaskEnergyRequirement.low:
        return Icons.eco_rounded;
      case TaskEnergyRequirement.medium:
        return Icons.local_fire_department_rounded;
      case TaskEnergyRequirement.high:
        return Icons.flash_on_rounded;
      case TaskEnergyRequirement.deep:
        return Icons.rocket_launch_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case TaskEnergyRequirement.low:
        return const Color(0xFF4F8A63);
      case TaskEnergyRequirement.medium:
        return const Color(0xFFBA7A32);
      case TaskEnergyRequirement.high:
        return const Color(0xFFAF5E2C);
      case TaskEnergyRequirement.deep:
        return const Color(0xFF8F3A2A);
    }
  }

  String get storageValue => name;

  static TaskEnergyRequirement fromStorageValue(String? value) {
    for (final level in TaskEnergyRequirement.values) {
      if (level.storageValue == value) {
        return level;
      }
    }
    return TaskEnergyRequirement.medium;
  }
}

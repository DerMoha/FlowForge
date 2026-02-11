import 'package:flutter/material.dart';

class EnergyPreset {
  const EnergyPreset({
    required this.value,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
}

const List<EnergyPreset> energyPresets = <EnergyPreset>[
  EnergyPreset(
    value: 25,
    label: 'Low',
    hint: 'Recovery mode',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF5F7A8A),
  ),
  EnergyPreset(
    value: 45,
    label: 'Warm',
    hint: 'Build momentum',
    icon: Icons.eco_rounded,
    color: Color(0xFF4F8A63),
  ),
  EnergyPreset(
    value: 65,
    label: 'Steady',
    hint: 'Main work mode',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFBA7A32),
  ),
  EnergyPreset(
    value: 85,
    label: 'Surging',
    hint: 'Deep push',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFF8F3A2A),
  ),
];

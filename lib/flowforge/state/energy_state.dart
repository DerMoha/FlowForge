import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/energy_preset.dart';

/// Manages energy levels, presets, and predictions
class EnergyState extends ChangeNotifier {
  double _energy = 65;

  double get energy => _energy;

  int get currentEnergyScore => _energy.round();

  EnergyPreset get activeEnergyPreset => closestEnergyPreset(_energy);

  /// Initialize state from storage
  Future<void> init() async {
    await _loadState();
  }

  /// Set energy level (snaps to nearest preset)
  void setEnergy(double value) {
    final snapped = _snapEnergy(value);
    if (_energy == snapped) return;

    _energy = snapped;
    notifyListeners();
    _saveState();
  }

  /// Set energy using a preset
  void setEnergyPreset(EnergyPreset preset) {
    setEnergy(preset.value.toDouble());
  }

  /// Snap energy to nearest preset value
  double _snapEnergy(double value) {
    return closestEnergyPreset(value).value.toDouble();
  }

  /// Find closest energy preset for a value
  EnergyPreset closestEnergyPreset(double value) {
    var closest = energyPresets.first;
    var closestDistance = (closest.value - value).abs();

    for (final preset in energyPresets.skip(1)) {
      final distance = (preset.value - value).abs();
      if (distance < closestDistance) {
        closest = preset;
        closestDistance = distance;
      }
    }

    return closest;
  }

  /// Get recommended focus minutes for current energy
  int get recommendedFocusMinutes => _recommendedFocusMinutesFor(_energy);

  int _recommendedFocusMinutesFor(double e) {
    if (e >= 80) return 60;
    if (e >= 60) return 45;
    if (e >= 40) return 25;
    return 15;
  }

  /// Load state from persistent storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEnergy = prefs.getDouble('energy');

      if (savedEnergy != null) {
        _energy = _snapEnergy(savedEnergy);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading energy state: $e');
    }
  }

  /// Save state to persistent storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('energy', _energy);
    } catch (e) {
      debugPrint('Error saving energy state: $e');
    }
  }
}

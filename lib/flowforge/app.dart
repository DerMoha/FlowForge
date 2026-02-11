import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'theme/energy_theme.dart';
import 'widgets/calm_scaffold.dart';

class FlowForgeApp extends StatefulWidget {
  const FlowForgeApp({super.key});

  @override
  State<FlowForgeApp> createState() => _FlowForgeAppState();
}

class _FlowForgeAppState extends State<FlowForgeApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late final FlowForgeState _state;

  @override
  void initState() {
    super.initState();
    _state = FlowForgeState();
    _state.init();
    _state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    _state.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  void _toggleThemeMode() {
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final currentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    setState(() {
      _themeMode = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlowForge',
      theme: EnergyTheme.buildTheme(_state.energy, Brightness.light),
      darkTheme: EnergyTheme.buildTheme(_state.energy, Brightness.dark),
      themeMode: _themeMode,
      home: CalmScaffold(
        state: _state,
        onToggleTheme: _toggleThemeMode,
      ),
    );
  }
}

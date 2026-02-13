import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'state/energy_state.dart';
import 'state/timer_state.dart';
import 'state/task_state.dart';
import 'state/gamification_state.dart';
import 'state/profile_state.dart';
import 'state/analytics_state.dart';
import 'theme/energy_theme.dart';
import 'widgets/main_navigation.dart';

class FlowForgeApp extends StatefulWidget {
  const FlowForgeApp({super.key});

  @override
  State<FlowForgeApp> createState() => _FlowForgeAppState();
}

class _FlowForgeAppState extends State<FlowForgeApp> {
  ThemeMode _themeMode = ThemeMode.system;

  // Keep legacy state for now during migration
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
    final currentlyDark =
        _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            platformBrightness == Brightness.dark);
    setState(() {
      _themeMode = currentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap with MultiProvider for new architecture
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EnergyState()..init()),
        ChangeNotifierProvider(create: (_) => TimerState()..init()),
        ChangeNotifierProvider(create: (_) => TaskState()..init()),
        ChangeNotifierProvider(create: (_) => GamificationState()..init()),
        ChangeNotifierProvider(create: (_) => ProfileState()..init()),
        ChangeNotifierProvider(create: (_) => AnalyticsState()..init()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlowForge',
        theme: EnergyTheme.buildTheme(_state.energy, Brightness.light),
        darkTheme: EnergyTheme.buildTheme(_state.energy, Brightness.dark),
        themeMode: _themeMode,
        home: MainNavigation(state: _state, onToggleTheme: _toggleThemeMode),
      ),
    );
  }
}

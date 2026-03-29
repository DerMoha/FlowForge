import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../practice/practice_list_screen.dart';
import '../quiz/quiz_list_screen.dart';
import '../voice/voice_tutor_screen.dart';
import '../progress/progress_dashboard.dart';
import '../settings/settings_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _selectedIndex = 0;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.library_books_outlined),
      selectedIcon: Icon(Icons.library_books),
      label: Text('Library'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: Text('Quizzes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: Text('Practice'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.record_voice_over_outlined),
      selectedIcon: Icon(Icons.record_voice_over),
      label: Text('Voice'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: Text('Progress'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const LibraryScreen();
      case 1:
        return const QuizListScreen();
      case 2:
        return const PracticeListScreen();
      case 3:
        return const VoiceTutorScreen();
      case 4:
        return const ProgressDashboard();
      case 5:
        return const SettingsScreen();
      default:
        return const LibraryScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}

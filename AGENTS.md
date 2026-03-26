# AGENTS.md

This file provides guidelines for agentic coding agents operating in the FlowForge repository.

## Build/Test/Lint Commands

```bash
# Install dependencies
flutter pub get

# Build the app for a specific platform
flutter build ios
flutter build android
flutter build macos
flutter build web
flutter build windows
flutter build linux

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests matching a name pattern
flutter test --name "workspace hub can activate"

# Run tests in a specific file with verbose output
flutter test test/date_helpers_test.dart -r expanded

# Analyze (lint) - run before committing
flutter analyze

# Hot reload during development
flutter run

# Clean build artifacts
flutter clean
```

## Code Style Guidelines

### General Principles
- Keep files under 500 lines when possible
- Prefer composition over inheritance
- Use dependency injection via constructors
- Avoid global state; use providers properly

### Linting
- Uses `flutter_lints` package - standard Flutter lint rules apply
- Run `flutter analyze` before committing - it should exit with no errors
- Use `withValues(alpha: ...)` instead of deprecated `withOpacity(...)`
- Avoid unnecessary string interpolation braces: prefer `$variable` over `${variable}` unless using methods

### Naming Conventions
- Classes: PascalCase (e.g., `FlowForgeApp`, `TodoItem`, `ProjectState`)
- Files: snake_case (e.g., `calm_scaffold.dart`, `todo_item.dart`)
- Private members: prefix with underscore (e.g., `_todos`, `_controller`, `_state`)
- Constants: lowercase_with_underscores (e.g., `defaultDuration`, `storageKey`)
- Test files: `_test.dart` suffix (e.g., `date_helpers_test.dart`)

### Imports Order
```dart
import 'package:flutter/material.dart';       // Flutter SDK first
import 'package:flutter_test/flutter_test.dart'; // Testing
import 'package:provider/provider.dart';        // Third-party packages

import '../state/app_state.dart';              // Local imports last
import '../models/todo_item.dart';
import '../utils/date_helpers.dart';
```

### Widget Structure
- Always use `super.key` in constructor
- Private State classes: `_ClassNameState extends State<WidgetName>`
- Prefer `const` constructors and widgets where possible
- Implement proper lifecycle methods: `initState`, `didUpdateWidget`, `dispose`
- Extract reusable widget sections into separate files (e.g., `task_detail_sections.dart`)

### State Management
- Uses listener pattern (app state notifies listeners)
- Access state via: `final state = FlowForgeState.of(context)` or `context.watch<StateType>()`
- State changes: `setState()` in widgets, `state.notifyListeners()` for app-wide state
- Use `provider` package for dependency injection
- Persist state in SharedPreferences; use async methods for save operations

### Models
- Immutable classes with `const` constructors where possible
- Use `final` fields
- Always implement `copyWith`, `toJson`, `fromJson` methods
- Validate types in `fromJson` with descriptive `FormatException` messages
- Use `EnergyPalette`, `TaskEnergyRequirement`, `TaskStatus` enums for domain types

### Error Handling
- Use descriptive error messages in model parsing
- Handle widget disposal properly to prevent memory leaks
- Use `mounted` checks before setState after async operations
- Wrap async operations in try-catch with proper error logging

### UI Patterns
- Use `Key` for widget identification in tests (e.g., `ValueKey('todo-input')`)
- Prefer `EdgeInsets.fromLTRB` or `EdgeInsets.symmetric` for padding
- Use `ValueKey<String>` for type-safe keys in widgets
- Implement proper disposal of controllers and listeners
- Use `AmbientGradientBackground` for consistent app background
- Center and constrain main content to `maxWidth: 1080` for responsive layouts

### Energy Theme System
- Use `EnergyTheme.palette(energy, brightness)` for energy-aware colors
- Define palettes in `lib/flowforge/theme/energy_theme.dart` with: `gradientStart`, `gradientEnd`, `glow`, `accent`, `accentStrong`, `surface`, `surfaceHigh`, `outline`, `seedColor`
- Apply theme via `EnergyTheme.buildTheme(energy, brightness)`

### Project/Task Organization
- Projects provide task context; use active project filtering in Focus/Tasks views
- Task states: `TaskStatus.today`, `TaskStatus.backlog`, `TaskStatus.done`
- Energy requirements: `TaskEnergyRequirement.low`, `medium`, `high`, `deep`
- Use shared `TaskDetailSections` widget for consistent task editing UI
- New tasks default to active project when one is set

### Testing

Tests use `flutter_test` package with these patterns:

```dart
// Widget test
testWidgets('test description', (WidgetTester tester) async {
  await tester.pumpWidget(const FlowForgeApp());
  await tester.tap(find.byKey(const ValueKey<String>('todo-input')));
  await tester.pumpAndSettle();
  expect(find.text('expected'), findsOneWidget);
});

// Unit test
test('description', () {
  expect(actual, expected);
});
```

- Use `SharedPreferences.setMockInitialValues({})` in setUp for tests using SharedPreferences
- Use `appState.init()` to initialize FlowForgeState in tests
- Test both happy paths and edge cases
- Add regression tests when fixing bugs

### Git Commit Messages

Use typed commits:
```
feat: add new feature
fix: bug fix
refactor: code restructure without behavior change
style: formatting, lint fixes
test: adding/updating tests
chore: maintenance, dependencies, tooling
```

Example: `feat: add project-aware filtering across focus and tasks`

## Project Structure

```
lib/flowforge/
├── animations/        # Animation helpers
├── models/           # Data models (TodoItem, Project, etc.)
├── services/         # External services (Calendar, Voice, Export)
├── state/            # State management (AppState, ProjectState, etc.)
├── theme/            # Theme and typography
├── utils/            # Utility functions
└── widgets/          # UI components
    ├── calm_scaffold.dart     # Focus dashboard
    ├── task_kanban_screen.dart # Kanban board
    ├── workspace_hub.dart      # Projects/Analytics hub
    └── ...                    # Other widgets
```

## Additional Notes

- No Cursor or Copilot rules currently configured for this repository
- The app uses Material 3 design system
- Primary fonts: Space Grotesk (headings), Plus Jakarta Sans (body), JetBrains Mono (timers)
- Energy system drives visual theming throughout the app

# AGENTS.md

## Build/Test/Lint Commands

```bash
# Install dependencies
flutter pub get

# Build the app
flutter build [ios|android|macos|web|windows|linux]

# Run tests
flutter test

# Run a single test
flutter test test/widget_test.dart

# Analyze (lint)
flutter analyze

# Hot reload during development
flutter run

# Clean build artifacts
flutter clean
```

## Code Style Guidelines

### Linting
- Uses `flutter_lints` package - standard Flutter lint rules apply
- Run `flutter analyze` before committing

### Naming Conventions
- Classes: PascalCase (e.g., `FlowForgeApp`, `TodoItem`)
- Files: snake_case (e.g., `calm_scaffold.dart`, `todo_item.dart`)
- Private members: prefix with underscore (e.g., `_todos`, `_controller`)
- Constants: lowercase_with_underscores (e.g., `defaultDuration`)

### Widget Structure
- Always use `super.key` in constructor
- Private State classes: `_ClassNameState extends State<WidgetName>`
- Prefer `const` constructors and widgets where possible
- Implement proper lifecycle methods: `initState`, `didUpdateWidget`, `dispose`

### Imports Order
```dart
import 'package:flutter/material.dart';  // Flutter SDK first
import 'package:flutter_test/flutter_test.dart';  // Third-party packages

import '../state/app_state.dart';  // Local imports last (relative paths)
import '../models/todo_item.dart';
```

### State Management
- Uses listener pattern (app state notifies listeners)
- Access state via: `final state = FlowForgeState.of(context)`
- State changes: `setState()` in widgets, `state.notifyListeners()` for app-wide state

### Models
- Immutable classes with `const` constructors
- Use `final` fields
- Implement `copyWith`, `toJson`, `fromJson` methods
- Validate types in `fromJson` with descriptive `FormatException` messages

### Error Handling
- Use descriptive error messages in model parsing
- Handle widget disposal properly to prevent memory leaks
- Use `mounted` checks before setState after async operations

### UI Patterns
- Use `Key` for widget identification in tests (e.g., `ValueKey('todo-input')`)
- Prefer `EdgeInsets.fromLTRB` or `EdgeInsets.symmetric` for padding
- Use `ValueKey<String>` for type-safe keys in widgets
- Implement proper disposal of controllers and listeners

## Testing

Tests use `flutter_test` package with standard patterns:
```dart
testWidgets('test description', (WidgetTester tester) async {
  await tester.pumpWidget(const FlowForgeApp());
  await tester.tap(find.byKey(const ValueKey<String>('todo-input')));
  await tester.pumpAndSettle();
  expect(find.text('expected'), findsOneWidget);
});
```

Use `SharedPreferences.setMockInitialValues({})` in setUp for tests using SharedPreferences.

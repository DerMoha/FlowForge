import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcut action types
enum ShortcutAction {
  newTask,
  toggleTimer,
  commandPalette,
  setEnergyLow,
  setEnergyMedium,
  setEnergyHigh,
  setEnergyDeep,
  exitFocusMode,
  showShortcuts,
  markComplete,
  deleteTask,
  editTask,
  focusTask,
  navigateUp,
  navigateDown,
}

/// Keyboard shortcuts service
class KeyboardShortcutsService {
  KeyboardShortcutsService._();

  static final instance = KeyboardShortcutsService._();

  final Map<ShortcutActivator, ShortcutAction> _shortcuts = {};
  final Map<ShortcutAction, VoidCallback> _handlers = {};

  /// Initialize shortcuts
  void init() {
    // Global shortcuts
    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN),
      ShortcutAction.newTask,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.space),
      ShortcutAction.toggleTimer,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK),
      ShortcutAction.commandPalette,
    );

    // Energy presets
    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit1),
      ShortcutAction.setEnergyLow,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit2),
      ShortcutAction.setEnergyMedium,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit3),
      ShortcutAction.setEnergyHigh,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.digit4),
      ShortcutAction.setEnergyDeep,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.escape),
      ShortcutAction.exitFocusMode,
    );

    // Task shortcuts
    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.enter),
      ShortcutAction.markComplete,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.delete),
      ShortcutAction.deleteTask,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyE),
      ShortcutAction.editTask,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.keyF),
      ShortcutAction.focusTask,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.arrowUp),
      ShortcutAction.navigateUp,
    );

    _registerShortcut(
      LogicalKeySet(LogicalKeyboardKey.arrowDown),
      ShortcutAction.navigateDown,
    );
  }

  /// Register a shortcut
  void _registerShortcut(ShortcutActivator activator, ShortcutAction action) {
    _shortcuts[activator] = action;
  }

  /// Register a handler for an action
  void registerHandler(ShortcutAction action, VoidCallback handler) {
    _handlers[action] = handler;
  }

  /// Unregister a handler
  void unregisterHandler(ShortcutAction action) {
    _handlers.remove(action);
  }

  /// Handle a shortcut
  void handleShortcut(ShortcutAction action) {
    final handler = _handlers[action];
    if (handler != null) {
      handler();
    }
  }

  /// Get all shortcuts
  Map<ShortcutActivator, ShortcutAction> get shortcuts => _shortcuts;

  /// Get description for a shortcut
  String getDescription(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.newTask:
        return 'Create new task';
      case ShortcutAction.toggleTimer:
        return 'Start/pause timer';
      case ShortcutAction.commandPalette:
        return 'Open command palette';
      case ShortcutAction.setEnergyLow:
        return 'Set energy to Low';
      case ShortcutAction.setEnergyMedium:
        return 'Set energy to Medium';
      case ShortcutAction.setEnergyHigh:
        return 'Set energy to High';
      case ShortcutAction.setEnergyDeep:
        return 'Set energy to Deep';
      case ShortcutAction.exitFocusMode:
        return 'Exit focus mode';
      case ShortcutAction.showShortcuts:
        return 'Show shortcuts overlay';
      case ShortcutAction.markComplete:
        return 'Mark task complete';
      case ShortcutAction.deleteTask:
        return 'Delete task';
      case ShortcutAction.editTask:
        return 'Edit task';
      case ShortcutAction.focusTask:
        return 'Focus on task';
      case ShortcutAction.navigateUp:
        return 'Navigate up';
      case ShortcutAction.navigateDown:
        return 'Navigate down';
    }
  }
}

/// Shortcuts overlay widget
class ShortcutsOverlay extends StatelessWidget {
  const ShortcutsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortcuts = KeyboardShortcutsService.instance.shortcuts;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keyboard Shortcuts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: shortcuts.entries.map((entry) {
                      final action = entry.value;
                      final description = KeyboardShortcutsService.instance
                          .getDescription(action);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(description)),
                            _buildShortcutBadge(context, entry.key),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutBadge(
    BuildContext context,
    ShortcutActivator activator,
  ) {
    final theme = Theme.of(context);
    // Simplified display - would need proper formatting
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        activator.toString(),
        style: theme.textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

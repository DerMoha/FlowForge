import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/date_helpers.dart';

class FocusTimerRing extends StatelessWidget {
  const FocusTimerRing({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalSeconds = state.focusMinutes * 60;
    final completion =
        (1 - (state.remainingSeconds / totalSeconds)).clamp(0.0, 1.0);
    final ringSize = state.isRunning ? 280.0 : 240.0;

    return Column(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0, end: completion),
                builder: (context, value, child) {
                  return SizedBox(
                    width: ringSize - 20,
                    height: ringSize - 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 12,
                      value: value,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        state.isRunning ? scheme.primary : scheme.secondary,
                      ),
                    ),
                  );
                },
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                width: state.isRunning ? 158 : 148,
                height: state.isRunning ? 158 : 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isRunning
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  border: Border.all(
                    color: state.isRunning
                        ? scheme.primary.withValues(alpha: 0.5)
                        : scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      formatDuration(state.remainingSeconds),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: state.isRunning
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isRunning ? 'Flow in progress' : 'Ready to focus',
                      style: textTheme.labelMedium?.copyWith(
                        color: state.isRunning
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                icon: Icon(
                  state.isRunning
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                label: Text(
                  state.isRunning ? 'Pause Session' : 'Start Session',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: state.toggleTimer,
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              key: const ValueKey<String>('focus-reset-button'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: state.hasFocusProgress
                  ? () => _confirmReset(context)
                  : null,
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          children: FlowForgeState.minutePresets
              .map(
                (minutes) => ChoiceChip(
                  label: Text('$minutes min'),
                  selectedColor: scheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: minutes == state.focusMinutes,
                  onSelected: (_) => state.setFocusMinutes(minutes),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Text(
          'Energy suggests ${state.recommendedFocusMinutes} minutes for your next block.',
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    if (!state.hasFocusProgress) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          key: const ValueKey<String>('focus-reset-dialog'),
          title: const Text('Reset focus session?'),
          content: Text(
            'This will clear your current timer and return it to ${state.focusMinutes} minutes.',
          ),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('focus-reset-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey<String>('focus-reset-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      state.resetTimer();
    }
  }
}

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
    final focusedTodo = state.focusedTodo;
    final totalSeconds = state.focusMinutes * 60;
    final completion = (1 - (state.remainingSeconds / totalSeconds)).clamp(
      0.0,
      1.0,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final ringSize = state.isRunning
            ? (isCompact ? 232.0 : 264.0)
            : (isCompact ? 220.0 : 248.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: AnimatedContainer(
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
                              state.isRunning
                                  ? scheme.primary
                                  : scheme.secondary,
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      width: state.isRunning ? 156 : 148,
                      height: state.isRunning ? 156 : 148,
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
                            state.isRunning
                                ? 'Block in progress'
                                : 'Ready to begin',
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
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    state.isRunning ? 'Locked on' : 'Next up',
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    focusedTodo?.title ??
                        'Choose a task to give this block a destination.',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isRunning
                        ? 'Keep this session simple: one task, one timer, one finish line.'
                        : 'Energy suggests ${state.recommendedFocusMinutes} minutes for your next block.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
                OutlinedButton.icon(
                  key: const ValueKey<String>('focus-reset-button'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: scheme.primary, width: 1.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onPressed: state.hasFocusProgress
                      ? () => _confirmReset(context)
                      : null,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
          ],
        );
      },
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

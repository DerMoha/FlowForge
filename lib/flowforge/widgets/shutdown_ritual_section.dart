import 'package:flutter/material.dart';

import '../state/app_state.dart';

class ShutdownRitualSection extends StatelessWidget {
  const ShutdownRitualSection({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow
                .withValues(alpha: isDark ? 0.7 : 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant
                  .withValues(alpha: isDark ? 0.45 : 0.7),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Close the day with three quick prompts.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _promptField(
                context,
                label: 'Biggest win',
                controller: state.winController,
                hint: 'What moved the needle today?',
              ),
              const SizedBox(height: 12),
              _promptField(
                context,
                label: 'Main friction',
                controller: state.frictionController,
                hint: 'What slowed me down?',
              ),
              const SizedBox(height: 12),
              _promptField(
                context,
                label: 'First move tomorrow',
                controller: state.tomorrowController,
                hint: 'How do I start fast tomorrow morning?',
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Draft Shutdown Note'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.draftShutdownNote,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: state.resetDay,
                    child: const Text('Reset Day'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.shutdownNote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow
                  .withValues(alpha: isDark ? 0.7 : 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant
                    .withValues(alpha: isDark ? 0.45 : 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily Close',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.shutdownNote,
                  style: textTheme.bodyLarge?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _promptField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

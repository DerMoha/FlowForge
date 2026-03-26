import 'package:flutter/material.dart';

import '../models/energy_preset.dart';
import '../state/app_state.dart';
import '../state/project_state.dart';
import 'session_stats_bar.dart';

Future<void> showFocusEnergySheet(BuildContext context, FlowForgeState state) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _EnergySheet(state: state),
  );
}

class ProjectScopeBanner extends StatelessWidget {
  const ProjectScopeBanner({super.key, required this.projectState});

  final ProjectState projectState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeProject = projectState.activeProject;
    if (activeProject == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeProject.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: activeProject.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: activeProject.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activeProject.icon, color: activeProject.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${activeProject.name} is shaping today\'s focus',
                  style: textTheme.titleSmall?.copyWith(
                    color: activeProject.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New captures land in this project until you clear the scope.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => projectState.setActiveProject(null),
            child: const Text('Show all'),
          ),
        ],
      ),
    );
  }
}

class TodayRhythmCard extends StatelessWidget {
  const TodayRhythmCard({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = state.activeEnergyPreset;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Today\'s rhythm',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            state.isRunning
                ? 'You are in a live focus block. Protect it until the timer or task tells you otherwise.'
                : 'Recommended next block: ${state.recommendedFocusMinutes} minutes at ${active.label.toLowerCase()} energy.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SessionStatsBar(state: state),
        ],
      ),
    );
  }
}

class _EnergySheet extends StatelessWidget {
  const _EnergySheet({required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = state.activeEnergyPreset;
    final activeIndex = energyPresets.indexWhere(
      (preset) => preset.value == active.value,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(active.icon, color: active.color, size: 24),
              const SizedBox(width: 12),
              Text(
                'Energy Level',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            active.hint,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _buildBatteryBar(context, activeIndex),
          const SizedBox(height: 16),
          Text(
            '${active.value}% energy',
            style: textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: active.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryBar(BuildContext context, int activeIndex) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: List<Widget>.generate(energyPresets.length, (index) {
                final preset = energyPresets[index];
                final lit = index <= activeIndex;
                final selected = index == activeIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == energyPresets.length - 1 ? 0 : 4,
                    ),
                    child: Tooltip(
                      message: '${preset.label} ${preset.value}%',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            state.setEnergyPreset(preset);
                            Navigator.of(context).pop();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            height: 36,
                            decoration: BoxDecoration(
                              color: lit
                                  ? preset.color.withValues(
                                      alpha: selected ? 0.95 : 0.55,
                                    )
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: lit
                                    ? preset.color.withValues(alpha: 0.85)
                                    : scheme.outlineVariant.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 5,
            height: 18,
            decoration: BoxDecoration(
              color: scheme.outlineVariant.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/energy_preset.dart';
import '../state/app_state.dart';

class EnergyFloatingIndicator extends StatelessWidget {
  const EnergyFloatingIndicator({super.key, required this.state});

  final FlowForgeState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = state.activeEnergyPreset;

    return GestureDetector(
      onTap: () => _showEnergySheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active.color.withValues(alpha: 0.4)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(active.icon, size: 18, color: active.color),
            const SizedBox(width: 6),
            Text(
              active.label,
              style: TextStyle(
                color: active.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnergySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EnergySheet(state: state),
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
      (p) => p.value == active.value,
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
                          key: ValueKey<String>(
                            'energy-preset-${preset.value}',
                          ),
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

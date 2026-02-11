import 'package:flutter/material.dart';

import '../theme/energy_theme.dart';

class AmbientGradientBackground extends StatelessWidget {
  const AmbientGradientBackground({
    super.key,
    required this.energy,
    required this.child,
  });

  final double energy;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final palette = EnergyTheme.palette(energy, brightness);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[palette.gradientStart, palette.gradientEnd],
        ),
      ),
      child: child,
    );
  }
}

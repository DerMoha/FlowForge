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
    final isDark = brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[palette.gradientStart, palette.gradientEnd],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: const Alignment(-1.05, -0.95),
              child: _GlowOrb(
                color: palette.glow.withValues(alpha: isDark ? 0.32 : 0.2),
                size: 240,
              ),
            ),
            Align(
              alignment: const Alignment(1.1, -0.3),
              child: _GlowOrb(
                color: palette.accent.withValues(alpha: isDark ? 0.2 : 0.14),
                size: 220,
              ),
            ),
            Align(
              alignment: const Alignment(0.15, 1.0),
              child: _GlowOrb(
                color: palette.accentStrong.withValues(
                  alpha: isDark ? 0.16 : 0.1,
                ),
                size: 280,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.white.withValues(alpha: isDark ? 0.02 : 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: isDark ? 0.08 : 0.03),
                  ],
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

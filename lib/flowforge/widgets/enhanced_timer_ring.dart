import 'dart:math';
import 'package:flutter/material.dart';

/// Enhanced timer ring with gradient, glow, and trail effects
class EnhancedTimerRing extends StatefulWidget {
  const EnhancedTimerRing({
    super.key,
    required this.progress,
    required this.isRunning,
    this.size = 240,
    this.strokeWidth = 12,
    this.showGlow = true,
    this.showTrail = true,
  });

  final double progress; // 0.0 to 1.0
  final bool isRunning;
  final double size;
  final double strokeWidth;
  final bool showGlow;
  final bool showTrail;

  @override
  State<EnhancedTimerRing> createState() => _EnhancedTimerRingState();
}

class _EnhancedTimerRingState extends State<EnhancedTimerRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final breathingScale = widget.isRunning
            ? 1.0 + (_breathingController.value * 0.015)
            : 1.0;

        return Transform.scale(
          scale: breathingScale,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _TimerRingPainter(
              progress: widget.progress,
              strokeWidth: widget.strokeWidth,
              showGlow: widget.showGlow,
              showTrail: widget.showTrail,
              glowIntensity: widget.isRunning ? 0.8 : 0.3,
              primaryColor: Theme.of(context).colorScheme.primary,
              secondaryColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        );
      },
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.showGlow,
    required this.showTrail,
    required this.glowIntensity,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final double strokeWidth;
  final bool showGlow;
  final bool showTrail;
  final double glowIntensity;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background ring
    final backgroundPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (progress > 0) {
      // Gradient for progress arc
      final gradientColors = [
        primaryColor,
        Color.lerp(primaryColor, secondaryColor, 0.5)!,
        secondaryColor,
      ];

      final sweepAngle = 2 * pi * progress;
      final startAngle = -pi / 2;

      // Draw trail effect (fading gradient behind indicator)
      if (showTrail && progress > 0.1) {
        final trailPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: startAngle,
            endAngle: startAngle + sweepAngle,
            colors: [
              ...gradientColors.map((c) => c.withValues(alpha: 0.3)),
              gradientColors.last.withValues(alpha: 0.8),
            ],
            transform: const GradientRotation(-pi / 2),
          ).createShader(rect);

        canvas.drawArc(rect, startAngle, sweepAngle, false, trailPaint);
      }

      // Main progress arc with gradient
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: gradientColors,
          transform: const GradientRotation(-pi / 2),
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // Glow effect
      if (showGlow) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: gradientColors
                .map((c) => c.withValues(alpha: glowIntensity * 0.3))
                .toList(),
            transform: const GradientRotation(-pi / 2),
          ).createShader(rect)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth / 2);

        canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
      }

      // Indicator dot at current position
      final indicatorAngle = startAngle + sweepAngle;
      final indicatorX = center.dx + radius * cos(indicatorAngle);
      final indicatorY = center.dy + radius * sin(indicatorAngle);
      final indicatorPosition = Offset(indicatorX, indicatorY);

      // Outer glow for indicator
      if (showGlow) {
        final indicatorGlowPaint = Paint()
          ..color = secondaryColor.withValues(alpha: glowIntensity * 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth);

        canvas.drawCircle(
          indicatorPosition,
          strokeWidth * 0.8,
          indicatorGlowPaint,
        );
      }

      // Indicator dot
      final indicatorPaint = Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(indicatorPosition, strokeWidth * 0.5, indicatorPaint);

      // Inner white dot for contrast
      final indicatorInnerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        indicatorPosition,
        strokeWidth * 0.25,
        indicatorInnerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        glowIntensity != oldDelegate.glowIntensity;
  }
}

/// Flip-board style countdown display
class FlipBoardTimer extends StatelessWidget {
  const FlipBoardTimer({
    super.key,
    required this.minutes,
    required this.seconds,
  });

  final int minutes;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FlipBoardDigit(value: minutes ~/ 10),
        const SizedBox(width: 4),
        _FlipBoardDigit(value: minutes % 10),
        const SizedBox(width: 12),
        _FlipBoardSeparator(),
        const SizedBox(width: 12),
        _FlipBoardDigit(value: seconds ~/ 10),
        const SizedBox(width: 4),
        _FlipBoardDigit(value: seconds % 10),
      ],
    );
  }
}

class _FlipBoardDigit extends StatefulWidget {
  const _FlipBoardDigit({required this.value});

  final int value;

  @override
  State<_FlipBoardDigit> createState() => _FlipBoardDigitState();
}

class _FlipBoardDigitState extends State<_FlipBoardDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_FlipBoardDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _previousValue = oldWidget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Previous digit (flipping up)
              if (_controller.isAnimating)
                Positioned.fill(
                  child: Opacity(
                    opacity: 1 - _animation.value,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_animation.value * pi / 2),
                      alignment: Alignment.center,
                      child: Center(
                        child: Text(
                          '$_previousValue',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Current digit (flipping down)
              Positioned.fill(
                child: Opacity(
                  opacity: _controller.isAnimating ? _animation.value : 1.0,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX((_animation.value - 1) * pi / 2),
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        '${widget.value}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlipBoardSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

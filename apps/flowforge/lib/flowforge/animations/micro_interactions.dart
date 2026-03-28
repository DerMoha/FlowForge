import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback patterns
enum HapticPattern { light, medium, heavy, success, warning, error }

/// Haptic feedback service
class HapticService {
  HapticService._();

  static final instance = HapticService._();

  bool _isEnabled = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> trigger(HapticPattern pattern) async {
    if (!_isEnabled) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        // Fallback to system haptics
        _triggerSystemHaptic(pattern);
        return;
      }

      switch (pattern) {
        case HapticPattern.light:
          HapticFeedback.lightImpact();
          break;
        case HapticPattern.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticPattern.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticPattern.success:
          await Vibration.vibrate(duration: 50);
          break;
        case HapticPattern.warning:
          await Vibration.vibrate(pattern: [0, 50, 50, 50]);
          break;
        case HapticPattern.error:
          await Vibration.vibrate(pattern: [0, 100, 50, 100]);
          break;
      }
    } catch (e) {
      // Silently fail if vibration not supported
      debugPrint('Haptic feedback error: $e');
    }
  }

  void _triggerSystemHaptic(HapticPattern pattern) {
    switch (pattern) {
      case HapticPattern.light:
        HapticFeedback.lightImpact();
        break;
      case HapticPattern.medium:
      case HapticPattern.success:
        HapticFeedback.mediumImpact();
        break;
      case HapticPattern.heavy:
      case HapticPattern.warning:
      case HapticPattern.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}

/// Spring animation widget
class SpringAnimation extends StatefulWidget {
  const SpringAnimation({
    super.key,
    required this.child,
    this.initialScale = 0.9,
    this.onPressed,
  });

  final Widget child;
  final double initialScale;
  final VoidCallback? onPressed;

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

/// Pulse ring animation
class PulseRing extends StatefulWidget {
  const PulseRing({
    super.key,
    required this.child,
    this.color,
    this.pulseCount = 3,
  });

  final Widget child;
  final Color? color;
  final int pulseCount;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse rings
        for (var i = 0; i < widget.pulseCount; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = i / widget.pulseCount;
              final progress = (_controller.value + delay) % 1.0;
              final scale = 1.0 + progress * 0.5;
              final opacity = (1.0 - progress) * 0.5;

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: opacity),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        // Center child
        widget.child,
      ],
    );
  }
}

/// Breathing scale animation (subtle pulsing)
class BreathingAnimation extends StatefulWidget {
  const BreathingAnimation({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.015,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

/// Bouncy button with haptic feedback
class BouncyButton extends StatefulWidget {
  const BouncyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.hapticPattern = HapticPattern.light,
  });

  final VoidCallback onPressed;
  final Widget child;
  final HapticPattern hapticPattern;

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTap() {
    HapticService.instance.trigger(widget.hapticPattern);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () => _controller.reverse(),
      onTap: _handleTap,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    final highlightColor =
        widget.highlightColor ??
        theme.colorScheme.surface.withValues(alpha: 0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, _controller.value, 1.0],
              tileMode: TileMode.mirror,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

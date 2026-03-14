import 'dart:math';
import 'package:flutter/material.dart';

/// Particle data for animation
class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  }) : age = 0;

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final double lifetime;
  double age;

  bool get isDead => age >= lifetime;

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    // Apply gravity
    velocity = velocity + const Offset(0, 200) * dt;
  }

  double get alpha {
    final progress = age / lifetime;
    return (1.0 - progress).clamp(0.0, 1.0);
  }
}

/// Particle system widget
class ParticleSystem extends StatefulWidget {
  const ParticleSystem({
    super.key,
    required this.particleCount,
    required this.colors,
    this.duration = const Duration(seconds: 3),
    this.minSize = 4,
    this.maxSize = 12,
    this.emitFromCenter = false,
  });

  final int particleCount;
  final List<Color> colors;
  final Duration duration;
  final double minSize;
  final double maxSize;
  final bool emitFromCenter;

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addListener(() {
      setState(() {
        _updateParticles(_controller.lastElapsedDuration?.inMilliseconds ?? 0);
      });
    });

    _initializeParticles();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    _particles.clear();

    for (var i = 0; i < widget.particleCount; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 100 + _random.nextDouble() * 300;

      _particles.add(
        Particle(
          position: Offset.zero,
          velocity: Offset(
            cos(angle) * speed,
            sin(angle) * speed - 200, // Initial upward velocity
          ),
          color: widget.colors[_random.nextInt(widget.colors.length)],
          size:
              widget.minSize +
              _random.nextDouble() * (widget.maxSize - widget.minSize),
          lifetime: 1.5 + _random.nextDouble() * 1.5,
        ),
      );
    }
  }

  void _updateParticles(int elapsedMs) {
    final dt = elapsedMs / 1000.0;
    for (final particle in _particles) {
      particle.update(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles),
      size: Size.infinite,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.particles);

  final List<Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      if (particle.isDead) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.alpha)
        ..style = PaintingStyle.fill;

      final position = Offset(
        centerX + particle.position.dx,
        centerY + particle.position.dy,
      );

      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// Sparkle trail effect for swipe gestures
class SparkleTrail extends StatefulWidget {
  const SparkleTrail({
    super.key,
    required this.startPosition,
    required this.endPosition,
    this.color = Colors.amber,
  });

  final Offset startPosition;
  final Offset endPosition;
  final Color color;

  @override
  State<SparkleTrail> createState() => _SparkleTrailState();
}

class _SparkleTrailState extends State<SparkleTrail>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _sparklePositions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _generateSparkles();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateSparkles() {
    final random = Random();
    final steps = 10;

    for (var i = 0; i < steps; i++) {
      final t = i / steps;
      final position = Offset.lerp(
        widget.startPosition,
        widget.endPosition,
        t,
      )!;

      // Add some randomness
      final offset = Offset(
        (random.nextDouble() - 0.5) * 20,
        (random.nextDouble() - 0.5) * 20,
      );

      _sparklePositions.add(position + offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SparkleTrailPainter(
            _sparklePositions,
            widget.color,
            _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SparkleTrailPainter extends CustomPainter {
  _SparkleTrailPainter(this.positions, this.color, this.progress);

  final List<Offset> positions;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < positions.length; i++) {
      final sparkleProgress = (progress - (i / positions.length)).clamp(
        0.0,
        1.0,
      );
      if (sparkleProgress <= 0) continue;

      final alpha = (1.0 - sparkleProgress);
      final sparkleSize = 6.0 * sparkleProgress;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Draw star shape
      final path = Path();
      for (var j = 0; j < 5; j++) {
        final angle = (j * 2 * pi / 5) - pi / 2;
        final outerRadius = sparkleSize;
        final innerRadius = sparkleSize / 2;

        final outerX = positions[i].dx + cos(angle) * outerRadius;
        final outerY = positions[i].dy + sin(angle) * outerRadius;

        if (j == 0) {
          path.moveTo(outerX, outerY);
        } else {
          path.lineTo(outerX, outerY);
        }

        final innerAngle = angle + (pi / 5);
        final innerX = positions[i].dx + cos(innerAngle) * innerRadius;
        final innerY = positions[i].dy + sin(innerAngle) * innerRadius;
        path.lineTo(innerX, innerY);
      }
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkleTrailPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Ambient floating particles
class AmbientParticles extends StatefulWidget {
  const AmbientParticles({
    super.key,
    this.particleCount = 25,
    this.color = Colors.white,
  });

  final int particleCount;
  final Color color;

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_AmbientParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _initializeParticles();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    for (var i = 0; i < widget.particleCount; i++) {
      _particles.add(
        _AmbientParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 1 + _random.nextDouble() * 3,
          speed: 0.1 + _random.nextDouble() * 0.2,
          phase: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AmbientParticlesPainter(
            _particles,
            widget.color,
            _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AmbientParticle {
  _AmbientParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
}

class _AmbientParticlesPainter extends CustomPainter {
  _AmbientParticlesPainter(this.particles, this.color, this.time);

  final List<_AmbientParticle> particles;
  final Color color;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final xOffset = sin(time * 2 * pi * particle.speed + particle.phase) * 30;
      final yOffset = cos(time * 2 * pi * particle.speed + particle.phase) * 30;

      final x = particle.x * size.width + xOffset;
      final y = particle.y * size.height + yOffset;

      final alpha = (sin(time * 2 * pi + particle.phase) * 0.3 + 0.4).clamp(
        0.0,
        1.0,
      );

      final paint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_AmbientParticlesPainter oldDelegate) =>
      time != oldDelegate.time;
}

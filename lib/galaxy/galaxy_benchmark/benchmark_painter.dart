part of '../galaxy_benchmark_page.dart';


// Custom painter: particles plus optional fragment shaders.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

class _GalaxyPainter extends CustomPainter {
  _GalaxyPainter({
    required this.particles,
    required this.visibleParticleCount,
    required this.visualEffect,
    required ValueListenable<int> ticker,
    required this.useFragmentShaders,
    this.nebulaProgram,
    this.auroraProgram,
  }) : _ticker = ticker,
       super(repaint: ticker);

  final Float32List particles;
  final int visibleParticleCount;
  final GalaxyVisualEffect visualEffect;
  final bool useFragmentShaders;
  final FragmentProgram? nebulaProgram;
  final FragmentProgram? auroraProgram;
  final ValueListenable<int> _ticker;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final scale = math.min(size.width, size.height) * 0.46;
    final time = _ticker.value / 60.0;

    _drawBaseSpace(canvas, rect);
    switch (visualEffect) {
      case GalaxyVisualEffect.nebula:
        _drawNebula(canvas, size, scale, time);
      case GalaxyVisualEffect.starWarp:
        _drawStarWarp(canvas, center, scale, time);
      case GalaxyVisualEffect.gravitationalLens:
        _drawGravitationalLens(canvas, center, scale, time);
      case GalaxyVisualEffect.aurora:
        _drawAurora(canvas, size, time);
      case GalaxyVisualEffect.riskHeatmap:
        _drawRiskHeatmap(canvas, center, scale, time);
      case GalaxyVisualEffect.deviceFingerprint:
        _drawDeviceFingerprintField(canvas, center, scale, time);
    }

    final visibleValueCount = math.min(
      particles.length,
      visibleParticleCount * galaxyParticleStride,
    );

    for (
      var offset = 0;
      offset < visibleValueCount;
      offset += galaxyParticleStride
    ) {
      final x = particles[offset].toDouble();
      final y = particles[offset + 1].toDouble();
      final vx = particles[offset + 2].toDouble();
      final vy = particles[offset + 3].toDouble();
      final particleIndex = offset ~/ galaxyParticleStride;
      final projected = _projectGalaxyParticle(
        x: x,
        y: y,
        particleIndex: particleIndex,
        center: center,
        scale: scale,
        time: time,
      );
      final depth = _fractional((particleIndex + 1) * 0.38196601125);
      final warmth = _fractional((particleIndex + 1) * 0.2360679775);
      final speed = math.min(math.sqrt((vx * vx) + (vy * vy)) * 20, 1.0);
      final glowColor = _particleColor(
        depth: depth,
        warmth: warmth,
        speed: speed,
        particleIndex: particleIndex,
      );
      final radius = lerpDouble(0.45, 1.18, depth)! + speed * 0.18;

      if (visualEffect == GalaxyVisualEffect.starWarp) {
        final radial = projected - center;
        final distance = radial.distance;
        if (distance > 0) {
          final direction = radial / distance;
          canvas.drawLine(
            projected - direction * (6 + speed * 18),
            projected + direction * (2 + speed * 5),
            Paint()
              ..color = glowColor.withValues(alpha: 0.16)
              ..strokeWidth = 1.2 + speed
              ..strokeCap = StrokeCap.round,
          );
        }
      }

      canvas.drawCircle(
        projected,
        radius * 2.1,
        Paint()..color = glowColor.withValues(alpha: 0.045),
      );
      canvas.drawCircle(projected, radius, Paint()..color = glowColor);
    }
  }

  void _drawBaseSpace(Canvas canvas, Rect rect) {
    final backgroundPaint =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF02040A),
              Color(0xFF06101A),
              Color(0xFF10121F),
            ],
          ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);
  }

  void _drawNebula(Canvas canvas, Size size, double scale, double time) {
    final program = useFragmentShaders ? nebulaProgram : null;
    if (program != null) {
      final shader =
          program.fragmentShader()
            ..setFloat(0, size.width) // uSize.x
            ..setFloat(1, size.height) // uSize.y
            ..setFloat(2, time) // uTime
            ..setFloat(3, scale); // uScale
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
      return;
    }

    // Software fallback (original gradient implementation)
    final firstCenter = Offset(
      size.width * (0.30 + math.sin(time * 0.18) * 0.04),
      size.height * (0.42 + math.cos(time * 0.14) * 0.04),
    );
    final secondCenter = Offset(
      size.width * (0.72 + math.cos(time * 0.11) * 0.03),
      size.height * (0.62 + math.sin(time * 0.16) * 0.03),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFF64D2FF).withValues(alpha: 0.18),
            const Color(0xFFB6F08A).withValues(alpha: 0.07),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.34, 1.0],
        ).createShader(Rect.fromCircle(center: firstCenter, radius: scale)),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFD37A).withValues(alpha: 0.10),
            const Color(0xFF7C8CFF).withValues(alpha: 0.06),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.38, 1.0],
        ).createShader(Rect.fromCircle(center: secondCenter, radius: scale)),
    );
  }

  void _drawStarWarp(Canvas canvas, Offset center, double scale, double time) {
    for (var index = 0; index < 96; index++) {
      final seed = _fractional((index + 1) * 0.75487766625);
      final angle = (seed * math.pi * 2) + time * 0.08;
      final distance = scale * (0.16 + _fractional(seed * 7.13 + time * 0.18));
      final direction = Offset(math.cos(angle), math.sin(angle));
      final start = center + direction * (distance - 10);
      final end = center + direction * (distance + 18 + seed * 34);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(
            0xFFBDEBFF,
          ).withValues(alpha: 0.06 + seed * 0.10)
          ..strokeWidth = 0.8 + seed * 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawGravitationalLens(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    canvas.drawCircle(
      center,
      scale * 0.32,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFFFFF).withValues(alpha: 0.13),
            const Color(0xFF7FDBFF).withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: scale * 0.42)),
    );
    for (var ring = 0; ring < 3; ring++) {
      canvas.drawCircle(
        center,
        scale * (0.18 + ring * 0.12 + math.sin(time * 0.5 + ring) * 0.008),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFDDF7FF).withValues(alpha: 0.10),
      );
    }
  }

  void _drawAurora(Canvas canvas, Size size, double time) {
    final program = useFragmentShaders ? auroraProgram : null;
    if (program != null) {
      final shader =
          program.fragmentShader()
            ..setFloat(0, size.width) // uSize.x
            ..setFloat(1, size.height) // uSize.y
            ..setFloat(2, time); // uTime
      canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
      return;
    }

    // Software fallback (original polyline implementation)
    final colors = <Color>[
      const Color(0xFF6EF2B8),
      const Color(0xFF69D3FF),
      const Color(0xFFB692FF),
    ];
    for (var ribbon = 0; ribbon < colors.length; ribbon++) {
      final path = Path();
      for (var step = 0; step <= 24; step++) {
        final x = size.width * (step / 24);
        final y =
            size.height * (0.28 + ribbon * 0.13) +
            math.sin(step * 0.72 + time * (0.45 + ribbon * 0.12)) * 28 +
            math.cos(step * 0.31 + time * 0.30) * 16;
        if (step == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20 - ribbon * 3
          ..strokeCap = StrokeCap.round
          ..color = colors[ribbon].withValues(alpha: 0.11),
      );
    }
  }

  void _drawRiskHeatmap(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    for (var ring = 1; ring <= 4; ring++) {
      canvas.drawCircle(
        center,
        scale * ring * 0.22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9EE493).withValues(alpha: 0.10),
      );
    }
    final sweep = math.pi * 0.58;
    final start = -math.pi / 2 + time * 0.22;
    final zones = <({double radius, Color color, double offset})>[
      (radius: 0.34, color: const Color(0xFF9EE493), offset: 0),
      (radius: 0.58, color: const Color(0xFFFFD166), offset: 0.52),
      (radius: 0.82, color: const Color(0xFFFF5C7A), offset: 1.04),
    ];
    for (final zone in zones) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: scale * zone.radius),
        start + zone.offset,
        sweep,
        true,
        Paint()..color = zone.color.withValues(alpha: 0.10),
      );
    }
    canvas.drawLine(
      center,
      center + Offset(math.cos(start), math.sin(start)) * scale * 0.88,
      Paint()
        ..color = const Color(0xFFB6F08A).withValues(alpha: 0.24)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawDeviceFingerprintField(
    Canvas canvas,
    Offset center,
    double scale,
    double time,
  ) {
    final arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7FDBFF).withValues(alpha: 0.12);
    for (var ring = 0; ring < 7; ring++) {
      final width = scale * (0.38 + ring * 0.13);
      final height = scale * (0.24 + ring * 0.09);
      final rect = Rect.fromCenter(
        center: center + Offset(math.sin(time * 0.2 + ring) * 5, 0),
        width: width,
        height: height,
      );
      canvas.drawArc(
        rect,
        -math.pi * 0.86 + ring * 0.13,
        math.pi * 1.45,
        false,
        arcPaint,
      );
    }

    for (var index = 0; index < 34; index++) {
      final seed = _fractional((index + 1) * 0.61803398875);
      final angle = seed * math.pi * 2;
      final radius = scale * (0.18 + _fractional(seed * 5.77) * 0.72);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        1.3,
        Paint()..color = const Color(0xFFBDEBFF).withValues(alpha: 0.30),
      );
    }
  }

  Offset _projectGalaxyParticle({
    required double x,
    required double y,
    required int particleIndex,
    required Offset center,
    required double scale,
    required double time,
  }) {
    final rawRadius = math.sqrt((x * x) + (y * y));
    final normalizedRadius = (rawRadius / 1.18).clamp(0.0, 1.0).toDouble();
    var radius = (0.08 + normalizedRadius * 0.96) * scale;
    var angle = math.atan2(y, x);

    angle += time * 0.22;
    angle += (1.0 - normalizedRadius) * 2.85;
    angle += (particleIndex % 3) * 0.11;
    angle += math.sin(particleIndex * 0.071) * 0.05;

    if (visualEffect == GalaxyVisualEffect.gravitationalLens) {
      final lens = ((0.42 - normalizedRadius) / 0.42).clamp(0.0, 1.0);
      angle += lens * lens * math.sin(time * 0.7) * 0.16;
      radius *= 1.0 + lens * 0.10;
    }

    if (visualEffect == GalaxyVisualEffect.starWarp) {
      radius *= 1.0 + math.sin(time * 2.0 + particleIndex) * 0.015;
    }

    final projected = Offset(
      math.cos(angle) * radius,
      math.sin(angle) * radius * 0.68,
    );
    return center + projected;
  }

  Color _particleColor({
    required double depth,
    required double warmth,
    required double speed,
    required int particleIndex,
  }) {
    if (visualEffect == GalaxyVisualEffect.riskHeatmap) {
      final risk = _fractional((particleIndex + 1) * 0.17320508075);
      final color =
          risk > 0.72
              ? const Color(0xFFFF5C7A)
              : risk > 0.44
              ? const Color(0xFFFFD166)
              : const Color(0xFF9EE493);
      return color.withValues(alpha: 0.28 + depth * 0.30);
    }

    if (visualEffect == GalaxyVisualEffect.deviceFingerprint) {
      return HSLColor.fromAHSL(
        0.24 + depth * 0.34,
        lerpDouble(178, 205, depth)!,
        0.64,
        (0.58 + speed * 0.10).clamp(0.0, 1.0),
      ).toColor();
    }

    if (visualEffect == GalaxyVisualEffect.aurora) {
      return HSLColor.fromAHSL(
        0.20 + depth * 0.30,
        lerpDouble(148, 286, _fractional(depth + warmth))!,
        0.62,
        (0.58 + speed * 0.10).clamp(0.0, 1.0),
      ).toColor();
    }

    final hue = warmth > 0.88 ? 42.0 : lerpDouble(198, 228, depth)!;
    final saturation = warmth > 0.88 ? 0.74 : lerpDouble(0.26, 0.56, depth)!;
    final lightness = lerpDouble(0.54, 0.82, depth)!;
    return HSLColor.fromAHSL(
      0.18 + (depth * 0.28),
      hue,
      saturation,
      (lightness + speed * 0.08).clamp(0.0, 1.0),
    ).toColor();
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter oldDelegate) {
    return !identical(oldDelegate.particles, particles) ||
        oldDelegate.visibleParticleCount != visibleParticleCount ||
        oldDelegate.visualEffect != visualEffect ||
        oldDelegate.useFragmentShaders != useFragmentShaders ||
        oldDelegate.nebulaProgram != nebulaProgram ||
        oldDelegate.auroraProgram != auroraProgram;
  }
}

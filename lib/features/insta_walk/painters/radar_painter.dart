// File location:
// lib/features/insta_walk/painters/radar_painter.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadarPainter extends CustomPainter {
  final double progress;

  RadarPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double radius =
        math.min(size.width, size.height) * .40;

    // ==========================================================
    // RADAR RINGS
    // ==========================================================

    final Paint rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF65D6C8)
          .withValues(alpha: .32);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * i / 3,
        rings,
      );
    }

    // ==========================================================
    // PULSE
    // ==========================================================

    final double pulse =
        radius * (.35 + progress * .65);

    final Paint pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF8FFFEF)
          .withValues(
            alpha: (1 - progress) * .65,
          );

    canvas.drawCircle(
      center,
      pulse,
      pulsePaint,
    );

    // ==========================================================
    // RADAR SWEEP
    // ==========================================================

    final double angle =
        progress * math.pi * 2;

    final Paint sweep = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 1.0,
        endAngle: angle,
        colors: [
          const Color(0xFF65D6C8)
              .withValues(alpha: 0),
          const Color(0xFF8FFFEF)
              .withValues(alpha: .55),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      sweep,
    );
  }

  @override
  bool shouldRepaint(
    covariant RadarPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

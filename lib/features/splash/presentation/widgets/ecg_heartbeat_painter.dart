import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class EcgHeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  EcgHeartbeatPainter({
    required this.progress,
    this.color = AppColors.primaryRed,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final Path fullPath = Path();
    fullPath.moveTo(0, centerY);

    // Flat start
    fullPath.lineTo(width * 0.32, centerY);

    // P-wave (small upward bump)
    fullPath.cubicTo(
      width * 0.35, centerY - (height * 0.12),
      width * 0.37, centerY - (height * 0.12),
      width * 0.39, centerY,
    );

    // Flat delay
    fullPath.lineTo(width * 0.43, centerY);

    // QRS Complex (Deep Q, High R spike, S dip)
    fullPath.lineTo(width * 0.45, centerY + (height * 0.18)); // Q dip
    fullPath.lineTo(width * 0.49, centerY - (height * 0.85)); // R spike
    fullPath.lineTo(width * 0.53, centerY + (height * 0.30)); // S dip
    fullPath.lineTo(width * 0.56, centerY);                   // Return to baseline

    // Flat segment before T wave
    fullPath.lineTo(width * 0.60, centerY);

    // T-wave (medium recovery bump)
    fullPath.cubicTo(
      width * 0.64, centerY - (height * 0.22),
      width * 0.68, centerY - (height * 0.22),
      width * 0.72, centerY,
    );

    // Flat end segment
    fullPath.lineTo(width, centerY);

    // Calculate drawn path length according to progress
    final Path metricsPath = Path();
    for (final PathMetric metric in fullPath.computeMetrics()) {
      final double extractLength = metric.length * progress.clamp(0.0, 1.0);
      final Path extracted = metric.extractPath(0.0, extractLength);
      metricsPath.addPath(extracted, Offset.zero);

      // Draw glowing lead dot at the animated tip
      if (progress > 0 && progress < 1.0) {
        final Tangent? tangent = metric.getTangentForOffset(extractLength);
        if (tangent != null) {
          final Offset tipPosition = tangent.position;

          // Glowing outer halo
          final Paint haloPaint = Paint()
            ..color = color.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawCircle(tipPosition, 8.0, haloPaint);

          // Lead point dot
          final Paint dotPaint = Paint()
            ..color = color
            ..style = PaintingStyle.fill;
          canvas.drawCircle(tipPosition, 4.0, dotPaint);
        }
      }
    }

    // Paint the ECG line
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(metricsPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant EcgHeartbeatPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Illustrative (not-to-scale) circle visualization of the employee's
/// position relative to the office geofence boundary.
class GeofenceRadar extends StatelessWidget {
  const GeofenceRadar({
    super.key,
    required this.officeRadiusMeters,
    required this.isWithinRange,
  });

  final double officeRadiusMeters;
  final bool isWithinRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _RadarPainter(
                        markerColor: isWithinRange
                            ? AppColors.success
                            : AppColors.rejected,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 28, top: 22),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Office · ${officeRadiusMeters.round()} m limit',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.markerColor});

  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 6);
    final radius = math.min(size.width, size.height) / 2 - 24;

    _drawDashedCircle(canvas, center, radius);

    final fillPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(center, 7, fillPaint);
    canvas.drawCircle(
      center,
      14,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );

    final markerOffset =
        center +
        Offset(
          radius * 1.45 * math.cos(-0.5),
          radius * 1.45 * math.sin(-0.5),
        );

    _drawDottedLine(canvas, center, markerOffset);

    canvas.drawCircle(
      markerOffset,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      markerOffset,
      9,
      Paint()
        ..color = markerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(markerOffset, 3.5, Paint()..color = markerColor);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dashCount = 40;
    const dashFraction = 0.6;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * dashFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawDottedLine(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 2;
    const dashLength = 4.0;
    final distance = (end - start).distance;
    final dashCount = (distance / (dashLength * 2)).floor();
    final direction = (end - start) / distance;
    for (var i = 0; i < dashCount; i++) {
      final from = start + direction * (i * dashLength * 2);
      final to = from + direction * dashLength;
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.markerColor != markerColor;
}

import 'dart:math';
import 'package:flutter/material.dart';

/// Custom painter to render a compass with a wind-direction needle.
class CompassPainter extends CustomPainter {
  final int windDeg;
  final double deviceHeading;

  CompassPainter({required this.windDeg, required this.deviceHeading});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    final needlePaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, circlePaint);

    final relativeAngle = ((windDeg - deviceHeading) - 90) * pi / 180;
    final needleLength = radius * 0.9;

    final needleEnd = Offset(
      center.dx + needleLength * cos(relativeAngle),
      center.dy + needleLength * sin(relativeAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    void drawCardinal(String label, Offset offset) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, offset);
    }

    drawCardinal('N', Offset(center.dx - 8, center.dy - radius + 4));
    drawCardinal('S', Offset(center.dx - 8, center.dy + radius - 20));
    drawCardinal('E', Offset(center.dx + radius - 16, center.dy - 8));
    drawCardinal('W', Offset(center.dx - radius + 4, center.dy - 8));
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.windDeg != windDeg ||
        oldDelegate.deviceHeading != deviceHeading;
  }
}

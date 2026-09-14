import 'package:flutter/material.dart';

/// Compact single-series polyline used for trend previews and mini charts.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  final double strokeWidth;

  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 36,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _SparklinePainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 3.0;
    final innerHeight = size.height - pad * 2;

    if (values.length < 2) {
      final y = size.height / 2;
      final p = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = strokeWidth;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      return;
    }

    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV).abs();

    double yFor(double value) =>
        pad + (1 - ((value - minV) / range)) * innerHeight;

    final dx = size.width / (values.length - 1);
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * dx;
      final y = yFor(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = Offset(size.width, yFor(values.last));
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
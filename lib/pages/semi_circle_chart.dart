
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SemiCircleChart extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final double size;
  final bool showPercentage;

  const SemiCircleChart({
    Key? key,
    required this.value,
    required this.label,
    required this.color,
    this.size = 120,
    this.showPercentage = true,
  }) : super(key: key);

  Color _getColorByValue(double value) {
    if (value >= 80) return Color(0xFF4CAF50); // Green
    if (value >= 60) return Color(0xFF8BC34A); // Light Green
    if (value >= 40) return Color(0xFFFFC107); // Yellow
    if (value >= 20) return Color(0xFFFF9800); // Orange
    return Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.7,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size(size, size * 0.6),
              painter: SemiCirclePainter(
                value: value,
                color: color != Colors.transparent ? color : _getColorByValue(value),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (showPercentage)
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color != Colors.transparent ? color : _getColorByValue(value),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double value;
  final Color color;

  SemiCirclePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;

    // Background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (value / 100) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );

    // Center value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height - 10,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WellnessGaugeChart extends StatelessWidget {
  final double value;
  final double size;

  const WellnessGaugeChart({
    Key? key,
    required this.value,
    this.size = 150,
  }) : super(key: key);

  Color _getColorByValue(double value) {
    if (value >= 80) return Color(0xFF4CAF50); // Green
    if (value >= 60) return Color(0xFF8BC34A); // Light Green
    if (value >= 40) return Color(0xFFFFC107); // Yellow
    if (value >= 20) return Color(0xFFFF9800); // Orange
    return Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.8,
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size(size, size * 0.7),
              painter: WellnessGaugePainter(
                value: value,
                color: _getColorByValue(value),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Wellness Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}',
            style: TextStyle(
              color: _getColorByValue(value),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class WellnessGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  WellnessGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 15;

    // Background semi-circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    // Progress semi-circle (colored based on score)
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (value / 100) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      progressPaint,
    );

    // Center score text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${value.toStringAsFixed(0)}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height - 5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';

/// A cloud with falling rain, readable at the table's small icon size.
class RainWeatherIcon extends StatelessWidget {
  const RainWeatherIcon({super.key, required this.color, this.heavy = false});
  final Color color;
  final bool heavy;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 19,
    child: CustomPaint(painter: _RainPainter(color, heavy)),
  );
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.color, this.heavy);
  final Color color;
  final bool heavy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()..color = color;
    final cloud = Path()
      ..moveTo(5, 14)
      ..cubicTo(0, 14, 0, 7, 5, 7)
      ..cubicTo(6, 0, 16, 0, 18, 7)
      ..cubicTo(24, 6, 25, 14, 19, 14)
      ..close();
    canvas.drawPath(cloud, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (final x in heavy ? [6.0, 12.0, 18.0] : [8.0, 16.0]) {
      canvas.drawLine(Offset(x, 17), Offset(x - 2, 21), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      color != oldDelegate.color || heavy != oldDelegate.heavy;
}

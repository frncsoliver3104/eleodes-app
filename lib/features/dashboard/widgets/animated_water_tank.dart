import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaterTank extends StatefulWidget {
  const AnimatedWaterTank({super.key, required this.percentage, this.flowRate});

  final double? percentage;

  /// Firebase's projected liters per day at the current flow, not today's total.
  final double? flowRate;

  @override
  State<AnimatedWaterTank> createState() => _AnimatedWaterTankState();
}

class _AnimatedWaterTankState extends State<AnimatedWaterTank>
    with TickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final AnimationController _fill = AnimationController(
    vsync: this,
    value: _level,
    duration: const Duration(milliseconds: 900),
  );
  bool _reduceMotion = false;

  static bool _hasValidPercentage(double? percentage) =>
      percentage != null &&
      percentage.isFinite &&
      percentage >= 0 &&
      percentage <= 100;

  bool get _hasLevel => _hasValidPercentage(widget.percentage);

  double get _level => _hasLevel ? widget.percentage! / 100 : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _wave.stop();
      _fill.value = _level;
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedWaterTank oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      if (_reduceMotion ||
          !_hasLevel ||
          !_hasValidPercentage(oldWidget.percentage)) {
        _fill.stop();
        _fill.value = _level;
      } else {
        _fill.animateTo(_level, curve: Curves.easeInOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.flowRate;
    final rateText = rate != null && rate.isFinite && rate >= 0
        ? rate.toStringAsFixed(1)
        : '--';
    return Semantics(
      label:
          '${_hasLevel ? 'Tank level ${widget.percentage!.round()} percent' : 'Tank level unavailable'}. '
          'Estimated daily production rate ${rateText == '--' ? 'unavailable' : '$rateText liters per day at the current flow'}.',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: 125,
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x806B8F80), Color(0x80B8F5DB)],
                      ),
                    ),
                  ),
                  CustomPaint(painter: _TankPainter(_wave, _fill)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Est. daily rate',
                            style: TextStyle(fontSize: 10, color: Colors.black),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: rateText,
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' L/day',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFF00BE87), width: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TankPainter extends CustomPainter {
  _TankPainter(this.wave, this.fill)
    : super(repaint: Listenable.merge([wave, fill]));

  final Animation<double> wave;
  final Animation<double> fill;

  @override
  void paint(Canvas canvas, Size size) {
    final level = fill.value;
    if (level <= 0) return;
    final paint = Paint()..color = const Color(0xFF1DE3AB);
    if (level >= 1) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    final surface = size.height * (1 - level);
    final amplitude = 4.0 * math.min(1.0, math.min(level, 1 - level) * 10);
    for (var layer = 0; layer < 2; layer++) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += 1) {
        final phase = wave.value * 2 * math.pi * (layer == 0 ? 1 : -1);
        final y =
            surface +
            math.sin(x / size.width * 2 * math.pi + phase + layer) * amplitude;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
      paint.color = layer == 0
          ? const Color(0x9900BE87)
          : const Color(0xFF1DE3AB);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TankPainter oldDelegate) =>
      oldDelegate.wave != wave || oldDelegate.fill != fill;
}

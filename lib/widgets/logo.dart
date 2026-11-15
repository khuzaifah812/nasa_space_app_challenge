import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The AgriSmart mark: a ring of four seasons turning around a seedling.
/// The same drawing is in assets/logo.svg.
class AgriSmartLogo extends StatelessWidget {
  const AgriSmartLogo({super.key, this.size = 120, this.onGreen = true});
  final double size;

  /// True when drawn on the green brand colour, false on a light surface.
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AgriSmart logo',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _LogoPainter(onGreen)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.onGreen);
  final bool onGreen;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 120; // the mark is drawn on a 120 grid
    final c = size.center(Offset.zero);
    final strong = onGreen ? Colors.white : const Color(0xFF1F5A3A);
    final soft = onGreen ? const Color(0xFFBFE0CB) : const Color(0xFF8FC3A3);

    // four arcs, one per season of a two-year rotation
    final ring = Rect.fromCircle(center: c, radius: 46 * u);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
          ring,
          -math.pi / 2 + i * math.pi / 2 + 0.2,
          math.pi / 2 - 0.4,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 13 * u
            ..strokeCap = StrokeCap.round
            ..color = i.isEven ? strong : soft);
    }

    // seedling: a stem and two leaves
    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * u
      ..strokeCap = StrokeCap.round
      ..color = strong;
    canvas.drawLine(c + Offset(0, 24 * u), c + Offset(0, -6 * u), stem);
    Path leaf(double dir) => Path()
      ..moveTo(c.dx, c.dy + 2 * u)
      ..quadraticBezierTo(c.dx + dir * 6 * u, c.dy - 22 * u, c.dx + dir * 26 * u, c.dy - 22 * u)
      ..quadraticBezierTo(c.dx + dir * 24 * u, c.dy - 2 * u, c.dx, c.dy + 2 * u)
      ..close();
    canvas.drawPath(leaf(1), Paint()..color = strong);
    canvas.drawPath(leaf(-1), Paint()..color = soft);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.onGreen != onGreen;
}

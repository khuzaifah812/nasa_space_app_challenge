import 'package:flutter/material.dart';

/// A small trend line with no axes.
class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: CustomPaint(
          painter: _SparkPainter(values, Theme.of(context).colorScheme.primary)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.first, hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = hi == lo
          ? size.height / 2
          : 3 + (size.height - 6) * (1 - (values[i] - lo) / span);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
}

/// One bar per year with a straight trend line through them.
class YearBars extends StatelessWidget {
  const YearBars({super.key, required this.years, required this.values, required this.unit});
  final List<int> years;
  final List<double> values;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Bar chart, one bar per year from ${years.first} to ${years.last}.',
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: _BarsPainter(years, values, unit, scheme.primary,
              scheme.onSurface, scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.years, this.values, this.unit, this.bar, this.line, this.label);
  final List<int> years;
  final List<double> values;
  final String unit;
  final Color bar;
  final Color line;
  final Color label;

  void _text(Canvas canvas, String s, Offset at, {bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: label, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, right ? at - Offset(tp.width, 0) : at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    const top = 18.0, bottom = 16.0;
    final h = size.height - top - bottom;
    var hi = 0.0, lo = 0.0;
    for (final v in values) {
      if (v > hi) hi = v;
      if (v < lo) lo = v;
    }
    if (hi - lo == 0) hi = lo + 1;
    final slot = size.width / n;
    double y(double v) => top + h * (1 - (v - lo) / (hi - lo));

    final paint = Paint()..color = bar;
    for (var i = 0; i < n; i++) {
      final a = y(values[i]), b = y(0);
      canvas.drawRect(
          Rect.fromLTRB(i * slot + slot * 0.15, a < b ? a : b,
              (i + 1) * slot - slot * 0.15, a < b ? b : a),
          paint);
    }
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)),
        Paint()..color = label..strokeWidth = 1);

    if (n >= 5) {
      final mx = (n - 1) / 2;
      var my = 0.0;
      for (final v in values) {
        my += v / n;
      }
      var num = 0.0, den = 0.0;
      for (var i = 0; i < n; i++) {
        num += (i - mx) * (values[i] - my);
        den += (i - mx) * (i - mx);
      }
      final slope = den == 0 ? 0.0 : num / den;
      canvas.drawLine(
          Offset(slot / 2, y(my - slope * mx)),
          Offset(size.width - slot / 2, y(my + slope * (n - 1 - mx))),
          Paint()
            ..color = line
            ..strokeWidth = 2);
    }
    _text(canvas, 'Highest: ${hi.toStringAsFixed(hi < 10 ? 1 : 0)} $unit', Offset.zero);
    _text(canvas, '${years.first}', Offset(0, size.height - 14));
    _text(canvas, '${years.last}', Offset(size.width, size.height - 14), right: true);
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.values != values || old.label != label;
}

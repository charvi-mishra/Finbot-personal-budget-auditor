import 'package:flutter/material.dart';

/// Piggy bank icon drawn with Flutter Canvas - no external asset required.
/// Shows a cute pink piggy bank with coins scattered around it.
class PiggyBankIcon extends StatelessWidget {
  final double size;
  final bool animate;

  const PiggyBankIcon({super.key, this.size = 60, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PiggyPainter(),
      ),
    );
  }
}

class _PiggyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle (optional subtle glow)
    final bgPaint = Paint()
      ..color = const Color(0xFFFF6B35).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    final bodyPaint = Paint()
      ..color = const Color(0xFFFFB7C5)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFFFF85A1)
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    final coinGold = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final coinEdge = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;

    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.58),
        width: w * 0.72,
        height: h * 0.58,
      ),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(Offset(w * 0.72, h * 0.38), w * 0.22, bodyPaint);

    // Ear
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.72, h * 0.18),
        width: w * 0.14,
        height: h * 0.16,
      ),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.72, h * 0.19),
        width: w * 0.08,
        height: h * 0.09,
      ),
      darkPaint,
    );

    // Snout
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.84, h * 0.44),
        width: w * 0.18,
        height: h * 0.13,
      ),
      darkPaint,
    );

    // Nostrils
    canvas.drawCircle(Offset(w * 0.80, h * 0.44), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.44), w * 0.025, eyePaint);

    // Eye
    canvas.drawCircle(Offset(w * 0.76, h * 0.33), w * 0.035, eyePaint);
    // Eye shine
    canvas.drawCircle(
      Offset(w * 0.77, h * 0.32),
      w * 0.012,
      Paint()..color = Colors.white,
    );

    // Legs (4 short stumps)
    final legPaint = Paint()..color = const Color(0xFFFFB7C5);
    for (int i = 0; i < 4; i++) {
      final lx = w * (0.22 + i * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(lx, h * 0.86), width: w * 0.1, height: h * 0.12),
          Radius.circular(w * 0.04),
        ),
        legPaint,
      );
    }

    // Tail (curly)
    final tailPath = Path()
      ..moveTo(w * 0.12, h * 0.62)
      ..cubicTo(w * 0.02, h * 0.58, w * 0.0, h * 0.5, w * 0.06, h * 0.46)
      ..cubicTo(w * 0.12, h * 0.42, w * 0.14, h * 0.5, w * 0.1, h * 0.54);
    canvas.drawPath(
      tailPath,
      Paint()
        ..color = const Color(0xFFFF85A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );

    // Coin slot on top of body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(w * 0.42, h * 0.32), width: w * 0.18, height: h * 0.04),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = const Color(0xFF1A1A2E).withOpacity(0.3),
    );

    // Gold coin (entering slot)
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.42, h * 0.25), width: w * 0.14, height: h * 0.1),
      coinGold,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.42, h * 0.25), width: w * 0.14, height: h * 0.1),
      coinEdge,
    );
    // $ on coin
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: const Color(0xFFDAA520),
          fontSize: w * 0.07,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.37, h * 0.21));

    // Scattered coins around (different currencies)
    _drawCoin(canvas, w * 0.08, h * 0.22, w * 0.09, '\$', coinGold, coinEdge);
    _drawCoin(canvas, w * 0.18, h * 0.75, w * 0.08, '€', coinGold, coinEdge);
    _drawCoin(canvas, w * 0.88, h * 0.72, w * 0.09, '£', coinGold, coinEdge);
  }

  void _drawCoin(Canvas canvas, double cx, double cy, double r, String symbol,
      Paint fill, Paint edge) {
    canvas.drawCircle(Offset(cx, cy), r, fill);
    canvas.drawCircle(Offset(cx, cy), r, edge);
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: const Color(0xFFDAA520),
          fontSize: r * 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - r * 0.4, cy - r * 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

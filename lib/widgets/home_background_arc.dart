import 'package:flutter/material.dart';

class HomeBackgroundArc extends StatelessWidget {
  final bool compact;
  const HomeBackgroundArc({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        painter: _ArcPainter(compact: compact),
        child: const SizedBox.expand(),
      ),
    );

  }
}

class _ArcPainter extends CustomPainter {
  final bool compact;
  _ArcPainter({required this.compact});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFFDF7ED);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final arcPaint = Paint()..color = const Color(0xFFC9D4B1);

    final center = Offset(
      size.width * 0.50,
      compact ? size.height * 0.70 : size.height * 0.82,
    );

    final radius = compact ? size.width * 0.92 : size.width * 0.68;

    canvas.drawCircle(center, radius, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

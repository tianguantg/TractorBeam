import 'package:flutter/material.dart';

class TapeWidget extends StatelessWidget {
  final double width;
  final double height;

  const TapeWidget({super.key, this.width = 110, this.height = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD6C8AF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: const Color(0xFF9E8F76).withValues(alpha: 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: CustomPaint(painter: _TapeTexturePainter()),
    );
  }
}

class _TapeTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB5A489).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    // Subtle diagonal hatching for masking tape texture
    for (double x = -size.height; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

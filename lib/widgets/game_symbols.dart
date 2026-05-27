import 'package:flutter/material.dart';
import 'dart:ui';

class GameX extends StatelessWidget {
  final double size;

  const GameX({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: XPainter()),
    );
  }
}

class XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00B4FF), Color(0xFF0066FF)],
      ).createShader(rect)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = const Color(0x5500B4FF)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), glow);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), glow);

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class GameO extends StatelessWidget {
  final double size;

  const GameO({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: OPainter()),
    );
  }
}

class OPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB347), Color(0xFFFF5E00)],
      ).createShader(rect)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    final glow = Paint()
      ..color = const Color(0x55FF7A00)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      glow,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WinLinePainter extends CustomPainter {
  final List<int> line;
  final double progress;
  final int boardSize;

  WinLinePainter(this.line, this.progress, this.boardSize);

  @override
  void paint(Canvas canvas, Size size) {
    ///  FIXED SAFE CELL SIZE
    double cell = size.width / boardSize;
    Offset getOffset(int index) {
      int row = index ~/ boardSize;
      int col = index % boardSize;
      return Offset(col * cell + cell / 2, row * cell + cell / 2);
    }

    Offset start = getOffset(line.first);
    Offset end = getOffset(line.last);
    Offset current = Offset.lerp(start, end, progress)!;

    final glowPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.7)
      ..strokeWidth = cell * 0.3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = cell * 0.15
      ..strokeCap = StrokeCap.round;

    /// DRAW
    canvas.drawLine(start, current, glowPaint);
    canvas.drawLine(start, current, linePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';

class GamePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final double cellSize;
  final int gridSize;
  final bool isGameOver;
  final Offset direction;

  GamePainter({
    required this.snake,
    required this.food,
    required this.cellSize,
    required this.gridSize,
    required this.isGameOver,
    required this.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        canvas.drawRect(
          Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
          gridPaint,
        );
      }
    }

    final foodPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        food.dx * cellSize,
        food.dy * cellSize,
        cellSize,
        cellSize,
      ),
      foodPaint,
    );

    final snakePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (var segment in snake) {
      canvas.drawRect(
        Rect.fromLTWH(
          segment.dx * cellSize,
          segment.dy * cellSize,
          cellSize,
          cellSize,
        ),
        snakePaint,
      );
    }

    if (snake.isNotEmpty) {
      final head = snake.first;
      final eyePaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      final eyeSize = cellSize / 5;
      final padding = cellSize / 4;

      if (direction.dx > 0) {
        _drawEye(canvas, eyePaint, head.dx * cellSize + cellSize - 2 * eyeSize,
            head.dy * cellSize + padding, eyeSize);
        _drawEye(canvas, eyePaint, head.dx * cellSize + cellSize - 2 * eyeSize,
            head.dy * cellSize + cellSize - padding - eyeSize, eyeSize);
      } else if (direction.dx < 0) {
        _drawEye(canvas, eyePaint, head.dx * cellSize + eyeSize,
            head.dy * cellSize + padding, eyeSize);
        _drawEye(canvas, eyePaint, head.dx * cellSize + eyeSize,
            head.dy * cellSize + cellSize - padding - eyeSize, eyeSize);
      } else if (direction.dy > 0) {
        _drawEye(canvas, eyePaint, head.dx * cellSize + padding,
            head.dy * cellSize + cellSize - 2 * eyeSize, eyeSize);
        _drawEye(
            canvas,
            eyePaint,
            head.dx * cellSize + cellSize - padding - eyeSize,
            head.dy * cellSize + cellSize - 2 * eyeSize,
            eyeSize);
      } else {
        _drawEye(canvas, eyePaint, head.dx * cellSize + padding,
            head.dy * cellSize + eyeSize, eyeSize);
        _drawEye(
            canvas,
            eyePaint,
            head.dx * cellSize + cellSize - padding - eyeSize,
            head.dy * cellSize + eyeSize,
            eyeSize);
      }
    }
  }

  void _drawEye(Canvas canvas, Paint paint, double x, double y, double size) {
    canvas.drawOval(
      Rect.fromLTWH(x, y, size, size),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

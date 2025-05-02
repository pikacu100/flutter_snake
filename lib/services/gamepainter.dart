import 'package:flutter/material.dart';

class GamePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final double cellSize;
  final int gridSize;
  final bool isGameOver;

  GamePainter({
    required this.snake,
    required this.food,
    required this.cellSize,
    required this.gridSize,
    required this.isGameOver,
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


    final firstSnakeSegmentPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (var segment in snake) {
      if (segment == snake.first) {
        canvas.drawRect(
          Rect.fromLTWH(
            segment.dx * cellSize,
            segment.dy * cellSize,
            cellSize,
            cellSize,
          ),
          firstSnakeSegmentPaint,
        );
        continue;
      }
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_snake/services/snakepainter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  final int gridSize = 20;

  int score = 0;
  int highScore = 0;
  bool isHighScore = false;
  final prefs = SharedPreferences.getInstance();

  late double cellSize;
  late double gameAreaSize;

  List<Offset> snake = [const Offset(10, 10)];
  Offset food = const Offset(5, 5);
  Offset direction = const Offset(1, 0);
  bool? hitWall;

  bool isGameOver = false;
  Timer? _gameTimer;
  bool isPaused = false;

  Timer? _countdownTimer;
  int _countdown = 3;
  bool _showCountdown = false;

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    startCountdown();
  }

  void restartGame() {
    startCountdown();
  }

  void startCountdown() {
    snake = [Offset((gridSize ~/ 2).toDouble(), (gridSize ~/ 2).toDouble())];
    direction = const Offset(1, 0);
    generateFood();
    isGameOver = false;
    isPaused = false;
    hitWall = null;
    score = 0;

    _countdown = 3;
    _showCountdown = true;
    setState(() {});

    _countdownTimer?.cancel();
    _gameTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        _showCountdown = false;
        timer.cancel();
        _startGameTimer();
      }
    });
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (isGameOver || isPaused) return;
      moveSnake();
    });
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void generateFood() {
    setState(() {
      score++;
    });
    final random = Random();
    food = Offset(
      random.nextInt(gridSize).toDouble(),
      random.nextInt(gridSize).toDouble(),
    );

    while (snake.contains(food)) {
      food = Offset(
        random.nextInt(gridSize).toDouble(),
        random.nextInt(gridSize).toDouble(),
      );
    }
  }

  void moveSnake() {
    if (isGameOver || isPaused) return;

    setState(() {
      double newX = snake.first.dx + direction.dx;
      double newY = snake.first.dy + direction.dy;

      if (newX < 0 || newX >= gridSize || newY < 0 || newY >= gridSize) {
        _handleDeath(hitWall: true);
        return;
      }

      Offset newHead = Offset(newX, newY);

      if (snake.contains(newHead)) {
        _handleDeath(hitWall: false);
        return;
      }

      snake.insert(0, newHead);

      if (newHead == food) {
        generateFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void changeDirection(Offset newDirection) {
    if (direction.dx != -newDirection.dx || direction.dy != -newDirection.dy) {
      direction = newDirection;
    }
  }

  void _handleDeath({required bool hitWall}) async {
    isGameOver = true;
    _gameTimer?.cancel();

    final SharedPreferences sharedPreferences = await prefs;
    final int previousHighScore = sharedPreferences.getInt('high_score') ?? 0;
    if (score > previousHighScore) {
      highScore = score;
      await sharedPreferences.setInt('high_score', score);
      isHighScore = true;
    } else {
      highScore = previousHighScore;
      isHighScore = false;
    }

    setState(() {
      this.hitWall = hitWall;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight - 200;

          cellSize = min(maxWidth, maxHeight) / gridSize;
          gameAreaSize = cellSize * gridSize;

          return Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "$score",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: cellSize * 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: cellSize),
                    GestureDetector(
                      onTap: togglePause,
                      child: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: cellSize * 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: gameAreaSize,
                      height: gameAreaSize,
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          if (details.delta.dy > 0) {
                            changeDirection(const Offset(0, 1));
                          } else if (details.delta.dy < 0) {
                            changeDirection(const Offset(0, -1));
                          }
                        },
                        onHorizontalDragUpdate: (details) {
                          if (details.delta.dx > 0) {
                            changeDirection(const Offset(1, 0));
                          } else if (details.delta.dx < 0) {
                            changeDirection(const Offset(-1, 0));
                          }
                        },
                        child: CustomPaint(
                          painter: GamePainter(
                            snake: snake,
                            food: food,
                            cellSize: cellSize,
                            gridSize: gridSize,
                            isGameOver: isGameOver,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          IconButton(
                            icon:
                                Icon(Icons.arrow_upward, size: cellSize * 1.5),
                            onPressed: () =>
                                changeDirection(const Offset(0, -1)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back,
                                    size: cellSize * 1.5),
                                onPressed: () =>
                                    changeDirection(const Offset(-1, 0)),
                              ),
                              SizedBox(width: cellSize * 2),
                              IconButton(
                                icon: Icon(Icons.arrow_forward,
                                    size: cellSize * 1.5),
                                onPressed: () =>
                                    changeDirection(const Offset(1, 0)),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_downward,
                                size: cellSize * 1.5),
                            onPressed: () =>
                                changeDirection(const Offset(0, 1)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPaused && !isGameOver)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PAUSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cellSize * 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: cellSize),
                          TextButton(
                            onPressed: togglePause,
                            child: Text(
                              'RESUME',
                              style: TextStyle(fontSize: cellSize),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (isGameOver)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hitWall == true
                                ? 'GAME OVER\nHIT THE WALL!'
                                : 'GAME OVER\nATE YOURSELF!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cellSize * 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: cellSize),
                          if (isHighScore)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'NEW HIGH SCORE!',
                                  style: TextStyle(
                                    color: Colors.yellow,
                                    fontSize: cellSize * 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: cellSize),
                              ],
                            ),
                          Text(
                            'SCORE: $score',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cellSize * 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isHighScore)
                            Text(
                              'HIGH SCORE: $highScore',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: cellSize * 0.75,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          SizedBox(height: cellSize),
                          TextButton(
                            onPressed: startCountdown,
                            child: Text(
                              'RESTART',
                              style: TextStyle(
                                  fontSize: cellSize, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_showCountdown)
                Center(
                  child: Text(
                    '$_countdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: cellSize * 3,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

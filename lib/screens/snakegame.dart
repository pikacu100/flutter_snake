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
  bool isGameStarted = false;

  Timer? _countdownTimer;
  int _countdown = 3;
  bool _showCountdown = false;

  bool _showSettings = false;
  double volumeLevel = 0.5;
  bool isEasy = true;
  bool isMedium = false;
  bool isHard = false;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _loadSettings();
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

  void _loadHighScore() async {
    final SharedPreferences sharedPreferences = await prefs;
    highScore = sharedPreferences.getInt('high_score') ?? 0;
  }

  void startCountdown() {
    isGameStarted = true;
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

  void _handleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });

    if (!_showSettings) {
      _saveSettings();
    } else {
      _loadSettings();
    }
  }

  void _saveSettings() async {
    final SharedPreferences sharedPreferences = await prefs;
    await sharedPreferences.setDouble('volume_level', volumeLevel);
    await sharedPreferences.setBool('is_easy', isEasy);
    await sharedPreferences.setBool('is_medium', isMedium);
    await sharedPreferences.setBool('is_hard', isHard);
  }

  void _resetSettings() async {
    final SharedPreferences sharedPreferences = await prefs;
    await sharedPreferences.setDouble('volume_level', 0.5);
    await sharedPreferences.setBool('is_easy', true);
    await sharedPreferences.setBool('is_medium', false);
    await sharedPreferences.setBool('is_hard', false);
    setState(() {
      volumeLevel = 0.5;
      isEasy = true;
      isMedium = false;
      isHard = false;
    });
  }

  void _loadSettings() async {
    final SharedPreferences sharedPreferences = await prefs;
    setState(() {
      volumeLevel = sharedPreferences.getDouble('volume_level') ?? 0.5;
      isEasy = sharedPreferences.getBool('is_easy') ?? true;
      isMedium = sharedPreferences.getBool('is_medium') ?? false;
      isHard = sharedPreferences.getBool('is_hard') ?? false;
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
                            direction: direction,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildArrowButton(
                            Icons.arrow_upward,
                            () => changeDirection(const Offset(0, -1)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildArrowButton(
                                Icons.arrow_back,
                                () => changeDirection(const Offset(-1, 0)),
                              ),
                              SizedBox(width: cellSize * 2),
                              _buildArrowButton(
                                Icons.arrow_forward,
                                () => changeDirection(const Offset(1, 0)),
                              ),
                            ],
                          ),
                          _buildArrowButton(Icons.arrow_downward,
                              () => changeDirection(const Offset(0, 1))),
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
                              style: TextStyle(
                                  fontSize: cellSize, color: Colors.white),
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
              if (isGameOver || !isGameStarted)
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
                            isGameStarted
                                ? hitWall == true
                                    ? 'GAME OVER\nHIT THE WALL!'
                                    : 'GAME OVER\nATE YOURSELF!'
                                : 'WELCOME TO SNAKE GAME 🐍',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: cellSize * 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: cellSize),
                          if (isHighScore && isGameStarted)
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
                          if (isGameStarted)
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
                              isGameStarted ? 'RESTART' : 'START',
                              style: TextStyle(
                                  fontSize: cellSize,
                                  color: isGameStarted
                                      ? Colors.red
                                      : Colors.indigo),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: _handleSettings,
                          child: Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: cellSize * 2,
                          ),
                        ),
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
              if (_showSettings) buildSettings()
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(cellSize * 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: cellSize * 1.5,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget buildSettings() {
    return SizedBox(
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
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(cellSize),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(cellSize),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: cellSize * 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: cellSize),
                Row(
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: cellSize),
                    SizedBox(width: cellSize * 0.5),
                    Expanded(
                      child: Slider(
                        value: volumeLevel,
                        onChanged: (value) {
                          setState(() => volumeLevel = value);
                        },
                        activeColor: Colors.indigo,
                        inactiveColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cellSize * 0.5),
                Row(
                  children: [
                    Text(
                      'Difficulty:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: cellSize,
                      ),
                    ),
                    SizedBox(width: cellSize),
                    ToggleButtons(
                      isSelected: [isEasy, isMedium, isHard],
                      onPressed: (index) {
                        setState(() {
                          isEasy = index == 0;
                          isMedium = index == 1;
                          isHard = index == 2;
                        });
                      },
                      borderRadius: BorderRadius.circular(5),
                      borderColor: Colors.grey.shade900,
                      selectedBorderColor: Colors.grey.shade200,
                      borderWidth: 2,
                      fillColor: Colors.indigo,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(cellSize * 0.5),
                          child: Text('Easy',
                              style: TextStyle(
                                  fontSize: cellSize * 0.8,
                                  color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(cellSize * 0.5),
                          child: Text('Medium',
                              style: TextStyle(
                                  fontSize: cellSize * 0.8,
                                  color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(cellSize * 0.5),
                          child: Text('Hard',
                              style: TextStyle(
                                  fontSize: cellSize * 0.8,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: cellSize),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _handleSettings,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: cellSize * 1.5,
                          vertical: cellSize * 0.5,
                        ),
                      ),
                      child: Text(
                        'SAVE & BACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: cellSize * 0.75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _resetSettings,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: cellSize * 1.5,
                          vertical: cellSize * 0.5,
                        ),
                      ),
                      child: Text(
                        'RESET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: cellSize * 0.75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: HomePage(),
    );
  }
}

enum Direction { up, right, down, left }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _kColumns = 20;
  static const _kRows = 35;
  static const _kSpacing = 3.0;
  static const _numberOfSquares = _kColumns * _kRows;

  static final Random _random = Random();
  static final List<int> _initialSnakePosition = [45, 65, 85, 105, 125];

  late List<int> _snakePosition;
  late int _foodPosition;
  late Direction _direction;

  final FocusNode _focusNode = FocusNode();

  void generateFood() {
    _foodPosition = _random.nextInt(_numberOfSquares);
    if (_snakePosition.contains(_foodPosition)) {
      generateFood();
    }
  }

  void startGame() {
    setState(() {
      _snakePosition = [..._initialSnakePosition];
      _direction = Direction.down;
    });

    generateFood();

    const duration = Duration(milliseconds: 200);
    Timer.periodic(duration, (timer) {
      // Game over: snake hit itself
      final hitItself =
          _snakePosition.sublist(1).contains(_snakePosition.first);

      if (hitItself) {
        timer.cancel();
        _showDialog();
      }

      // Eat food
      if (_snakePosition.last == _foodPosition) {
        generateFood();
        setState(() {
          _snakePosition.insert(0, _snakePosition.first);
        });
      }

      updateSnake();
    });
  }

  void updateDirection(Direction newDirection) {
    if ((newDirection.index - _direction.index).abs() == 2) {
      return;
    }
    setState(() {
      _direction = newDirection;
    });
  }

  void updateSnake() {
    int nextPosition;
    switch (_direction) {
      case Direction.right:
        nextPosition = _snakePosition.last % _kColumns == _kColumns - 1
            ? _snakePosition.last + 1 - _kColumns
            : _snakePosition.last + 1;
        break;
      case Direction.left:
        nextPosition = _snakePosition.last % _kColumns == 0
            ? _snakePosition.last - 1 + _kColumns
            : _snakePosition.last - 1;
        break;
      case Direction.up:
        nextPosition = _snakePosition.last - _kColumns < 0
            ? _numberOfSquares - (_kColumns - _snakePosition.last)
            : _snakePosition.last - _kColumns;
        break;
      case Direction.down:
        nextPosition = _snakePosition.last + _kColumns > _numberOfSquares - 1
            ? _snakePosition.last + _kColumns - _numberOfSquares
            : _snakePosition.last + _kColumns;
        break;
    }

    setState(() {
      _snakePosition.add(nextPosition);
      _snakePosition.removeAt(0);
    });
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(
            'You scored ${_snakePosition.length - _initialSnakePosition.length} points!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              startGame();
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        updateDirection(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        updateDirection(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        updateDirection(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        updateDirection(Direction.right);
      }
    }
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    startGame();
    super.initState();
  }

  @override
  void dispose() {
    // Focus nodes need to be disposed.
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Focus(
                focusNode: _focusNode,
                onKey: _handleKeyEvent,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy > 0) {
                      updateDirection(Direction.down);
                    } else if (details.delta.dy < 0) {
                      updateDirection(Direction.up);
                    }
                  },
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx > 0) {
                      updateDirection(Direction.right);
                    } else if (details.delta.dx < 0) {
                      updateDirection(Direction.left);
                    }
                  },
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _numberOfSquares,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _kColumns,
                      crossAxisSpacing: _kSpacing,
                      mainAxisSpacing: _kSpacing,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                          decoration: BoxDecoration(
                        color: _snakePosition.contains(index)
                            ? Colors.white
                            : _foodPosition == index
                                ? Colors.green
                                : Colors.grey[800],
                        borderRadius: BorderRadius.circular(5.0),
                      ));
                    },
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Score: ${_snakePosition.length - _initialSnakePosition.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

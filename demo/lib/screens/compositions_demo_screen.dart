import 'dart:math' as math;
import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/demo_card.dart';
import '../widgets/clickable_demo.dart';

class CompositionsDemoScreen extends StatelessWidget {
  const CompositionsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complex Compositions'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.3,
        children: const [
          _Match3GameDemo(),
          _CardStackDemo(),
          _PhotoGalleryDemo(),
          _OnboardingFlowDemo(),
        ],
      ),
    );
  }
}

// Tile data class
class GameTile {
  final int id;
  final int color;
  final AnimatableProperty<Offset> position;
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> opacity;
  bool isMatched = false;

  GameTile({
    required this.id,
    required this.color,
    required Offset initialPosition,
  })  : position = animatableOffset(initialPosition),
        scale = animatableDouble(0.0),
        opacity = animatableDouble(1.0);
}

// Match-3 Game Demo
class _Match3GameDemo extends StatefulWidget {
  const _Match3GameDemo();

  @override
  State<_Match3GameDemo> createState() => _Match3GameDemoState();
}

class _Match3GameDemoState extends State<_Match3GameDemo> {
  static const rows = 6;
  static const cols = 6;
  static const tileSize = 45.0;
  static const gap = 4.0;
  static const colors = [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
  ];

  List<List<GameTile?>> grid = [];
  int? selectedRow;
  int? selectedCol;
  int score = 0;
  int moves = 0;
  int movesLeft = 20;
  int targetScore = 500;
  int combo = 0;
  bool isAnimating = false;
  bool gameOver = false;
  bool isAutoPlay = false;
  int nextTileId = 0;

  final random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    grid = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) {
          final tile = _createTile(row, col);
          // Spawn animation
          Future.delayed(Duration(milliseconds: row * 50 + col * 30), () {
            if (mounted) {
              scaleIn(tile.scale, config: const ScaleConfig(duration: 300))
                  .play();
            }
          });
          return tile;
        },
      ),
    );
  }

  GameTile _createTile(int row, int col) {
    return GameTile(
      id: nextTileId++,
      color: random.nextInt(colors.length),
      initialPosition: _getPosition(row, col),
    );
  }

  Offset _getPosition(int row, int col) {
    return Offset(
      col * (tileSize + gap),
      row * (tileSize + gap),
    );
  }

  void _trigger() {
    // Reset game
    setState(() {
      score = 0;
      moves = 0;
      movesLeft = 20;
      combo = 0;
      isAnimating = false;
      gameOver = false;
      selectedRow = null;
      selectedCol = null;
      isAutoPlay = false;
    });
    _initializeGrid();
  }

  void _startAutoPlay() {
    setState(() {
      isAutoPlay = true;
      score = 0;
      moves = 0;
      movesLeft = 20;
      combo = 0;
      isAnimating = false;
      gameOver = false;
      selectedRow = null;
      selectedCol = null;
    });
    _initializeGrid();
    _autoPlay();
  }

  void _autoPlay() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !isAutoPlay) return;

    // Try to make a few moves
    for (var i = 0; i < 5 && isAutoPlay && !gameOver; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || !isAutoPlay) return;

      // Find a random valid swap
      final row = random.nextInt(rows);
      final col = random.nextInt(cols);

      if (row < rows - 1 && !gameOver) {
        await _handleSwap(row, col, row + 1, col, isPlayerMove: false);
      }
    }
  }

  void _onTileTap(int row, int col) {
    if (isAnimating || gameOver || isAutoPlay) return;
    if (grid[row][col] == null) return;

    setState(() {
      if (selectedRow == null && selectedCol == null) {
        // First selection
        selectedRow = row;
        selectedCol = col;
      } else {
        // Second selection - check if adjacent
        final rowDiff = (row - selectedRow!).abs();
        final colDiff = (col - selectedCol!).abs();

        if ((rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)) {
          // Valid adjacent swap
          _handleSwap(selectedRow!, selectedCol!, row, col, isPlayerMove: true);
        } else {
          // Not adjacent - just change selection
          selectedRow = row;
          selectedCol = col;
        }
      }
    });
  }

  Future<void> _handleSwap(int row1, int col1, int row2, int col2,
      {required bool isPlayerMove}) async {
    if (isAnimating) return;
    if (grid[row1][col1] == null || grid[row2][col2] == null) return;

    setState(() {
      isAnimating = true;
      if (isPlayerMove) {
        moves++;
        movesLeft--;
      }
    });

    final tile1 = grid[row1][col1]!;
    final tile2 = grid[row2][col2]!;

    // Animate swap
    final pos1Target = _getPosition(row2, col2);
    final pos2Target = _getPosition(row1, col1);

    final anim1 = animate()
        .to(tile1.position, pos1Target)
        .withDuration(250)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final anim2 = animate()
        .to(tile2.position, pos2Target)
        .withDuration(250)
        .withEasing(Easing.easeInOutCubic)
        .build();

    parallel([anim1, anim2]);

    await Future.delayed(const Duration(milliseconds: 300));

    // Swap in grid
    grid[row1][col1] = tile2;
    grid[row2][col2] = tile1;

    // Check for matches
    final hadMatches = await _processMatches();

    // If no matches and player move, swap back
    if (!hadMatches && isPlayerMove) {
      await Future.delayed(const Duration(milliseconds: 200));

      // Swap back animation
      final swapBackAnim1 = animate()
          .to(tile2.position, pos2Target)
          .withDuration(250)
          .withEasing(Easing.easeInOutCubic)
          .build();

      final swapBackAnim2 = animate()
          .to(tile1.position, pos1Target)
          .withDuration(250)
          .withEasing(Easing.easeInOutCubic)
          .build();

      parallel([swapBackAnim1, swapBackAnim2]);

      await Future.delayed(const Duration(milliseconds: 300));

      // Swap back in grid
      grid[row1][col1] = tile1;
      grid[row2][col2] = tile2;

      // Restore move
      setState(() {
        moves--;
        movesLeft++;
      });
    }

    setState(() {
      isAnimating = false;
      selectedRow = null;
      selectedCol = null;
    });

    // Check game over
    if (movesLeft <= 0) {
      setState(() => gameOver = true);
    }
  }

  Future<bool> _processMatches() async {
    combo = 0;
    var foundMatches = true;
    var hadAnyMatches = false;

    while (foundMatches && mounted) {
      final matches = _findMatches();
      if (matches.isEmpty) {
        foundMatches = false;
        break;
      }

      hadAnyMatches = true;
      combo++;

      // Animate matched tiles out
      for (final pos in matches) {
        final tile = grid[pos.$1][pos.$2];
        if (tile != null) {
          tile.isMatched = true;
          // Zoom out + fade
          zoomOut(tile.scale, tile.opacity).play();
        }
      }

      await Future.delayed(const Duration(milliseconds: 400));

      // Remove matched tiles
      for (final pos in matches) {
        grid[pos.$1][pos.$2] = null;
      }

      // Update score
      setState(() {
        score += matches.length * 10 * combo;
      });

      // Apply gravity
      await _applyGravity();

      // Spawn new tiles
      await _spawnNewTiles();

      await Future.delayed(const Duration(milliseconds: 200));
    }

    return hadAnyMatches;
  }

  List<(int, int)> _findMatches() {
    final matches = <(int, int)>{};

    // Check horizontal matches
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols - 2; col++) {
        final tile1 = grid[row][col];
        final tile2 = grid[row][col + 1];
        final tile3 = grid[row][col + 2];

        if (tile1 != null &&
            tile2 != null &&
            tile3 != null &&
            tile1.color == tile2.color &&
            tile2.color == tile3.color) {
          matches.add((row, col));
          matches.add((row, col + 1));
          matches.add((row, col + 2));
        }
      }
    }

    // Check vertical matches
    for (var row = 0; row < rows - 2; row++) {
      for (var col = 0; col < cols; col++) {
        final tile1 = grid[row][col];
        final tile2 = grid[row + 1][col];
        final tile3 = grid[row + 2][col];

        if (tile1 != null &&
            tile2 != null &&
            tile3 != null &&
            tile1.color == tile2.color &&
            tile2.color == tile3.color) {
          matches.add((row, col));
          matches.add((row + 1, col));
          matches.add((row + 2, col));
        }
      }
    }

    return matches.toList();
  }

  Future<void> _applyGravity() async {
    for (var col = 0; col < cols; col++) {
      // Count empty spaces from bottom
      var emptyCount = 0;
      for (var row = rows - 1; row >= 0; row--) {
        if (grid[row][col] == null) {
          emptyCount++;
        } else if (emptyCount > 0) {
          // Move tile down
          final tile = grid[row][col]!;
          final newRow = row + emptyCount;

          // Animate fall
          final targetPos = _getPosition(newRow, col);
          animate()
              .to(tile.position, targetPos)
              .withDuration(300 + emptyCount * 50)
              .withEasing(Easing.easeInCubic)
              .build()
              .play();

          grid[newRow][col] = tile;
          grid[row][col] = null;
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _spawnNewTiles() async {
    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < rows; row++) {
        if (grid[row][col] == null) {
          final tile = _createTile(row, col);

          // Start above the grid
          tile.position.value = Offset(col * (tileSize + gap), -tileSize);

          // Animate fall
          final targetPos = _getPosition(row, col);
          animate()
              .to(tile.position, targetPos)
              .withDuration(400)
              .withEasing(Easing.easeInOutBounce)
              .build()
              .play();

          // Scale in
          scaleIn(tile.scale, config: const ScaleConfig(duration: 300)).play();

          grid[row][col] = tile;
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  KitoAnimation zoomOut(
      AnimatableProperty<double> scale, AnimatableProperty<double> opacity) {
    return animate()
        .to(scale, 0.0)
        .to(opacity, 0.0)
        .withDuration(300)
        .withEasing(Easing.easeInOutBack)
        .build();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Match-3 Game (Playable!)',
      description:
          'Interactive Candy Crush-style game - Click tiles to swap and match! (click to animate)',
      codeSnippet: '''// Interactive Match-3 Game Features:

// Tile selection with visual feedback
void _onTileTap(int row, int col) {
  if (selectedRow == null) {
    selectedRow = row;
    selectedCol = col; // First selection
  } else {
    // Check if adjacent
    final adjacent = isAdjacent(row, col);
    if (adjacent) {
      await _handleSwap(); // Swap tiles
    }
  }
}

// Swap validation: revert if no match
final hadMatches = await _processMatches();
if (!hadMatches) {
  // Animate swap back
  parallel([swapBackAnim1, swapBackAnim2]);
}

// Cascade combos + gravity physics
await _applyGravity();
await _spawnNewTiles();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => ReactiveBuilder(
        builder: (__) => Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Game board
              Container(
                width: cols * (tileSize + gap) + gap,
                height: rows * (tileSize + gap) + gap,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    // Render all tiles
                    for (var row = 0; row < rows; row++)
                      for (var col = 0; col < cols; col++)
                        if (grid[row][col] != null)
                          _buildTile(grid[row][col]!, row, col),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Stats panel
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statRow(context, 'Score', score.toString(),
                        highlight: score >= targetScore),
                    const SizedBox(height: 8),
                    _statRow(context, 'Target', targetScore.toString()),
                    const SizedBox(height: 8),
                    _statRow(context, 'Moves Left', movesLeft.toString(),
                        highlight: movesLeft <= 3),
                    const SizedBox(height: 12),
                    if (combo > 1)
                      _statRow(context, 'Combo', '${combo}x', highlight: true),
                    const SizedBox(height: 16),

                    // Game state
                    if (gameOver)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: score >= targetScore
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: score >= targetScore
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          score >= targetScore ? '🎉 You Won!' : '💔 Game Over',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: score >= targetScore
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Auto-play button
                    if (!gameOver && !isAutoPlay)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _startAutoPlay,
                          icon: const Icon(Icons.smart_toy, size: 16),
                          label: const Text('Auto-Play'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),

                    if (isAutoPlay)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => isAutoPlay = false),
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('Stop Auto'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                    Text(
                      'How to Play:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _featureText(context, '• Click tiles to select'),
                    _featureText(context, '• Swap adjacent tiles'),
                    _featureText(context, '• Match 3+ same colors'),
                    _featureText(context, '• Reach target score!'),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildTile(GameTile tile, int row, int col) {
    final isSelected = selectedRow == row && selectedCol == col;

    return Positioned(
      left: tile.position.value.dx + gap,
      top: tile.position.value.dy + gap,
      child: GestureDetector(
        onTap: () => _onTileTap(row, col),
        child: Transform.scale(
          scale: tile.scale.value * (isSelected ? 1.1 : 1.0),
          child: Opacity(
            opacity: tile.opacity.value,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: colors[tile.color],
                borderRadius: BorderRadius.circular(4),
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 3,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, isSelected ? 4 : 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: highlight ? Theme.of(context).colorScheme.primary : null,
              ),
        ),
      ],
    );
  }

  Widget _featureText(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

// Card data class
class SwipeCard {
  final String title;
  final String subtitle;
  final Color color;
  final AnimatableProperty<Offset> position;
  final AnimatableProperty<double> rotation;
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> opacity;

  SwipeCard({
    required this.title,
    required this.subtitle,
    required this.color,
  })  : position = animatableOffset(Offset.zero),
        rotation = animatableDouble(0.0),
        scale = animatableDouble(1.0),
        opacity = animatableDouble(1.0);
}

// Card Stack Demo (Tinder-style swipe)
class _CardStackDemo extends StatefulWidget {
  const _CardStackDemo();

  @override
  State<_CardStackDemo> createState() => _CardStackDemoState();
}

class _CardStackDemoState extends State<_CardStackDemo> {
  final cards = <SwipeCard>[];
  int currentIndex = 0;
  Offset? dragStart;
  bool isDragging = false;
  int likesCount = 0;
  int passesCount = 0;

  final cardColors = const [
    Color(0xFFE74C3C), // Red
    Color(0xFF3498DB), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFFF39C12), // Orange
    Color(0xFF9B59B6), // Purple
  ];

  final cardTitles = const [
    'Mountains',
    'Ocean',
    'Forest',
    'Desert',
    'City',
  ];

  final cardSubtitles = const [
    'Adventure awaits',
    'Calm and peaceful',
    'Nature\'s beauty',
    'Vast horizons',
    'Urban exploration',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    cards.clear();
    for (var i = 0; i < 5; i++) {
      cards.add(SwipeCard(
        title: cardTitles[i],
        subtitle: cardSubtitles[i],
        color: cardColors[i],
      ));
    }
    currentIndex = 0;
    likesCount = 0;
    passesCount = 0;
  }

  void _trigger() {
    setState(() {
      _initializeCards();
    });

    // Auto-demo: swipe through cards
    _autoSwipe();
  }

  void _autoSwipe() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || currentIndex >= cards.length) return;

    // Swipe right
    await _swipeCard(true);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted || currentIndex >= cards.length) return;

    // Swipe left
    await _swipeCard(false);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted || currentIndex >= cards.length) return;

    // Swipe right
    await _swipeCard(true);
  }

  void _onPanStart(DragStartDetails details) {
    if (currentIndex >= cards.length) return;
    setState(() {
      dragStart = details.localPosition;
      isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentIndex >= cards.length || dragStart == null) return;

    final card = cards[currentIndex];
    final delta = details.localPosition - dragStart!;

    setState(() {
      card.position.value = delta;
      // Rotation based on horizontal drag (-15 to +15 degrees)
      card.rotation.value = (delta.dx / 200).clamp(-0.26, 0.26); // ~15 degrees
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentIndex >= cards.length) return;

    final card = cards[currentIndex];
    final swipeThreshold = 100.0;

    if (card.position.value.dx.abs() > swipeThreshold) {
      // Complete the swipe
      final swipeRight = card.position.value.dx > 0;
      _swipeCard(swipeRight);
    } else {
      // Snap back
      _snapBack();
    }

    setState(() {
      isDragging = false;
      dragStart = null;
    });
  }

  Future<void> _swipeCard(bool right) async {
    if (currentIndex >= cards.length) return;

    final card = cards[currentIndex];

    setState(() {
      if (right) {
        likesCount++;
      } else {
        passesCount++;
      }
    });

    // Animate card flying off
    final targetX = right ? 400.0 : -400.0;
    final targetRotation = right ? 0.4 : -0.4;

    final swipeAnim = animate()
        .to(card.position, Offset(targetX, -100))
        .to(card.rotation, targetRotation)
        .to(card.opacity, 0.0)
        .withDuration(400)
        .withEasing(Easing.easeInCubic)
        .build();

    swipeAnim.play();

    // Scale up next card
    if (currentIndex + 1 < cards.length) {
      final nextCard = cards[currentIndex + 1];
      final scaleAnim = animate()
          .to(nextCard.scale, 1.0)
          .withDuration(300)
          .withEasing(Easing.easeOutBack)
          .build();
      scaleAnim.play();
    }

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      currentIndex++;
    });
  }

  void _snapBack() {
    if (currentIndex >= cards.length) return;

    final card = cards[currentIndex];

    final snapAnim = animate()
        .to(card.position, Offset.zero)
        .to(card.rotation, 0.0)
        .withDuration(300)
        .withEasing(Easing.easeOutBack)
        .build();

    snapAnim.play();
  }

  @override
  Widget build(BuildContext context) {
    final allSwiped = currentIndex >= cards.length;

    return DemoCard(
      title: 'Card Stack',
      description: 'Tinder-style swipe cards with gesture physics (click to animate)',
      codeSnippet: '''// Gesture-driven card swipe

void _onPanUpdate(DragUpdateDetails details) {
  final delta = details.localPosition - dragStart;

  // Update position
  card.position.value = delta;

  // Rotation based on horizontal drag
  card.rotation.value = (delta.dx / 200)
    .clamp(-0.26, 0.26); // ±15°
}

void _onPanEnd(DragEndDetails details) {
  if (card.position.dx.abs() > threshold) {
    // Swipe complete
    _swipeCard(card.position.dx > 0);
  } else {
    // Snap back with spring
    spring(property: card.position,
           target: Offset.zero).play();
  }
}''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => ReactiveBuilder(
        builder: (__) => Column(
          children: [
            // Card stack
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 360,
                  child: allSwiped
                      ? _buildAllSwiped(context)
                      : Stack(
                          children: [
                            // Future cards (dimmed)
                            for (var i = math.min(
                                    currentIndex + 2, cards.length - 1);
                                i > currentIndex;
                                i--)
                              _buildCard(
                                  context, cards[i], i - currentIndex, false),
                            // Current card (draggable)
                            if (currentIndex < cards.length)
                              _buildCard(context, cards[currentIndex], 0, true),
                          ],
                        ),
                ),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(
                    context,
                    Icons.close,
                    Colors.red,
                    'Pass ($passesCount)',
                    currentIndex < cards.length
                        ? () => _swipeCard(false)
                        : null,
                  ),
                  _actionButton(
                    context,
                    Icons.favorite,
                    Colors.green,
                    'Like ($likesCount)',
                    currentIndex < cards.length ? () => _swipeCard(true) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, SwipeCard card, int depth, bool draggable) {
    final offset = depth * 4.0;
    final scale = 1.0 - (depth * 0.05);

    Widget cardWidget = Transform.translate(
      offset: Offset(0, offset) + card.position.value,
      child: Transform.rotate(
        angle: card.rotation.value,
        child: Transform.scale(
          scale: card.scale.value * scale,
          child: Opacity(
            opacity: card.opacity.value * (1.0 - depth * 0.2),
            child: Container(
              width: 280,
              height: 360,
              decoration: BoxDecoration(
                color: card.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      card.subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (draggable) {
      cardWidget = GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildAllSwiped(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'All cards swiped!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _trigger,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    VoidCallback? onPressed,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color,
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            disabledBackgroundColor: Colors.grey.withOpacity(0.1),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// Photo data class
class Photo {
  final int id;
  final String title;
  final Color color;
  final IconData icon;
  final AnimatableProperty<Offset> position;
  final AnimatableProperty<Size> size;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;

  Photo({
    required this.id,
    required this.title,
    required this.color,
    required this.icon,
    required Offset initialPosition,
    required Size initialSize,
  })  : position = animatableOffset(initialPosition),
        size = animatableSize(initialSize),
        opacity = animatableDouble(1.0),
        scale = animatableDouble(1.0);
}

// Photo Gallery Demo
class _PhotoGalleryDemo extends StatefulWidget {
  const _PhotoGalleryDemo();

  @override
  State<_PhotoGalleryDemo> createState() => _PhotoGalleryDemoState();
}

class _PhotoGalleryDemoState extends State<_PhotoGalleryDemo> {
  static const gridRows = 2;
  static const gridCols = 3;
  static const thumbSize = 80.0;
  static const gap = 8.0;

  List<Photo> photos = [];
  late final Signal<int?> expandedPhotoId;
  late final Signal<bool> isAnimating;

  @override
  void initState() {
    super.initState();
    expandedPhotoId = signal<int?>(null);
    isAnimating = signal<bool>(false);
    _initializePhotos();
  }

  void _initializePhotos() {
    final photoData = [
      ('Mountain', Color(0xFF3498DB), Icons.landscape),
      ('Beach', Color(0xFF1ABC9C), Icons.beach_access),
      ('City', Color(0xFFE74C3C), Icons.location_city),
      ('Forest', Color(0xFF27AE60), Icons.park),
      ('Desert', Color(0xFFF39C12), Icons.wb_sunny),
      ('Snow', Color(0xFFECF0F1), Icons.ac_unit),
    ];

    photos = [];
    for (var i = 0; i < photoData.length; i++) {
      final row = i ~/ gridCols;
      final col = i % gridCols;
      final x = col * (thumbSize + gap);
      final y = row * (thumbSize + gap);

      photos.add(Photo(
        id: i,
        title: photoData[i].$1,
        color: photoData[i].$2,
        icon: photoData[i].$3,
        initialPosition: Offset(x, y),
        initialSize: const Size(thumbSize, thumbSize),
      ));
    }
  }

  void _trigger() {
    if (isAnimating.value) return;

    if (expandedPhotoId.value != null) {
      _collapsePhoto();
    } else {
      _expandPhoto(photos[0].id);
    }
  }

  Future<void> _expandPhoto(int photoId) async {
    if (isAnimating.value || expandedPhotoId.value != null) return;

    isAnimating.value = true;
    expandedPhotoId.value = photoId;

    final photo = photos.firstWhere((p) => p.id == photoId);

    // Calculate fullscreen position and size
    final targetPosition = const Offset(0, 0);
    const targetSize = Size(400, 300); // Fullscreen size for demo container

    // Animate selected photo to fullscreen
    final expandAnim = animate()
        .to(photo.position, targetPosition)
        .to(photo.size, targetSize)
        .withDuration(400)
        .withEasing(Easing.easeInOutCubic)
        .build();

    // Fade out other photos
    final fadeAnims = photos
        .where((p) => p.id != photoId)
        .map((p) => animate()
            .to(p.opacity, 0.0)
            .withDuration(300)
            .withEasing(Easing.easeOutCubic)
            .build())
        .toList();

    parallel([expandAnim, ...fadeAnims]);

    await Future.delayed(const Duration(milliseconds: 400));
    isAnimating.value = false;
  }

  Future<void> _collapsePhoto() async {
    if (isAnimating.value || expandedPhotoId.value == null) return;

    isAnimating.value = true;

    final List<KitoAnimation> animations = [];

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final row = i ~/ gridCols;
      final col = i % gridCols;
      final x = col * (thumbSize + gap);
      final y = row * (thumbSize + gap);

      final collapseAnim = animate()
          .to(photo.position, Offset(x, y))
          .to(photo.size, const Size(thumbSize, thumbSize))
          .to(photo.opacity, 1.0)
          .withDuration(400)
          .withEasing(Easing.easeInOutCubic)
          .build();

      animations.add(collapseAnim);
    }

    parallel(animations);

    await Future.delayed(const Duration(milliseconds: 400));
    isAnimating.value = false;
    expandedPhotoId.value = null;
  }

  void _onPhotoTap(int photoId) {
    if (expandedPhotoId.value == null) {
      _expandPhoto(photoId);
    } else if (expandedPhotoId.value == photoId) {
      _collapsePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Photo Gallery',
      description: 'Shared element transitions (click to animate)',
      codeSnippet: '''
// Expand photo with hero animation
final expandAnim = animate()
    .to(photo.position, targetPosition)
    .to(photo.size, targetSize)
    .withDuration(400)
    .withEasing(Easing.easeInOutCubic)
    .build();

// Fade out other photos
final fadeAnims = otherPhotos
    .map((p) => animate()
        .to(p.opacity, 0.0)
        .withDuration(300)
        .build())
    .toList();

parallel([expandAnim, ...fadeAnims]);
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => ReactiveBuilder(
        builder: (context) {
          return _buildGallery(context);
        },
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: gridCols * (thumbSize + gap) - gap,
          height: gridRows * (thumbSize + gap) - gap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Render photos
              ...photos.map((photo) => _buildPhoto(photo)),

              // Detail view overlay when photo is expanded
              if (expandedPhotoId.value != null)
                _buildDetailOverlay(
                  photos.firstWhere((p) => p.id == expandedPhotoId.value),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(Photo photo) {
    final isExpanded = expandedPhotoId.value == photo.id;
    final shouldShowExpandedContent = isExpanded && !isAnimating.value;

    return Positioned(
      left: photo.position.value.dx,
      top: photo.position.value.dy,
      child: GestureDetector(
        onTap: () => _onPhotoTap(photo.id),
        child: Opacity(
          opacity: photo.opacity.value,
          child: Container(
            width: photo.size.value.width,
            height: photo.size.value.height,
            decoration: BoxDecoration(
              color: photo.color,
              borderRadius: BorderRadius.circular(isExpanded ? 8 : 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isExpanded ? 0.3 : 0.2),
                  blurRadius: isExpanded ? 16 : 4,
                  offset: Offset(0, isExpanded ? 8 : 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  photo.icon,
                  size: isExpanded ? 64 : 32,
                  color: Colors.white.withOpacity(0.9),
                ),
                if (shouldShowExpandedContent) ...[
                  const SizedBox(height: 16),
                  Text(
                    photo.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Tap to close',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailOverlay(Photo photo) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _collapsePhoto,
        child: Container(
          color: Colors.black.withOpacity(0.0),
        ),
      ),
    );
  }
}

// Onboarding page data class
class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AnimatableProperty<Offset> position;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  })  : position = animatableOffset(Offset.zero),
        opacity = animatableDouble(0.0),
        scale = animatableDouble(0.8);
}

// Onboarding Flow Demo
class _OnboardingFlowDemo extends StatefulWidget {
  const _OnboardingFlowDemo();

  @override
  State<_OnboardingFlowDemo> createState() => _OnboardingFlowDemoState();
}

class _OnboardingFlowDemoState extends State<_OnboardingFlowDemo> {
  List<OnboardingPage> pages = [];
  int currentPage = 0;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializePages();
    _showPage(0);
  }

  void _initializePages() {
    pages = [
      OnboardingPage(
        title: 'Welcome',
        description: 'Discover amazing features',
        icon: Icons.waving_hand,
        color: const Color(0xFF3498DB),
      ),
      OnboardingPage(
        title: 'Explore',
        description: 'Find what you love',
        icon: Icons.explore,
        color: const Color(0xFF2ECC71),
      ),
      OnboardingPage(
        title: 'Get Started',
        description: 'Begin your journey',
        icon: Icons.rocket_launch,
        color: const Color(0xFFE74C3C),
      ),
    ];
  }

  void _trigger() {
    if (currentPage < pages.length - 1) {
      _nextPage();
    } else {
      _restart();
    }
  }

  Future<void> _showPage(int index) async {
    if (index < 0 || index >= pages.length) return;

    final page = pages[index];

    final showAnim = animate()
        .to(page.position, Offset.zero)
        .to(page.opacity, 1.0)
        .to(page.scale, 1.0)
        .withDuration(500)
        .withEasing(Easing.easeOutCubic)
        .build();

    showAnim.play();
  }

  Future<void> _nextPage() async {
    if (isAnimating || currentPage >= pages.length - 1) return;

    setState(() => isAnimating = true);

    // Slide current page out to the left
    final currentPageObj = pages[currentPage];
    final slideOutAnim = animate()
        .to(currentPageObj.position, const Offset(-400, 0))
        .to(currentPageObj.opacity, 0.0)
        .withDuration(400)
        .withEasing(Easing.easeInCubic)
        .build();

    slideOutAnim.play();

    await Future.delayed(const Duration(milliseconds: 200));

    // Prepare next page
    setState(() => currentPage++);

    // Reset position for next page (start from right)
    final nextPageObj = pages[currentPage];
    nextPageObj.position.value = const Offset(400, 0);
    nextPageObj.opacity.value = 0.0;
    nextPageObj.scale.value = 0.8;

    await Future.delayed(const Duration(milliseconds: 100));

    // Slide next page in from the right
    final slideInAnim = animate()
        .to(nextPageObj.position, Offset.zero)
        .to(nextPageObj.opacity, 1.0)
        .to(nextPageObj.scale, 1.0)
        .withDuration(500)
        .withEasing(Easing.easeOutCubic)
        .build();

    slideInAnim.play();

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isAnimating = false);
  }

  Future<void> _previousPage() async {
    if (isAnimating || currentPage <= 0) return;

    setState(() => isAnimating = true);

    // Slide current page out to the right
    final currentPageObj = pages[currentPage];
    final slideOutAnim = animate()
        .to(currentPageObj.position, const Offset(400, 0))
        .to(currentPageObj.opacity, 0.0)
        .withDuration(400)
        .withEasing(Easing.easeInCubic)
        .build();

    slideOutAnim.play();

    await Future.delayed(const Duration(milliseconds: 200));

    // Prepare previous page
    setState(() => currentPage--);

    // Reset position for previous page (start from left)
    final prevPageObj = pages[currentPage];
    prevPageObj.position.value = const Offset(-400, 0);
    prevPageObj.opacity.value = 0.0;
    prevPageObj.scale.value = 0.8;

    await Future.delayed(const Duration(milliseconds: 100));

    // Slide previous page in from the left
    final slideInAnim = animate()
        .to(prevPageObj.position, Offset.zero)
        .to(prevPageObj.opacity, 1.0)
        .to(prevPageObj.scale, 1.0)
        .withDuration(500)
        .withEasing(Easing.easeOutCubic)
        .build();

    slideInAnim.play();

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isAnimating = false);
  }

  Future<void> _restart() async {
    if (isAnimating) return;

    setState(() => isAnimating = true);

    // Fade out current page
    final currentPageObj = pages[currentPage];
    final fadeOutAnim = animate()
        .to(currentPageObj.opacity, 0.0)
        .to(currentPageObj.scale, 0.8)
        .withDuration(300)
        .withEasing(Easing.easeInCubic)
        .build();

    fadeOutAnim.play();

    await Future.delayed(const Duration(milliseconds: 300));

    // Reset to first page
    setState(() => currentPage = 0);

    // Reset all pages
    for (var page in pages) {
      page.position.value = Offset.zero;
      page.opacity.value = 0.0;
      page.scale.value = 0.8;
    }

    await Future.delayed(const Duration(milliseconds: 100));

    // Show first page
    _showPage(0);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => isAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Onboarding Flow',
      description: 'Multi-step page transitions (click to animate)',
      codeSnippet: '''
// Slide out current page
final slideOut = animate()
    .to(currentPage.position, Offset(-400, 0))
    .to(currentPage.opacity, 0.0)
    .withDuration(400)
    .build();

// Slide in next page
nextPage.position.value = Offset(400, 0);
final slideIn = animate()
    .to(nextPage.position, Offset.zero)
    .to(nextPage.opacity, 1.0)
    .to(nextPage.scale, 1.0)
    .withDuration(500)
    .withEasing(Easing.easeOutCubic)
    .build();

sequential([slideOut, slideIn]);
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => ReactiveBuilder(
        builder: (context) {
          return _buildOnboarding(context);
        },
        ),
      ),
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page content
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...pages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final page = entry.value;

                  if (index != currentPage) {
                    return const SizedBox.shrink();
                  }

                  return _buildPage(page);
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentPage
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed:
                    currentPage > 0 && !isAnimating ? _previousPage : null,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Back', style: TextStyle(fontSize: 12)),
              ),
              FilledButton(
                onPressed: !isAnimating ? _trigger : null,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  currentPage < pages.length - 1 ? 'Next' : 'Restart',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Transform.translate(
      offset: page.position.value,
      child: Transform.scale(
        scale: page.scale.value,
        child: Opacity(
          opacity: page.opacity.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: page.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  page.icon,
                  size: 48,
                  color: page.color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                page.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: page.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                page.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

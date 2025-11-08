import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/reactive_builder.dart';
import '../widgets/demo_card.dart';

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
        crossAxisCount: 1,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.6,
        children: const [
          _Match3GameDemo(),
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
  int combo = 0;
  bool isAnimating = false;
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
              scaleIn(tile.scale, config: const ScaleConfig(duration: 300)).play();
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
    // Auto-play demo: make random swaps
    score = 0;
    moves = 0;
    combo = 0;
    isAnimating = false;
    _initializeGrid();

    // Simulate some moves
    _autoPlay();
  }

  void _autoPlay() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Try to make a few moves
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;

      // Find a random valid swap
      final row = random.nextInt(rows);
      final col = random.nextInt(cols);

      if (row < rows - 1) {
        await _handleSwap(row, col, row + 1, col);
      }
    }
  }

  Future<void> _handleSwap(int row1, int col1, int row2, int col2) async {
    if (isAnimating) return;
    if (grid[row1][col1] == null || grid[row2][col2] == null) return;

    isAnimating = true;
    moves++;

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
    await _processMatches();

    isAnimating = false;
  }

  Future<void> _processMatches() async {
    combo = 0;
    var foundMatches = true;

    while (foundMatches && mounted) {
      final matches = _findMatches();
      if (matches.isEmpty) {
        foundMatches = false;
        break;
      }

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
              .withEasing(Easing.easeOutBounce)
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

  KitoAnimation zoomOut(AnimatableProperty<double> scale, AnimatableProperty<double> opacity) {
    return animate()
        .to(scale, 0.0)
        .to(opacity, 0.0)
        .withDuration(300)
        .withEasing(Easing.easeInBack)
        .build();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Match-3 Game',
      description: 'Candy Crush-style game with match detection, gravity, and combos',
      onTrigger: _trigger,
      codeSnippet: '''// Combining multiple Kito patterns:
// - Grid shuffle for tile swapping
// - Atomic primitives for match effects
// - Timeline orchestration for cascades
// - Reactive state for score tracking

// Match detection
final matches = _findMatches();

// Animate removal
for (final tile in matches) {
  zoomOut(tile.scale, tile.opacity).play();
}

// Apply gravity + spawn new tiles
await _applyGravity();
await _spawnNewTiles();

// Recursive match checking for cascades''',
      child: ReactiveBuilder(
        builder: (_) => Container(
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
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
                    _statRow(context, 'Score', score.toString()),
                    const SizedBox(height: 12),
                    _statRow(context, 'Moves', moves.toString()),
                    const SizedBox(height: 12),
                    if (combo > 1)
                      _statRow(context, 'Combo', '${combo}x', highlight: true),
                    const SizedBox(height: 20),
                    Text(
                      'Features:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _featureText(context, '• Match 3+ tiles'),
                    _featureText(context, '• Gravity physics'),
                    _featureText(context, '• Cascade combos'),
                    _featureText(context, '• Spawn animations'),
                    const SizedBox(height: 20),
                    Text(
                      'Click ▶ to see auto-play',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
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

  Widget _buildTile(GameTile tile, int row, int col) {
    return Positioned(
      left: tile.position.value.dx + gap,
      top: tile.position.value.dy + gap,
      child: Transform.scale(
        scale: tile.scale.value,
        child: Opacity(
          opacity: tile.opacity.value,
          child: Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              color: colors[tile.color],
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value, {bool highlight = false}) {
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

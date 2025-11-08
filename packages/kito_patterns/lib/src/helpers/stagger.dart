import 'package:kito/kito.dart';

/// Stagger configuration for sequential animations
class StaggerConfig {
  /// Base delay in milliseconds
  final int baseDelay;

  /// Delay multiplier for each subsequent item
  final double delayMultiplier;

  /// Maximum delay cap in milliseconds
  final int? maxDelay;

  /// Direction of stagger
  final StaggerDirection direction;

  /// Easing function for the stagger timing
  final EasingFunction timing;

  const StaggerConfig({
    this.baseDelay = 50,
    this.delayMultiplier = 1.0,
    this.maxDelay,
    this.direction = StaggerDirection.forward,
    this.timing = Easing.linear,
  });

  /// Calculate delay for item at index
  int delayForIndex(int index, int totalItems) {
    final actualIndex = direction == StaggerDirection.reverse
        ? (totalItems - 1 - index)
        : index;

    final rawDelay = (baseDelay * actualIndex * delayMultiplier).round();

    if (maxDelay != null && rawDelay > maxDelay!) {
      return maxDelay!;
    }

    return rawDelay;
  }

  /// Fast stagger (25ms between items)
  static const StaggerConfig fast = StaggerConfig(baseDelay: 25);

  /// Normal stagger (50ms between items)
  static const StaggerConfig normal = StaggerConfig(baseDelay: 50);

  /// Slow stagger (100ms between items)
  static const StaggerConfig slow = StaggerConfig(baseDelay: 100);

  /// Cascade effect (increasing delays)
  static const StaggerConfig cascade = StaggerConfig(
    baseDelay: 30,
    delayMultiplier: 1.2,
    maxDelay: 500,
  );
}

/// Direction for stagger animations
enum StaggerDirection {
  forward,   // 0, 1, 2, 3...
  reverse,   // ...3, 2, 1, 0
}

/// Grid stagger configuration
class GridStaggerConfig {
  /// Stagger by row, column, or diagonal
  final GridStaggerMode mode;

  /// Base delay in milliseconds
  final int baseDelay;

  /// Number of columns in grid
  final int columns;

  /// Maximum delay cap
  final int? maxDelay;

  const GridStaggerConfig({
    this.mode = GridStaggerMode.row,
    this.baseDelay = 40,
    required this.columns,
    this.maxDelay,
  });

  /// Calculate delay for grid position
  int delayForPosition(int index) {
    final row = index ~/ columns;
    final col = index % columns;

    switch (mode) {
      case GridStaggerMode.row:
        return baseDelay * row;

      case GridStaggerMode.column:
        return baseDelay * col;

      case GridStaggerMode.diagonal:
        return baseDelay * (row + col);

      case GridStaggerMode.spiral:
        return _spiralDelay(row, col);

      case GridStaggerMode.random:
        // Use index as seed for consistent randomness
        return (baseDelay * ((index * 7) % 20)).toInt();
    }
  }

  int _spiralDelay(int row, int col) {
    // Simplified spiral calculation
    final distance = row.abs() + col.abs();
    return baseDelay * distance;
  }
}

/// Grid stagger modes
enum GridStaggerMode {
  row,       // Animate by row (left to right, top to bottom)
  column,    // Animate by column (top to bottom, left to right)
  diagonal,  // Animate diagonally
  spiral,    // Spiral from center or corner
  random,    // Random but consistent order
}

/// Helper for creating staggered animations
class StaggerHelper {
  /// Create staggered list animations
  static List<KitoAnimation> createStaggeredList({
    required int count,
    required KitoAnimation Function(int index) animationBuilder,
    StaggerConfig config = const StaggerConfig(),
    bool autoplay = true,
  }) {
    final animations = <KitoAnimation>[];

    for (var i = 0; i < count; i++) {
      final anim = animationBuilder(i);
      final delay = config.delayForIndex(i, count);

      if (autoplay) {
        Future.delayed(Duration(milliseconds: delay), () {
          anim.play();
        });
      }

      animations.add(anim);
    }

    return animations;
  }

  /// Create staggered grid animations
  static List<KitoAnimation> createStaggeredGrid({
    required int count,
    required int columns,
    required KitoAnimation Function(int index) animationBuilder,
    GridStaggerConfig? gridConfig,
    bool autoplay = true,
  }) {
    final config = gridConfig ?? GridStaggerConfig(columns: columns);
    final animations = <KitoAnimation>[];

    for (var i = 0; i < count; i++) {
      final anim = animationBuilder(i);
      final delay = config.delayForPosition(i);

      if (autoplay) {
        Future.delayed(Duration(milliseconds: delay), () {
          anim.play();
        });
      }

      animations.add(anim);
    }

    return animations;
  }

  /// Create wave effect (sine wave delay pattern)
  static List<KitoAnimation> createWaveEffect({
    required int count,
    required KitoAnimation Function(int index) animationBuilder,
    int waveLength = 5,
    int baseDelay = 30,
    bool autoplay = true,
  }) {
    final animations = <KitoAnimation>[];

    for (var i = 0; i < count; i++) {
      final anim = animationBuilder(i);

      // Calculate sine wave delay
      final phase = (i / waveLength) * 3.14159 * 2;
      final multiplier = (1 + (0.5 * (1 + Math.sin(phase))));
      final delay = (baseDelay * multiplier).round();

      if (autoplay) {
        Future.delayed(Duration(milliseconds: delay), () {
          anim.play();
        });
      }

      animations.add(anim);
    }

    return animations;
  }
}

/// Math helpers for wave calculations
class Math {
  static double sin(double x) {
    // Simple sine approximation using Taylor series
    // Good enough for animation timing
    var result = x;
    var term = x;

    for (var i = 1; i <= 5; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }

    return result;
  }
}

import 'dart:math' as math;
import 'package:kito/kito.dart';
import 'drag_shuffle_fsm.dart';

/// Grid-specific configuration for drag-and-shuffle
class DragShuffleGridConfig extends DragShuffleConfig {
  /// Number of columns in the grid
  final int columns;

  /// Item width (for position calculations)
  final double itemWidth;

  /// Item height (for position calculations)
  final double itemHeight;

  /// Horizontal gap between items
  final double horizontalGap;

  /// Vertical gap between items
  final double verticalGap;

  /// Animation mode when items reposition
  final GridRepositionMode repositionMode;

  const DragShuffleGridConfig({
    required this.columns,
    required this.itemWidth,
    required this.itemHeight,
    this.horizontalGap = 8.0,
    this.verticalGap = 8.0,
    this.repositionMode = GridRepositionMode.wave,
    super.repositionDuration = 300,
    super.dropDuration = 250,
    super.repositionEasing = Easing.easeOutCubic,
    super.dropEasing = Easing.easeOutBack,
    super.dragScale = 1.08,
    super.dragOpacity = 0.9,
    super.displaceScale = 0.98,
    super.dragElevation = 8.0,
    super.dragRotation = 3.0,
  });

  /// Calculate total width of a single item (including gap)
  double get itemWidthWithGap => itemWidth + horizontalGap;

  /// Calculate total height of a single item (including gap)
  double get itemHeightWithGap => itemHeight + verticalGap;

  /// Calculate row index from linear index
  int rowFromIndex(int index) => index ~/ columns;

  /// Calculate column index from linear index
  int colFromIndex(int index) => index % columns;

  /// Calculate linear index from row and column
  int indexFromRowCol(int row, int col) => row * columns + col;

  /// Calculate X position for item at index
  double xPositionForIndex(int index) {
    final col = colFromIndex(index);
    return col * itemWidthWithGap;
  }

  /// Calculate Y position for item at index
  double yPositionForIndex(int index) {
    final row = rowFromIndex(index);
    return row * itemHeightWithGap;
  }
}

/// Grid reposition animation modes
enum GridRepositionMode {
  /// All items move simultaneously
  simultaneous,

  /// Items move in a wave pattern
  wave,

  /// Items move based on distance from dragged item
  radial,

  /// Items in same row move first, then others
  rowByRow,

  /// Items in same column move first, then others
  columnByColumn,
}

/// Context for a grid item
class GridItemContext extends DragItemContext {
  /// Grid configuration
  final DragShuffleGridConfig gridConfig;

  /// Absolute X position (for smooth animations without jumps)
  late AnimatableProperty<double> absoluteX;

  /// Absolute Y position (for smooth animations without jumps - overrides parent)
  @override
  late AnimatableProperty<double> absoluteY;

  GridItemContext({
    required this.gridConfig,
    required super.index,
    required super.config,
  }) : super(
          initialY: gridConfig.yPositionForIndex(index),
        ) {
    absoluteX = animatableDouble(gridConfig.xPositionForIndex(index));
    absoluteY = animatableDouble(gridConfig.yPositionForIndex(index));
  }
}

/// Controller for drag-and-shuffle grid with reactive state
class DragShuffleGridController<T> {
  final DragShuffleGridConfig config;
  final void Function(List<T> newOrder)? onReorder;

  /// Current order of items (reactive signal)
  late final Signal<List<T>> _currentOrder;

  /// Animation contexts keyed by item (stable reference)
  final Map<T, GridItemContext> _itemContexts = {};

  /// Reactive signal that increments on every animation frame
  late final Signal<int> _frameCounter;

  int? _draggingIndex;
  int? _targetIndex;

  DragShuffleGridController({
    required this.config,
    this.onReorder,
  }) {
    _currentOrder = signal<List<T>>([]);
    _frameCounter = signal(0);
  }

  /// Get current order of items (reactive)
  List<T> get currentOrder => _currentOrder.value;

  /// Get frame counter for triggering reactive rebuilds
  int get frameCounter => _frameCounter.value;

  /// Initialize grid items
  void initializeItems(List<T> items) {
    _currentOrder.value = List.from(items);
    _itemContexts.clear();

    for (var i = 0; i < items.length; i++) {
      _itemContexts[items[i]] = GridItemContext(
        gridConfig: config,
        index: i,
        config: config,
      );
    }
  }

  /// Get item at visual position
  T getItemAt(int visualIndex) => _currentOrder.value[visualIndex];

  /// Get animation context for an item
  GridItemContext getContext(T item) => _itemContexts[item]!;

  /// Get animation context at visual position
  GridItemContext getContextAt(int visualIndex) =>
      _itemContexts[_currentOrder.value[visualIndex]]!;

  /// Get total number of rows
  int get rowCount => (_currentOrder.value.length / config.columns).ceil();

  /// Start dragging an item at visual position
  void startDrag(int visualIndex) {
    _draggingIndex = visualIndex;
    _targetIndex = visualIndex;

    final item = _currentOrder.value[visualIndex];
    final ctx = _itemContexts[item]!;
    _animateDragStart(ctx);
  }

  /// Update target drop position
  void updateTargetPosition(int newTargetIndex) {
    if (_draggingIndex == null || _targetIndex == newTargetIndex) return;

    final oldTarget = _targetIndex!;
    _targetIndex = newTargetIndex;

    // Animate items to make space for drop
    _animateGridDisplacement(oldTarget, newTargetIndex);
  }

  /// Drop the item - handles reordering internally
  void drop() {
    if (_draggingIndex == null || _targetIndex == null) return;

    final dragIndex = _draggingIndex!;
    final dropIndex = _targetIndex!;

    if (dragIndex != dropIndex) {
      // REORDER INTERNALLY
      final newOrder = List<T>.from(_currentOrder.value);
      final item = newOrder.removeAt(dragIndex);
      newOrder.insert(dropIndex, item);
      _currentOrder.value = newOrder;

      // Update all context indices to match new positions
      for (var i = 0; i < newOrder.length; i++) {
        _itemContexts[newOrder[i]]!.index = i;
        _itemContexts[newOrder[i]]!.targetIndex = i;
      }

      // Notify parent of new order
      onReorder?.call(List.unmodifiable(newOrder));
    }

    final item = _currentOrder.value[dropIndex];
    final ctx = _itemContexts[item]!;
    _animateDrop(ctx, dropIndex);

    _draggingIndex = null;
    _targetIndex = null;
  }

  /// Cancel drag
  void cancelDrag() {
    if (_draggingIndex == null) return;

    final item = _currentOrder.value[_draggingIndex!];
    final ctx = _itemContexts[item]!;
    _animateCancel(ctx);

    _draggingIndex = null;
    _targetIndex = null;
  }

  // Animation helpers

  void _animateDragStart(GridItemContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.scale, config.dragScale)
        .to(ctx.opacity, config.dragOpacity)
        .to(ctx.rotation, config.dragRotation)
        .to(ctx.elevation, config.dragElevation)
        .withDuration(200)
        .withEasing(Easing.easeOutSine)
        .onUpdate((t) => _frameCounter.value++) // Trigger rebuild on each frame
        .build()
      ..play();
  }

  void _animateGridDisplacement(int oldTarget, int newTarget) {
    if (_draggingIndex == null) return;

    final dragIndex = _draggingIndex!;

    // Animate all items to their target positions
    for (var i = 0; i < _currentOrder.value.length; i++) {
      if (i == dragIndex) continue; // Skip the dragged item

      final item = _currentOrder.value[i];
      final ctx = _itemContexts[item]!;

      // Calculate target position based on whether this item needs to make space
      double targetX;
      double targetY;
      bool isDisplaced = false;

      if (dragIndex < newTarget) {
        // Dragging forward: items between drag and target move backward
        if (i > dragIndex && i <= newTarget) {
          final newIndex = i - 1;
          targetX = config.xPositionForIndex(newIndex);
          targetY = config.yPositionForIndex(newIndex);
          isDisplaced = true;
        } else {
          targetX = config.xPositionForIndex(i);
          targetY = config.yPositionForIndex(i);
        }
      } else if (dragIndex > newTarget) {
        // Dragging backward: items between target and drag move forward
        if (i >= newTarget && i < dragIndex) {
          final newIndex = i + 1;
          targetX = config.xPositionForIndex(newIndex);
          targetY = config.yPositionForIndex(newIndex);
          isDisplaced = true;
        } else {
          targetX = config.xPositionForIndex(i);
          targetY = config.yPositionForIndex(i);
        }
      } else {
        targetX = config.xPositionForIndex(i);
        targetY = config.yPositionForIndex(i);
      }

      // Calculate delay based on reposition mode
      final delay = _calculateRepositionDelay(ctx, dragIndex, i);

      ctx.currentAnimation?.dispose();

      // Animate to target position with fade effect for displaced items
      // Note: Only animate position and opacity, NOT scale (to avoid jumps)
      ctx.currentAnimation = animate()
          .to(ctx.absoluteX, targetX)
          .to(ctx.absoluteY, targetY)
          .to(ctx.opacity, isDisplaced ? 0.7 : 1.0)
          .withDelay(delay)
          .withDuration(config.repositionDuration)
          .withEasing(config.repositionEasing)
          .onUpdate((t) => _frameCounter.value++)
          .build()
        ..play();

      // Ensure scale is reset for displaced items
      if (!isDisplaced) {
        ctx.scale.value = 1.0;
      }
    }
  }

  /// Calculate delay based on reposition mode
  int _calculateRepositionDelay(GridItemContext ctx, int draggedIndex, int itemIndex) {
    final draggedRow = config.rowFromIndex(draggedIndex);
    final draggedCol = config.colFromIndex(draggedIndex);
    final itemRow = config.rowFromIndex(itemIndex);
    final itemCol = config.colFromIndex(itemIndex);

    switch (config.repositionMode) {
      case GridRepositionMode.simultaneous:
        return 0;

      case GridRepositionMode.wave:
        // Delay based on Manhattan distance from dragged item
        final distance = (itemRow - draggedRow).abs() + (itemCol - draggedCol).abs();
        return distance * 30;

      case GridRepositionMode.radial:
        // Delay based on Euclidean distance from dragged item
        final dx = (itemCol - draggedCol).toDouble();
        final dy = (itemRow - draggedRow).toDouble();
        final radialDist = math.sqrt(dx * dx + dy * dy);
        return (radialDist * 40).toInt();

      case GridRepositionMode.rowByRow:
        // Same row moves first, then others
        final rowDiff = (itemRow - draggedRow).abs();
        return rowDiff * 50;

      case GridRepositionMode.columnByColumn:
        // Same column moves first, then others
        final colDiff = (itemCol - draggedCol).abs();
        return colDiff * 50;
    }
  }

  void _animateDrop(GridItemContext ctx, int dropIndex) {
    final targetX = config.xPositionForIndex(dropIndex);
    final targetY = config.yPositionForIndex(dropIndex);

    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.absoluteX, targetX)
        .to(ctx.absoluteY, targetY)
        .to(ctx.offsetX, 0.0)
        .to(ctx.offsetY, 0.0)
        .to(ctx.scale, 1.0)
        .to(ctx.opacity, 1.0)
        .to(ctx.rotation, 0.0)
        .to(ctx.elevation, 0.0)
        .withDuration(config.dropDuration)
        .withEasing(config.dropEasing)
        .onUpdate((t) => _frameCounter.value++) // Trigger rebuild on each frame
        .build()
      ..play();

    // Reset other items after drop
    Future.delayed(Duration(milliseconds: config.dropDuration), () {
      for (var i = 0; i < _currentOrder.value.length; i++) {
        final item = _currentOrder.value[i];
        final otherCtx = _itemContexts[item]!;

        // Ensure all items are at their final positions
        otherCtx.absoluteX.value = config.xPositionForIndex(i);
        otherCtx.absoluteY.value = config.yPositionForIndex(i);
        otherCtx.offsetX.value = 0.0;
        otherCtx.offsetY.value = 0.0;
        otherCtx.scale.value = 1.0;
        otherCtx.opacity.value = 1.0;
      }
      _frameCounter.value++; // Final rebuild
    });
  }

  void _animateCancel(GridItemContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.offsetX, 0.0)
        .to(ctx.offsetY, 0.0)
        .to(ctx.scale, 1.0)
        .to(ctx.opacity, 1.0)
        .to(ctx.rotation, 0.0)
        .to(ctx.elevation, 0.0)
        .withDuration(250)
        .withEasing(Easing.easeOutCubic)
        .onUpdate((t) => _frameCounter.value++)
        .build()
      ..play();

    // Reset displaced items
    for (final item in _currentOrder.value) {
      final otherCtx = _itemContexts[item]!;
      if (otherCtx != ctx) {
        otherCtx.currentAnimation?.dispose();
        otherCtx.currentAnimation = animate()
            .to(otherCtx.offsetX, 0.0)
            .to(otherCtx.offsetY, 0.0)
            .to(otherCtx.scale, 1.0)
            .withDuration(250)
            .withEasing(Easing.easeOutCubic)
            .onUpdate((t) => _frameCounter.value++)
            .build()
          ..play();
      }
    }
  }

  /// Dispose all animations
  void dispose() {
    for (final ctx in _itemContexts.values) {
      ctx.currentAnimation?.dispose();
    }
  }
}

import 'dart:math' as math;
import 'package:kito/kito.dart';
import 'package:kito_reactive/kito_reactive.dart';
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

  /// Original row position
  int originalRow;

  /// Original column position
  int originalCol;

  /// Target row position
  int targetRow;

  /// Target column position
  int targetCol;

  GridItemContext({
    required this.gridConfig,
    required int index,
    required DragShuffleConfig config,
  })  : originalRow = gridConfig.rowFromIndex(index),
        originalCol = gridConfig.colFromIndex(index),
        targetRow = gridConfig.rowFromIndex(index),
        targetCol = gridConfig.colFromIndex(index),
        super(
          config: config,
          index: index,
        );

  /// Calculate position offset based on target grid position
  void updateTargetPosition(int newIndex) {
    targetRow = gridConfig.rowFromIndex(newIndex);
    targetCol = gridConfig.colFromIndex(newIndex);
    targetIndex = newIndex;
  }

  /// Get offset X for target position
  double get targetOffsetX {
    final currentX = gridConfig.xPositionForIndex(index);
    final targetX = gridConfig.xPositionForIndex(targetIndex);
    return targetX - currentX;
  }

  /// Get offset Y for target position
  double get targetOffsetY {
    final currentY = gridConfig.yPositionForIndex(index);
    final targetY = gridConfig.yPositionForIndex(targetIndex);
    return targetY - currentY;
  }
}

/// Controller for drag-and-shuffle grid
class DragShuffleGridController {
  final DragShuffleGridConfig config;
  final List<GridItemContext> items = [];
  final void Function(int oldIndex, int newIndex)? onReorder;

  int? _draggingIndex;
  int? _targetIndex;

  DragShuffleGridController({
    required this.config,
    this.onReorder,
  });

  /// Initialize grid items
  void initializeItems(int count) {
    items.clear();
    for (var i = 0; i < count; i++) {
      items.add(GridItemContext(
        gridConfig: config,
        index: i,
        config: config,
      ));
    }
  }

  /// Get item context
  GridItemContext getItem(int index) => items[index];

  /// Get total number of rows
  int get rowCount => (items.length / config.columns).ceil();

  /// Start dragging an item
  void startDrag(int index) {
    _draggingIndex = index;
    _targetIndex = index;

    final item = items[index];
    _animateDragStart(item);
  }

  /// Update drag position (pixel coordinates)
  void updateDragPosition(int index, double offsetX, double offsetY) {
    if (_draggingIndex == null) return;

    final item = items[index];
    item.offsetX.value = offsetX;
    item.offsetY.value = offsetY;

    // Calculate which grid cell the drag is over
    final draggedOverIndex =
        _calculateGridIndexFromOffset(index, offsetX, offsetY);

    if (draggedOverIndex != null && draggedOverIndex != _targetIndex) {
      updateTargetPosition(draggedOverIndex);
    }
  }

  /// Calculate which grid index is being dragged over
  int? _calculateGridIndexFromOffset(
      int draggedIndex, double offsetX, double offsetY) {
    final item = items[draggedIndex];
    final currentRow = item.originalRow;
    final currentCol = item.originalCol;

    // Calculate new position
    final currentX = config.xPositionForIndex(draggedIndex);
    final currentY = config.yPositionForIndex(draggedIndex);

    final newX = currentX + offsetX;
    final newY = currentY + offsetY;

    // Convert to grid coordinates
    final newCol =
        (newX / config.itemWidthWithGap).round().clamp(0, config.columns - 1);
    final newRow =
        (newY / config.itemHeightWithGap).round().clamp(0, rowCount - 1);

    final newIndex = config.indexFromRowCol(newRow, newCol);

    // Make sure index is valid
    if (newIndex >= 0 && newIndex < items.length) {
      return newIndex;
    }

    return null;
  }

  /// Update target drop position
  void updateTargetPosition(int newTargetIndex) {
    if (_draggingIndex == null || _targetIndex == newTargetIndex) return;

    final oldTarget = _targetIndex!;
    _targetIndex = newTargetIndex;

    // Animate items to make space for drop
    _animateGridDisplacement(oldTarget, newTargetIndex);
  }

  /// Drop the item
  void drop() {
    if (_draggingIndex == null || _targetIndex == null) return;

    final dragIndex = _draggingIndex!;
    final dropIndex = _targetIndex!;

    _animateDrop(items[dragIndex], dropIndex);

    // Notify reorder callback
    if (dragIndex != dropIndex) {
      onReorder?.call(dragIndex, dropIndex);
    }

    _draggingIndex = null;
    _targetIndex = null;
  }

  /// Cancel drag
  void cancelDrag() {
    if (_draggingIndex == null) return;

    final item = items[_draggingIndex!];
    _animateCancel(item);

    _draggingIndex = null;
    _targetIndex = null;
  }

  // Animation helpers

  void _animateDragStart(GridItemContext item) {
    item.currentAnimation?.dispose();
    item.currentAnimation = animate()
        .to(item.scale, config.dragScale)
        .to(item.opacity, config.dragOpacity)
        .to(item.rotation, config.dragRotation)
        .to(item.elevation, config.dragElevation)
        .withDuration(200)
        .withEasing(Easing.easeOutSine)
        .build()
      ..play();
  }

  void _animateGridDisplacement(int oldTarget, int newTarget) {
    // Determine which items need to move
    final start = oldTarget < newTarget ? oldTarget : newTarget;
    final end = oldTarget < newTarget ? newTarget : oldTarget;

    for (var i = start; i <= end; i++) {
      if (i == _draggingIndex) continue;

      final item = items[i];
      final displacement = _calculateGridDisplacement(i, newTarget);

      // Calculate delay based on reposition mode
      final delay = _calculateRepositionDelay(item, newTarget);

      item.currentAnimation?.dispose();
      item.currentAnimation = animate()
          .to(item.offsetX, displacement.dx)
          .to(item.offsetY, displacement.dy)
          .to(
              item.scale,
              displacement.dx != 0 || displacement.dy != 0
                  ? config.displaceScale
                  : 1.0)
          .withDelay(delay)
          .withDuration(config.repositionDuration)
          .withEasing(config.repositionEasing)
          .build()
        ..play();
    }
  }

  /// Calculate displacement offset for grid item
  _Offset _calculateGridDisplacement(int itemIndex, int targetIndex) {
    if (_draggingIndex == null) return _Offset(0.0, 0.0);

    final dragIndex = _draggingIndex!;
    final item = items[itemIndex];

    // Determine if item should move
    bool shouldMove = false;

    if (dragIndex < targetIndex) {
      // Dragging forward
      if (itemIndex > dragIndex && itemIndex <= targetIndex) {
        shouldMove = true;
      }
    } else if (dragIndex > targetIndex) {
      // Dragging backward
      if (itemIndex < dragIndex && itemIndex >= targetIndex) {
        shouldMove = true;
      }
    }

    if (!shouldMove) {
      return _Offset(0.0, 0.0);
    }

    // Calculate new position for this item
    final newIndex = dragIndex < targetIndex ? itemIndex - 1 : itemIndex + 1;

    final currentX = config.xPositionForIndex(itemIndex);
    final currentY = config.yPositionForIndex(itemIndex);
    final newX = config.xPositionForIndex(newIndex);
    final newY = config.yPositionForIndex(newIndex);

    return _Offset(newX - currentX, newY - currentY);
  }

  /// Calculate delay based on reposition mode
  int _calculateRepositionDelay(GridItemContext item, int targetIndex) {
    if (_draggingIndex == null) return 0;

    final draggedItem = items[_draggingIndex!];

    switch (config.repositionMode) {
      case GridRepositionMode.simultaneous:
        return 0;

      case GridRepositionMode.wave:
        // Delay based on distance from dragged item
        final distance = _gridDistance(item, draggedItem);
        return (distance * 30).toInt();

      case GridRepositionMode.radial:
        // Delay based on radial distance
        final radialDist = _euclideanDistance(item, draggedItem);
        return (radialDist * 40).toInt();

      case GridRepositionMode.rowByRow:
        // Same row moves first, then others
        final rowDiff = (item.originalRow - draggedItem.originalRow).abs();
        return rowDiff * 50;

      case GridRepositionMode.columnByColumn:
        // Same column moves first, then others
        final colDiff = (item.originalCol - draggedItem.originalCol).abs();
        return colDiff * 50;
    }
  }

  /// Calculate grid distance (Manhattan distance)
  int _gridDistance(GridItemContext a, GridItemContext b) {
    return (a.originalRow - b.originalRow).abs() +
        (a.originalCol - b.originalCol).abs();
  }

  /// Calculate Euclidean distance
  double _euclideanDistance(GridItemContext a, GridItemContext b) {
    final dx = (a.originalCol - b.originalCol).toDouble();
    final dy = (a.originalRow - b.originalRow).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  void _animateDrop(GridItemContext item, int dropIndex) {
    final targetX = item.targetOffsetX;
    final targetY = item.targetOffsetY;

    item.currentAnimation?.dispose();
    item.currentAnimation = animate()
        .to(item.offsetX, targetX)
        .to(item.offsetY, targetY)
        .to(item.scale, 1.0)
        .to(item.opacity, 1.0)
        .to(item.rotation, 0.0)
        .to(item.elevation, 0.0)
        .withDuration(config.dropDuration)
        .withEasing(config.dropEasing)
        .build()
      ..play();

    // Reset other items after drop
    Future.delayed(Duration(milliseconds: config.dropDuration), () {
      for (var i = 0; i < items.length; i++) {
        final otherItem = items[i];
        if (i != item.index) {
          otherItem.offsetX.value = 0.0;
          otherItem.offsetY.value = 0.0;
          otherItem.scale.value = 1.0;
          otherItem.updateTargetPosition(i);
        } else {
          // Update dragged item's target position
          item.updateTargetPosition(dropIndex);
        }
      }
    });
  }

  void _animateCancel(GridItemContext item) {
    item.currentAnimation?.dispose();
    item.currentAnimation = animate()
        .to(item.offsetX, 0.0)
        .to(item.offsetY, 0.0)
        .to(item.scale, 1.0)
        .to(item.opacity, 1.0)
        .to(item.rotation, 0.0)
        .to(item.elevation, 0.0)
        .withDuration(250)
        .withEasing(Easing.easeOutCubic)
        .build()
      ..play();

    // Reset displaced items
    for (var i = 0; i < items.length; i++) {
      final otherItem = items[i];
      if (i != item.index) {
        otherItem.currentAnimation?.dispose();
        otherItem.currentAnimation = animate()
            .to(otherItem.offsetX, 0.0)
            .to(otherItem.offsetY, 0.0)
            .to(otherItem.scale, 1.0)
            .withDuration(250)
            .withEasing(Easing.easeOutCubic)
            .build()
          ..play();
      }
    }
  }

  /// Dispose all animations
  void dispose() {
    for (final item in items) {
      item.currentAnimation?.dispose();
    }
  }
}

/// Helper class for 2D offset
class _Offset {
  final double dx;
  final double dy;

  _Offset(this.dx, this.dy);
}

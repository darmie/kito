import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'package:kito_reactive/kito_reactive.dart';

/// Drag-and-shuffle states for reorderable items
enum DragShuffleState {
  idle, // Not dragging
  dragging, // Item being dragged
  hovering, // Dragged item hovering over drop target
  dropping, // Item being dropped
  animating, // Items animating to new positions
}

/// Drag-and-shuffle events
enum DragShuffleEvent {
  startDrag, // Start dragging an item
  updateDrag, // Drag position updated
  hoverTarget, // Dragging over a new target position
  drop, // Drop item
  animComplete, // Animation completed
  reset, // Reset to idle
}

/// Configuration for drag-and-shuffle animations
class DragShuffleConfig {
  /// Duration for item reposition animation (ms)
  final int repositionDuration;

  /// Duration for drop animation (ms)
  final int dropDuration;

  /// Easing for reposition animation
  final EasingFunction repositionEasing;

  /// Easing for drop animation
  final EasingFunction dropEasing;

  /// Scale of dragged item
  final double dragScale;

  /// Opacity of dragged item
  final double dragOpacity;

  /// Scale of items being displaced
  final double displaceScale;

  /// Elevation/shadow intensity during drag
  final double dragElevation;

  /// Rotation angle when dragging (in degrees)
  final double dragRotation;

  const DragShuffleConfig({
    this.repositionDuration = 300,
    this.dropDuration = 250,
    this.repositionEasing = Easing.easeOutCubic,
    this.dropEasing = Easing.easeOutBack,
    this.dragScale = 1.05,
    this.dragOpacity = 0.9,
    this.displaceScale = 0.95,
    this.dragElevation = 8.0,
    this.dragRotation = 2.0,
  });

  /// Subtle, minimal drag effect
  static const DragShuffleConfig subtle = DragShuffleConfig(
    dragScale: 1.02,
    dragOpacity: 0.95,
    dragRotation: 0.0,
    repositionDuration: 250,
  );

  /// Smooth, fluid drag effect
  static const DragShuffleConfig smooth = DragShuffleConfig(
    dragScale: 1.08,
    dragOpacity: 0.92,
    dragRotation: 3.0,
    repositionDuration: 350,
    repositionEasing: Easing.easeInOutCubic,
  );

  /// Playful, bouncy drag effect
  static const DragShuffleConfig playful = DragShuffleConfig(
    dragScale: 1.12,
    dragOpacity: 0.88,
    dragRotation: 5.0,
    repositionDuration: 400,
    dropDuration: 350,
    dropEasing: Easing.easeOutElastic,
  );
}

/// Context for a single draggable item
class DragItemContext {
  /// Configuration
  final DragShuffleConfig config;

  /// Item index
  final int index;

  /// Target position (when being displaced)
  int targetIndex;

  /// Current offset from original position
  AnimatableProperty<double> offsetX = animatableDouble(0.0);
  AnimatableProperty<double> offsetY = animatableDouble(0.0);

  /// Scale
  AnimatableProperty<double> scale = animatableDouble(1.0);

  /// Opacity
  AnimatableProperty<double> opacity = animatableDouble(1.0);

  /// Rotation (degrees)
  AnimatableProperty<double> rotation = animatableDouble(0.0);

  /// Elevation
  AnimatableProperty<double> elevation = animatableDouble(0.0);

  /// Current animation (if any)
  KitoAnimation? currentAnimation;

  DragItemContext({
    required this.config,
    required this.index,
  }) : targetIndex = index;
}

/// Controller for managing drag-and-shuffle list
class DragShuffleController {
  final DragShuffleConfig config;
  final List<DragItemContext> items = [];
  final void Function(int oldIndex, int newIndex)? onReorder;

  int? _draggingIndex;
  int? _targetIndex;

  DragShuffleController({
    this.config = const DragShuffleConfig(),
    this.onReorder,
  });

  /// Initialize items
  void initializeItems(int count) {
    items.clear();
    for (var i = 0; i < count; i++) {
      items.add(DragItemContext(
        config: config,
        index: i,
      ));
    }
  }

  /// Get item context
  DragItemContext getItem(int index) => items[index];

  /// Start dragging an item
  void startDrag(int index) {
    _draggingIndex = index;
    _targetIndex = index;

    final item = items[index];
    _animateDragStart(item);
  }

  /// Update drag position
  void updateDragPosition(int index, double offsetX, double offsetY) {
    if (_draggingIndex == null) return;

    final item = items[index];
    item.offsetX.value = offsetX;
    item.offsetY.value = offsetY;
  }

  /// Update target drop position
  void updateTargetPosition(int newTargetIndex) {
    if (_draggingIndex == null || _targetIndex == newTargetIndex) return;

    final oldTarget = _targetIndex!;
    _targetIndex = newTargetIndex;

    // Animate items to make space for drop
    _animateDisplacement(oldTarget, newTargetIndex);
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

  void _animateDragStart(DragItemContext item) {
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

  void _animateDisplacement(int oldTarget, int newTarget) {
    // Determine which items need to move
    final start = oldTarget < newTarget ? oldTarget : newTarget;
    final end = oldTarget < newTarget ? newTarget : oldTarget;

    for (var i = start; i <= end; i++) {
      if (i == _draggingIndex) continue;

      final item = items[i];
      final displacement = _calculateDisplacement(i, newTarget);

      item.currentAnimation?.dispose();
      item.currentAnimation = animate()
          .to(item.offsetY, displacement)
          .to(item.scale, displacement != 0 ? config.displaceScale : 1.0)
          .withDuration(config.repositionDuration)
          .withEasing(config.repositionEasing)
          .build()
        ..play();
    }
  }

  double _calculateDisplacement(int itemIndex, int targetIndex) {
    if (_draggingIndex == null) return 0.0;

    final dragIndex = _draggingIndex!;

    // Item height approximation (would be configurable in real implementation)
    const itemHeight = 60.0;

    if (dragIndex < targetIndex) {
      // Dragging downward
      if (itemIndex > dragIndex && itemIndex <= targetIndex) {
        return -itemHeight; // Move up
      }
    } else if (dragIndex > targetIndex) {
      // Dragging upward
      if (itemIndex < dragIndex && itemIndex >= targetIndex) {
        return itemHeight; // Move down
      }
    }

    return 0.0;
  }

  void _animateDrop(DragItemContext item, int dropIndex) {
    final targetY = _calculateDisplacement(item.index, dropIndex);

    item.currentAnimation?.dispose();
    item.currentAnimation = animate()
        .to(item.offsetX, 0.0)
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
        }
      }
    });
  }

  void _animateCancel(DragItemContext item) {
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

/// Simplified state machine for individual drag item
/// (The controller manages the overall drag-shuffle logic)
class DragItemStateMachine extends KitoStateMachine<DragShuffleState,
    DragShuffleEvent, DragItemContext> {
  DragItemStateMachine(DragItemContext context)
      : super(
          initial: DragShuffleState.idle,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<DragShuffleState,
          StateConfig<DragShuffleState, DragShuffleEvent, DragItemContext>>
      _buildStates() {
    return {
      // IDLE STATE
      DragShuffleState.idle: StateConfig(
        state: DragShuffleState.idle,
        transitions: {
          DragShuffleEvent.startDrag: TransitionConfig(
            target: DragShuffleState.dragging,
            action: (ctx) => ctx,
          ),
        },
      ),

      // DRAGGING STATE
      DragShuffleState.dragging: StateConfig(
        state: DragShuffleState.dragging,
        transitions: {
          DragShuffleEvent.updateDrag: TransitionConfig(
            target: DragShuffleState.dragging,
            action: (ctx) => ctx,
          ),
          DragShuffleEvent.hoverTarget: TransitionConfig(
            target: DragShuffleState.hovering,
            action: (ctx) => ctx,
          ),
          DragShuffleEvent.drop: TransitionConfig(
            target: DragShuffleState.dropping,
            action: (ctx) => ctx,
          ),
        },
      ),

      // HOVERING STATE
      DragShuffleState.hovering: StateConfig(
        state: DragShuffleState.hovering,
        transitions: {
          DragShuffleEvent.updateDrag: TransitionConfig(
            target: DragShuffleState.dragging,
            action: (ctx) => ctx,
          ),
          DragShuffleEvent.drop: TransitionConfig(
            target: DragShuffleState.dropping,
            action: (ctx) => ctx,
          ),
        },
      ),

      // DROPPING STATE
      DragShuffleState.dropping: StateConfig(
        state: DragShuffleState.dropping,
        transitions: {
          DragShuffleEvent.animComplete: TransitionConfig(
            target: DragShuffleState.animating,
            action: (ctx) => ctx,
          ),
        },
      ),

      // ANIMATING STATE
      DragShuffleState.animating: StateConfig(
        state: DragShuffleState.animating,
        transitions: {
          DragShuffleEvent.reset: TransitionConfig(
            target: DragShuffleState.idle,
            action: (ctx) => ctx,
          ),
        },
      ),
    };
  }
}

import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

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

  /// Item index (mutable for reordering)
  int index;

  /// Target position (when being displaced)
  int targetIndex;

  /// Current offset from original position
  AnimatableProperty<double> offsetX = animatableDouble(0.0);
  AnimatableProperty<double> offsetY = animatableDouble(0.0);

  /// Absolute Y position (for smooth animations without jumps)
  late AnimatableProperty<double> absoluteY;

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
    double initialY = 0.0,
  }) : targetIndex = index {
    absoluteY = animatableDouble(initialY);
  }
}



/// Controller for managing drag-and-shuffle list with reactive state
class DragShuffleController<T> {
  final DragShuffleConfig config;
  final void Function(List<T> newOrder)? onReorder;

  /// Current order of items (reactive signal)
  late final Signal<List<T>> _currentOrder;

  /// Animation contexts keyed by item (stable reference)
  final Map<T, DragItemContext> _itemContexts = {};

  /// Reactive signal that increments on every animation frame
  late final Signal<int> _frameCounter;

  /// Height of each item (for position calculations)
  double _itemHeight = 60.0;

  int? _draggingIndex;
  int? _targetIndex;

  DragShuffleController({
    this.config = const DragShuffleConfig(),
    this.onReorder,
  }) {
    _currentOrder = signal<List<T>>([]);
    _frameCounter = signal(0);
  }

  /// Get current order of items (reactive)
  List<T> get currentOrder => _currentOrder.value;

  /// Get frame counter for triggering reactive rebuilds
  int get frameCounter => _frameCounter.value;

  /// Initialize items with a list
  void initializeItems(List<T> items, {double itemHeight = 60.0}) {
    _itemHeight = itemHeight;
    _currentOrder.value = List.from(items);
    _itemContexts.clear();

    // Create animation context for each item, keyed by the item itself
    for (var i = 0; i < items.length; i++) {
      _itemContexts[items[i]] = DragItemContext(
        config: config,
        index: i,
        initialY: i * itemHeight,
      );
    }
  }

  /// Get item at visual position
  T getItemAt(int visualIndex) => _currentOrder.value[visualIndex];

  /// Get animation context for an item
  DragItemContext getContext(T item) => _itemContexts[item]!;

  /// Get animation context at visual position
  DragItemContext getContextAt(int visualIndex) =>
      _itemContexts[_currentOrder.value[visualIndex]]!;

  /// Start dragging an item at visual position
  void startDrag(int visualIndex) {
    _draggingIndex = visualIndex;
    _targetIndex = visualIndex;

    final item = _currentOrder.value[visualIndex];
    final ctx = _itemContexts[item]!;
    _animateDragStart(ctx);
  }

  /// Update drag position (optional - for custom drag handling)
  void updateDragPosition(int visualIndex, double offsetX, double offsetY) {
    if (_draggingIndex == null) return;

    final item = _currentOrder.value[visualIndex];
    final ctx = _itemContexts[item]!;
    ctx.offsetX.value = offsetX;
    ctx.offsetY.value = offsetY;
    _frameCounter.value++; // Trigger reactive rebuild
  }

  /// Update target drop position
  void updateTargetPosition(int newTargetIndex) {
    if (_draggingIndex == null || _targetIndex == newTargetIndex) return;

    final oldTarget = _targetIndex!;
    _targetIndex = newTargetIndex;

    // Animate items to make space for drop
    _animateDisplacement(oldTarget, newTargetIndex);
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

  void _animateDragStart(DragItemContext ctx) {
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

  void _animateDisplacement(int oldTarget, int newTarget) {
    if (_draggingIndex == null) return;

    final dragIndex = _draggingIndex!;

    // Animate all items to their target positions
    for (var i = 0; i < _currentOrder.value.length; i++) {
      if (i == dragIndex) continue; // Skip the dragged item

      final item = _currentOrder.value[i];
      final ctx = _itemContexts[item]!;

      // Calculate target Y position based on whether this item needs to make space
      double targetY;
      bool isDisplaced = false;

      if (dragIndex < newTarget) {
        // Dragging downward: items between drag and target move up
        if (i > dragIndex && i <= newTarget) {
          targetY = (i - 1) * _itemHeight; // Move up one slot
          isDisplaced = true;
        } else {
          targetY = i * _itemHeight; // Stay in place
        }
      } else if (dragIndex > newTarget) {
        // Dragging upward: items between target and drag move down
        if (i >= newTarget && i < dragIndex) {
          targetY = (i + 1) * _itemHeight; // Move down one slot
          isDisplaced = true;
        } else {
          targetY = i * _itemHeight; // Stay in place
        }
      } else {
        targetY = i * _itemHeight; // No displacement needed
      }

      ctx.currentAnimation?.dispose();

      // Animate to target position with fade effect for displaced items
      // Note: Only animate position and opacity, NOT scale (to avoid jumps)
      ctx.currentAnimation = animate()
          .to(ctx.absoluteY, targetY)
          .to(ctx.opacity, isDisplaced ? 0.7 : 1.0)
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

  void _animateDrop(DragItemContext ctx, int dropIndex) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.absoluteY, dropIndex * _itemHeight)
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
        otherCtx.absoluteY.value = i * _itemHeight;
        otherCtx.offsetX.value = 0.0;
        otherCtx.offsetY.value = 0.0;
        otherCtx.scale.value = 1.0;
        otherCtx.opacity.value = 1.0;
      }
      _frameCounter.value++; // Final rebuild
    });
  }

  void _animateCancel(DragItemContext ctx) {
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

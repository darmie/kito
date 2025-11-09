import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import '../primitives/motion_primitives.dart';

/// Swipe-to-Delete states
enum SwipeState {
  idle, // No interaction
  dragging, // Actively being dragged
  snappingBack, // Animating back to idle (rubberband)
  deleting, // Delete threshold exceeded, animating deletion
}

/// Swipe-to-Delete events
enum SwipeEvent {
  dragStart, // User starts horizontal drag
  dragUpdate, // Drag position updated
  dragEnd, // User releases drag
  thresholdExceeded, // Swipe exceeds delete threshold
  snapBackComplete, // Snap-back animation finished
  deleteComplete, // Delete animation finished
}

/// Swipe animation configuration
class SwipeAnimationConfig {
  /// Threshold distance (in pixels) to trigger deletion
  final double deleteThreshold;

  /// Maximum swipe distance allowed
  final double maxSwipeDistance;

  /// Duration for snap-back animation
  final int snapBackDuration;

  /// Duration for delete animation
  final int deleteDuration;

  /// Use elastic rubberband effect on snap-back
  final bool useElasticSnapBack;

  /// Elastic configuration for snap-back
  final ElasticConfig elasticConfig;

  /// Background color revealed during swipe
  final Color backgroundColor;

  /// Icon shown in background
  final IconData? backgroundIcon;

  const SwipeAnimationConfig({
    this.deleteThreshold = 80.0,
    this.maxSwipeDistance = 120.0,
    this.snapBackDuration = 600,
    this.deleteDuration = 300,
    this.useElasticSnapBack = true,
    this.elasticConfig = const ElasticConfig(
      displacement: 0.3,
      oscillations: 2,
      duration: 600,
      damping: 0.7,
    ),
    this.backgroundColor = const Color(0xFFE74C3C),
    this.backgroundIcon = Icons.delete,
  });

  static const SwipeAnimationConfig gentle = SwipeAnimationConfig(
    deleteThreshold: 100.0,
    snapBackDuration: 500,
    elasticConfig: ElasticConfig.subtle,
  );

  static const SwipeAnimationConfig quick = SwipeAnimationConfig(
    deleteThreshold: 60.0,
    snapBackDuration: 400,
    deleteDuration: 250,
    useElasticSnapBack: false,
  );
}

/// Swipe context
class SwipeContext {
  final SwipeAnimationConfig config;

  // Animation properties
  final AnimatableProperty<Offset> swipeOffset;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> backgroundOpacity;

  KitoAnimation? currentAnimation;
  KitoAnimation? backgroundAnimation;

  // Callback when item is deleted
  VoidCallback? onDelete;

  SwipeContext({
    required this.config,
    this.onDelete,
  })  : swipeOffset = animatableOffset(Offset.zero),
        opacity = animatableDouble(1.0),
        scale = animatableDouble(1.0),
        backgroundOpacity = animatableDouble(0.0);

  void dispose() {
    currentAnimation?.dispose();
    backgroundAnimation?.dispose();
  }
}

/// Swipe-to-Delete state machine
class SwipeToDeleteStateMachine
    extends KitoStateMachine<SwipeState, SwipeEvent, SwipeContext> {
  SwipeToDeleteStateMachine(SwipeContext context)
      : super(
          initial: SwipeState.idle,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<SwipeState, StateConfig<SwipeState, SwipeEvent, SwipeContext>>
      _buildStates() {
    return {
      SwipeState.idle: StateConfig(
        state: SwipeState.idle,
        transitions: {
          SwipeEvent.dragStart: TransitionConfig(
            target: SwipeState.dragging,
            action: (ctx) {
              _startDrag(ctx);
              return ctx;
            },
          ),
        },
      ),
      SwipeState.dragging: StateConfig(
        state: SwipeState.dragging,
        transitions: {
          SwipeEvent.dragEnd: TransitionConfig(
            target: SwipeState.snappingBack,
            guard: (ctx) => !_isOverThreshold(ctx),
            action: (ctx) {
              _snapBack(ctx);
              return ctx;
            },
          ),
          SwipeEvent.thresholdExceeded: TransitionConfig(
            target: SwipeState.deleting,
            action: (ctx) {
              _animateDelete(ctx);
              return ctx;
            },
          ),
        },
      ),
      SwipeState.snappingBack: const StateConfig(
        state: SwipeState.snappingBack,
        transient: TransientConfig(
          after: Duration(milliseconds: 600),
          target: SwipeState.idle,
        ),
      ),
      SwipeState.deleting: StateConfig(
        state: SwipeState.deleting,
        onEntry: (ctx, from, to) {
          // Call delete callback when entering delete state
          Future.delayed(Duration(milliseconds: ctx.config.deleteDuration), () {
            ctx.onDelete?.call();
          });
        },
      ),
    };
  }

  /// Update drag position (call this from gesture detector)
  void updateDrag(double deltaX) {
    if (currentState.value != SwipeState.dragging) return;

    final ctx = context;

    // Clamp to max swipe distance
    final clampedDelta = deltaX.clamp(
      -ctx.config.maxSwipeDistance,
      ctx.config.maxSwipeDistance,
    );

    ctx.swipeOffset.value = Offset(clampedDelta, 0);

    // Update background opacity based on swipe progress
    final progress =
        (clampedDelta.abs() / ctx.config.deleteThreshold).clamp(0.0, 1.0);
    ctx.backgroundOpacity.value = progress * 0.9; // Max 90% opacity

    // Check if threshold exceeded
    if (clampedDelta.abs() >= ctx.config.deleteThreshold) {
      send(SwipeEvent.thresholdExceeded);
    }
  }

  static void _startDrag(SwipeContext ctx) {
    // Cancel any ongoing animations
    ctx.currentAnimation?.dispose();
    ctx.backgroundAnimation?.dispose();
  }

  static bool _isOverThreshold(SwipeContext ctx) {
    return ctx.swipeOffset.value.dx.abs() >= ctx.config.deleteThreshold;
  }

  static void _snapBack(SwipeContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.backgroundAnimation?.dispose();

    if (ctx.config.useElasticSnapBack) {
      // Use elastic rubberband animation
      ctx.currentAnimation = createElastic(
        ctx.swipeOffset,
        Offset.zero,
        config: ctx.config.elasticConfig,
      );

      ctx.backgroundAnimation = animate()
          .to(ctx.backgroundOpacity, 0.0)
          .withDuration(ctx.config.snapBackDuration)
          .withEasing(Easing.easeOutCubic)
          .build();

      ctx.currentAnimation!.play();
      ctx.backgroundAnimation!.play();
    } else {
      // Use simple easeOutBack animation
      ctx.currentAnimation = animate()
          .to(ctx.swipeOffset, Offset.zero)
          .to(ctx.backgroundOpacity, 0.0)
          .withDuration(ctx.config.snapBackDuration)
          .withEasing(Easing.easeOutBack)
          .build();

      ctx.currentAnimation!.play();
    }
  }

  static void _animateDelete(SwipeContext ctx) {
    // Determine slide direction based on current swipe
    final targetX = ctx.swipeOffset.value.dx > 0
        ? ctx.config.maxSwipeDistance * 2.5
        : -ctx.config.maxSwipeDistance * 2.5;

    ctx.currentAnimation?.dispose();
    ctx.backgroundAnimation?.dispose();

    ctx.currentAnimation = animate()
        .to(ctx.swipeOffset, Offset(targetX, 0))
        .to(ctx.opacity, 0.0)
        .to(ctx.scale, 0.8)
        .withDuration(ctx.config.deleteDuration)
        .withEasing(Easing.easeInCubic)
        .build();

    // Fade out the background indicator during deletion
    ctx.backgroundAnimation = animate()
        .to(ctx.backgroundOpacity, 0.0)
        .withDuration(ctx.config.deleteDuration)
        .withEasing(Easing.easeInCubic)
        .build();

    ctx.currentAnimation!.play();
    ctx.backgroundAnimation!.play();
  }
}

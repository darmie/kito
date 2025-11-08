import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'package:kito_reactive/kito_reactive.dart';

/// Pull-to-refresh states
enum PullToRefreshState {
  idle,       // Not pulling
  pulling,    // User is pulling down
  threshold,  // Pull distance exceeds threshold, will refresh on release
  releasing,  // User released, animating back
  refreshing, // Refresh callback is running
  complete,   // Refresh complete, animating out
}

/// Pull-to-refresh events
enum PullToRefreshEvent {
  startPull,      // User starts dragging down
  updatePull,     // Drag position updated
  crossThreshold, // Pull distance crossed threshold
  release,        // User released
  refresh,        // Start refresh callback
  complete,       // Refresh callback completed
  reset,          // Reset to idle
}

/// Configuration for pull-to-refresh animations
class PullToRefreshConfig {
  /// Threshold distance in pixels to trigger refresh
  final double threshold;

  /// Maximum pull distance (overscroll limit)
  final double maxPullDistance;

  /// Duration for release animation (ms)
  final int releaseDuration;

  /// Duration for complete animation (ms)
  final int completeDuration;

  /// Easing for release animation
  final EasingFunction releaseEasing;

  /// Rotation speed during refresh (degrees per second)
  final double rotationSpeed;

  /// Scale factor at threshold
  final double thresholdScale;

  /// Opacity when idle
  final double idleOpacity;

  /// Opacity when active
  final double activeOpacity;

  const PullToRefreshConfig({
    this.threshold = 80.0,
    this.maxPullDistance = 120.0,
    this.releaseDuration = 300,
    this.completeDuration = 400,
    this.releaseEasing = Easing.easeOutCubic,
    this.rotationSpeed = 360.0,
    this.thresholdScale = 1.2,
    this.idleOpacity = 0.0,
    this.activeOpacity = 1.0,
  });

  /// Quick, snappy refresh
  static const PullToRefreshConfig snappy = PullToRefreshConfig(
    threshold: 60.0,
    releaseDuration: 200,
    releaseEasing: Easing.easeOutBack,
    rotationSpeed: 540.0,
  );

  /// Smooth, gentle refresh
  static const PullToRefreshConfig smooth = PullToRefreshConfig(
    threshold: 100.0,
    releaseDuration: 400,
    releaseEasing: Easing.easeOutCubic,
    rotationSpeed: 270.0,
  );

  /// Elastic, bouncy refresh
  static const PullToRefreshConfig elastic = PullToRefreshConfig(
    threshold: 80.0,
    releaseDuration: 500,
    releaseEasing: Easing.easeOutElastic,
    rotationSpeed: 360.0,
    thresholdScale: 1.3,
  );
}

/// Context for pull-to-refresh state machine
class PullToRefreshContext {
  /// Configuration
  final PullToRefreshConfig config;

  /// Callback to execute when refreshing
  final Future<void> Function() onRefresh;

  /// Current pull distance in pixels
  AnimatableProperty<double> pullDistance = animatableDouble(0.0);

  /// Rotation angle for indicator (in degrees)
  AnimatableProperty<double> rotation = animatableDouble(0.0);

  /// Scale of indicator
  AnimatableProperty<double> scale = animatableDouble(1.0);

  /// Opacity of indicator
  AnimatableProperty<double> opacity = animatableDouble(0.0);

  /// Current animation (if any)
  KitoAnimation? currentAnimation;

  /// Flag to track if threshold was crossed
  bool thresholdCrossed = false;

  /// Reference to the state machine (set after construction)
  PullToRefreshStateMachine? _stateMachine;

  PullToRefreshContext({
    required this.config,
    required this.onRefresh,
  });

  void _setStateMachine(PullToRefreshStateMachine machine) {
    _stateMachine = machine;
  }
}

/// Pull-to-refresh state machine
class PullToRefreshStateMachine
    extends KitoStateMachine<PullToRefreshState, PullToRefreshEvent, PullToRefreshContext> {
  PullToRefreshStateMachine(PullToRefreshContext context)
      : super(
          initial: PullToRefreshState.idle,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        ) {
    context._setStateMachine(this);
  }

  static Map<PullToRefreshState, StateConfig<PullToRefreshState, PullToRefreshEvent, PullToRefreshContext>>
      _buildStates() {
    return {
      // IDLE STATE
      PullToRefreshState.idle: StateConfig(
        state: PullToRefreshState.idle,
        transitions: {
          PullToRefreshEvent.startPull: TransitionConfig(
            target: PullToRefreshState.pulling,
            action: (ctx) {
              ctx.thresholdCrossed = false;
              _animateOpacityIn(ctx);
              return ctx;
            },
          ),
        },
      ),

      // PULLING STATE
      PullToRefreshState.pulling: StateConfig(
        state: PullToRefreshState.pulling,
        transitions: {
          PullToRefreshEvent.updatePull: TransitionConfig(
            target: PullToRefreshState.pulling,
            action: (ctx) {
              // Stay in pulling, just update visuals
              return ctx;
            },
          ),
          PullToRefreshEvent.crossThreshold: TransitionConfig(
            target: PullToRefreshState.threshold,
            action: (ctx) {
              ctx.thresholdCrossed = true;
              _animateThresholdCross(ctx);
              return ctx;
            },
          ),
          PullToRefreshEvent.release: TransitionConfig(
            target: PullToRefreshState.releasing,
            guard: (ctx) => !ctx.thresholdCrossed,
            action: (ctx) {
              _animateRelease(ctx);
              return ctx;
            },
          ),
        },
      ),

      // THRESHOLD STATE (past trigger point)
      PullToRefreshState.threshold: StateConfig(
        state: PullToRefreshState.threshold,
        transitions: {
          PullToRefreshEvent.updatePull: TransitionConfig(
            target: PullToRefreshState.threshold,
            action: (ctx) {
              // Stay in threshold
              return ctx;
            },
          ),
          PullToRefreshEvent.release: TransitionConfig(
            target: PullToRefreshState.refreshing,
            action: (ctx) {
              _animateToRefreshPosition(ctx);
              return ctx;
            },
          ),
        },
      ),

      // RELEASING STATE (cancelled pull)
      PullToRefreshState.releasing: StateConfig(
        state: PullToRefreshState.releasing,
        transitions: {
          PullToRefreshEvent.reset: TransitionConfig(
            target: PullToRefreshState.idle,
            action: (ctx) {
              return ctx;
            },
          ),
        },
        onEntry: (ctx, from, to) {
          // Watch animation completion
          if (ctx.currentAnimation != null) {
            effect(() {
              final anim = ctx.currentAnimation;
              if (anim != null && anim.currentState.value == AnimState.completed) {
                // Auto-transition to idle when release animation completes
                Future.microtask(() {
                  if (ctx._stateMachine?.currentState.value == PullToRefreshState.releasing) {
                    ctx._stateMachine?.send(PullToRefreshEvent.reset);
                  }
                });
              }
            });
          }
        },
      ),

      // REFRESHING STATE
      PullToRefreshState.refreshing: StateConfig(
        state: PullToRefreshState.refreshing,
        transitions: {
          PullToRefreshEvent.complete: TransitionConfig(
            target: PullToRefreshState.complete,
            action: (ctx) {
              _animateComplete(ctx);
              return ctx;
            },
          ),
        },
        onEntry: (ctx, from, to) {
          // Start spinning animation
          _animateRefreshing(ctx);

          // Execute refresh callback
          ctx.onRefresh().then((_) {
            if (ctx._stateMachine?.currentState.value == PullToRefreshState.refreshing) {
              ctx._stateMachine?.send(PullToRefreshEvent.complete);
            }
          });
        },
      ),

      // COMPLETE STATE
      PullToRefreshState.complete: StateConfig(
        state: PullToRefreshState.complete,
        transitions: {
          PullToRefreshEvent.reset: TransitionConfig(
            target: PullToRefreshState.idle,
            action: (ctx) {
              return ctx;
            },
          ),
        },
        onEntry: (ctx, from, to) {
          // Watch animation completion
          if (ctx.currentAnimation != null) {
            effect(() {
              final anim = ctx.currentAnimation;
              if (anim != null && anim.currentState.value == AnimState.completed) {
                // Auto-transition to idle when complete animation finishes
                Future.microtask(() {
                  if (ctx._stateMachine?.currentState.value == PullToRefreshState.complete) {
                    ctx._stateMachine?.send(PullToRefreshEvent.reset);
                  }
                });
              }
            });
          }
        },
      ),
    };
  }

  /// Update pull distance (call this from drag handler)
  void updatePullDistance(double distance) {
    final ctx = context;
    final clampedDistance = distance.clamp(0.0, ctx.config.maxPullDistance);

    ctx.pullDistance.value = clampedDistance;

    // Update rotation based on pull distance
    final progress = clampedDistance / ctx.config.threshold;
    ctx.rotation.value = progress * 180.0; // Half rotation at threshold

    // Update scale based on pull distance
    final scaleProgress = (clampedDistance / ctx.config.threshold).clamp(0.0, 1.0);
    ctx.scale.value = 1.0 + (scaleProgress * (ctx.config.thresholdScale - 1.0));

    // Check threshold crossing
    if (clampedDistance >= ctx.config.threshold && !ctx.thresholdCrossed) {
      send(PullToRefreshEvent.crossThreshold);
    }

    // Send update event
    if (currentState.value == PullToRefreshState.pulling ||
        currentState.value == PullToRefreshState.threshold) {
      send(PullToRefreshEvent.updatePull);
    }
  }

  /// Start pulling (call when drag starts)
  void startPull() {
    send(PullToRefreshEvent.startPull);
  }

  /// Release pull (call when drag ends)
  void releasePull() {
    send(PullToRefreshEvent.release);
  }

  // Animation helpers

  static void _animateOpacityIn(PullToRefreshContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.opacity, ctx.config.activeOpacity)
        .withDuration(200)
        .withEasing(Easing.easeOutCubic)
        .build()
      ..play();
  }

  static void _animateThresholdCross(PullToRefreshContext ctx) {
    // Quick scale bump to indicate threshold crossed
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.scale, ctx.config.thresholdScale)
        .withDuration(150)
        .withEasing(Easing.easeOutBack)
        .build()
      ..play();
  }

  static void _animateRelease(PullToRefreshContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.pullDistance, 0.0)
        .to(ctx.rotation, 0.0)
        .to(ctx.scale, 1.0)
        .to(ctx.opacity, ctx.config.idleOpacity)
        .withDuration(ctx.config.releaseDuration)
        .withEasing(ctx.config.releaseEasing)
        .build()
      ..play();
  }

  static void _animateToRefreshPosition(PullToRefreshContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.pullDistance, ctx.config.threshold)
        .withDuration(200)
        .withEasing(Easing.easeOutCubic)
        .build()
      ..play();
  }

  static void _animateRefreshing(PullToRefreshContext ctx) {
    ctx.currentAnimation?.dispose();

    // Continuous rotation during refresh
    ctx.currentAnimation = animate()
        .to(ctx.rotation, 360.0)
        .withDuration(1000)
        .withEasing(Easing.linear)
        .loopInfinitely()
        .build()
      ..play();
  }

  static void _animateComplete(PullToRefreshContext ctx) {
    ctx.currentAnimation?.dispose();
    ctx.currentAnimation = animate()
        .to(ctx.pullDistance, 0.0)
        .to(ctx.rotation, 0.0)
        .to(ctx.scale, 1.0)
        .to(ctx.opacity, ctx.config.idleOpacity)
        .withDuration(ctx.config.completeDuration)
        .withEasing(Easing.easeOutCubic)
        .build()
      ..play();
  }
}

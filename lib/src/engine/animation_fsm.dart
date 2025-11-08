import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:kito_fsm/kito_fsm.dart' hide AnimationCallback, AnimationCompleteCallback, AnimationDirection;
import '../types/types.dart';
import '../easing/easing.dart';
import 'animatable.dart';
import 'animation.dart';
import 'keyframe.dart';

/// Animation states for the state machine
enum AnimState {
  idle,      // Not started or reset
  playing,   // Actively animating
  paused,    // Suspended, can resume
  completed, // Finished all loops
}

/// Animation events
enum AnimEvent {
  play,     // Start or resume
  pause,    // Pause animation
  stop,     // Stop and reset
  restart,  // Reset and play
  complete, // Animation finished (internal)
}

/// Animation context - holds all animation state
class AnimationContext {
  // Configuration (immutable)
  final List<AnimationTarget> targets;
  final int duration;
  final int delay;
  final EasingFunction easing;
  final int loop;
  final AnimationDirection direction;

  // Callbacks
  final AnimationCallback? onUpdate;
  final AnimationCompleteCallback? onComplete;
  final AnimationCompleteCallback? onBegin;

  // Runtime state (mutable)
  double progress = 0.0;
  int currentLoop = 0;
  Ticker? ticker;
  Duration? startTime;
  Duration? pausedAt;
  bool reversed = false;
  int loopCount = 0;

  AnimationContext({
    required this.targets,
    required this.duration,
    required this.delay,
    required this.easing,
    required this.loop,
    required this.direction,
    this.onUpdate,
    this.onComplete,
    this.onBegin,
  }) {
    reversed = direction == AnimationDirection.reverse;
  }
}

/// Animation state machine
class AnimationStateMachine extends KitoStateMachine<AnimState, AnimEvent, AnimationContext> {
  AnimationStateMachine(AnimationContext context)
      : super(
          initial: AnimState.idle,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<AnimState, StateConfig<AnimState, AnimEvent, AnimationContext>> _buildStates() {
    return {
      // IDLE STATE
      AnimState.idle: StateConfig(
        state: AnimState.idle,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _resetContext(ctx);
              _startTicker(ctx);
              return ctx;
            },
          ),
        },
      ),

      // PLAYING STATE
      AnimState.playing: StateConfig(
        state: AnimState.playing,
        transitions: {
          AnimEvent.pause: TransitionConfig(
            target: AnimState.paused,
            action: (ctx) {
              _recordPauseTime(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              _resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _stopTicker(ctx);
              _resetContext(ctx);
              _startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.complete: TransitionConfig(
            target: AnimState.completed,
            guard: (ctx) => !_hasMoreLoops(ctx),
            action: (ctx) {
              _stopTicker(ctx);
              return ctx;
            },
          ),
        },
        // No transient config needed - looping handled in tick
        onEntry: (ctx, from, to) {
          if (from == AnimState.idle) {
            ctx.onBegin?.call();
          }
        },
        onExit: (ctx, from, to) {
          if (to != AnimState.paused && to != AnimState.playing) {
            ctx.ticker?.stop();
          }
        },
      ),

      // PAUSED STATE
      AnimState.paused: StateConfig(
        state: AnimState.paused,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _resumeTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              _resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _resetContext(ctx);
              _startTicker(ctx);
              return ctx;
            },
          ),
        },
        onEntry: (ctx, from, to) {
          ctx.ticker?.stop();
        },
        onExit: (ctx, from, to) {
          ctx.pausedAt = null;
        },
      ),

      // COMPLETED STATE
      AnimState.completed: StateConfig(
        state: AnimState.completed,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _resetContext(ctx);
              _startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              _resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              _resetContext(ctx);
              _startTicker(ctx);
              return ctx;
            },
          ),
        },
        onEntry: (ctx, from, to) {
          ctx.onComplete?.call();
        },
      ),
    };
  }

  // Helper function to handle tick updates
  void handleTick(Duration elapsed) {
    _tick(elapsed, context, this);
  }

  /// Check if animation has more loops to run
  static bool _hasMoreLoops(AnimationContext ctx) {
    return ctx.loop == -1 || ctx.loopCount < ctx.loop - 1;
  }

  /// Start ticker
  static void _startTicker(AnimationContext ctx) {
    // Ticker will be started by KitoAnimation using handleTick
    ctx.startTime = null;
  }

  /// Stop ticker
  static void _stopTicker(AnimationContext ctx) {
    ctx.ticker?.stop();
    ctx.ticker?.dispose();
    ctx.ticker = null;
  }

  /// Resume ticker (from pause)
  static void _resumeTicker(AnimationContext ctx) {
    // Ticker will be restarted by KitoAnimation
    ctx.startTime = null;
  }

  /// Reset context
  static void _resetContext(AnimationContext ctx) {
    ctx.progress = 0.0;
    ctx.loopCount = 0;
    ctx.currentLoop = 0;
    ctx.reversed = ctx.direction == AnimationDirection.reverse;
    ctx.startTime = null;
    ctx.pausedAt = null;
    _stopTicker(ctx);
  }

  /// Record pause time
  static void _recordPauseTime(AnimationContext ctx) {
    ctx.pausedAt = ctx.startTime;
  }

  /// Handle loop iteration
  static void _handleLoop(AnimationContext ctx) {
    ctx.loopCount++;
    ctx.currentLoop = ctx.loopCount;

    if (ctx.direction == AnimationDirection.alternate) {
      ctx.reversed = !ctx.reversed;
    }

    ctx.startTime = null;
  }

  /// Tick callback for animation
  static void _tick(Duration elapsed, AnimationContext ctx, AnimationStateMachine fsm) {
    ctx.startTime ??= elapsed;

    final actualElapsed = elapsed - ctx.startTime!;
    final totalDuration = ctx.delay + ctx.duration;
    final millisElapsed = actualElapsed.inMilliseconds;

    // Handle delay
    if (millisElapsed < ctx.delay) {
      return;
    }

    // Calculate progress
    final animationElapsed = millisElapsed - ctx.delay;
    var rawProgress = (animationElapsed / ctx.duration).clamp(0.0, 1.0);

    // Apply direction
    if (ctx.reversed) {
      rawProgress = 1.0 - rawProgress;
    }

    ctx.progress = rawProgress;
    updateTargets(ctx);

    // Check if animation is complete
    if (millisElapsed >= totalDuration) {
      if (_hasMoreLoops(ctx)) {
        // More loops remaining - handle loop and continue
        _handleLoop(ctx);
        // Don't send complete event, just restart ticker
      } else {
        // No more loops - send complete event
        fsm.send(AnimEvent.complete);
      }
    }
  }

  /// Update all animation targets (public for seek())
  static void updateTargets(AnimationContext ctx) {
    for (final target in ctx.targets) {
      _updateTarget(target, ctx);
    }
    ctx.onUpdate?.call(ctx.progress);
  }

  /// Update a single animation target
  static void _updateTarget(AnimationTarget target, AnimationContext ctx) {
    final targetEasing = target.easing ?? ctx.easing;
    final easedProgress = targetEasing(ctx.progress);

    if (target.keyframes != null && target.keyframes!.isNotEmpty) {
      // Keyframe-based animation
      final value = interpolateKeyframes(
        target.keyframes!,
        easedProgress,
        target.property.interpolate,
        targetEasing,
      );
      target.property.value = value;
    } else if (target.endValue != null) {
      // Simple from-to animation
      final startValue = target.property.value;
      final value = target.property.interpolate(
        startValue,
        target.endValue!,
        easedProgress,
      );
      target.property.value = value;
    }
  }
}

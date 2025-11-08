# KitoAnimation FSM Refactor Design

## Executive Summary

This document outlines the design for refactoring `KitoAnimation` to use `kito_fsm` internally while maintaining a backward-compatible public API. This refactor will provide declarative state management, better testability, and leverage the FSM's built-in features like history tracking, guards, and event bubbling.

## Current Implementation Analysis

### Current States (implicit)
```dart
enum AnimationState {
  idle,      // Animation not started or reset
  playing,   // Animation actively running
  paused,    // Animation stopped but can resume
  completed, // Animation finished all loops
}
```

### Current Methods (imperative)
- `play()` - Start or resume animation
- `pause()` - Pause active animation
- `restart()` - Reset and play from beginning
- `seek(double)` - Jump to specific progress
- `stop()` - Stop and reset to idle
- `dispose()` - Cleanup resources

### Current Internal State
```dart
// Reactive signals
Signal<double> _progress;        // 0.0 to 1.0
Signal<AnimationState> _state;   // Current state
Signal<int> _currentLoop;        // Loop iteration

// Timing state
Ticker? _ticker;                 // Frame callback driver
Duration? _startTime;            // When animation started
Duration? _pausedAt;             // When animation was paused

// Playback state
bool _reversed;                  // Direction flag
int _loopCount;                  // Completed loops
```

### Problems with Current Approach
1. **State management scattered** - State transitions logic mixed with business logic
2. **Implicit state machine** - States/transitions not declarative
3. **Hard to test edge cases** - Complex conditionals for state changes
4. **No history tracking** - Can't easily track transition history
5. **Manual guard checks** - `if (state == ...)` checks everywhere

---

## FSM Design

### State Machine Configuration

```dart
// Animation states
enum AnimState {
  idle,       // Not started or reset
  playing,    // Actively animating
  paused,     // Suspended, can resume
  completed,  // Finished all loops
}

// Animation events
enum AnimEvent {
  play,       // Start or resume
  pause,      // Pause animation
  stop,       // Stop and reset
  restart,    // Reset and play
  complete,   // Animation finished (internal)
}

// Animation context (replaces instance variables)
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
  });
}
```

### State Transitions

```
┌─────────────────────────────────────────────────────────────────┐
│                      Animation State Machine                     │
└─────────────────────────────────────────────────────────────────┘

                    play
         ┌────────────────────────┐
         │                        │
         ▼                        │
    ┌────────┐    play       ┌────────┐
    │  idle  │──────────────▶│playing │
    └────────┘                └────────┘
         ▲                         │   │
         │                    pause│   │complete (has loops)
         │                         │   │(restart ticker)
         │                         ▼   │
         │                    ┌────────┐
         │              play  │ paused │
         │    ┌───────────────└────────┘
         │    │
         │    │
    stop │    │ complete (no more loops)
         │    │
         │    ▼
         │  ┌───────────┐
         └──│ completed │
            └───────────┘
                 │  ▲
                 │  │ play (replay)
                 └──┘

All states + restart → playing (via idle entry/exit)
```

### Transition Table

| From State | Event    | To State  | Guard                     | Action                                    |
|-----------|----------|-----------|---------------------------|-------------------------------------------|
| idle      | play     | playing   | -                         | startTicker(), callOnBegin()              |
| idle      | restart  | playing   | -                         | resetContext(), startTicker()             |
| playing   | pause    | paused    | -                         | stopTicker(), recordPauseTime()           |
| playing   | stop     | idle      | -                         | stopTicker(), resetContext()              |
| playing   | restart  | playing   | -                         | stopTicker(), resetContext(), startTicker()|
| playing   | complete | playing   | hasMoreLoops()            | handleLoop(), resetTicker()               |
| playing   | complete | completed | !hasMoreLoops()           | stopTicker(), callOnComplete()            |
| paused    | play     | playing   | -                         | resumeTicker()                            |
| paused    | stop     | idle      | -                         | stopTicker(), resetContext()              |
| paused    | restart  | playing   | -                         | resetContext(), startTicker()             |
| completed | play     | playing   | -                         | resetContext(), startTicker()             |
| completed | stop     | idle      | -                         | resetContext()                            |
| completed | restart  | playing   | -                         | resetContext(), startTicker()             |

### State Actions

#### Entry Actions
```dart
// On enter idle
onEntry: (ctx, from, to) {
  // Already reset by transition actions
}

// On enter playing
onEntry: (ctx, from, to) {
  if (from == AnimState.idle) {
    ctx.onBegin?.call();
  }
}

// On enter paused
onEntry: (ctx, from, to) {
  // Ticker already stopped by transition
}

// On enter completed
onEntry: (ctx, from, to) {
  ctx.onComplete?.call();
}
```

#### Exit Actions
```dart
// On exit idle
onExit: (ctx, from, to) {
  // Nothing special
}

// On exit playing
onExit: (ctx, from, to) {
  ctx.ticker?.stop();
}

// On exit paused
onExit: (ctx, from, to) {
  ctx.pausedAt = null;
}

// On exit completed
onExit: (ctx, from, to) {
  // Preparing for replay
}
```

### Guards

```dart
// Check if animation has more loops to run
bool hasMoreLoops(AnimationContext ctx) {
  return ctx.loop == -1 || ctx.loopCount < ctx.loop - 1;
}

// Check if currently playing (for pause guard)
bool isPlaying(AnimationContext ctx, AnimState currentState) {
  return currentState == AnimState.playing;
}
```

### Transition Actions

```dart
// Start ticker
void startTicker(AnimationContext ctx) {
  ctx.ticker = Ticker((elapsed) => _tick(elapsed, ctx, stateMachine));
  ctx.startTime = null;
  ctx.ticker!.start();
}

// Stop ticker
void stopTicker(AnimationContext ctx) {
  ctx.ticker?.stop();
  ctx.ticker?.dispose();
  ctx.ticker = null;
}

// Resume ticker (from pause)
void resumeTicker(AnimationContext ctx) {
  ctx.ticker = Ticker((elapsed) => _tick(elapsed, ctx, stateMachine));
  ctx.startTime = null; // Will be recalculated
  ctx.ticker!.start();
}

// Reset context
void resetContext(AnimationContext ctx) {
  ctx.progress = 0.0;
  ctx.loopCount = 0;
  ctx.currentLoop = 0;
  ctx.reversed = ctx.direction == AnimationDirection.reverse;
  ctx.startTime = null;
  ctx.pausedAt = null;
  stopTicker(ctx);
}

// Record pause time
void recordPauseTime(AnimationContext ctx) {
  ctx.pausedAt = ctx.startTime; // Store current time
}

// Handle loop
void handleLoop(AnimationContext ctx) {
  ctx.loopCount++;
  ctx.currentLoop = ctx.loopCount;

  if (ctx.direction == AnimationDirection.alternate) {
    ctx.reversed = !ctx.reversed;
  }

  ctx.startTime = null; // Reset for next iteration
}

// Call onBegin callback
void callOnBegin(AnimationContext ctx) {
  ctx.onBegin?.call();
}

// Call onComplete callback
void callOnComplete(AnimationContext ctx) {
  ctx.onComplete?.call();
}

// Reset ticker (for looping)
void resetTicker(AnimationContext ctx) {
  ctx.startTime = null;
}
```

### Tick Handling (Not an FSM Event)

The `_tick()` callback updates progress and triggers `complete` event when done:

```dart
void _tick(Duration elapsed, AnimationContext ctx, AnimationFSM fsm) {
  ctx.startTime ??= elapsed;

  final actualElapsed = elapsed - ctx.startTime!;
  final totalDuration = ctx.delay + ctx.duration;
  final millisElapsed = actualElapsed.inMilliseconds;

  // Handle delay
  if (millisElapsed < ctx.delay) return;

  // Calculate progress
  final animationElapsed = millisElapsed - ctx.delay;
  var rawProgress = (animationElapsed / ctx.duration).clamp(0.0, 1.0);

  // Apply direction
  if (ctx.reversed) {
    rawProgress = 1.0 - rawProgress;
  }

  ctx.progress = rawProgress;
  _updateTargets(ctx);

  // Check completion
  if (millisElapsed >= totalDuration) {
    fsm.send(AnimEvent.complete); // Trigger FSM event!
  }
}

void _updateTargets(AnimationContext ctx) {
  for (final target in ctx.targets) {
    _updateTarget(target, ctx);
  }
  ctx.onUpdate?.call(ctx.progress);
}
```

---

## Implementation Strategy

### Phase 1: Create AnimationStateMachine

```dart
class AnimationStateMachine extends KitoStateMachine<AnimState, AnimEvent, AnimationContext> {
  AnimationStateMachine(AnimationContext context)
      : super(
          config: StateMachineConfig(
            initial: AnimState.idle,
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<AnimState, StateConfig<AnimState, AnimEvent, AnimationContext>> _buildStates() {
    return {
      AnimState.idle: StateConfig(
        state: AnimState.idle,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              resetContext(ctx);
              startTicker(ctx);
              return ctx;
            },
          ),
        },
      ),

      AnimState.playing: StateConfig(
        state: AnimState.playing,
        transitions: {
          AnimEvent.pause: TransitionConfig(
            target: AnimState.paused,
            action: (ctx) {
              recordPauseTime(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              stopTicker(ctx);
              resetContext(ctx);
              startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.complete: TransitionConfig(
            target: AnimState.completed,
            guard: (ctx) => !hasMoreLoops(ctx),
            action: (ctx) => ctx,
          ),
        },
        transient: TransientConfig(
          guard: (ctx) => false, // Completed with more loops
          target: AnimState.playing,
        ),
        onEntry: (ctx, from, to) {
          if (from == AnimState.idle) {
            ctx.onBegin?.call();
          }
        },
        onExit: (ctx, from, to) {
          ctx.ticker?.stop();
        },
      ),

      AnimState.paused: StateConfig(
        state: AnimState.paused,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              resumeTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              resetContext(ctx);
              startTicker(ctx);
              return ctx;
            },
          ),
        },
        onExit: (ctx, from, to) {
          ctx.pausedAt = null;
        },
      ),

      AnimState.completed: StateConfig(
        state: AnimState.completed,
        transitions: {
          AnimEvent.play: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              resetContext(ctx);
              startTicker(ctx);
              return ctx;
            },
          ),
          AnimEvent.stop: TransitionConfig(
            target: AnimState.idle,
            action: (ctx) {
              resetContext(ctx);
              return ctx;
            },
          ),
          AnimEvent.restart: TransitionConfig(
            target: AnimState.playing,
            action: (ctx) {
              resetContext(ctx);
              startTicker(ctx);
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
}
```

### Phase 2: Refactor KitoAnimation to Use FSM

```dart
class KitoAnimation {
  late final AnimationStateMachine _fsm;

  KitoAnimation({
    required List<AnimationTarget> targets,
    int duration = 1000,
    int delay = 0,
    EasingFunction easing = Easing.linear,
    int loop = 1,
    AnimationDirection direction = AnimationDirection.forward,
    bool autoplay = false,
    AnimationCallback? onUpdate,
    AnimationCompleteCallback? onComplete,
    AnimationCompleteCallback? onBegin,
  }) {
    final context = AnimationContext(
      targets: targets,
      duration: duration,
      delay: delay,
      easing: easing,
      loop: loop,
      direction: direction,
      onUpdate: onUpdate,
      onComplete: onComplete,
      onBegin: onBegin,
    );

    _fsm = AnimationStateMachine(context);

    if (autoplay) {
      play();
    }
  }

  // Expose FSM state as reactive signal
  Signal<AnimState> get currentState => _fsm.currentState;

  // Computed signals derived from context
  late final Computed<double> progress = computed(() {
    // Trigger recomputation when state changes
    _fsm.currentState.value;
    return _fsm.context.progress;
  });

  late final Computed<int> currentLoop = computed(() {
    _fsm.currentState.value;
    return _fsm.context.currentLoop;
  });

  // Backward-compatible getters
  double get progressValue => _fsm.context.progress;
  AnimationState get state => _animStateToLegacy(_fsm.currentState.value);
  int get currentLoopValue => _fsm.context.currentLoop;

  // Public API (unchanged!)
  void play() => _fsm.send(AnimEvent.play);
  void pause() => _fsm.send(AnimEvent.pause);
  void stop() => _fsm.send(AnimEvent.stop);
  void restart() => _fsm.send(AnimEvent.restart);

  void seek(double targetProgress) {
    _fsm.context.progress = targetProgress.clamp(0.0, 1.0);
    _updateTargets(_fsm.context);
  }

  void dispose() {
    stop();
    _fsm.dispose();
  }

  // Map new FSM states to legacy AnimationState enum
  AnimationState _animStateToLegacy(AnimState state) {
    switch (state) {
      case AnimState.idle: return AnimationState.idle;
      case AnimState.playing: return AnimationState.playing;
      case AnimState.paused: return AnimationState.paused;
      case AnimState.completed: return AnimationState.completed;
    }
  }
}
```

---

## Benefits of FSM Approach

### 1. Declarative State Management
- All states and transitions in one place
- Easy to visualize and reason about
- Self-documenting code

### 2. Better Testability
- Test state transitions independently
- Easy to test edge cases (e.g., pause while idle)
- Mock-friendly architecture

### 3. History Tracking
- Built-in transition history
- Debugging and analytics for free
- Can implement "undo" functionality

### 4. Guards and Actions
- Clear separation of concerns
- Reusable guard predicates
- Composable transition logic

### 5. Future Extensibility
- Easy to add new states (e.g., `seeking`, `buffering`)
- Easy to add new events (e.g., `skip`, `reverse`)
- Hierarchical states for complex animations

### 6. Reactive Integration
- FSM state is a Signal
- Computed values derived from state
- Effects can react to state changes

---

## Migration Strategy

### Phase 1: Create FSM Implementation (New Code)
- Implement `AnimationStateMachine` class
- Implement helper functions
- Write comprehensive tests

### Phase 2: Refactor KitoAnimation (Replace Internals)
- Replace manual state management with FSM
- Keep public API identical
- Update internal implementation

### Phase 3: Test and Validate
- Ensure all existing tests pass
- Add FSM-specific tests
- Performance benchmarking

### Phase 4: Documentation
- Update API docs
- Add FSM architecture guide
- Migration guide for advanced users

---

## Open Questions

1. **Performance**: Does FSM add overhead? Need benchmarks.
2. **Seek behavior**: Should seek() be an FSM event or direct mutation?
3. **Looping logic**: Should we model loop iterations as separate states?
4. **Timeline integration**: How does this affect Timeline class?

---

## Next Steps

1. ✓ Complete this design document
2. Create proof-of-concept implementation
3. Write comprehensive tests
4. Benchmark performance
5. Full implementation
6. Update documentation

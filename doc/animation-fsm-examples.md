# KitoAnimation FSM Examples

This document provides concrete examples of how the FSM-based animation system works.

## Example 1: Basic Animation Lifecycle

```dart
import 'package:kito/kito.dart';

void basicExample() {
  final position = signal(Offset.zero);

  final anim = animate()
    .to(position, Offset(100, 100))
    .withDuration(1000)
    .build();

  // State: idle
  print(anim.state); // AnimationState.idle

  // Event: play
  anim.play();
  // State: playing
  print(anim.state); // AnimationState.playing

  // Event: pause
  anim.pause();
  // State: paused
  print(anim.state); // AnimationState.paused

  // Event: play (resume)
  anim.play();
  // State: playing
  print(anim.state); // AnimationState.playing

  // Internal event: complete (triggered by ticker)
  // State: completed
  // Callback: onComplete() called
}
```

## Example 2: Looping Animation

```dart
void loopingExample() {
  final scale = signal(1.0);

  final anim = animate()
    .to(scale, 1.5)
    .withDuration(500)
    .withLoop(3) // 3 iterations
    .onComplete(() {
      print('All loops completed!');
    })
    .build();

  anim.play();

  // Internal flow:
  // 1. playing (loop 0)
  // 2. complete event → hasMoreLoops() = true
  // 3. playing (loop 1)
  // 4. complete event → hasMoreLoops() = true
  // 5. playing (loop 2)
  // 6. complete event → hasMoreLoops() = false
  // 7. completed → onComplete() called
}
```

## Example 3: State Machine with React Effect

```dart
void reactiveExample() {
  final position = signal(Offset.zero);

  final anim = animate()
    .to(position, Offset(200, 200))
    .withDuration(1000)
    .build();

  // React to state changes
  effect(() {
    final state = anim.currentState.value;
    print('Animation state changed to: $state');

    switch (state) {
      case AnimState.idle:
        print('Animation is ready');
        break;
      case AnimState.playing:
        print('Animation is running');
        break;
      case AnimState.paused:
        print('Animation is paused');
        break;
      case AnimState.completed:
        print('Animation finished');
        break;
    }
  });

  // Derived computed values
  final isRunning = computed(() =>
    anim.currentState.value == AnimState.playing
  );

  final canPause = computed(() =>
    anim.currentState.value == AnimState.playing
  );

  // Use in UI
  effect(() {
    if (isRunning.value) {
      print('Show pause button');
    } else {
      print('Show play button');
    }
  });

  anim.play();
  // Prints:
  // Animation state changed to: AnimState.playing
  // Animation is running
  // Show pause button
}
```

## Example 4: State Transition Guards

```dart
void guardsExample() {
  final opacity = signal(0.0);

  final anim = animate()
    .to(opacity, 1.0)
    .withDuration(1000)
    .build();

  // Try to pause when idle - FSM guard prevents invalid transition
  anim.pause(); // No effect, guard fails
  print(anim.state); // Still AnimationState.idle

  anim.play();
  print(anim.state); // AnimationState.playing

  anim.pause(); // Now it works
  print(anim.state); // AnimationState.paused
}
```

## Example 5: Restart Behavior

```dart
void restartExample() {
  final rotation = signal(0.0);

  final anim = animate()
    .to(rotation, 360.0)
    .withDuration(2000)
    .onBegin(() => print('Animation started'))
    .onComplete(() => print('Animation completed'))
    .build();

  anim.play();
  // State: playing
  // Callback: onBegin() called

  // After 1 second (halfway through)
  await Future.delayed(Duration(milliseconds: 1000));
  print(anim.progress.value); // ~0.5

  // Restart resets everything
  anim.restart();
  // State: playing (via idle transition)
  // Progress: 0.0
  // Callback: onBegin() called again
  print(anim.progress.value); // 0.0
}
```

## Example 6: Complex State-Driven UI

```dart
class AnimatedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scale = signal(1.0);
    final anim = animate()
      .to(scale, 1.2)
      .withDuration(300)
      .withDirection(AnimationDirection.alternate)
      .withLoop(2)
      .build();

    return ReactiveBuilder(
      builder: (context) {
        // Rebuild when animation state changes
        final state = anim.currentState.value;
        final progress = anim.progress.value;
        final currentScale = scale.value;

        return GestureDetector(
          onTapDown: (_) => anim.play(),
          child: Transform.scale(
            scale: currentScale,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getColorForState(state),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(_getLabelForState(state)),
                  if (state == AnimState.playing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getColorForState(AnimState state) {
    switch (state) {
      case AnimState.idle: return Colors.blue;
      case AnimState.playing: return Colors.green;
      case AnimState.paused: return Colors.orange;
      case AnimState.completed: return Colors.purple;
    }
  }

  String _getLabelForState(AnimState state) {
    switch (state) {
      case AnimState.idle: return 'Tap to animate';
      case AnimState.playing: return 'Animating...';
      case AnimState.paused: return 'Paused';
      case AnimState.completed: return 'Done!';
    }
  }
}
```

## Example 7: Transition History for Debugging

```dart
void historyExample() {
  final position = signal(Offset.zero);

  final anim = animate()
    .to(position, Offset(100, 100))
    .withDuration(1000)
    .build();

  // Track all state changes
  final history = <String>[];

  effect(() {
    final state = anim.currentState.value;
    history.add('State: $state at ${DateTime.now()}');
  });

  anim.play();
  anim.pause();
  anim.play();
  anim.stop();

  // View transition history
  for (final entry in history) {
    print(entry);
  }
  // Output:
  // State: AnimState.idle at 2024-01-15 10:00:00.000
  // State: AnimState.playing at 2024-01-15 10:00:00.100
  // State: AnimState.paused at 2024-01-15 10:00:01.000
  // State: AnimState.playing at 2024-01-15 10:00:02.000
  // State: AnimState.idle at 2024-01-15 10:00:03.000
}
```

## Example 8: Coordinating Multiple Animations

```dart
void coordinatedExample() {
  final x = signal(0.0);
  final y = signal(0.0);
  final scale = signal(1.0);

  final moveX = animate().to(x, 100.0).withDuration(1000).build();
  final moveY = animate().to(y, 100.0).withDuration(1000).build();
  final scaleAnim = animate().to(scale, 2.0).withDuration(500).build();

  // Start all when first one starts
  effect(() {
    if (moveX.currentState.value == AnimState.playing) {
      moveY.play();
      scaleAnim.play();
    }
  });

  // Stop all when any completes
  effect(() {
    if (moveX.currentState.value == AnimState.completed ||
        moveY.currentState.value == AnimState.completed) {
      moveX.stop();
      moveY.stop();
      scaleAnim.stop();
    }
  });

  moveX.play(); // Triggers all three
}
```

## Example 9: State-Based Animation Chaining

```dart
void chainingExample() async {
  final opacity = signal(0.0);
  final scale = signal(0.0);
  final rotation = signal(0.0);

  final fadeIn = animate()
    .to(opacity, 1.0)
    .withDuration(500)
    .build();

  final scaleUp = animate()
    .to(scale, 1.0)
    .withDuration(300)
    .build();

  final rotate = animate()
    .to(rotation, 360.0)
    .withDuration(600)
    .build();

  // Chain animations using state reactions
  effect(() {
    if (fadeIn.currentState.value == AnimState.completed) {
      scaleUp.play();
    }
  });

  effect(() {
    if (scaleUp.currentState.value == AnimState.completed) {
      rotate.play();
    }
  });

  // Start the chain
  fadeIn.play();

  // Flow:
  // 1. fadeIn: idle → playing → completed
  // 2. scaleUp: idle → playing → completed
  // 3. rotate: idle → playing → completed
}
```

## Example 10: Testing State Transitions

```dart
void testExample() {
  test('Animation state transitions correctly', () {
    final value = signal(0.0);
    final anim = animate().to(value, 100.0).withDuration(1000).build();

    // Initial state
    expect(anim.state, AnimationState.idle);

    // Play
    anim.play();
    expect(anim.state, AnimationState.playing);

    // Pause
    anim.pause();
    expect(anim.state, AnimationState.paused);

    // Resume
    anim.play();
    expect(anim.state, AnimationState.playing);

    // Stop
    anim.stop();
    expect(anim.state, AnimationState.idle);

    // Restart (from idle)
    anim.restart();
    expect(anim.state, AnimationState.playing);
  });

  test('Cannot pause when idle', () {
    final value = signal(0.0);
    final anim = animate().to(value, 100.0).build();

    anim.pause(); // Should have no effect
    expect(anim.state, AnimationState.idle);
  });

  test('Looping transitions correctly', () {
    final value = signal(0.0);
    var completeCount = 0;

    final anim = animate()
      .to(value, 100.0)
      .withDuration(100)
      .withLoop(3)
      .onComplete(() => completeCount++)
      .build();

    anim.play();

    // Simulate completion
    // Loop 1: playing → complete (has loops) → playing
    // Loop 2: playing → complete (has loops) → playing
    // Loop 3: playing → complete (no loops) → completed

    expect(completeCount, 1); // Only called once at true completion
    expect(anim.state, AnimationState.completed);
  });
}
```

## FSM Benefits in Action

### 1. Clear State Management
The FSM makes state transitions explicit and prevents invalid states.

### 2. Reactive Integration
FSM state is a Signal, enabling reactive UIs and effects.

### 3. Testability
Easy to test state transitions in isolation.

### 4. Debugging
Built-in history tracking and state visualization.

### 5. Extensibility
Easy to add new states/events without breaking existing code.

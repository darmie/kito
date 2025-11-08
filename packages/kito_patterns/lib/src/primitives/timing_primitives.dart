import 'dart:async';
import 'package:kito/kito.dart';

/// Atomic timing and orchestration primitives
///
/// These primitives help coordinate and time animations without
/// complex state machines. Pure functions for animation timing.

/// Simple delay helper
///
/// Delays the start of an animation by a specified duration.
///
/// Example:
/// ```dart
/// final anim = delay(
///   animate().to(opacity, 1.0).build(),
///   milliseconds: 500,
/// );
/// ```
KitoAnimation delay(
  KitoAnimation animation, {
  required int milliseconds,
}) {
  Future.delayed(Duration(milliseconds: milliseconds), () {
    animation.play();
  });
  return animation;
}

/// Chain animations in sequence
///
/// Plays animations one after another.
///
/// Example:
/// ```dart
/// chain([
///   animate().to(opacity, 1.0).build(),
///   animate().to(scale, 1.5).build(),
///   animate().to(rotation, 360.0).build(),
/// ]);
/// ```
void chain(List<KitoAnimation> animations, {int gap = 0}) {
  if (animations.isEmpty) return;

  animations[0].play();

  for (var i = 1; i < animations.length; i++) {
    final prevAnim = animations[i - 1];
    final currentAnim = animations[i];

    // Watch for completion of previous animation
    effect(() {
      if (prevAnim.currentState.value == AnimState.completed) {
        if (gap > 0) {
          Future.delayed(Duration(milliseconds: gap), () {
            currentAnim.play();
          });
        } else {
          currentAnim.play();
        }
      }
    });
  }
}

/// Run animations in parallel
///
/// Plays all animations simultaneously.
///
/// Example:
/// ```dart
/// parallel([
///   animate().to(opacity, 1.0).build(),
///   animate().to(scale, 1.5).build(),
///   animate().to(rotation, 360.0).build(),
/// ]);
/// ```
void parallel(List<KitoAnimation> animations) {
  for (final anim in animations) {
    anim.play();
  }
}

/// Wait for animation completion
///
/// Returns a Future that completes when the animation finishes.
///
/// Example:
/// ```dart
/// await waitFor(animation);
/// print('Animation complete!');
/// ```
Future<void> waitFor(KitoAnimation animation) {
  final completer = Completer<void>();

  effect(() {
    if (animation.currentState.value == AnimState.completed) {
      completer.complete();
    }
  });

  return completer.future;
}

/// Repeat animation a specific number of times
///
/// Alternative to loop that works with dynamic control.
///
/// Example:
/// ```dart
/// repeat(
///   animate().to(scale, 1.2).build(),
///   times: 5,
///   gap: 100,
/// );
/// ```
void repeat(
  KitoAnimation animation, {
  required int times,
  int gap = 0,
  bool reverse = false,
}) {
  var count = 0;

  void playNext() {
    if (count >= times) return;

    animation.play();
    count++;

    effect(() {
      if (animation.currentState.value == AnimState.completed) {
        if (reverse) {
          // Reverse direction for next iteration
          animation.restart();
        }

        if (count < times) {
          if (gap > 0) {
            Future.delayed(Duration(milliseconds: gap), playNext);
          } else {
            animation.restart();
            playNext();
          }
        }
      }
    });
  }

  playNext();
}

/// Yoyo animation (play forward then backward)
///
/// Creates a back-and-forth effect.
///
/// Example:
/// ```dart
/// yoyo(
///   animate().to(offsetX, 100.0).build(),
///   times: 3,
/// );
/// ```
void yoyo(
  KitoAnimation animation, {
  int times = 1,
  int gap = 0,
}) {
  // Each yoyo consists of forward + backward, so double the loop count
  repeat(animation, times: times * 2, gap: gap, reverse: true);
}

/// Stagger start times for multiple animations
///
/// Simplified version of StaggerHelper for quick use.
///
/// Example:
/// ```dart
/// final anims = [anim1, anim2, anim3, anim4];
/// staggerStart(anims, delayMs: 100);
/// ```
void staggerStart(
  List<KitoAnimation> animations, {
  required int delayMs,
  bool reverse = false,
}) {
  final indices = reverse
      ? List.generate(animations.length, (i) => animations.length - 1 - i)
      : List.generate(animations.length, (i) => i);

  for (final i in indices) {
    final anim = animations[i];
    final delay = delayMs * i;

    Future.delayed(Duration(milliseconds: delay), () {
      anim.play();
    });
  }
}

/// Synchronized start for multiple animations
///
/// Ensures all animations start at the exact same time.
///
/// Example:
/// ```dart
/// syncStart([anim1, anim2, anim3]);
/// ```
void syncStart(List<KitoAnimation> animations) {
  // Use microtask to ensure they all start in the same frame
  Future.microtask(() {
    for (final anim in animations) {
      anim.play();
    }
  });
}

/// Wait for all animations to complete
///
/// Returns a Future that completes when all animations are done.
///
/// Example:
/// ```dart
/// await waitForAll([anim1, anim2, anim3]);
/// print('All animations complete!');
/// ```
Future<void> waitForAll(List<KitoAnimation> animations) async {
  await Future.wait(animations.map((anim) => waitFor(anim)));
}

/// Wait for any animation to complete
///
/// Returns a Future that completes when the first animation finishes.
///
/// Example:
/// ```dart
/// await waitForAny([anim1, anim2, anim3]);
/// print('First animation complete!');
/// ```
Future<void> waitForAny(List<KitoAnimation> animations) async {
  final completer = Completer<void>();

  for (final anim in animations) {
    effect(() {
      if (anim.currentState.value == AnimState.completed && !completer.isCompleted) {
        completer.complete();
      }
    });
  }

  return completer.future;
}

/// Crossfade between two properties
///
/// Fades out one while fading in another.
///
/// Example:
/// ```dart
/// crossfade(
///   outOpacity: opacity1,
///   inOpacity: opacity2,
///   duration: 400,
/// );
/// ```
void crossfade({
  required Animatable<double> outOpacity,
  required Animatable<double> inOpacity,
  int duration = 400,
}) {
  final fadeOut = animate()
      .to(outOpacity, 0.0)
      .withDuration(duration)
      .build();

  final fadeIn = animate()
      .to(inOpacity, 1.0)
      .withDuration(duration)
      .build();

  parallel([fadeOut, fadeIn]);
}

/// Ping-pong animation (alternate between two values)
///
/// Creates an oscillating effect between two states.
///
/// Example:
/// ```dart
/// pingPong(
///   property: scale,
///   from: 1.0,
///   to: 1.3,
///   duration: 500,
///   times: 5,
/// );
/// ```
void pingPong({
  required Animatable<double> property,
  required double from,
  required double to,
  int duration = 500,
  int times = -1,
  int gap = 0,
}) {
  var isForward = true;
  var count = 0;

  void play() {
    if (times != -1 && count >= times) return;

    final anim = animate()
        .to(property, isForward ? to : from)
        .withDuration(duration)
        .withEasing(Easing.easeInOut)
        .build();

    anim.play();
    isForward = !isForward;
    count++;

    effect(() {
      if (anim.currentState.value == AnimState.completed) {
        if (times == -1 || count < times) {
          if (gap > 0) {
            Future.delayed(Duration(milliseconds: gap), play);
          } else {
            play();
          }
        }
      }
    });
  }

  play();
}

/// Ease between multiple keyframe values smoothly
///
/// Continuously animates through a sequence of values.
///
/// Example:
/// ```dart
/// easeThrough(
///   property: rotation,
///   values: [0.0, 45.0, 90.0, 135.0, 180.0],
///   duration: 2000,
/// );
/// ```
KitoAnimation easeThrough({
  required Animatable<double> property,
  required List<double> values,
  int duration = 1000,
  EasingFunction easing = Easing.easeInOut,
}) {
  if (values.length < 2) {
    throw ArgumentError('Need at least 2 values for easeThrough');
  }

  final keyframes = <Keyframe<double>>[];
  for (var i = 0; i < values.length; i++) {
    final offset = i / (values.length - 1);
    keyframes.add(Keyframe(
      value: values[i],
      offset: offset,
      easing: easing,
    ));
  }

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(duration)
      .build();
}

/// Interpolate smoothly between current and target over time
///
/// Creates a spring-like interpolation.
///
/// Example:
/// ```dart
/// smoothTo(
///   property: offsetX,
///   target: 200.0,
///   duration: 600,
///   tension: 0.8,
/// );
/// ```
KitoAnimation smoothTo({
  required Animatable<double> property,
  required double target,
  int duration = 500,
  double tension = 0.5,
}) {
  final start = property.value;
  final diff = target - start;

  // Create keyframes with tension-based easing
  return animate()
      .withKeyframes(property, [
        Keyframe(value: start, offset: 0.0),
        Keyframe(
          value: start + (diff * (1.0 + tension)),
          offset: 0.6,
          easing: Easing.easeOut,
        ),
        Keyframe(value: target, offset: 1.0),
      ])
      .withDuration(duration)
      .build();
}

/// Animate with momentum/inertia
///
/// Simulates physics-based motion with decay.
///
/// Example:
/// ```dart
/// momentum(
///   property: offsetX,
///   velocity: 500.0,
///   friction: 0.95,
///   duration: 1000,
/// );
/// ```
KitoAnimation momentum({
  required Animatable<double> property,
  required double velocity,
  double friction = 0.95,
  int duration = 1000,
}) {
  final start = property.value;

  // Calculate end position based on velocity and friction
  final distance = velocity * (1.0 - friction) * (duration / 1000.0);
  final target = start + distance;

  return animate()
      .to(property, target)
      .withDuration(duration)
      .withEasing(Easing.easeOut)
      .build();
}

/// Spring animation with configurable stiffness and damping
///
/// Creates a physics-based spring motion.
///
/// Example:
/// ```dart
/// spring(
///   property: scale,
///   target: 1.5,
///   stiffness: 200.0,
///   damping: 10.0,
/// );
/// ```
KitoAnimation spring({
  required Animatable<double> property,
  required double target,
  double stiffness = 100.0,
  double damping = 10.0,
  int duration = 800,
}) {
  final start = property.value;

  // Simplified spring calculation for keyframes
  final overshoot = (stiffness / damping) * 0.1;

  return animate()
      .withKeyframes(property, [
        Keyframe(value: start, offset: 0.0),
        Keyframe(
          value: target + (target - start) * overshoot,
          offset: 0.6,
          easing: Easing.easeOut,
        ),
        Keyframe(
          value: target - (target - start) * (overshoot * 0.3),
          offset: 0.8,
        ),
        Keyframe(value: target, offset: 1.0),
      ])
      .withDuration(duration)
      .build();
}

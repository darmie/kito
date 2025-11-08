import 'package:kito/kito.dart';

/// Primitive animation patterns that can be applied to any component
///
/// These are reusable, low-level effects that serve as building blocks
/// for more complex animations. Each primitive returns a configured
/// KitoAnimation that can be played, looped, or composed.

/// Configuration for elastic/rubber band effect
class ElasticConfig {
  /// Initial displacement amount
  final double displacement;

  /// Number of oscillations
  final int oscillations;

  /// Duration in milliseconds
  final int duration;

  /// Damping factor (0.0 to 1.0)
  final double damping;

  const ElasticConfig({
    this.displacement = 1.0,
    this.oscillations = 3,
    this.duration = 800,
    this.damping = 0.6,
  });

  static const ElasticConfig subtle = ElasticConfig(
    displacement: 0.5,
    oscillations: 2,
    duration: 600,
  );

  static const ElasticConfig strong = ElasticConfig(
    displacement: 1.5,
    oscillations: 4,
    duration: 1000,
  );
}

/// Create an elastic/rubber band animation
///
/// The property will oscillate around its target value with decreasing
/// amplitude, creating a spring-like or rubber band effect.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final anim = createElastic(scale, 1.5, config: ElasticConfig.strong);
/// anim.play();
/// ```
KitoAnimation createElastic<T>(
  Animatable<T> property,
  T targetValue, {
  ElasticConfig config = const ElasticConfig(),
}) {
  final startValue = property.value;

  // Create keyframes for elastic effect
  final keyframes = <Keyframe<T>>[];

  // Start at current value
  keyframes.add(Keyframe(value: startValue, offset: 0.0));

  // Create oscillations with decreasing amplitude
  for (var i = 1; i <= config.oscillations; i++) {
    final progress = i / config.oscillations;
    final offset = progress;

    // Oscillate between over and under the target
    final amplitude = config.displacement * (1.0 - (progress * config.damping));

    if (i % 2 == 1) {
      // Overshoot
      final overshoot = property.interpolate(
        targetValue,
        targetValue,
        1.0 + amplitude,
      );
      keyframes.add(Keyframe(
        value: overshoot,
        offset: offset - (0.5 / config.oscillations),
        easing: Easing.easeInOut,
      ));
    } else {
      // Undershoot
      final undershoot = property.interpolate(
        targetValue,
        targetValue,
        1.0 - amplitude,
      );
      keyframes.add(Keyframe(
        value: undershoot,
        offset: offset - (0.5 / config.oscillations),
        easing: Easing.easeInOut,
      ));
    }
  }

  // End at target value
  keyframes.add(Keyframe(value: targetValue, offset: 1.0));

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(config.duration)
      .build();
}

/// Configuration for bounce effect
class BounceConfig {
  /// Number of bounces
  final int bounces;

  /// Duration in milliseconds
  final int duration;

  /// Height of first bounce (relative to target)
  final double initialBounceHeight;

  /// How much each bounce decreases (0.0 to 1.0)
  final double decay;

  const BounceConfig({
    this.bounces = 3,
    this.duration = 800,
    this.initialBounceHeight = 0.3,
    this.decay = 0.5,
  });

  static const BounceConfig subtle = BounceConfig(
    bounces = 2,
    initialBounceHeight: 0.2,
    duration: 600,
  );

  static const BounceConfig playful = BounceConfig(
    bounces: 4,
    initialBounceHeight: 0.4,
    duration: 1000,
  );
}

/// Create a bounce animation
///
/// The property will bounce several times with decreasing amplitude
/// before settling at the target value.
///
/// Example:
/// ```dart
/// final posY = animatableDouble(0.0);
/// final anim = createBounce(posY, 100.0, config: BounceConfig.playful);
/// anim.play();
/// ```
KitoAnimation createBounce<T>(
  Animatable<T> property,
  T targetValue, {
  BounceConfig config = const BounceConfig(),
}) {
  final startValue = property.value;
  final keyframes = <Keyframe<T>>[];

  keyframes.add(Keyframe(value: startValue, offset: 0.0));

  // Create bounces
  for (var i = 1; i <= config.bounces; i++) {
    final progress = i / config.bounces;
    final bounceHeight = config.initialBounceHeight * (1.0 - (progress * config.decay));

    // Peak of bounce
    final peak = property.interpolate(
      targetValue,
      startValue,
      bounceHeight,
    );

    keyframes.add(Keyframe(
      value: peak,
      offset: progress - (0.5 / config.bounces),
      easing: Easing.easeOut,
    ));

    // Return to target
    keyframes.add(Keyframe(
      value: targetValue,
      offset: progress,
      easing: Easing.easeIn,
    ));
  }

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(config.duration)
      .build();
}

/// Configuration for shake/wiggle effect
class ShakeConfig {
  /// Intensity of shake
  final double intensity;

  /// Number of shakes
  final int shakes;

  /// Duration in milliseconds
  final int duration;

  /// Axis to shake on ('x' or 'y')
  final String axis;

  const ShakeConfig({
    this.intensity = 10.0,
    this.shakes = 4,
    this.duration = 400,
    this.axis = 'x',
  });

  static const ShakeConfig subtle = ShakeConfig(
    intensity: 5.0,
    shakes: 3,
    duration: 300,
  );

  static const ShakeConfig strong = ShakeConfig(
    intensity: 20.0,
    shakes: 6,
    duration: 600,
  );
}

/// Create a shake/wiggle animation
///
/// The property will shake back and forth with decreasing amplitude.
/// Commonly used for error states or to draw attention.
///
/// Example:
/// ```dart
/// final offsetX = animatableDouble(0.0);
/// final anim = createShake(offsetX, config: ShakeConfig.strong);
/// anim.play();
/// ```
KitoAnimation createShake(
  Animatable<double> property, {
  ShakeConfig config = const ShakeConfig(),
}) {
  final startValue = property.value;
  final keyframes = <Keyframe<double>>[];

  keyframes.add(Keyframe(value: startValue, offset: 0.0));

  // Create shake movements
  for (var i = 1; i <= config.shakes; i++) {
    final progress = i / config.shakes;
    final amplitude = config.intensity * (1.0 - progress);

    // Alternate direction
    final direction = i % 2 == 0 ? 1.0 : -1.0;

    keyframes.add(Keyframe(
      value: startValue + (amplitude * direction),
      offset: progress - (0.5 / config.shakes),
      easing: Easing.easeInOut,
    ));

    // Return to center
    if (i < config.shakes) {
      keyframes.add(Keyframe(
        value: startValue,
        offset: progress,
      ));
    }
  }

  // End at start value
  keyframes.add(Keyframe(value: startValue, offset: 1.0));

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(config.duration)
      .build();
}

/// Configuration for pulse effect
class PulseConfig {
  /// Scale at peak of pulse
  final double peakScale;

  /// Duration of one pulse in milliseconds
  final int duration;

  /// Number of pulses (or -1 for infinite)
  final int pulses;

  const PulseConfig({
    this.peakScale = 1.1,
    this.duration = 500,
    this.pulses = 3,
  });

  static const PulseConfig subtle = PulseConfig(
    peakScale: 1.05,
    duration: 400,
  );

  static const PulseConfig strong = PulseConfig(
    peakScale: 1.2,
    duration: 600,
  );

  static const PulseConfig infinite = PulseConfig(
    peakScale: 1.1,
    duration: 1000,
    pulses: -1,
  );
}

/// Create a pulse animation
///
/// The property will smoothly scale up and down, creating a pulsing effect.
/// Useful for attention-grabbing or loading states.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final anim = createPulse(scale, config: PulseConfig.infinite);
/// anim.play();
/// ```
KitoAnimation createPulse(
  Animatable<double> property, {
  PulseConfig config = const PulseConfig(),
}) {
  final startValue = property.value;

  final anim = animate()
      .withKeyframes(property, [
        Keyframe(value: startValue, offset: 0.0),
        Keyframe(value: startValue * config.peakScale, offset: 0.5, easing: Easing.easeInOut),
        Keyframe(value: startValue, offset: 1.0),
      ])
      .withDuration(config.duration);

  if (config.pulses == -1) {
    return anim.loopInfinitely().build();
  } else {
    return anim.withLoop(config.pulses).build();
  }
}

/// Configuration for flash effect
class FlashConfig {
  /// Opacity at peak of flash
  final double peakOpacity;

  /// Duration in milliseconds
  final int duration;

  /// Number of flashes
  final int flashes;

  const FlashConfig({
    this.peakOpacity = 0.0,
    this.duration = 600,
    this.flashes = 3,
  });

  static const FlashConfig quick = FlashConfig(
    duration: 400,
    flashes: 2,
  );

  static const FlashConfig slow = FlashConfig(
    duration: 800,
    flashes: 4,
  );
}

/// Create a flash animation
///
/// The property will flash between its current value and peak opacity.
/// Commonly used for visibility effects or notifications.
///
/// Example:
/// ```dart
/// final opacity = animatableDouble(1.0);
/// final anim = createFlash(opacity, config: FlashConfig.quick);
/// anim.play();
/// ```
KitoAnimation createFlash(
  Animatable<double> property, {
  FlashConfig config = const FlashConfig(),
}) {
  final startValue = property.value;
  final keyframes = <Keyframe<double>>[];

  keyframes.add(Keyframe(value: startValue, offset: 0.0));

  for (var i = 1; i <= config.flashes; i++) {
    final progress = i / config.flashes;

    // Flash
    keyframes.add(Keyframe(
      value: config.peakOpacity,
      offset: progress - (0.5 / config.flashes),
      easing: Easing.easeInOut,
    ));

    // Return
    keyframes.add(Keyframe(
      value: startValue,
      offset: progress,
    ));
  }

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(config.duration)
      .build();
}

/// Configuration for swing/pendulum effect
class SwingConfig {
  /// Maximum rotation angle in degrees
  final double maxAngle;

  /// Number of swings
  final int swings;

  /// Duration in milliseconds
  final int duration;

  const SwingConfig({
    this.maxAngle = 15.0,
    this.swings = 3,
    this.duration = 800,
  });

  static const SwingConfig gentle = SwingConfig(
    maxAngle: 10.0,
    swings: 2,
    duration: 600,
  );

  static const SwingConfig strong = SwingConfig(
    maxAngle: 25.0,
    swings: 4,
    duration: 1000,
  );
}

/// Create a swing/pendulum animation
///
/// The property (typically rotation) will swing back and forth
/// with decreasing amplitude like a pendulum.
///
/// Example:
/// ```dart
/// final rotation = animatableDouble(0.0);
/// final anim = createSwing(rotation, config: SwingConfig.strong);
/// anim.play();
/// ```
KitoAnimation createSwing(
  Animatable<double> property, {
  SwingConfig config = const SwingConfig(),
}) {
  final startValue = property.value;
  final keyframes = <Keyframe<double>>[];

  keyframes.add(Keyframe(value: startValue, offset: 0.0));

  for (var i = 1; i <= config.swings; i++) {
    final progress = i / config.swings;
    final amplitude = config.maxAngle * (1.0 - progress);

    // Swing one direction
    final direction = i % 2 == 0 ? 1.0 : -1.0;

    keyframes.add(Keyframe(
      value: startValue + (amplitude * direction),
      offset: progress - (0.5 / config.swings),
      easing: Easing.easeInOut,
    ));

    // Return to center
    keyframes.add(Keyframe(
      value: startValue,
      offset: progress,
    ));
  }

  return animate()
      .withKeyframes(property, keyframes)
      .withDuration(config.duration)
      .build();
}

/// Configuration for jello/wobble effect
class JelloConfig {
  /// Intensity of wobble
  final double intensity;

  /// Duration in milliseconds
  final int duration;

  const JelloConfig({
    this.intensity = 0.1,
    this.duration = 600,
  });

  static const JelloConfig subtle = JelloConfig(
    intensity: 0.05,
    duration: 500,
  );

  static const JelloConfig strong = JelloConfig(
    intensity: 0.15,
    duration: 800,
  );
}

/// Create a jello/wobble animation
///
/// Creates a gelatinous wobble effect by animating scale or skew.
/// The element appears to compress and stretch.
///
/// Example:
/// ```dart
/// final scaleX = animatableDouble(1.0);
/// final scaleY = animatableDouble(1.0);
/// final animX = createJello(scaleX, axis: 'x', config: JelloConfig.strong);
/// final animY = createJello(scaleY, axis: 'y', config: JelloConfig.strong);
/// animX.play();
/// animY.play();
/// ```
KitoAnimation createJello(
  Animatable<double> property, {
  String axis = 'x',
  JelloConfig config = const JelloConfig(),
}) {
  final startValue = property.value;

  return animate()
      .withKeyframes(property, [
        Keyframe(value: startValue, offset: 0.0),
        Keyframe(value: startValue * (1.0 + config.intensity), offset: 0.222),
        Keyframe(value: startValue * (1.0 - config.intensity), offset: 0.333),
        Keyframe(value: startValue * (1.0 + config.intensity * 0.5), offset: 0.444),
        Keyframe(value: startValue * (1.0 - config.intensity * 0.5), offset: 0.555),
        Keyframe(value: startValue * (1.0 + config.intensity * 0.25), offset: 0.666),
        Keyframe(value: startValue * (1.0 - config.intensity * 0.25), offset: 0.777),
        Keyframe(value: startValue, offset: 1.0),
      ])
      .withDuration(config.duration)
      .build();
}

/// Configuration for heartbeat effect
class HeartbeatConfig {
  /// Scale at peak of beat
  final double peakScale;

  /// Duration of one beat in milliseconds
  final int duration;

  /// Number of beats (or -1 for infinite)
  final int beats;

  const HeartbeatConfig({
    this.peakScale = 1.3,
    this.duration = 1000,
    this.beats = -1,
  });

  static const HeartbeatConfig slow = HeartbeatConfig(
    peakScale: 1.2,
    duration: 1400,
  );

  static const HeartbeatConfig fast = HeartbeatConfig(
    peakScale: 1.25,
    duration: 600,
  );
}

/// Create a heartbeat animation
///
/// Creates a double-pulse effect that mimics a heartbeat.
/// Useful for like buttons or health indicators.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final anim = createHeartbeat(scale, config: HeartbeatConfig.fast);
/// anim.play();
/// ```
KitoAnimation createHeartbeat(
  Animatable<double> property, {
  HeartbeatConfig config = const HeartbeatConfig(),
}) {
  final startValue = property.value;

  final anim = animate()
      .withKeyframes(property, [
        Keyframe(value: startValue, offset: 0.0),
        // First beat
        Keyframe(value: startValue * config.peakScale, offset: 0.14, easing: Easing.easeOut),
        Keyframe(value: startValue, offset: 0.28),
        // Second beat
        Keyframe(value: startValue * config.peakScale, offset: 0.42, easing: Easing.easeOut),
        Keyframe(value: startValue, offset: 0.70),
      ])
      .withDuration(config.duration);

  if (config.beats == -1) {
    return anim.loopInfinitely().build();
  } else {
    return anim.withLoop(config.beats).build();
  }
}

/// Helper to combine multiple primitives
///
/// Plays multiple animations simultaneously on different properties.
///
/// Example:
/// ```dart
/// final animations = combinePrimitives([
///   createPulse(scale),
///   createSwing(rotation),
///   createFlash(opacity),
/// ]);
///
/// // Play all at once
/// for (final anim in animations) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> combinePrimitives(List<KitoAnimation> animations) {
  return animations;
}

/// Helper to sequence primitives
///
/// Plays animations one after another with optional delays.
///
/// Example:
/// ```dart
/// sequencePrimitives([
///   createBounce(posY, 100.0),
///   createElastic(scale, 1.5),
///   createFlash(opacity),
/// ], delayBetween: 200);
/// ```
void sequencePrimitives(
  List<KitoAnimation> animations, {
  int delayBetween = 0,
}) {
  var cumulativeDelay = 0;

  for (var i = 0; i < animations.length; i++) {
    final anim = animations[i];

    Future.delayed(Duration(milliseconds: cumulativeDelay), () {
      anim.play();
    });

    cumulativeDelay += anim.duration + delayBetween;
  }
}

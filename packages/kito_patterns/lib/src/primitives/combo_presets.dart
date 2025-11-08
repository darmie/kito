import 'package:kito/kito.dart';

/// Combo animation presets that combine multiple effects
///
/// These are higher-level presets that orchestrate multiple properties
/// for dramatic, attention-grabbing effects.

/// Configuration for dramatic entrance
class DramaticEntranceConfig {
  /// Duration in milliseconds
  final int duration;

  /// Final scale
  final double finalScale;

  /// Rotation amount in radians
  final double rotation;

  const DramaticEntranceConfig({
    this.duration = 1000,
    this.finalScale = 1.0,
    this.rotation = 6.28, // Full rotation
  });

  static const DramaticEntranceConfig quick = DramaticEntranceConfig(
    duration: 600,
    rotation: 3.14, // Half rotation
  );

  static const DramaticEntranceConfig theatrical = DramaticEntranceConfig(
    duration: 1400,
    rotation: 12.56, // Double rotation
    finalScale: 1.2,
  );
}

/// Create a dramatic entrance animation
///
/// Combines fade, scale, and rotation for a theatrical entrance effect.
/// Perfect for splash screens, important notifications, or celebrations.
///
/// Example:
/// ```dart
/// final opacity = animatableDouble(0.0);
/// final scale = animatableDouble(0.0);
/// final rotation = animatableDouble(0.0);
///
/// final anims = createDramaticEntrance(
///   opacity: opacity,
///   scale: scale,
///   rotation: rotation,
///   config: DramaticEntranceConfig.theatrical,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createDramaticEntrance({
  required Animatable<double> opacity,
  required Animatable<double> scale,
  required Animatable<double> rotation,
  DramaticEntranceConfig config = const DramaticEntranceConfig(),
}) {
  return [
    // Fade in
    animate()
        .to(opacity, 1.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeOutCubic)
        .build(),

    // Scale up with bounce
    animate()
        .withKeyframes(scale, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: config.finalScale * 1.1, offset: 0.7, easing: Easing.easeOutCubic),
          Keyframe(value: config.finalScale, offset: 1.0, easing: Easing.easeInOut),
        ])
        .withDuration(config.duration)
        .build(),

    // Rotate in
    animate()
        .to(rotation, config.rotation)
        .withDuration(config.duration)
        .withEasing(Easing.easeOutCubic)
        .build(),
  ];
}

/// Create a dramatic exit animation
///
/// Combines fade, scale, and rotation for a theatrical exit effect.
///
/// Example:
/// ```dart
/// final opacity = animatableDouble(1.0);
/// final scale = animatableDouble(1.0);
/// final rotation = animatableDouble(0.0);
///
/// final anims = createDramaticExit(
///   opacity: opacity,
///   scale: scale,
///   rotation: rotation,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createDramaticExit({
  required Animatable<double> opacity,
  required Animatable<double> scale,
  required Animatable<double> rotation,
  DramaticEntranceConfig config = const DramaticEntranceConfig(),
}) {
  return [
    // Fade out
    animate()
        .to(opacity, 0.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeInCubic)
        .build(),

    // Scale down
    animate()
        .to(scale, 0.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeInCubic)
        .build(),

    // Rotate out
    animate()
        .to(rotation, rotation.value + config.rotation)
        .withDuration(config.duration)
        .withEasing(Easing.easeInCubic)
        .build(),
  ];
}

/// Configuration for pop effect
class PopConfig {
  /// Duration in milliseconds
  final int duration;

  /// Peak scale
  final double peakScale;

  /// Final scale
  final double finalScale;

  const PopConfig({
    this.duration = 400,
    this.peakScale = 1.2,
    this.finalScale = 1.0,
  });

  static const PopConfig subtle = PopConfig(
    duration: 300,
    peakScale: 1.1,
  );

  static const PopConfig strong = PopConfig(
    duration: 500,
    peakScale = 1.4,
  );
}

/// Create a pop-in animation
///
/// Element appears with an elastic pop effect.
/// Perfect for buttons, notifications, or any interactive element.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(0.0);
/// final opacity = animatableDouble(0.0);
///
/// final anims = createPopIn(scale: scale, opacity: opacity);
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createPopIn({
  required Animatable<double> scale,
  required Animatable<double> opacity,
  PopConfig config = const PopConfig(),
}) {
  return [
    // Quick fade in
    animate()
        .to(opacity, 1.0)
        .withDuration((config.duration * 0.6).round())
        .withEasing(Easing.easeOut)
        .build(),

    // Elastic scale
    animate()
        .withKeyframes(scale, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: config.peakScale, offset: 0.7, easing: Easing.easeOutCubic),
          Keyframe(value: config.finalScale, offset: 1.0, easing: Easing.easeOutBack),
        ])
        .withDuration(config.duration)
        .build(),
  ];
}

/// Create a pop-out animation
///
/// Element disappears with a quick pop effect.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final opacity = animatableDouble(1.0);
///
/// final anims = createPopOut(scale: scale, opacity: opacity);
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createPopOut({
  required Animatable<double> scale,
  required Animatable<double> opacity,
  PopConfig config = const PopConfig(),
}) {
  return [
    // Quick fade out
    animate()
        .to(opacity, 0.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeIn)
        .build(),

    // Quick scale down with overshoot
    animate()
        .withKeyframes(scale, [
          Keyframe(value: config.finalScale, offset: 0.0),
          Keyframe(value: config.finalScale * 1.1, offset: 0.3, easing: Easing.easeIn),
          Keyframe(value: 0.0, offset: 1.0, easing: Easing.easeInBack),
        ])
        .withDuration(config.duration)
        .build(),
  ];
}

/// Configuration for grow/shrink effect
class GrowShrinkConfig {
  /// Duration in milliseconds
  final int duration;

  /// Target scale
  final double targetScale;

  const GrowShrinkConfig({
    this.duration = 400,
    this.targetScale = 1.2,
  });

  static const GrowShrinkConfig subtle = GrowShrinkConfig(
    targetScale: 1.1,
    duration: 300,
  );

  static const GrowShrinkConfig strong = GrowShrinkConfig(
    targetScale: 1.5,
    duration: 500,
  );
}

/// Create a grow animation
///
/// Element smoothly grows larger.
/// Useful for hover effects or emphasis.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final anim = createGrow(scale, config: GrowShrinkConfig.strong);
/// anim.play();
/// ```
KitoAnimation createGrow(
  Animatable<double> property, {
  GrowShrinkConfig config = const GrowShrinkConfig(),
}) {
  return animate()
      .to(property, config.targetScale)
      .withDuration(config.duration)
      .withEasing(Easing.easeOutBack)
      .build();
}

/// Create a shrink animation
///
/// Element smoothly shrinks smaller.
///
/// Example:
/// ```dart
/// final scale = animatableDouble(1.0);
/// final anim = createShrink(scale, config: GrowShrinkConfig.subtle);
/// anim.play();
/// ```
KitoAnimation createShrink(
  Animatable<double> property, {
  double targetScale = 0.8,
  int duration = 400,
}) {
  return animate()
      .to(property, targetScale)
      .withDuration(duration)
      .withEasing(Easing.easeInBack)
      .build();
}

/// Configuration for rotate-in effect
class RotateInConfig {
  /// Duration in milliseconds
  final int duration;

  /// Starting rotation in radians
  final double startRotation;

  /// Final rotation in radians
  final double finalRotation;

  const RotateInConfig({
    this.duration = 600,
    this.startRotation = 3.14, // 180 degrees
    this.finalRotation = 0.0,
  });

  static const RotateInConfig quick = RotateInConfig(
    duration: 400,
    startRotation: 1.57, // 90 degrees
  );

  static const RotateInConfig full = RotateInConfig(
    duration: 800,
    startRotation: 6.28, // 360 degrees
  );
}

/// Create a rotate-in animation
///
/// Element rotates into view with fade and scale.
/// Great for cards, modals, or attention-grabbing elements.
///
/// Example:
/// ```dart
/// final rotation = animatableDouble(3.14);
/// final opacity = animatableDouble(0.0);
/// final scale = animatableDouble(0.0);
///
/// final anims = createRotateIn(
///   rotation: rotation,
///   opacity: opacity,
///   scale: scale,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createRotateIn({
  required Animatable<double> rotation,
  required Animatable<double> opacity,
  required Animatable<double> scale,
  RotateInConfig config = const RotateInConfig(),
}) {
  return [
    // Rotate
    animate()
        .to(rotation, config.finalRotation)
        .withDuration(config.duration)
        .withEasing(Easing.easeOutBack)
        .build(),

    // Fade in
    animate()
        .to(opacity, 1.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeOut)
        .build(),

    // Scale in
    animate()
        .to(scale, 1.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeOutBack)
        .build(),
  ];
}

/// Create a rotate-out animation
///
/// Element rotates out of view with fade and scale.
///
/// Example:
/// ```dart
/// final rotation = animatableDouble(0.0);
/// final opacity = animatableDouble(1.0);
/// final scale = animatableDouble(1.0);
///
/// final anims = createRotateOut(
///   rotation: rotation,
///   opacity: opacity,
///   scale: scale,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createRotateOut({
  required Animatable<double> rotation,
  required Animatable<double> opacity,
  required Animatable<double> scale,
  RotateInConfig config = const RotateInConfig(),
}) {
  return [
    // Rotate
    animate()
        .to(rotation, rotation.value + config.startRotation)
        .withDuration(config.duration)
        .withEasing(Easing.easeInBack)
        .build(),

    // Fade out
    animate()
        .to(opacity, 0.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeIn)
        .build(),

    // Scale out
    animate()
        .to(scale, 0.0)
        .withDuration(config.duration)
        .withEasing(Easing.easeInBack)
        .build(),
  ];
}

/// Configuration for attention seeker combo
class AttentionSeekerConfig {
  /// Duration in milliseconds
  final int duration;

  const AttentionSeekerConfig({
    this.duration = 1000,
  });

  static const AttentionSeekerConfig quick = AttentionSeekerConfig(
    duration: 600,
  );

  static const AttentionSeekerConfig slow = AttentionSeekerConfig(
    duration: 1400,
  );
}

/// Create a bouncy attention seeker
///
/// Combines bounce with scale pulse for maximum attention.
/// Perfect for notifications, alerts, or CTAs.
///
/// Example:
/// ```dart
/// final posY = animatableDouble(0.0);
/// final scale = animatableDouble(1.0);
///
/// final anims = createBouncyAttention(
///   posY: posY,
///   scale: scale,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createBouncyAttention({
  required Animatable<double> posY,
  required Animatable<double> scale,
  AttentionSeekerConfig config = const AttentionSeekerConfig(),
}) {
  return [
    // Bounce vertically
    animate()
        .withKeyframes(posY, [
          Keyframe(value: posY.value, offset: 0.0),
          Keyframe(value: posY.value - 30, offset: 0.2, easing: Easing.easeOut),
          Keyframe(value: posY.value, offset: 0.4, easing: Easing.easeIn),
          Keyframe(value: posY.value - 15, offset: 0.6, easing: Easing.easeOut),
          Keyframe(value: posY.value, offset: 0.8, easing: Easing.easeIn),
          Keyframe(value: posY.value, offset: 1.0),
        ])
        .withDuration(config.duration)
        .build(),

    // Pulse scale
    animate()
        .withKeyframes(scale, [
          Keyframe(value: 1.0, offset: 0.0),
          Keyframe(value: 1.1, offset: 0.5, easing: Easing.easeInOut),
          Keyframe(value: 1.0, offset: 1.0, easing: Easing.easeInOut),
        ])
        .withDuration(config.duration)
        .build(),
  ];
}

/// Create a wiggle attention seeker
///
/// Combines rotation shake with scale pulse.
/// Playful way to grab attention.
///
/// Example:
/// ```dart
/// final rotation = animatableDouble(0.0);
/// final scale = animatableDouble(1.0);
///
/// final anims = createWiggleAttention(
///   rotation: rotation,
///   scale: scale,
/// );
///
/// for (final anim in anims) {
///   anim.play();
/// }
/// ```
List<KitoAnimation> createWiggleAttention({
  required Animatable<double> rotation,
  required Animatable<double> scale,
  AttentionSeekerConfig config = const AttentionSeekerConfig(),
}) {
  return [
    // Wiggle rotation
    animate()
        .withKeyframes(rotation, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: -0.1, offset: 0.125, easing: Easing.easeInOut),
          Keyframe(value: 0.1, offset: 0.25, easing: Easing.easeInOut),
          Keyframe(value: -0.1, offset: 0.375, easing: Easing.easeInOut),
          Keyframe(value: 0.1, offset: 0.5, easing: Easing.easeInOut),
          Keyframe(value: -0.05, offset: 0.625, easing: Easing.easeInOut),
          Keyframe(value: 0.05, offset: 0.75, easing: Easing.easeInOut),
          Keyframe(value: 0.0, offset: 1.0),
        ])
        .withDuration(config.duration)
        .build(),

    // Pulse scale
    animate()
        .withKeyframes(scale, [
          Keyframe(value: 1.0, offset: 0.0),
          Keyframe(value: 1.05, offset: 0.5, easing: Easing.easeInOut),
          Keyframe(value: 1.0, offset: 1.0, easing: Easing.easeInOut),
        ])
        .withDuration(config.duration)
        .build(),
  ];
}

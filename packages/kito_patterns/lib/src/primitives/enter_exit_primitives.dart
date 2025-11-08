import 'package:kito/kito.dart';

/// Atomic enter/exit animation primitives
///
/// These are fundamental building blocks for visibility transitions.
/// Each primitive is a pure, composable function that creates a configured animation.

/// Configuration for fade animations
class FadeConfig {
  /// Starting opacity
  final double fromOpacity;

  /// Ending opacity
  final double toOpacity;

  /// Duration in milliseconds
  final int duration;

  /// Easing function
  final EasingFunction easing;

  const FadeConfig({
    this.fromOpacity = 0.0,
    this.toOpacity = 1.0,
    this.duration = 300,
    this.easing = Easing.easeOutSine,
  });

  static const FadeConfig quick = FadeConfig(duration: 150);
  static const FadeConfig slow = FadeConfig(duration: 600);
}

/// Atomic fade in
KitoAnimation fadeIn(
  Animatable<double> opacity, {
  FadeConfig config = const FadeConfig(),
}) {
  opacity.value = config.fromOpacity;

  return animate()
      .to(opacity, config.toOpacity)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic fade out
KitoAnimation fadeOut(
  Animatable<double> opacity, {
  FadeConfig? config,
}) {
  final cfg = config ??
      FadeConfig(
        fromOpacity: opacity.value,
        toOpacity: 0.0,
        duration: 300,
        easing: Easing.easeInSine,
      );

  return animate()
      .to(opacity, cfg.toOpacity)
      .withDuration(cfg.duration)
      .withEasing(cfg.easing)
      .build();
}

/// Configuration for slide animations
class SlideConfig {
  /// Starting offset (in pixels or percentage)
  final double fromOffset;

  /// Ending offset
  final double toOffset;

  /// Duration in milliseconds
  final int duration;

  /// Easing function
  final EasingFunction easing;

  const SlideConfig({
    this.fromOffset = 0.0,
    this.toOffset = 0.0,
    this.duration = 350,
    this.easing = Easing.easeOutCubic,
  });

  static const SlideConfig quick = SlideConfig(duration: 200);
  static const SlideConfig smooth =
      SlideConfig(duration: 400, easing: Easing.easeInOutCubic);
}

/// Atomic slide in from right
KitoAnimation slideInFromRight(
  Animatable<double> offsetX,
  double distance, {
  SlideConfig config = const SlideConfig(),
}) {
  offsetX.value = distance;

  return animate()
      .to(offsetX, 0.0)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide in from left
KitoAnimation slideInFromLeft(
  Animatable<double> offsetX,
  double distance, {
  SlideConfig config = const SlideConfig(),
}) {
  offsetX.value = -distance;

  return animate()
      .to(offsetX, 0.0)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide in from top
KitoAnimation slideInFromTop(
  Animatable<double> offsetY,
  double distance, {
  SlideConfig config = const SlideConfig(),
}) {
  offsetY.value = -distance;

  return animate()
      .to(offsetY, 0.0)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide in from bottom
KitoAnimation slideInFromBottom(
  Animatable<double> offsetY,
  double distance, {
  SlideConfig config = const SlideConfig(),
}) {
  offsetY.value = distance;

  return animate()
      .to(offsetY, 0.0)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide out to right
KitoAnimation slideOutToRight(
  Animatable<double> offsetX,
  double distance, {
  SlideConfig config = const SlideConfig(easing: Easing.easeInCubic),
}) {
  return animate()
      .to(offsetX, distance)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide out to left
KitoAnimation slideOutToLeft(
  Animatable<double> offsetX,
  double distance, {
  SlideConfig config = const SlideConfig(easing: Easing.easeInCubic),
}) {
  return animate()
      .to(offsetX, -distance)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide out to top
KitoAnimation slideOutToTop(
  Animatable<double> offsetY,
  double distance, {
  SlideConfig config = const SlideConfig(easing: Easing.easeInCubic),
}) {
  return animate()
      .to(offsetY, -distance)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic slide out to bottom
KitoAnimation slideOutToBottom(
  Animatable<double> offsetY,
  double distance, {
  SlideConfig config = const SlideConfig(easing: Easing.easeInCubic),
}) {
  return animate()
      .to(offsetY, distance)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Configuration for scale animations
class ScaleConfig {
  /// Starting scale
  final double fromScale;

  /// Ending scale
  final double toScale;

  /// Duration in milliseconds
  final int duration;

  /// Easing function
  final EasingFunction easing;

  const ScaleConfig({
    this.fromScale = 0.0,
    this.toScale = 1.0,
    this.duration = 300,
    this.easing = Easing.easeOutBack,
  });

  static const ScaleConfig quick = ScaleConfig(duration: 200);
  static const ScaleConfig smooth =
      ScaleConfig(duration: 400, easing: Easing.easeOutCubic);
  static const ScaleConfig elastic =
      ScaleConfig(duration: 500, easing: Easing.easeOutElastic);
}

/// Atomic scale in (grow)
KitoAnimation scaleIn(
  Animatable<double> scale, {
  ScaleConfig config = const ScaleConfig(),
}) {
  scale.value = config.fromScale;

  return animate()
      .to(scale, config.toScale)
      .withDuration(config.duration)
      .withEasing(config.easing)
      .build();
}

/// Atomic scale out (shrink)
KitoAnimation scaleOut(
  Animatable<double> scale, {
  ScaleConfig? config,
}) {
  final cfg = config ??
      ScaleConfig(
        fromScale: scale.value,
        toScale: 0.0,
        duration: 300,
        easing: Easing.easeInBack,
      );

  return animate()
      .to(scale, cfg.toScale)
      .withDuration(cfg.duration)
      .withEasing(cfg.easing)
      .build();
}

/// Configuration for rotate animations
class RotateConfig {
  /// Starting rotation in degrees
  final double fromRotation;

  /// Ending rotation in degrees
  final double toRotation;

  /// Duration in milliseconds
  final int duration;

  /// Easing function
  final EasingFunction easing;

  const RotateConfig({
    this.fromRotation = 0.0,
    this.toRotation = 0.0,
    this.duration = 400,
    this.easing = Easing.easeOutCubic,
  });

  static const RotateConfig quick = RotateConfig(duration: 250);
  static const RotateConfig smooth = RotateConfig(duration: 500);
}

/// Atomic rotate in (clockwise)
KitoAnimation rotateIn(
  Animatable<double> rotation, {
  double fromDegrees = 180.0,
  RotateConfig? config,
}) {
  rotation.value = fromDegrees;
  final cfg =
      config ?? RotateConfig(fromRotation: fromDegrees, toRotation: 0.0);

  return animate()
      .to(rotation, cfg.toRotation)
      .withDuration(cfg.duration)
      .withEasing(cfg.easing)
      .build();
}

/// Atomic rotate out (clockwise)
KitoAnimation rotateOut(
  Animatable<double> rotation, {
  double toDegrees = 180.0,
  RotateConfig? config,
}) {
  final cfg = config ??
      RotateConfig(fromRotation: rotation.value, toRotation: toDegrees);

  return animate()
      .to(rotation, cfg.toRotation)
      .withDuration(cfg.duration)
      .withEasing(cfg.easing)
      .build();
}

/// Atomic blur in (from blurred to sharp)
KitoAnimation blurIn(
  Animatable<double> blur, {
  double fromBlur = 10.0,
  int duration = 400,
}) {
  blur.value = fromBlur;

  return animate()
      .to(blur, 0.0)
      .withDuration(duration)
      .withEasing(Easing.easeOutSine)
      .build();
}

/// Atomic blur out (from sharp to blurred)
KitoAnimation blurOut(
  Animatable<double> blur, {
  double toBlur = 10.0,
  int duration = 400,
}) {
  return animate()
      .to(blur, toBlur)
      .withDuration(duration)
      .withEasing(Easing.easeInSine)
      .build();
}

/// Combination primitives - common combinations of atomic effects

/// Fade + Scale in
KitoAnimation fadeScaleIn(
  Animatable<double> opacity,
  Animatable<double> scale, {
  FadeConfig? fadeConfig,
  ScaleConfig? scaleConfig,
}) {
  final fadeCfg = fadeConfig ?? const FadeConfig();
  final scaleCfg = scaleConfig ?? const ScaleConfig();

  opacity.value = fadeCfg.fromOpacity;
  scale.value = scaleCfg.fromScale;

  return animate()
      .to(opacity, fadeCfg.toOpacity)
      .to(scale, scaleCfg.toScale)
      .withDuration(fadeCfg.duration)
      .withEasing(scaleCfg.easing)
      .build();
}

/// Fade + Scale out
KitoAnimation fadeScaleOut(
  Animatable<double> opacity,
  Animatable<double> scale, {
  int duration = 300,
}) {
  return animate()
      .to(opacity, 0.0)
      .to(scale, 0.0)
      .withDuration(duration)
      .withEasing(Easing.easeInBack)
      .build();
}

/// Slide + Fade in
KitoAnimation slideFadeIn(
  Animatable<double> opacity,
  Animatable<double> offset,
  double distance, {
  FadeConfig? fadeConfig,
  SlideConfig? slideConfig,
}) {
  final fadeCfg = fadeConfig ?? const FadeConfig();
  final slideCfg = slideConfig ?? const SlideConfig();

  opacity.value = fadeCfg.fromOpacity;
  offset.value = distance;

  return animate()
      .to(opacity, fadeCfg.toOpacity)
      .to(offset, 0.0)
      .withDuration(slideCfg.duration)
      .withEasing(slideCfg.easing)
      .build();
}

/// Slide + Fade out
KitoAnimation slideFadeOut(
  Animatable<double> opacity,
  Animatable<double> offset,
  double distance, {
  int duration = 300,
}) {
  return animate()
      .to(opacity, 0.0)
      .to(offset, distance)
      .withDuration(duration)
      .withEasing(Easing.easeInCubic)
      .build();
}

/// Rotate + Scale in (spin and grow)
KitoAnimation rotateScaleIn(
  Animatable<double> rotation,
  Animatable<double> scale, {
  double fromDegrees = 180.0,
  ScaleConfig? scaleConfig,
}) {
  final cfg = scaleConfig ?? const ScaleConfig();

  rotation.value = fromDegrees;
  scale.value = cfg.fromScale;

  return animate()
      .to(rotation, 0.0)
      .to(scale, cfg.toScale)
      .withDuration(cfg.duration)
      .withEasing(cfg.easing)
      .build();
}

/// Rotate + Scale out (spin and shrink)
KitoAnimation rotateScaleOut(
  Animatable<double> rotation,
  Animatable<double> scale, {
  double toDegrees = 180.0,
  int duration = 400,
}) {
  return animate()
      .to(rotation, toDegrees)
      .to(scale, 0.0)
      .withDuration(duration)
      .withEasing(Easing.easeInBack)
      .build();
}

/// Flip in (3D-like rotation)
KitoAnimation flipIn(
  Animatable<double> rotation,
  Animatable<double> opacity, {
  String axis = 'y', // 'x' or 'y'
  int duration = 500,
}) {
  rotation.value = 90.0;
  opacity.value = 0.0;

  return animate()
      .withKeyframes(rotation, [
        Keyframe(value: 90.0, offset: 0.0),
        Keyframe(value: -10.0, offset: 0.6),
        Keyframe(value: 0.0, offset: 1.0),
      ])
      .to(opacity, 1.0)
      .withDuration(duration)
      .withEasing(Easing.easeOutSine)
      .build();
}

/// Flip out (3D-like rotation)
KitoAnimation flipOut(
  Animatable<double> rotation,
  Animatable<double> opacity, {
  String axis = 'y',
  int duration = 500,
}) {
  return animate()
      .withKeyframes(rotation, [
        Keyframe(value: 0.0, offset: 0.0),
        Keyframe(value: 10.0, offset: 0.4),
        Keyframe(value: 90.0, offset: 1.0),
      ])
      .to(opacity, 0.0)
      .withDuration(duration)
      .withEasing(Easing.easeInSine)
      .build();
}

/// Zoom in (scale + fade combination with bounce)
KitoAnimation zoomIn(
  Animatable<double> scale,
  Animatable<double> opacity, {
  int duration = 400,
}) {
  scale.value = 0.3;
  opacity.value = 0.0;

  return animate()
      .withKeyframes(scale, [
        Keyframe(value: 0.3, offset: 0.0),
        Keyframe(value: 1.05, offset: 0.7),
        Keyframe(value: 1.0, offset: 1.0),
      ])
      .to(opacity, 1.0)
      .withDuration(duration)
      .withEasing(Easing.easeOutSine)
      .build();
}

/// Zoom out (scale + fade combination with shrink)
KitoAnimation zoomOut(
  Animatable<double> scale,
  Animatable<double> opacity, {
  int duration = 400,
}) {
  return animate()
      .withKeyframes(scale, [
        Keyframe(value: 1.0, offset: 0.0),
        Keyframe(value: 0.95, offset: 0.3),
        Keyframe(value: 0.3, offset: 1.0),
      ])
      .to(opacity, 0.0)
      .withDuration(duration)
      .withEasing(Easing.easeInSine)
      .build();
}

import '../types/types.dart';

/// Represents a keyframe in an animation
class Keyframe<T> {
  /// The value at this keyframe
  final T value;

  /// Time offset (0.0 to 1.0) within the animation duration
  final double offset;

  /// Easing function to use from this keyframe to the next
  final EasingFunction? easing;

  /// Create a keyframe
  const Keyframe({
    required this.value,
    required this.offset,
    this.easing,
  });
}

/// Build keyframes from a list of values
class KeyframeBuilder<T> {
  final List<Keyframe<T>> _keyframes = [];

  /// Add a keyframe at a specific offset
  KeyframeBuilder<T> at(double offset, T value, {EasingFunction? easing}) {
    _keyframes.add(Keyframe(
      value: value,
      offset: offset,
      easing: easing,
    ));
    return this;
  }

  /// Build the keyframes list (sorted by offset)
  List<Keyframe<T>> build() {
    _keyframes.sort((a, b) => a.offset.compareTo(b.offset));
    return List.unmodifiable(_keyframes);
  }
}

/// Helper to create keyframes
KeyframeBuilder<T> keyframes<T>() => KeyframeBuilder<T>();

/// Get the interpolated value between keyframes at a given progress
T interpolateKeyframes<T>(
  List<Keyframe<T>> keyframes,
  double progress,
  T Function(T start, T end, double t) interpolator,
  EasingFunction defaultEasing,
) {
  if (keyframes.isEmpty) {
    throw ArgumentError('Keyframes list cannot be empty');
  }

  if (keyframes.length == 1) {
    return keyframes.first.value;
  }

  // Clamp progress
  progress = progress.clamp(0.0, 1.0);

  // Find the keyframes to interpolate between
  Keyframe<T>? startKeyframe;
  Keyframe<T>? endKeyframe;

  for (int i = 0; i < keyframes.length - 1; i++) {
    if (progress >= keyframes[i].offset && progress <= keyframes[i + 1].offset) {
      startKeyframe = keyframes[i];
      endKeyframe = keyframes[i + 1];
      break;
    }
  }

  // If we're past the last keyframe, use the last value
  if (startKeyframe == null || endKeyframe == null) {
    return keyframes.last.value;
  }

  // Calculate local progress between the two keyframes
  final offsetDiff = endKeyframe.offset - startKeyframe.offset;
  final localProgress = offsetDiff > 0
      ? (progress - startKeyframe.offset) / offsetDiff
      : 1.0;

  // Apply easing
  final easing = startKeyframe.easing ?? defaultEasing;
  final easedProgress = easing(localProgress);

  // Interpolate
  return interpolator(
    startKeyframe.value,
    endKeyframe.value,
    easedProgress,
  );
}

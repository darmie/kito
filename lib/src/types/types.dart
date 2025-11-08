import 'dart:ui';

/// Duration in milliseconds
typedef Duration = int;

/// Callback for animation updates
typedef AnimationCallback = void Function(double progress);

/// Callback for animation completion
typedef AnimationCompleteCallback = void Function();

/// Easing function type
typedef EasingFunction = double Function(double t);

/// Interpolation function for custom types
typedef Interpolator<T> = T Function(T start, T end, double progress);

/// Common interpolators for built-in types
class Interpolators {
  /// Interpolate between two doubles
  static double lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  /// Interpolate between two integers
  static int lerpInt(int start, int end, double t) {
    return (start + (end - start) * t).round();
  }

  /// Interpolate between two colors
  static Color lerpColor(Color start, Color end, double t) {
    return Color.lerp(start, end, t)!;
  }

  /// Interpolate between two offsets
  static Offset lerpOffset(Offset start, Offset end, double t) {
    return Offset.lerp(start, end, t)!;
  }

  /// Interpolate between two sizes
  static Size lerpSize(Size start, Size end, double t) {
    return Size.lerp(start, end, t)!;
  }

  /// Interpolate between two rects
  static Rect lerpRect(Rect start, Rect end, double t) {
    return Rect.lerp(start, end, t)!;
  }
}

/// Animation playback direction
enum AnimationDirection {
  /// Play forward
  forward,

  /// Play backward
  reverse,

  /// Alternate between forward and reverse
  alternate,
}

/// Animation playback state
enum AnimationState {
  /// Animation is idle/not started
  idle,

  /// Animation is currently playing
  playing,

  /// Animation is paused
  paused,

  /// Animation has completed
  completed,
}

import '../reactive/signal.dart';
import '../types/types.dart';

/// Base interface for animatable properties
abstract class Animatable<T> {
  /// The current value of this animatable
  T get value;

  /// Set the value
  set value(T newValue);

  /// Interpolate between two values
  T interpolate(T start, T end, double progress);
}

/// A reactive animatable property
class AnimatableProperty<T> implements Animatable<T> {
  final Signal<T> _signal;
  final Interpolator<T> _interpolator;

  /// Create an animatable property with an initial value and interpolator
  AnimatableProperty(T initialValue, this._interpolator)
      : _signal = Signal(initialValue);

  @override
  T get value => _signal.value;

  @override
  set value(T newValue) {
    _signal.value = newValue;
  }

  @override
  T interpolate(T start, T end, double progress) {
    return _interpolator(start, end, progress);
  }

  /// Get the underlying signal for direct reactive access
  Signal<T> get signal => _signal;
}

/// Create a double animatable property
AnimatableProperty<double> animatableDouble(double initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerp);
}

/// Create an integer animatable property
AnimatableProperty<int> animatableInt(int initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerpInt);
}

/// Create a color animatable property
AnimatableProperty<Color> animatableColor(Color initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerpColor);
}

/// Create an offset animatable property
AnimatableProperty<Offset> animatableOffset(Offset initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerpOffset);
}

/// Create a size animatable property
AnimatableProperty<Size> animatableSize(Size initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerpSize);
}

/// Create a rect animatable property
AnimatableProperty<Rect> animatableRect(Rect initialValue) {
  return AnimatableProperty(initialValue, Interpolators.lerpRect);
}

/// Create a custom animatable property with a custom interpolator
AnimatableProperty<T> animatable<T>(
  T initialValue,
  Interpolator<T> interpolator,
) {
  return AnimatableProperty(initialValue, interpolator);
}

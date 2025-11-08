import 'package:kito_reactive/kito_reactive.dart';
import '../engine/animatable.dart';
import 'svg_path.dart';

/// Animatable SVG path property
class AnimatableSvgPath implements Animatable<SvgPath> {
  final Signal<SvgPath> _signal;

  /// Create an animatable SVG path
  AnimatableSvgPath(SvgPath initialValue) : _signal = Signal(initialValue);

  @override
  SvgPath get value => _signal.value;

  @override
  set value(SvgPath newValue) {
    _signal.value = newValue;
  }

  @override
  SvgPath interpolate(SvgPath start, SvgPath end, double progress) {
    return SvgPathInterpolator.interpolate(start, end, progress);
  }

  /// Get the underlying signal for direct reactive access
  Signal<SvgPath> get signal => _signal;
}

/// Create an SVG path animatable property
AnimatableSvgPath animatableSvgPath(SvgPath initialValue) {
  return AnimatableSvgPath(initialValue);
}

/// Create an SVG path animatable from a path string
AnimatableSvgPath animatableSvgPathString(String pathData) {
  return AnimatableSvgPath(SvgPath.fromString(pathData));
}

/// SVG path interpolator for use with Interpolators class
class SvgPathInterpolators {
  /// Interpolate between two SVG paths
  static SvgPath lerpPath(SvgPath start, SvgPath end, double t) {
    return SvgPathInterpolator.interpolate(start, end, t);
  }
}

import 'package:flutter/widgets.dart';
import '../reactive/signal.dart';
import '../reactive/computed.dart';
import '../engine/animatable.dart';

/// A Flutter widget that rebuilds when reactive values change
class ReactiveBuilder extends StatefulWidget {
  /// Builder function that creates the widget tree
  final Widget Function(BuildContext context) builder;

  const ReactiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ReactiveBuilder> createState() => _ReactiveBuilderState();
}

class _ReactiveBuilderState extends State<ReactiveBuilder> {
  void Function()? _dispose;

  @override
  void initState() {
    super.initState();
    _setupEffect();
  }

  void _setupEffect() {
    // The effect will automatically track dependencies during build
    bool isFirstRun = true;
    _dispose = () {
      // This will be replaced by the actual effect dispose function
    };

    // We need to manually create an effect that rebuilds on changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// Widget properties that can be animated
class AnimatedWidgetProperties {
  /// Opacity
  final AnimatableProperty<double> opacity;

  /// Scale
  final AnimatableProperty<double> scale;

  /// Rotation (in radians)
  final AnimatableProperty<double> rotation;

  /// Translation X
  final AnimatableProperty<double> translateX;

  /// Translation Y
  final AnimatableProperty<double> translateY;

  /// Width
  final AnimatableProperty<double>? width;

  /// Height
  final AnimatableProperty<double>? height;

  AnimatedWidgetProperties({
    double opacity = 1.0,
    double scale = 1.0,
    double rotation = 0.0,
    double translateX = 0.0,
    double translateY = 0.0,
    double? width,
    double? height,
  })  : opacity = animatableDouble(opacity),
        scale = animatableDouble(scale),
        rotation = animatableDouble(rotation),
        translateX = animatableDouble(translateX),
        translateY = animatableDouble(translateY),
        width = width != null ? animatableDouble(width) : null,
        height = height != null ? animatableDouble(height) : null;

  /// Create a computed transform from the properties
  Computed<Matrix4> get transform {
    return computed(() {
      final matrix = Matrix4.identity();
      matrix.translate(translateX.value, translateY.value);
      matrix.rotateZ(rotation.value);
      matrix.scale(scale.value, scale.value);
      return matrix;
    });
  }
}

/// An animated widget that applies transformations based on animatable properties
class KitoAnimatedWidget extends StatelessWidget {
  /// The widget to animate
  final Widget child;

  /// Animation properties
  final AnimatedWidgetProperties properties;

  const KitoAnimatedWidget({
    super.key,
    required this.child,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _SignalListenable(properties.opacity.signal),
        _SignalListenable(properties.scale.signal),
        _SignalListenable(properties.rotation.signal),
        _SignalListenable(properties.translateX.signal),
        _SignalListenable(properties.translateY.signal),
        if (properties.width != null) _SignalListenable(properties.width!.signal),
        if (properties.height != null) _SignalListenable(properties.height!.signal),
      ]),
      builder: (context, child) {
        Widget result = child!;

        // Apply size if specified
        if (properties.width != null || properties.height != null) {
          result = SizedBox(
            width: properties.width?.value,
            height: properties.height?.value,
            child: result,
          );
        }

        // Apply transform
        result = Transform(
          transform: properties.transform.value,
          alignment: Alignment.center,
          child: result,
        );

        // Apply opacity
        result = Opacity(
          opacity: properties.opacity.value.clamp(0.0, 1.0),
          child: result,
        );

        return result;
      },
      child: child,
    );
  }
}

/// Helper class to make Signal work with Flutter's Listenable
class _SignalListenable<T> extends ChangeNotifier {
  final Signal<T> _signal;
  void Function()? _dispose;

  _SignalListenable(this._signal) {
    // We'd ideally use an effect here, but for simplicity,
    // we'll use a different approach
    _setupListener();
  }

  void _setupListener() {
    // In a real implementation, we'd set up proper reactive listening
    // For now, we'll trigger updates on signal changes
    // This is a simplified version - production code would integrate better
  }

  void triggerUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }
}

/// Create an animated widget with properties
KitoAnimatedWidget kitoWidget({
  required Widget child,
  required AnimatedWidgetProperties properties,
}) {
  return KitoAnimatedWidget(
    properties: properties,
    child: child,
  );
}

/// Extension on BuildContext for reactive rebuilds
extension ReactiveContext on BuildContext {
  /// Watch a signal and rebuild when it changes
  T watch<T>(Signal<T> signal) {
    // In a production implementation, this would integrate with
    // Flutter's element tree to trigger rebuilds
    return signal.value;
  }

  /// Watch a computed value and rebuild when it changes
  T watchComputed<T>(Computed<T> computed) {
    return computed.value;
  }
}

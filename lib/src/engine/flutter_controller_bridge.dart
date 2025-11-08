import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:kito_reactive/kito_reactive.dart';
import '../types/types.dart';
import '../easing/easing.dart';
import 'animatable.dart';
import 'animation.dart';

/// Bridge between Kito animations and Flutter's AnimationController
///
/// This integration allows:
/// 1. Driving Kito animatable properties from AnimationController
/// 2. Creating AnimationController from Kito animations
/// 3. Bidirectional synchronization between both systems

/// Drives a Kito animatable property from a Flutter Animation
class AnimatableAnimationDriver<T> {
  final Animatable<T> _property;
  final Animation<double> _animation;
  final T _startValue;
  final T _endValue;
  VoidCallback? _listener;

  /// Create a driver that updates [property] based on [animation] progress
  /// from [startValue] to [endValue]
  AnimatableAnimationDriver({
    required Animatable<T> property,
    required Animation<double> animation,
    required T startValue,
    required T endValue,
  })  : _property = property,
        _animation = animation,
        _startValue = startValue,
        _endValue = endValue {
    _listener = _updateProperty;
    _animation.addListener(_listener!);
    _updateProperty();
  }

  void _updateProperty() {
    final progress = _animation.value;
    _property.value = _property.interpolate(_startValue, _endValue, progress);
  }

  /// Dispose this driver and stop listening to animation changes
  void dispose() {
    if (_listener != null) {
      _animation.removeListener(_listener!);
      _listener = null;
    }
  }
}

/// Wraps a Kito Animatable as a Flutter Animation
class KitoAnimation<T> extends Animation<T>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  final Animatable<T> _property;
  final Signal<AnimationStatus> _status;
  void Function()? _dispose;

  /// Create a Flutter Animation from a Kito Animatable
  ///
  /// The animation status should be managed externally through [status] signal
  KitoAnimation(
    this._property, {
    Signal<AnimationStatus>? status,
  }) : _status = status ?? signal(AnimationStatus.dismissed) {
    // Set up reactive effect to notify listeners when property changes
    _dispose = effect(() {
      final _ = _property.value; // Track dependency
      notifyListeners();
    });

    // Set up effect for status changes
    final statusDispose = effect(() {
      final _ = _status.value; // Track dependency
      notifyStatusListeners(_status.value);
    });

    final oldDispose = _dispose;
    _dispose = () {
      oldDispose?.call();
      statusDispose();
    };
  }

  @override
  T get value => _property.value;

  @override
  AnimationStatus get status => _status.value;

  @override
  void dispose() {
    _dispose?.call();
    super.dispose();
  }
}

/// Creates an AnimationController that drives a Kito animation
class KitoAnimationController {
  final AnimationController controller;
  final KitoAnimation _kitoAnimation;
  final List<AnimatableAnimationDriver> _drivers = [];

  KitoAnimationController._({
    required this.controller,
    required KitoAnimation kitoAnimation,
    required List<AnimatableAnimationDriver> drivers,
  })  : _kitoAnimation = kitoAnimation,
        _drivers = drivers;

  /// Create an AnimationController that drives Kito animatable properties
  ///
  /// Example:
  /// ```dart
  /// final scale = animatableDouble(1.0);
  /// final opacity = animatableDouble(1.0);
  ///
  /// final kitoController = KitoAnimationController.create(
  ///   vsync: this,
  ///   duration: Duration(milliseconds: 500),
  ///   properties: {
  ///     scale: 1.5,
  ///     opacity: 0.5,
  ///   },
  /// );
  ///
  /// kitoController.forward();
  /// ```
  static KitoAnimationController create<T>({
    required TickerProvider vsync,
    required Duration duration,
    required Map<Animatable, dynamic> properties,
    Curve curve = Curves.linear,
    Duration? reverseDuration,
    String? debugLabel,
    double? lowerBound,
    double? upperBound,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior,
    );

    final animation = CurvedAnimation(parent: controller, curve: curve);
    final status = signal(controller.status);

    // Listen to status changes
    controller.addStatusListener((newStatus) {
      status.value = newStatus;
    });

    final drivers = <AnimatableAnimationDriver>[];

    // Create drivers for each property
    properties.forEach((property, endValue) {
      final startValue = property.value;
      final driver = AnimatableAnimationDriver(
        property: property,
        animation: animation,
        startValue: startValue,
        endValue: endValue,
      );
      drivers.add(driver);
    });

    // Use first property as the value source for KitoAnimation
    // This is mainly for compatibility with Flutter's Animation API
    final firstProperty = properties.keys.first;
    final kitoAnimation = KitoAnimation(
      firstProperty,
      status: status,
    );

    return KitoAnimationController._(
      controller: controller,
      kitoAnimation: kitoAnimation,
      drivers: drivers,
    );
  }

  /// The underlying Flutter AnimationController
  AnimationController get animationController => controller;

  /// The Kito animation wrapper (for Flutter Animation compatibility)
  Animation get animation => _kitoAnimation;

  /// Forward the animation
  TickerFuture forward({double? from}) => controller.forward(from: from);

  /// Reverse the animation
  TickerFuture reverse({double? from}) => controller.reverse(from: from);

  /// Reset the animation
  void reset() => controller.reset();

  /// Stop the animation
  void stop({bool canceled = true}) => controller.stop(canceled: canceled);

  /// Repeat the animation
  TickerFuture repeat({
    double? min,
    double? max,
    bool reverse = false,
    Duration? period,
  }) =>
      controller.repeat(min: min, max: max, reverse: reverse, period: period);

  /// Dispose the controller and all drivers
  void dispose() {
    for (final driver in _drivers) {
      driver.dispose();
    }
    _drivers.clear();
    _kitoAnimation.dispose();
    controller.dispose();
  }
}

/// Extension to easily convert Kito easing functions to Flutter Curves
extension EasingToCurve on EasingFunction {
  /// Convert a Kito easing function to a Flutter Curve
  Curve toCurve() => _KitoEasingCurve(this);
}

class _KitoEasingCurve extends Curve {
  final EasingFunction _easing;

  _KitoEasingCurve(this._easing);

  @override
  double transform(double t) => _easing(t);
}

/// Extension to easily convert Flutter Curves to Kito easing functions
extension CurveToEasing on Curve {
  /// Convert a Flutter Curve to a Kito easing function
  EasingFunction toEasing() => (double t) => transform(t);
}

/// Create a Flutter AnimationController from a Kito animation
///
/// This allows you to use Kito animations with Flutter widgets that expect
/// AnimationController (like AnimatedBuilder, Tween, etc.)
///
/// Example:
/// ```dart
/// final props = AnimatedWidgetProperties(scale: 1.0);
/// final kitoAnim = animate()
///   .to(props.scale, 1.5)
///   .withDuration(500)
///   .build();
///
/// final controller = kitoAnim.toAnimationController(vsync: this);
/// controller.forward();
/// ```
extension KitoAnimationControllerExtension on KitoAnimation {
  /// Create an AnimationController that mirrors this Kito animation's state
  AnimationController toAnimationController({
    required TickerProvider vsync,
    Duration? duration,
    Duration? reverseDuration,
    String? debugLabel,
    double? lowerBound,
    double? upperBound,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    final controller = AnimationController(
      vsync: vsync,
      duration: duration ?? Duration(milliseconds: this.duration),
      reverseDuration: reverseDuration,
      debugLabel: debugLabel ?? 'KitoAnimation',
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior,
      value: progressValue,
    );

    // Sync Kito animation progress to controller
    effect(() {
      final progress = this.progress.value;
      if (controller.value != progress) {
        controller.value = progress;
      }
    });

    // Sync Kito animation state to controller status
    effect(() {
      final state = currentState.value;
      AnimationStatus status;
      switch (state.toString().split('.').last) {
        case 'idle':
          status = AnimationStatus.dismissed;
          break;
        case 'playing':
          status = AnimationStatus.forward;
          break;
        case 'paused':
          status = AnimationStatus.forward;
          break;
        case 'completed':
          status = AnimationStatus.completed;
          break;
        default:
          status = AnimationStatus.dismissed;
      }
      // Note: AnimationController doesn't have a direct way to set status
      // without triggering the animation, so we rely on value sync
    });

    return controller;
  }
}

/// Helper to create a Tween-like animation from Kito animatables
class AnimatableTween<T> {
  final Animatable<T> property;
  final T begin;
  final T end;

  AnimatableTween({
    required this.property,
    required this.begin,
    required this.end,
  });

  /// Evaluate the tween at a given progress
  T evaluate(double progress) {
    return property.interpolate(begin, end, progress);
  }

  /// Animate this tween with an Animation<double>
  Animation<T> animate(Animation<double> animation) {
    return _AnimatableTweenAnimation(this, animation);
  }
}

class _AnimatableTweenAnimation<T> extends Animation<T>
    with AnimationLocalListenersMixin {
  final AnimatableTween<T> _tween;
  final Animation<double> _parent;

  _AnimatableTweenAnimation(this._tween, this._parent) {
    _parent.addListener(notifyListeners);
  }

  @override
  T get value => _tween.evaluate(_parent.value);

  @override
  AnimationStatus get status => _parent.status;

  @override
  void dispose() {
    _parent.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Common Flutter curve presets as Kito easing functions
class FlutterCurves {
  /// Linear easing (same as Kito's Easing.linear)
  static final EasingFunction linear = Curves.linear.toEasing();

  /// Fast out, slow in
  static final EasingFunction fastOutSlowIn = Curves.fastOutSlowIn.toEasing();

  /// Ease in
  static final EasingFunction easeIn = Curves.easeIn.toEasing();

  /// Ease out
  static final EasingFunction easeOut = Curves.easeOut.toEasing();

  /// Ease in out
  static final EasingFunction easeInOut = Curves.easeInOut.toEasing();

  /// Bouncy curve
  static final EasingFunction bounceIn = Curves.bounceIn.toEasing();

  /// Bounce out
  static final EasingFunction bounceOut = Curves.bounceOut.toEasing();

  /// Bounce in out
  static final EasingFunction bounceInOut = Curves.bounceInOut.toEasing();

  /// Elastic in
  static final EasingFunction elasticIn = Curves.elasticIn.toEasing();

  /// Elastic out
  static final EasingFunction elasticOut = Curves.elasticOut.toEasing();

  /// Elastic in out
  static final EasingFunction elasticInOut = Curves.elasticInOut.toEasing();

  /// Decelerate
  static final EasingFunction decelerate = Curves.decelerate.toEasing();

  /// Ease in cubic
  static final EasingFunction easeInCubic = Curves.easeInCubic.toEasing();

  /// Ease out cubic
  static final EasingFunction easeOutCubic = Curves.easeOutCubic.toEasing();

  /// Ease in out cubic
  static final EasingFunction easeInOutCubic = Curves.easeInOutCubic.toEasing();
}

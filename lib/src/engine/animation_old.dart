import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:kito_reactive/kito_reactive.dart';
import '../types/types.dart';
import '../easing/easing.dart';
import 'animatable.dart';
import 'keyframe.dart';

/// Configuration for an animation target
class AnimationTarget<T> {
  /// The animatable property to animate
  final Animatable<T> property;

  /// The end value to animate to
  final T? endValue;

  /// Keyframes for the animation
  final List<Keyframe<T>>? keyframes;

  /// Easing function for this target
  final EasingFunction? easing;

  /// Duration override for this target (in milliseconds)
  final int? duration;

  /// Delay override for this target (in milliseconds)
  final int? delay;

  const AnimationTarget({
    required this.property,
    this.endValue,
    this.keyframes,
    this.easing,
    this.duration,
    this.delay,
  });
}

/// Main animation class that integrates with the reactive system
class KitoAnimation {
  /// Animation targets
  final List<AnimationTarget> _targets;

  /// Duration in milliseconds
  final int duration;

  /// Delay before starting in milliseconds
  final int delay;

  /// Default easing function
  final EasingFunction easing;

  /// Number of times to loop (-1 for infinite)
  final int loop;

  /// Animation direction
  final AnimationDirection direction;

  /// Whether to automatically play the animation
  final bool autoplay;

  /// Update callback
  final AnimationCallback? onUpdate;

  /// Complete callback
  final AnimationCompleteCallback? onComplete;

  /// Begin callback
  final AnimationCompleteCallback? onBegin;

  // Reactive state
  final Signal<double> _progress = Signal(0.0);
  final Signal<AnimationState> _state = Signal(AnimationState.idle);
  final Signal<int> _currentLoop = Signal(0);

  // Ticker
  Ticker? _ticker;
  Duration? _startTime;
  Duration? _pausedAt;
  bool _reversed = false;
  int _loopCount = 0;

  /// Create an animation
  KitoAnimation({
    required List<AnimationTarget> targets,
    this.duration = 1000,
    this.delay = 0,
    this.easing = Easing.linear,
    this.loop = 1,
    this.direction = AnimationDirection.forward,
    this.autoplay = false,
    this.onUpdate,
    this.onComplete,
    this.onBegin,
  }) : _targets = targets {
    if (autoplay) {
      play();
    }
  }

  /// Current progress (0.0 to 1.0)
  double get progress => _progress.value;

  /// Current animation state
  AnimationState get state => _state.value;

  /// Current loop iteration
  int get currentLoop => _currentLoop.value;

  /// Play the animation
  void play() {
    if (_state.value == AnimationState.playing) return;

    _state.value = AnimationState.playing;

    if (_pausedAt != null) {
      // Resume from pause
      _ticker = Ticker(_tick);
      _startTime = null;
      _ticker!.start();
    } else {
      // Start fresh
      if (_state.value == AnimationState.idle) {
        onBegin?.call();
      }

      _ticker = Ticker(_tick);
      _startTime = null;
      _ticker!.start();
    }
  }

  /// Pause the animation
  void pause() {
    if (_state.value != AnimationState.playing) return;

    _state.value = AnimationState.paused;
    _ticker?.stop();
  }

  /// Restart the animation from the beginning
  void restart() {
    _loopCount = 0;
    _currentLoop.value = 0;
    _reversed = direction == AnimationDirection.reverse;
    _startTime = null;
    _pausedAt = null;
    _progress.value = 0.0;

    if (_state.value == AnimationState.playing) {
      _ticker?.stop();
    }

    play();
  }

  /// Seek to a specific progress (0.0 to 1.0)
  void seek(double targetProgress) {
    _progress.value = targetProgress.clamp(0.0, 1.0);
    _updateTargets();
  }

  /// Stop and reset the animation
  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _state.value = AnimationState.idle;
    _progress.value = 0.0;
    _startTime = null;
    _pausedAt = null;
    _loopCount = 0;
    _currentLoop.value = 0;
  }

  /// Dispose the animation
  void dispose() {
    stop();
  }

  /// Tick callback for the animation
  void _tick(Duration elapsed) {
    _startTime ??= elapsed;

    final actualElapsed = elapsed - _startTime!;
    final totalDuration = delay + duration;
    final millisElapsed = actualElapsed.inMilliseconds;

    // Handle delay
    if (millisElapsed < delay) {
      return;
    }

    // Calculate progress
    final animationElapsed = millisElapsed - delay;
    var rawProgress = (animationElapsed / duration).clamp(0.0, 1.0);

    // Apply direction
    if (_reversed) {
      rawProgress = 1.0 - rawProgress;
    }

    _progress.value = rawProgress;
    _updateTargets();

    // Check if animation is complete
    if (millisElapsed >= totalDuration) {
      _handleAnimationComplete();
    }
  }

  /// Update all animation targets
  void _updateTargets() {
    for (final target in _targets) {
      _updateTarget(target);
    }
    onUpdate?.call(_progress.value);
  }

  /// Update a single animation target
  void _updateTarget(AnimationTarget target) {
    final targetEasing = target.easing ?? easing;
    final easedProgress = targetEasing(_progress.value);

    if (target.keyframes != null && target.keyframes!.isNotEmpty) {
      // Keyframe-based animation
      final value = interpolateKeyframes(
        target.keyframes!,
        easedProgress,
        target.property.interpolate,
        targetEasing,
      );
      target.property.value = value;
    } else if (target.endValue != null) {
      // Simple from-to animation
      final startValue = target.property.value;
      final value = target.property.interpolate(
        startValue,
        target.endValue!,
        easedProgress,
      );
      target.property.value = value;
    }
  }

  /// Handle animation completion
  void _handleAnimationComplete() {
    _loopCount++;

    // Check if we should loop
    if (loop == -1 || _loopCount < loop) {
      _currentLoop.value = _loopCount;

      // Handle alternating direction
      if (direction == AnimationDirection.alternate) {
        _reversed = !_reversed;
      }

      // Restart
      _startTime = null;
    } else {
      // Animation fully complete
      _ticker?.stop();
      _state.value = AnimationState.completed;
      onComplete?.call();
    }
  }
}

/// Builder for creating animations with a fluent API
class AnimationBuilder {
  final List<AnimationTarget> _targets = [];
  int _duration = 1000;
  int _delay = 0;
  EasingFunction _easing = Easing.linear;
  int _loop = 1;
  AnimationDirection _direction = AnimationDirection.forward;
  bool _autoplay = false;
  AnimationCallback? _onUpdate;
  AnimationCompleteCallback? _onComplete;
  AnimationCompleteCallback? _onBegin;

  /// Animate a property to a target value
  AnimationBuilder to<T>(
    Animatable<T> property,
    T value, {
    EasingFunction? easing,
    int? duration,
    int? delay,
  }) {
    _targets.add(AnimationTarget(
      property: property,
      endValue: value,
      easing: easing,
      duration: duration,
      delay: delay,
    ));
    return this;
  }

  /// Animate a property using keyframes
  AnimationBuilder withKeyframes<T>(
    Animatable<T> property,
    List<Keyframe<T>> keyframes, {
    EasingFunction? easing,
    int? duration,
    int? delay,
  }) {
    _targets.add(AnimationTarget(
      property: property,
      keyframes: keyframes,
      easing: easing,
      duration: duration,
      delay: delay,
    ));
    return this;
  }

  /// Set the duration
  AnimationBuilder withDuration(int milliseconds) {
    _duration = milliseconds;
    return this;
  }

  /// Set the delay
  AnimationBuilder withDelay(int milliseconds) {
    _delay = milliseconds;
    return this;
  }

  /// Set the easing function
  AnimationBuilder withEasing(EasingFunction easing) {
    _easing = easing;
    return this;
  }

  /// Set the loop count
  AnimationBuilder withLoop(int count) {
    _loop = count;
    return this;
  }

  /// Loop infinitely
  AnimationBuilder loopInfinitely() {
    _loop = -1;
    return this;
  }

  /// Set the direction
  AnimationBuilder withDirection(AnimationDirection direction) {
    _direction = direction;
    return this;
  }

  /// Enable autoplay
  AnimationBuilder withAutoplay() {
    _autoplay = true;
    return this;
  }

  /// Set update callback
  AnimationBuilder onUpdate(AnimationCallback callback) {
    _onUpdate = callback;
    return this;
  }

  /// Set complete callback
  AnimationBuilder onComplete(AnimationCompleteCallback callback) {
    _onComplete = callback;
    return this;
  }

  /// Set begin callback
  AnimationBuilder onBegin(AnimationCompleteCallback callback) {
    _onBegin = callback;
    return this;
  }

  /// Build the animation
  KitoAnimation build() {
    return KitoAnimation(
      targets: _targets,
      duration: _duration,
      delay: _delay,
      easing: _easing,
      loop: _loop,
      direction: _direction,
      autoplay: _autoplay,
      onUpdate: _onUpdate,
      onComplete: _onComplete,
      onBegin: _onBegin,
    );
  }
}

/// Create an animation builder
AnimationBuilder animate() => AnimationBuilder();

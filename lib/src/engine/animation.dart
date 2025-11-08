import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:kito_reactive/kito_reactive.dart';
import '../types/types.dart';
import '../easing/easing.dart';
import 'animatable.dart';
import 'keyframe.dart';
import 'animation_fsm.dart';

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
/// Now powered by kito_fsm for declarative state management
class KitoAnimation {
  late final AnimationStateMachine _fsm;
  late final AnimationContext _context;

  /// Create an animation
  KitoAnimation({
    required List<AnimationTarget> targets,
    int duration = 1000,
    int delay = 0,
    EasingFunction easing = Easing.linear,
    int loop = 1,
    AnimationDirection direction = AnimationDirection.forward,
    bool autoplay = false,
    AnimationCallback? onUpdate,
    AnimationCompleteCallback? onComplete,
    AnimationCompleteCallback? onBegin,
  }) {
    _context = AnimationContext(
      targets: targets,
      duration: duration,
      delay: delay,
      easing: easing,
      loop: loop,
      direction: direction,
      onUpdate: onUpdate,
      onComplete: onComplete,
      onBegin: onBegin,
    );

    _fsm = AnimationStateMachine(_context);

    // Set up effect to manage ticker based on FSM state
    effect(() {
      final state = _fsm.currentState.value;

      if (state == AnimState.playing && _context.ticker == null) {
        _context.ticker = Ticker(_fsm.handleTick);
        _context.ticker!.start();
      } else if (state != AnimState.playing && _context.ticker != null) {
        // Ticker cleanup happens in FSM state exit actions
      }
    });

    if (autoplay) {
      play();
    }
  }

  /// Current progress (0.0 to 1.0) as a reactive signal
  Computed<double> get progress => computed(() {
    // Trigger recomputation when state changes (which happens on ticks)
    _fsm.currentState.value;
    return _context.progress;
  });

  /// Current progress value (non-reactive)
  double get progressValue => _context.progress;

  /// Current animation state as reactive signal
  Signal<AnimState> get currentState => _fsm.currentState;

  /// Current animation state (backward compatible)
  AnimationState get state => _animStateToLegacy(_fsm.currentState.value);

  /// Current loop iteration as reactive computed
  Computed<int> get currentLoop => computed(() {
    _fsm.currentState.value;
    return _context.currentLoop;
  });

  /// Current loop value (non-reactive)
  int get currentLoopValue => _context.currentLoop;

  /// Play the animation
  void play() => _fsm.send(AnimEvent.play);

  /// Pause the animation
  void pause() => _fsm.send(AnimEvent.pause);

  /// Restart the animation from the beginning
  void restart() => _fsm.send(AnimEvent.restart);

  /// Seek to a specific progress (0.0 to 1.0)
  void seek(double targetProgress) {
    _context.progress = targetProgress.clamp(0.0, 1.0);
    AnimationStateMachine.updateTargets(_context);
  }

  /// Duration in milliseconds (for Timeline compatibility)
  int get duration => _context.duration;

  /// Delay in milliseconds (for Timeline compatibility)
  int get delay => _context.delay;

  /// Stop and reset the animation
  void stop() => _fsm.send(AnimEvent.stop);

  /// Dispose the animation
  void dispose() {
    stop();
    _fsm.dispose();
  }

  /// Map FSM AnimState to legacy AnimationState enum
  AnimationState _animStateToLegacy(AnimState state) {
    switch (state) {
      case AnimState.idle:
        return AnimationState.idle;
      case AnimState.playing:
        return AnimationState.playing;
      case AnimState.paused:
        return AnimationState.paused;
      case AnimState.completed:
        return AnimationState.completed;
    }
  }

  /// Access to FSM for advanced use cases
  AnimationStateMachine get fsm => _fsm;

  /// Access to context for advanced use cases
  AnimationContext get context => _context;
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

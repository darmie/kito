/// Core types for Kito state machines.
library;

/// Direction of animation playback
enum AnimationDirection {
  /// Play forward
  forward,

  /// Play backward
  reverse,

  /// Alternate between forward and reverse
  alternate,
}

/// State of the animation
enum AnimationState {
  /// Animation not started
  idle,

  /// Animation is playing
  playing,

  /// Animation is paused
  paused,

  /// Animation completed
  completed,
}

/// Callback for animation updates
typedef AnimationCallback = void Function(double progress);

/// Callback for animation completion
typedef AnimationCompleteCallback = void Function();

/// Represents a state transition that occurred
class StateTransition<S extends Enum, E extends Enum> {
  /// The state we transitioned from
  final S from;

  /// The state we transitioned to
  final S to;

  /// The event that triggered the transition (null for transient states)
  final E? event;

  /// When the transition occurred
  final DateTime timestamp;

  /// How long the transition took to execute
  final Duration? duration;

  const StateTransition({
    required this.from,
    required this.to,
    this.event,
    required this.timestamp,
    this.duration,
  });

  @override
  String toString() {
    final eventStr = event != null ? ' via ${event!.name}' : '';
    return 'StateTransition(${from.name} → ${to.name}$eventStr @ ${timestamp.toIso8601String()})';
  }
}

/// Represents a state change event (emitted via stream)
class StateChange<S extends Enum, E extends Enum> {
  /// The state we transitioned from
  final S from;

  /// The state we transitioned to
  final S to;

  /// The event that triggered the transition
  final E? event;

  /// When the transition occurred
  final DateTime timestamp;

  /// How long the transition took
  final Duration? transitionDuration;

  const StateChange({
    required this.from,
    required this.to,
    this.event,
    required this.timestamp,
    this.transitionDuration,
  });

  @override
  String toString() {
    final eventStr = event != null ? ' (${event!.name})' : '';
    return '${from.name} → ${to.name}$eventStr';
  }
}

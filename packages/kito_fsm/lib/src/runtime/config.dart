/// Configuration types for state machines.
library;

import 'action_context.dart';

/// Configuration for an entire state machine
class StateMachineConfig<S extends Enum, E extends Enum, C> {
  /// Map of state to their configurations
  final Map<S, StateConfig<S, E, C>> states;

  const StateMachineConfig({
    required this.states,
  });
}

/// Configuration for a single state
class StateConfig<S extends Enum, E extends Enum, C> {
  /// The state this config represents
  final S state;

  /// Map of events to transition configurations
  final Map<E, TransitionConfig<S, E, C>> transitions;

  /// Callback executed when entering this state
  ///
  /// Receives:
  /// - context: Current business logic context
  /// - from: Previous state
  /// - to: Current state (same as this state)
  final void Function(C context, S from, S to)? onEntry;

  /// Callback executed when exiting this state
  ///
  /// Receives:
  /// - context: Current business logic context
  /// - from: Current state (same as this state)
  /// - to: Next state
  final void Function(C context, S from, S to)? onExit;

  /// Transient state configuration (auto-transition)
  final TransientConfig<S, C>? transient;

  const StateConfig({
    required this.state,
    this.transitions = const {},
    this.onEntry,
    this.onExit,
    this.transient,
  });

  /// Check if this is a transient state
  bool get isTransient => transient != null;
}

/// Configuration for a transition between states
class TransitionConfig<S extends Enum, E extends Enum, C> {
  /// Target state to transition to
  final S target;

  /// Guard function that must return true for transition to occur
  ///
  /// Signature: `bool guard(C context)`
  final bool Function(C context)? guard;

  /// Action to execute during transition (transforms context)
  ///
  /// Can be either:
  /// - Simple: `C action(C context)`
  /// - Enhanced: `C action(ActionContext<S, E, C> actx)`
  ///
  /// The runtime will detect which signature and call appropriately.
  final Function? action;

  /// Events to emit after transition completes
  final List<ConditionalEvent<E, C>>? emit;

  const TransitionConfig({
    required this.target,
    this.guard,
    this.action,
    this.emit,
  });
}

/// Configuration for a transient state (auto-transition)
class TransientConfig<S extends Enum, C> {
  /// Duration to wait before auto-transition (if null, transitions immediately)
  final Duration? after;

  /// Target state to transition to
  final S target;

  /// Condition that must be true for auto-transition to occur
  final bool Function(C context)? condition;

  /// Action to execute during auto-transition
  final Function? action;

  /// Events to emit after transition
  final List<ConditionalEvent<Enum, C>>? emit;

  const TransientConfig({
    this.after,
    required this.target,
    this.condition,
    this.action,
    this.emit,
  });

  /// Check if transition should occur immediately
  bool get isImmediate => after == null || after == Duration.zero;
}

/// Event that may be emitted conditionally
class ConditionalEvent<E extends Enum, C> {
  /// The event to emit
  final E event;

  /// Condition that must be true to emit (if null, always emits)
  final bool Function(C context)? condition;

  /// Delay before emitting (if null, emits immediately)
  final Duration? delay;

  const ConditionalEvent({
    required this.event,
    this.condition,
    this.delay,
  });

  /// Check if this event should be emitted for the given context
  bool shouldEmit(C context) {
    return condition == null || condition!(context);
  }

  /// Check if this event should be emitted immediately
  bool get isImmediate => delay == null || delay == Duration.zero;
}

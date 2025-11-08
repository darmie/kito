/// Enhanced context passed to actions, providing access to state machine internals.
library;

import '../types/types.dart';

/// Enhanced context passed to actions that need access to the state machine.
///
/// Actions can use either signature:
/// - Simple: `C action(C context)`
/// - Enhanced: `C action(ActionContext<S, E, C> actx)`
///
/// The enhanced signature provides:
/// - Current state for decision-making
/// - Event emission for cascading transitions
/// - State history for complex logic
///
/// Example:
/// ```dart
/// static CounterContext increment(
///   ActionContext<CounterState, CounterEvent, CounterContext> actx
/// ) {
///   final newCtx = actx.context.copyWith(value: actx.context.value + 1);
///
///   // Emit event when max reached
///   if (newCtx.value >= 10) {
///     actx.emit(CounterEvent.maxReached);
///   }
///
///   return newCtx;
/// }
/// ```
class ActionContext<S extends Enum, E extends Enum, C> {
  /// The business logic context
  final C context;

  /// Current state of the state machine
  final S currentState;

  /// Emit an event (will be queued and processed after action completes)
  final void Function(E event) emit;

  /// Read-only access to state machine history
  final List<StateTransition<S, E>> history;

  const ActionContext({
    required this.context,
    required this.currentState,
    required this.emit,
    required this.history,
  });

  @override
  String toString() {
    return 'ActionContext(state: ${currentState.name}, historyLength: ${history.length})';
  }
}

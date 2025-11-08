/// Transition execution logic.
library;

import 'dart:async';
import 'action_context.dart';
import 'config.dart';
import '../types/types.dart';

/// Handles the execution of state transitions
class TransitionExecutor<S extends Enum, E extends Enum, C> {
  /// Execute a transition
  ///
  /// Returns the new context after executing action (if any)
  C execute({
    required S currentState,
    required C context,
    required TransitionConfig<S, E, C> transition,
    required E? event,
    required void Function(E event) emitEvent,
    required List<StateTransition<S, E>> history,
  }) {
    var newContext = context;

    // Execute transition action if present
    if (transition.action != null) {
      newContext = _executeAction(
        action: transition.action!,
        context: context,
        currentState: currentState,
        event: event,
        emitEvent: emitEvent,
        history: history,
      );
    }

    // Handle event emissions
    if (transition.emit != null) {
      for (final conditionalEvent in transition.emit!) {
        if (conditionalEvent.shouldEmit(newContext)) {
          if (conditionalEvent.isImmediate) {
            // Emit immediately (queue for next tick)
            emitEvent(conditionalEvent.event);
          } else {
            // Schedule delayed emission
            Timer(conditionalEvent.delay!, () {
              emitEvent(conditionalEvent.event);
            });
          }
        }
      }
    }

    return newContext;
  }

  /// Execute an action (handles both simple and enhanced signatures)
  C _executeAction({
    required Function action,
    required C context,
    required S currentState,
    required E? event,
    required void Function(E event) emitEvent,
    required List<StateTransition<S, E>> history,
  }) {
    // Try to detect action signature by checking parameter count
    // This is a simplified approach - in production, we'd use more robust type checking

    try {
      // Try enhanced signature first: C action(ActionContext<S, E, C>)
      final actx = ActionContext<S, E, C>(
        context: context,
        currentState: currentState,
        emit: emitEvent,
        history: history,
      );

      return action(actx) as C;
    } catch (e) {
      // Fall back to simple signature: C action(C)
      try {
        return action(context) as C;
      } catch (e) {
        // If both fail, rethrow original error
        rethrow;
      }
    }
  }

  /// Execute a transient transition
  C executeTransient({
    required S currentState,
    required C context,
    required TransientConfig<S, C> transient,
    required void Function(Enum event) emitEvent,
    required List<StateTransition<S, E>> history,
  }) {
    var newContext = context;

    // Execute transient action if present
    if (transient.action != null) {
      newContext = _executeAction(
        action: transient.action!,
        context: context,
        currentState: currentState,
        event: null,
        emitEvent: (e) => emitEvent(e),
        history: history,
      );
    }

    // Handle event emissions
    if (transient.emit != null) {
      for (final conditionalEvent in transient.emit!) {
        if (conditionalEvent.shouldEmit(newContext)) {
          if (conditionalEvent.isImmediate) {
            emitEvent(conditionalEvent.event);
          } else {
            Timer(conditionalEvent.delay!, () {
              emitEvent(conditionalEvent.event);
            });
          }
        }
      }
    }

    return newContext;
  }
}

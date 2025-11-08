/// Core state machine runtime.
library;

import 'dart:async';
import 'dart:collection';
import 'package:kito/kito.dart' show Signal, signal;
import 'config.dart';
import 'transition.dart';
import '../types/types.dart';

/// Base class for all Kito state machines.
///
/// Type parameters:
/// - S: State enum type
/// - E: Event enum type
/// - C: Context type (business logic state)
///
/// Example:
/// ```dart
/// class CounterStateMachine extends KitoStateMachine<
///   CounterState,
///   CounterEvent,
///   CounterContext
/// > {
///   CounterStateMachine({
///     required CounterContext context,
///   }) : super(
///     initial: CounterState.idle,
///     context: context,
///     config: _buildConfig(),
///   );
/// }
/// ```
abstract class KitoStateMachine<S extends Enum, E extends Enum, C> {
  /// Current state (reactive)
  late final Signal<S> currentState;

  /// Current business logic context
  C _context;

  /// State machine configuration
  final StateMachineConfig<S, E, C> config;

  /// Transition history for debugging
  final List<StateTransition<S, E>> _history = [];

  /// Stream controller for state changes
  final StreamController<StateChange<S, E>> _changesController =
      StreamController<StateChange<S, E>>.broadcast();

  /// Event queue for labelled events
  final Queue<E> _eventQueue = Queue<E>();

  /// Flag to prevent infinite event loops
  bool _isProcessingEvent = false;

  /// Transition executor
  final TransitionExecutor<S, E, C> _executor = TransitionExecutor();

  /// Transient state timer
  Timer? _transientTimer;

  /// Timestamp when state machine was created
  final DateTime createdAt = DateTime.now();

  /// Create a state machine
  ///
  /// Parameters:
  /// - initial: Initial state
  /// - context: Initial business logic context
  /// - config: State machine configuration
  KitoStateMachine({
    required S initial,
    required C context,
    required this.config,
  }) : _context = context {
    currentState = signal(initial);

    // Set up transient state handling
    currentState.peek(); // Force initial value
    _checkTransientState();
  }

  /// Get current business logic context
  C get context => _context;

  /// Update the context (useful for external updates)
  ///
  /// Note: This does not trigger a state transition.
  /// Use send() to trigger transitions.
  void updateContext(C newContext) {
    _context = newContext;
  }

  /// Get transition history
  List<StateTransition<S, E>> get history => List.unmodifiable(_history);

  /// Stream of state changes
  Stream<StateChange<S, E>> get changes => _changesController.stream;

  /// Send an event to the state machine
  ///
  /// The event will be queued and processed in order.
  /// If the event triggers a valid transition, the state will change.
  void send(E event) {
    _eventQueue.add(event);
    _processEventQueue();
  }

  /// Process queued events
  void _processEventQueue() {
    if (_isProcessingEvent || _eventQueue.isEmpty) return;

    _isProcessingEvent = true;

    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeFirst();
      _handleEvent(event);
    }

    _isProcessingEvent = false;
  }

  /// Handle a single event
  void _handleEvent(E event) {
    final current = currentState.peek();
    final stateConfig = config.states[current];

    if (stateConfig == null) {
      _logWarning('No configuration for state: ${current.name}');
      return;
    }

    final transition = stateConfig.transitions[event];

    if (transition == null) {
      _logWarning(
          'No transition for event ${event.name} in state ${current.name}');
      return;
    }

    // Evaluate guard
    if (transition.guard != null && !transition.guard!(_context)) {
      _logDebug(
          'Guard blocked transition from ${current.name} via ${event.name}');
      return;
    }

    // Execute transition
    _performTransition(
      from: current,
      to: transition.target,
      event: event,
      transition: transition,
    );
  }

  /// Perform a state transition
  void _performTransition({
    required S from,
    required S to,
    required E? event,
    TransitionConfig<S, E, C>? transition,
  }) {
    final startTime = DateTime.now();

    // Execute exit callback for current state
    final fromConfig = config.states[from];
    fromConfig?.onExit?.call(_context, from, to);

    // Execute transition action and get new context
    if (transition != null) {
      _context = _executor.execute(
        currentState: from,
        context: _context,
        transition: transition,
        event: event,
        emitEvent: (e) => _eventQueue.add(e),
        history: _history,
      );
    }

    // Change state
    currentState.value = to;

    // Record transition
    final transitionRecord = StateTransition<S, E>(
      from: from,
      to: to,
      event: event,
      timestamp: startTime,
      duration: DateTime.now().difference(startTime),
    );
    _history.add(transitionRecord);

    // Emit state change
    _changesController.add(StateChange<S, E>(
      from: from,
      to: to,
      event: event,
      timestamp: startTime,
      transitionDuration: transitionRecord.duration,
    ));

    // Execute entry callback for new state
    final toConfig = config.states[to];
    toConfig?.onEntry?.call(_context, from, to);

    // Check if new state is transient
    _checkTransientState();

    _logDebug('Transitioned: ${from.name} → ${to.name}' +
        (event != null ? ' (${event.name})' : ''));
  }

  /// Check if current state is transient and schedule transition
  void _checkTransientState() {
    _transientTimer?.cancel();

    final current = currentState.peek();
    final stateConfig = config.states[current];

    if (stateConfig == null || !stateConfig.isTransient) {
      return;
    }

    final transient = stateConfig.transient!;

    // Check condition (if any)
    if (transient.condition != null && !transient.condition!(_context)) {
      return;
    }

    if (transient.isImmediate) {
      // Transition immediately (on next tick to avoid recursion)
      Future.microtask(() {
        _performTransientTransition(transient);
      });
    } else {
      // Schedule delayed transition
      _transientTimer = Timer(transient.after!, () {
        _performTransientTransition(transient);
      });
    }
  }

  /// Perform a transient state transition
  void _performTransientTransition(TransientConfig<S, C> transient) {
    final current = currentState.peek();

    // Execute transient action and get new context
    _context = _executor.executeTransient(
      currentState: current,
      context: _context,
      transient: transient,
      emitEvent: (e) => _eventQueue.add(e as E),
      history: _history,
    );

    // Perform the transition (no event for transient transitions)
    _performTransition(
      from: current,
      to: transient.target,
      event: null,
    );

    // Process any events that were emitted during the transient transition
    _processEventQueue();
  }

  /// Dispose the state machine
  ///
  /// Cancels timers and closes streams.
  void dispose() {
    _transientTimer?.cancel();
    _changesController.close();
    _eventQueue.clear();
  }

  /// Log a debug message (override to customize logging)
  void _logDebug(String message) {
    // Override in subclass to enable logging
    // print('[${runtimeType}] $message');
  }

  /// Log a warning message (override to customize logging)
  void _logWarning(String message) {
    // Override in subclass to enable logging
    // print('[${runtimeType}] WARNING: $message');
  }
}

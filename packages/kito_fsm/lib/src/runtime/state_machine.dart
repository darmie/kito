/// Core state machine runtime.
library;

import 'dart:async';
import 'dart:collection';
import 'package:kito_reactive/kito_reactive.dart' show Signal, signal;
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
  /// Current state (reactive) - represents the leaf state in hierarchy
  late final Signal<S> currentState;

  /// Current state path for hierarchical states
  /// The last element is the leaf state (same as currentState.value)
  /// For flat machines, this will have only one element
  final List<S> _statePath = [];

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
    // Build initial state path (handles compound states)
    _statePath.addAll(_buildStatePath(initial));
    final leafState = _statePath.last;
    currentState = signal(leafState);

    // Set up transient state handling
    currentState.peek(); // Force initial value
    _checkTransientState();
  }

  /// Build the full state path for a given state
  ///
  /// If the state is compound, this will recursively enter its initial substates
  /// Returns the complete path from root to leaf
  List<S> _buildStatePath(S state) {
    // First, try to find the state in the root config
    var currentConfig = config.states[state];

    if (currentConfig != null) {
      // It's a root state, build path from here
      final path = <S>[state];

      // If compound, recursively enter initial substates
      while (currentConfig != null && currentConfig.isCompound) {
        final initial = currentConfig.initial;
        if (initial == null) break;

        path.add(initial);
        currentConfig = currentConfig.substates?[initial];
      }

      return path;
    }

    // Not in root states, must be a substate - search for it
    for (final rootState in config.states.keys) {
      final path = _findStateInHierarchy(rootState, state);
      if (path != null) {
        return path;
      }
    }

    // Fallback: state not found in hierarchy, return as single-element path
    return [state];
  }

  /// Recursively search for a state in the hierarchy
  ///
  /// Returns the full path if found, null otherwise
  List<S>? _findStateInHierarchy(S root, S target, [List<S>? pathSoFar]) {
    final path = pathSoFar ?? <S>[];
    path.add(root);

    // Found it?
    if (root == target) {
      // If it's compound, enter its initial substates
      var currentConfig = _getStateConfigFromPath(path);
      while (currentConfig != null && currentConfig.isCompound) {
        final initial = currentConfig.initial;
        if (initial == null) break;
        path.add(initial);
        currentConfig = currentConfig.substates?[initial];
      }
      return path;
    }

    // Search in substates
    final config = _getStateConfigFromPath(path);
    if (config?.substates != null) {
      for (final substate in config!.substates!.keys) {
        final result = _findStateInHierarchy(substate, target, List.from(path));
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  /// Get state config from a path
  StateConfig<S, E, C>? _getStateConfigFromPath(List<S> path) {
    if (path.isEmpty) return null;

    StateConfig<S, E, C>? currentConfig;
    for (var i = 0; i < path.length; i++) {
      final state = path[i];
      if (i == 0) {
        currentConfig = config.states[state];
      } else {
        currentConfig = currentConfig?.substates?[state];
      }
      if (currentConfig == null) return null;
    }

    return currentConfig;
  }

  /// Get the current state path (for hierarchical machines)
  ///
  /// Returns a list where the first element is the root state
  /// and the last element is the leaf state (same as currentState.value)
  List<S> get statePath => List.unmodifiable(_statePath);

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
  ///
  /// Uses event bubbling for hierarchical states:
  /// Tries to handle the event at the leaf state first,
  /// then bubbles up the hierarchy until a transition is found
  void _handleEvent(E event) {
    // Try to find a transition by bubbling up the state hierarchy
    for (var i = _statePath.length - 1; i >= 0; i--) {
      final state = _statePath[i];
      final stateConfig = _getStateConfig(i);

      if (stateConfig == null) continue;

      final transition = stateConfig.transitions[event];
      if (transition == null) continue;

      // Evaluate guard
      if (transition.guard != null && !transition.guard!(_context)) {
        _logDebug(
            'Guard blocked transition from ${state.name} via ${event.name}');
        continue; // Try parent state
      }

      // Found valid transition, execute it
      _performTransition(
        from: _statePath.last, // Current leaf state
        to: transition.target,
        event: event,
        transition: transition,
      );
      return;
    }

    // No transition found in any state in the hierarchy
    _logWarning(
        'No transition for event ${event.name} in state path: ${_statePath.map((s) => s.name).join(" → ")}');
  }

  /// Get state config for a specific level in the current state path
  ///
  /// Returns the config for the state at the given index in the path
  StateConfig<S, E, C>? _getStateConfig(int pathIndex) {
    if (pathIndex < 0 || pathIndex >= _statePath.length) return null;

    // Navigate through the hierarchy to get the config
    StateConfig<S, E, C>? config;
    for (var i = 0; i <= pathIndex; i++) {
      final state = _statePath[i];
      if (i == 0) {
        // Root level
        config = this.config.states[state];
      } else {
        // Child level
        config = config?.substates?[state];
      }
    }

    return config;
  }

  /// Perform a state transition
  ///
  /// Handles hierarchical entry/exit:
  /// 1. Exits states from leaf up to common ancestor
  /// 2. Executes transition action
  /// 3. Enters states from common ancestor down to new leaf
  void _performTransition({
    required S from,
    required S to,
    required E? event,
    TransitionConfig<S, E, C>? transition,
  }) {
    final startTime = DateTime.now();

    // Build new state path
    final newStatePath = _buildStatePath(to);

    // Find common ancestor index (where old and new paths diverge)
    final commonAncestorIndex = _findCommonAncestorIndex(_statePath, newStatePath);

    // Exit states from leaf up to (but not including) common ancestor
    for (var i = _statePath.length - 1; i > commonAncestorIndex; i--) {
      final exitState = _statePath[i];
      final exitConfig = _getStateConfig(i);
      exitConfig?.onExit?.call(_context, exitState, to);
    }

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

    // Update state path
    _statePath.clear();
    _statePath.addAll(newStatePath);

    // Change current state to new leaf
    final newLeaf = _statePath.last;
    currentState.value = newLeaf;

    // Record transition
    final transitionRecord = StateTransition<S, E>(
      from: from,
      to: newLeaf,
      event: event,
      timestamp: startTime,
      duration: DateTime.now().difference(startTime),
    );
    _history.add(transitionRecord);

    // Emit state change
    _changesController.add(StateChange<S, E>(
      from: from,
      to: newLeaf,
      event: event,
      timestamp: startTime,
      transitionDuration: transitionRecord.duration,
    ));

    // Enter states from (after) common ancestor down to new leaf
    for (var i = commonAncestorIndex + 1; i < _statePath.length; i++) {
      final enterState = _statePath[i];
      final enterConfig = _getStateConfig(i);
      enterConfig?.onEntry?.call(_context, from, enterState);
    }

    // Check if new state is transient
    _checkTransientState();

    _logDebug('Transitioned: ${from.name} → ${newLeaf.name}' +
        (event != null ? ' (${event.name})' : ''));
  }

  /// Find the index of the common ancestor between two state paths
  ///
  /// Returns -1 if there is no common ancestor (completely different trees)
  /// Returns the index of the last common state
  int _findCommonAncestorIndex(List<S> path1, List<S> path2) {
    var commonIndex = -1;
    final minLength = path1.length < path2.length ? path1.length : path2.length;

    for (var i = 0; i < minLength; i++) {
      if (path1[i] == path2[i]) {
        commonIndex = i;
      } else {
        break;
      }
    }

    return commonIndex;
  }

  /// Check if current state is transient and schedule transition
  void _checkTransientState() {
    _transientTimer?.cancel();

    final current = currentState.peek();
    final stateConfig = _getStateConfig(_statePath.length - 1); // Get leaf config

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

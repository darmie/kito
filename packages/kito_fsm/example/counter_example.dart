/// Simple counter example demonstrating Kito state machines.
///
/// This example shows:
/// - Context-based state machine
/// - Guards that prevent invalid transitions
/// - Actions that transform context
/// - Enhanced actions that emit events
/// - Transient states with auto-transitions

import 'package:kito_fsm/kito_fsm.dart';

// ============================================================================
// 1. Define Context
// ============================================================================

class CounterContext {
  final int value;
  final int maxValue;
  final int minValue;

  const CounterContext({
    this.value = 0,
    this.maxValue = 10,
    this.minValue = 0,
  });

  CounterContext copyWith({int? value}) {
    return CounterContext(
      value: value ?? this.value,
      maxValue: maxValue,
      minValue: minValue,
    );
  }

  @override
  String toString() =>
      'CounterContext(value: $value, min: $minValue, max: $maxValue)';
}

// ============================================================================
// 2. Define States and Events
// ============================================================================

enum CounterState {
  idle,
  incrementing,
  decrementing,
  atMax,
  atMin,
}

enum CounterEvent {
  increment,
  decrement,
  reset,
  maxReached,
  minReached,
}

// ============================================================================
// 3. Define Guards
// ============================================================================

class CounterGuards {
  static bool notAtMax(CounterContext ctx) => ctx.value < ctx.maxValue;

  static bool notAtMin(CounterContext ctx) => ctx.value > ctx.minValue;

  static bool willReachMax(CounterContext ctx) => ctx.value + 1 >= ctx.maxValue;

  static bool willReachMin(CounterContext ctx) => ctx.value - 1 <= ctx.minValue;
}

// ============================================================================
// 4. Define Actions
// ============================================================================

class CounterActions {
  // Enhanced action with ActionContext
  static CounterContext increment(
    ActionContext<CounterState, CounterEvent, CounterContext> actx,
  ) {
    final newValue = actx.context.value + 1;

    print('Incrementing from state: ${actx.currentState.name}');

    // Emit event when max reached
    if (newValue >= actx.context.maxValue) {
      print('Max reached! Emitting maxReached event');
      actx.emit(CounterEvent.maxReached);
    }

    return actx.context.copyWith(value: newValue);
  }

  // Enhanced action
  static CounterContext decrement(
    ActionContext<CounterState, CounterEvent, CounterContext> actx,
  ) {
    final newValue = actx.context.value - 1;

    print('Decrementing from state: ${actx.currentState.name}');

    // Emit event when min reached
    if (newValue <= actx.context.minValue) {
      print('Min reached! Emitting minReached event');
      actx.emit(CounterEvent.minReached);
    }

    return actx.context.copyWith(value: newValue);
  }

  // Simple pure action
  static CounterContext reset(CounterContext ctx) {
    print('Resetting counter');
    return ctx.copyWith(value: 0);
  }
}

// ============================================================================
// 5. Define State Machine
// ============================================================================

class CounterStateMachine
    extends KitoStateMachine<CounterState, CounterEvent, CounterContext> {
  CounterStateMachine({
    CounterContext? context,
  }) : super(
          initial: CounterState.idle,
          context: context ?? const CounterContext(),
          config: _buildConfig(),
        );

  static StateMachineConfig<CounterState, CounterEvent, CounterContext>
      _buildConfig() {
    return StateMachineConfig(
      states: {
        // Idle state
        CounterState.idle: StateConfig(
          state: CounterState.idle,
          transitions: {
            CounterEvent.increment: TransitionConfig(
              target: CounterState.incrementing,
              guard: CounterGuards.notAtMax,
              action: CounterActions.increment,
            ),
            CounterEvent.decrement: TransitionConfig(
              target: CounterState.decrementing,
              guard: CounterGuards.notAtMin,
              action: CounterActions.decrement,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.reset,
            ),
          },
        ),

        // Incrementing (transient state)
        CounterState.incrementing: StateConfig(
          state: CounterState.incrementing,
          transitions: {
            CounterEvent.maxReached: TransitionConfig(
              target: CounterState.atMax,
            ),
          },
          // Auto-transition back to idle after 100ms
          transient: const TransientConfig(
            after: Duration(milliseconds: 100),
            target: CounterState.idle,
          ),
        ),

        // Decrementing (transient state)
        CounterState.decrementing: StateConfig(
          state: CounterState.decrementing,
          transitions: {
            CounterEvent.minReached: TransitionConfig(
              target: CounterState.atMin,
            ),
          },
          // Auto-transition back to idle after 100ms
          transient: const TransientConfig(
            after: Duration(milliseconds: 100),
            target: CounterState.idle,
          ),
        ),

        // At max state
        CounterState.atMax: StateConfig(
          state: CounterState.atMax,
          onEntry: (ctx, from, to) {
            print('=== AT MAX VALUE: ${ctx.value} ===');
          },
          transitions: {
            CounterEvent.decrement: TransitionConfig(
              target: CounterState.decrementing,
              action: CounterActions.decrement,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.reset,
            ),
          },
        ),

        // At min state
        CounterState.atMin: StateConfig(
          state: CounterState.atMin,
          onEntry: (ctx, from, to) {
            print('=== AT MIN VALUE: ${ctx.value} ===');
          },
          transitions: {
            CounterEvent.increment: TransitionConfig(
              target: CounterState.incrementing,
              action: CounterActions.increment,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.reset,
            ),
          },
        ),
      },
    );
  }
}

// ============================================================================
// 6. Example Usage
// ============================================================================

void main() async {
  print('=== Kito State Machine Counter Example ===\n');

  final machine = CounterStateMachine();

  // Listen to state changes
  machine.changes.listen((change) {
    print('State change: ${change.from.name} → ${change.to.name}');
    print('Context: ${machine.context}');
    print('');
  });

  print('Initial state: ${machine.currentState.value.name}');
  print('Initial context: ${machine.context}\n');

  // Increment to max
  print('--- Incrementing to max ---');
  for (var i = 0; i < 12; i++) {
    machine.send(CounterEvent.increment);
    await Future.delayed(const Duration(milliseconds: 150));
  }

  // Wait for transient states
  await Future.delayed(const Duration(milliseconds: 200));

  print('--- Decrementing from max ---');
  machine.send(CounterEvent.decrement);
  await Future.delayed(const Duration(milliseconds: 200));

  print('--- Resetting ---');
  machine.send(CounterEvent.reset);
  await Future.delayed(const Duration(milliseconds: 100));

  print('--- Decrementing to min ---');
  for (var i = 0; i < 2; i++) {
    machine.send(CounterEvent.decrement);
    await Future.delayed(const Duration(milliseconds: 150));
  }

  await Future.delayed(const Duration(milliseconds: 200));

  print('Final state: ${machine.currentState.value.name}');
  print('Final context: ${machine.context}');
  print('\nHistory: ${machine.history.length} transitions');

  machine.dispose();
}

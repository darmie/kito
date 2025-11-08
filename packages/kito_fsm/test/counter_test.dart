import 'package:flutter_test/flutter_test.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Counter states
enum CounterState {
  idle,
  incrementing,
  decrementing,
  maxReached,
  minReached,
}

/// Counter events
enum CounterEvent {
  increment,
  decrement,
  reset,
  maxReached,
  minReached,
}

/// Business logic context
class CounterContext {
  final int value;
  final int maxValue;
  final int minValue;

  const CounterContext({
    required this.value,
    this.maxValue = 10,
    this.minValue = 0,
  });

  CounterContext copyWith({
    int? value,
    int? maxValue,
    int? minValue,
  }) {
    return CounterContext(
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      minValue: minValue ?? this.minValue,
    );
  }

  @override
  String toString() =>
      'CounterContext(value: $value, max: $maxValue, min: $minValue)';
}

/// Guards - pure static functions checking conditions
class CounterGuards {
  static bool notAtMax(CounterContext ctx) => ctx.value < ctx.maxValue;
  static bool notAtMin(CounterContext ctx) => ctx.value > ctx.minValue;

  static bool willReachMax(CounterContext ctx) =>
      ctx.value + 1 >= ctx.maxValue;

  static bool willReachMin(CounterContext ctx) =>
      ctx.value - 1 <= ctx.minValue;
}

/// Actions - pure static functions transforming context
class CounterActions {
  /// Enhanced action with state machine awareness
  static CounterContext increment(
    ActionContext<CounterState, CounterEvent, CounterContext> actx,
  ) {
    final newValue = actx.context.value + 1;

    // Emit event when max reached
    if (newValue >= actx.context.maxValue) {
      actx.emit(CounterEvent.maxReached);
    }

    return actx.context.copyWith(value: newValue);
  }

  /// Simple action without state machine access
  static CounterContext decrement(CounterContext ctx) {
    return ctx.copyWith(value: ctx.value - 1);
  }

  static CounterContext resetToZero(CounterContext ctx) {
    return ctx.copyWith(value: 0);
  }
}

/// Counter state machine implementation
class CounterStateMachine extends KitoStateMachine<CounterState, CounterEvent,
    CounterContext> {
  CounterStateMachine({
    required CounterContext context,
  }) : super(
          initial: CounterState.idle,
          context: context,
          config: _buildConfig(),
        );

  static StateMachineConfig<CounterState, CounterEvent, CounterContext>
      _buildConfig() {
    return StateMachineConfig(
      states: {
        // Idle state - waiting for user input
        CounterState.idle: StateConfig(
          state: CounterState.idle,
          transitions: {
            CounterEvent.increment: TransitionConfig(
              target: CounterState.incrementing,
              guard: CounterGuards.notAtMax,
            ),
            CounterEvent.decrement: TransitionConfig(
              target: CounterState.decrementing,
              guard: CounterGuards.notAtMin,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.resetToZero,
            ),
            CounterEvent.maxReached: TransitionConfig(
              target: CounterState.maxReached,
            ),
            CounterEvent.minReached: TransitionConfig(
              target: CounterState.minReached,
            ),
          },
        ),

        // Transient state - auto-returns to idle
        CounterState.incrementing: StateConfig(
          state: CounterState.incrementing,
          transient: TransientConfig(
            after: Duration.zero, // Immediate
            target: CounterState.idle,
            action: CounterActions.increment,
          ),
        ),

        // Transient state - auto-returns to idle
        CounterState.decrementing: StateConfig(
          state: CounterState.decrementing,
          transient: TransientConfig(
            after: Duration.zero, // Immediate
            target: CounterState.idle,
            action: CounterActions.decrement,
          ),
        ),

        // Final states
        CounterState.maxReached: StateConfig(
          state: CounterState.maxReached,
          transitions: {
            CounterEvent.decrement: TransitionConfig(
              target: CounterState.decrementing,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.resetToZero,
            ),
          },
        ),

        CounterState.minReached: StateConfig(
          state: CounterState.minReached,
          transitions: {
            CounterEvent.increment: TransitionConfig(
              target: CounterState.incrementing,
            ),
            CounterEvent.reset: TransitionConfig(
              target: CounterState.idle,
              action: CounterActions.resetToZero,
            ),
          },
        ),
      },
    );
  }
}

void main() {
  group('Counter State Machine', () {
    test('should start in idle state', () {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0),
      );

      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 0);

      machine.dispose();
    });

    test('should increment value', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0),
      );

      machine.send(CounterEvent.increment);

      // Wait for transient state to complete
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 1);

      machine.dispose();
    });

    test('should decrement value', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 5),
      );

      machine.send(CounterEvent.decrement);

      // Wait for transient state to complete
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 4);

      machine.dispose();
    });

    test('should not increment beyond max', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 10, maxValue: 10),
      );

      machine.send(CounterEvent.increment);

      // Wait for any transient states
      await Future.delayed(const Duration(milliseconds: 10));

      // Should stay at max and remain idle (guard blocked transition)
      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 10);

      machine.dispose();
    });

    test('should not decrement below min', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0, minValue: 0),
      );

      machine.send(CounterEvent.decrement);

      // Wait for any transient states
      await Future.delayed(const Duration(milliseconds: 10));

      // Should stay at min and remain idle (guard blocked transition)
      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 0);

      machine.dispose();
    });

    test('should emit maxReached event when reaching max', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 9, maxValue: 10),
      );

      machine.send(CounterEvent.increment);

      // Wait for transient state and event emission to complete
      // The increment action emits maxReached, which then transitions to maxReached state
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify value was incremented to max
      expect(machine.context.value, 10);

      // Verify we transitioned to maxReached state
      expect(machine.currentState.peek(), CounterState.maxReached);

      machine.dispose();
    });

    test('should reset to zero', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 5),
      );

      machine.send(CounterEvent.reset);

      // Wait for action to complete
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), CounterState.idle);
      expect(machine.context.value, 0);

      machine.dispose();
    });

    test('should track transition history', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0),
      );

      machine.send(CounterEvent.increment);
      await Future.delayed(const Duration(milliseconds: 10));

      machine.send(CounterEvent.increment);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.history.length, greaterThanOrEqualTo(4));
      // Each increment creates 2 transitions: idle->incrementing, incrementing->idle

      machine.dispose();
    });

    test('should stream state changes', () async {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0),
      );

      final changes = <StateChange<CounterState, CounterEvent>>[];
      machine.changes.listen(changes.add);

      machine.send(CounterEvent.increment);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(changes.length, greaterThanOrEqualTo(2));
      expect(changes[0].from, CounterState.idle);
      expect(changes[0].to, CounterState.incrementing);

      machine.dispose();
    });

    test('should update context externally', () {
      final machine = CounterStateMachine(
        context: const CounterContext(value: 0),
      );

      machine.updateContext(const CounterContext(value: 5));

      expect(machine.context.value, 5);
      expect(machine.currentState.peek(), CounterState.idle);

      machine.dispose();
    });
  });
}

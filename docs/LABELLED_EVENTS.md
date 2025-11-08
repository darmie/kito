# Labelled Events & Enhanced Actions

**Part of:** [STATE_MACHINE_ARCHITECTURE.md](./STATE_MACHINE_ARCHITECTURE.md)
**Version:** 1.0
**Last Updated:** 2025-11-08

---

## Overview

**Labelled events** are namespaced events based on state hierarchy and transient state transitions, similar to XState. They enable cascading state transitions and complex interaction patterns. Enhanced actions receive an **ActionContext** that provides access to the current state, event emission, and the state tree.

### Event Namespacing

Events are automatically namespaced based on:
- **State hierarchy**: `parent.child.EVENT_NAME`
- **Transient states**: Auto-generated events for automatic transitions
- **Explicit labels**: Developer-defined event names in DSL

---

## Event Namespace Patterns

### Flat Event Names (Simple)

```yaml
# No hierarchy - simple event names
events:
  - submit
  - cancel
  - retry

# Usage
machine.send(FormEvent.submit);
```

### Hierarchical State Events

```yaml
# Hierarchical states create namespaced events
states:
  form:
    states:
      idle:
        on:
          FOCUS:  # → form.idle.FOCUS
            target: form.editing

      editing:
        on:
          SUBMIT:  # → form.editing.SUBMIT
            target: form.validating

      validating:
        transient:
          - condition: FormGuards.isValid
            target: form.valid
            emit: form.validating.SUCCESS  # Namespaced event

          - condition: FormGuards.isInvalid
            target: form.invalid
            emit: form.validating.FAILURE

# Generated events
enum FormEvent {
  formIdleFocus,          // form.idle.FOCUS
  formEditingSubmit,      // form.editing.SUBMIT
  formValidatingSuccess,  // form.validating.SUCCESS
  formValidatingFailure,  // form.validating.FAILURE
}
```

### Transient State Auto-Events

Transient states automatically generate namespaced events:

```yaml
states:
  button:
    states:
      idle:
        on:
          TAP:
            target: button.pressed

      pressed:
        # Transient state - auto-generates event
        transient:
          after: 100ms
          target: button.released
          # Auto-event: button.pressed.DONE

      released:
        transient:
          after: 50ms
          target: button.idle
          # Auto-event: button.released.DONE

# Generated events include auto-events
enum ButtonEvent {
  buttonIdleTap,          // Explicit
  buttonPressedDone,      // Auto-generated from transient
  buttonReleasedDone,     // Auto-generated from transient
}
```

### Wildcard Event Matching

Match events from any child state:

```yaml
states:
  workflow:
    states:
      step1:
        on:
          NEXT: workflow.step2
          ERROR: workflow.error

      step2:
        on:
          NEXT: workflow.step3
          ERROR: workflow.error

      step3:
        on:
          COMPLETE: workflow.complete
          ERROR: workflow.error

    # Parent handles all error events
    on:
      "*.ERROR":  # Wildcard: workflow.*.ERROR
        target: workflow.error
        action: ErrorActions.handle
```

### Scoped Event Emission

Actions can emit namespaced events:

```dart
class WorkflowActions {
  static WorkflowContext validateStep(
    ActionContext<WorkflowState, WorkflowEvent, WorkflowContext> actx
  ) {
    // Emit namespaced event
    if (actx.context.isValid) {
      actx.emit(WorkflowEvent.workflowStep1Success);  // Namespaced
    } else {
      actx.emit(WorkflowEvent.workflowStep1Failure);
    }

    return actx.context;
  }
}
```

---

## The Problem

Pure actions transform context but can't:
- ❌ Trigger follow-up events
- ❌ Access current state for decision-making
- ❌ Cause cascading state transitions
- ❌ Interact with the state machine

**Example:**
```dart
// Pure action - limited capability
static ButtonContext incrementClick(ButtonContext ctx) {
  final newCtx = ctx.copyWith(clickCount: ctx.clickCount + 1);

  // ❌ Can't trigger event when max reached
  // ❌ Can't access current state
  // ❌ Can't emit events

  return newCtx;
}
```

---

## Solution: Enhanced Actions with ActionContext

### ActionContext Type

Actions can optionally receive an **ActionContext** that provides:

```dart
/// Enhanced context passed to actions
class ActionContext<S extends Enum, E extends Enum, C> {
  /// Current business logic context
  final C context;

  /// Current state of the machine
  final S currentState;

  /// Emit an event (will be queued and processed after action completes)
  final void Function(E event) emit;

  /// Read-only access to state machine history
  final List<StateTransition<S, E>> history;

  ActionContext({
    required this.context,
    required this.currentState,
    required this.emit,
    required this.history,
  });
}
```

### Enhanced Action Signature

Actions can use **either** signature:

**Simple (Pure):**
```dart
static C action(C context) { ... }
```

**Enhanced (With ActionContext):**
```dart
static C action(ActionContext<S, E, C> actx) { ... }
```

### Example: Enhanced Action

```dart
class ButtonActions {
  // Enhanced action with event emission
  static ButtonContext incrementClick(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx
  ) {
    final newCtx = actx.context.copyWith(
      clickCount: actx.context.clickCount + 1
    );

    // Emit event when max reached
    if (newCtx.clickCount >= 10) {
      actx.emit(ButtonEvent.maxReached);
    }

    // Access current state for logging
    print('Clicked in state: ${actx.currentState.name}');

    return newCtx;
  }

  // Simple pure action (still supported)
  static ButtonContext reset(ButtonContext ctx) {
    return ctx.copyWith(clickCount: 0);
  }
}
```

---

## Labelled Events in DSL

### Basic Syntax

Declare events to emit after action execution:

```yaml
config:
  hovered:
    on:
      tap:
        target: pressed
        action: ButtonActions.incrementClick
        emit:  # Labelled events (emitted after action)
          - maxReached  # Simple event
```

### Conditional Events

Emit events based on guards:

```yaml
config:
  idle:
    on:
      submit:
        target: validating
        action: FormActions.validate
        emit:
          - event: validationSuccess
            condition: FormGuards.isValid
          - event: validationFailure
            condition: FormGuards.isInvalid
```

### Multiple Events

Emit multiple events in sequence:

```yaml
config:
  loading:
    on:
      dataLoaded:
        target: processing
        action: DataActions.processData
        emit:
          - analyticsTracked
          - cacheUpdated
          - uiRefreshed
```

### Delayed Events

Emit events after a delay:

```yaml
config:
  success:
    entry:
      action: NotificationActions.show
      emit:
        - event: dismiss
          after: 3000  # Emit after 3 seconds
```

---

## Complete Example

### YAML Definition

```yaml
name: CounterStateMachine
context: CounterContext

states: [idle, incrementing, atMax, atMin, resetting]
events: [increment, decrement, maxReached, minReached, reset, resetComplete]
initial: idle

guards:
  - CounterGuards.notAtMax
  - CounterGuards.notAtMin
  - CounterGuards.willReachMax
  - CounterGuards.willReachMin

actions:
  - CounterActions.increment
  - CounterActions.decrement
  - CounterActions.reset

config:
  idle:
    on:
      increment:
        target: incrementing
        action: CounterActions.increment
        emit:
          - event: maxReached
            condition: CounterGuards.willReachMax

      decrement:
        target: idle
        action: CounterActions.decrement
        emit:
          - event: minReached
            condition: CounterGuards.willReachMin

      reset:
        target: resetting
        action: CounterActions.reset

  incrementing:
    on:
      maxReached:
        target: atMax

  atMax:
    entry:
      # Emit event after animation completes
      emit:
        - event: reset
          after: 2000
    on:
      reset:
        target: resetting
        action: CounterActions.reset

  resetting:
    # Transient state
    after:
      duration: 300
      target: idle
      emit:
        - resetComplete
```

### Implementation

```dart
/// Context
@immutable
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
}

/// Guards
class CounterGuards {
  static bool notAtMax(CounterContext ctx) => ctx.value < ctx.maxValue;
  static bool notAtMin(CounterContext ctx) => ctx.value > ctx.minValue;
  static bool willReachMax(CounterContext ctx) => ctx.value + 1 >= ctx.maxValue;
  static bool willReachMin(CounterContext ctx) => ctx.value - 1 <= ctx.minValue;
}

/// Enhanced Actions
class CounterActions {
  // Enhanced action with ActionContext
  static CounterContext increment(
    ActionContext<CounterState, CounterEvent, CounterContext> actx
  ) {
    final newValue = actx.context.value + 1;

    // Log state transition
    print('Incrementing from ${actx.currentState.name}');

    // Emit analytics event
    if (newValue % 5 == 0) {
      actx.emit(CounterEvent.milestone);  // Custom event for analytics
    }

    return actx.context.copyWith(value: newValue);
  }

  // Enhanced action
  static CounterContext decrement(
    ActionContext<CounterState, CounterEvent, CounterContext> actx
  ) {
    return actx.context.copyWith(value: actx.context.value - 1);
  }

  // Simple pure action (no ActionContext needed)
  static CounterContext reset(CounterContext ctx) {
    return ctx.copyWith(value: 0);
  }
}
```

### Usage

```dart
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late CounterStateMachine _machine;

  @override
  void initState() {
    super.initState();

    _machine = CounterStateMachine(
      context: CounterContext(),
      properties: props,
    );

    // Listen to state changes
    _machine.changes.listen((change) {
      setState(() {});

      // React to labelled events
      if (change.event == CounterEvent.maxReached) {
        showSnackBar('Maximum value reached!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Value: ${_machine.context.value}'),
        Text('State: ${_machine.currentState.value.name}'),

        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => _machine.send(CounterEvent.decrement),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _machine.send(CounterEvent.increment),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _machine.send(CounterEvent.reset),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Generated Code

### Action Dispatcher

The code generator detects action signatures and wraps them appropriately:

```dart
class CounterStateMachine extends KitoStateMachine<
  CounterState,
  CounterEvent,
  CounterContext
> {
  static StateMachineConfig<CounterState, CounterEvent, CounterContext> _buildConfig(
    AnimatedWidgetProperties properties,
  ) {
    return StateMachineConfig(
      states: {
        CounterState.idle: StateConfig(
          transitions: {
            CounterEvent.increment: TransitionConfig(
              target: CounterState.incrementing,

              // Wrap enhanced action
              action: (actx) => CounterActions.increment(actx),

              // Conditional labelled events
              emit: [
                ConditionalEvent(
                  event: CounterEvent.maxReached,
                  condition: (ctx) => CounterGuards.willReachMax(ctx),
                ),
              ],
            ),

            CounterEvent.reset: TransitionConfig(
              target: CounterState.resetting,

              // Wrap simple action (convert to enhanced signature)
              action: (actx) => CounterActions.reset(actx.context),
            ),
          },
        ),

        CounterState.atMax: StateConfig(
          onEntry: (ctx, from, to) {
            // Entry emissions are scheduled
          },

          // Delayed emissions from entry
          entryEmissions: [
            DelayedEvent(
              event: CounterEvent.reset,
              delay: Duration(milliseconds: 2000),
            ),
          ],
        ),
      },
    );
  }
}
```

### Event Queue

The runtime maintains an event queue for labelled events:

```dart
abstract class KitoStateMachine<S extends Enum, E extends Enum, C> {
  final Queue<E> _eventQueue = Queue();
  bool _isProcessingEvent = false;

  /// Send an event to the state machine
  void send(E event) {
    _eventQueue.add(event);
    _processEventQueue();
  }

  void _processEventQueue() {
    if (_isProcessingEvent || _eventQueue.isEmpty) return;

    _isProcessingEvent = true;

    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeFirst();
      _handleEvent(event);
    }

    _isProcessingEvent = false;
  }

  void _handleEvent(E event) {
    // 1. Find transition
    final transition = _config.states[currentState.value]?.transitions[event];
    if (transition == null) return;

    // 2. Evaluate guard
    if (transition.guard != null && !transition.guard!(context)) {
      return;
    }

    // 3. Execute action (with ActionContext)
    if (transition.action != null) {
      final actx = ActionContext(
        context: context,
        currentState: currentState.value,
        emit: (event) => _eventQueue.add(event),  // Queue emitted events
        history: history,
      );

      context = transition.action!(actx);
    }

    // 4. Change state
    final previousState = currentState.value;
    currentState.value = transition.target;

    // 5. Process labelled events from transition
    if (transition.emit != null) {
      for (final conditionalEvent in transition.emit!) {
        if (conditionalEvent.condition == null ||
            conditionalEvent.condition!(context)) {

          if (conditionalEvent.delay != null) {
            // Schedule delayed emission
            Future.delayed(conditionalEvent.delay!, () {
              send(conditionalEvent.event);
            });
          } else {
            // Queue immediate emission
            _eventQueue.add(conditionalEvent.event);
          }
        }
      }
    }

    // 6. Trigger animations
    _triggerAnimations(transition);
  }
}
```

---

## Advanced Patterns

### Pattern 1: Event Chains

```yaml
# Multi-step workflow with labelled events
config:
  idle:
    on:
      start:
        target: step1
        action: WorkflowActions.initStep1
        emit: [step1Started]

  step1:
    on:
      step1Started:
        target: step1Running

      step1Complete:
        target: step2
        action: WorkflowActions.initStep2
        emit: [step2Started]

  step2:
    on:
      step2Started:
        target: step2Running

      step2Complete:
        target: complete
        emit: [workflowComplete]
```

### Pattern 2: Conditional Cascades

```dart
// Action that emits different events based on context
static FormContext validate(
  ActionContext<FormState, FormEvent, FormContext> actx
) {
  final errors = _runValidation(actx.context);

  if (errors.isEmpty) {
    actx.emit(FormEvent.validationSuccess);
  } else {
    actx.emit(FormEvent.validationFailure);
  }

  return actx.context.copyWith(errors: errors);
}
```

### Pattern 3: Analytics Integration

```dart
// Emit analytics events alongside state transitions
static OrderContext submitOrder(
  ActionContext<OrderState, OrderEvent, OrderContext> actx
) {
  // Track analytics
  actx.emit(OrderEvent.analyticsSubmitted);

  // Update context
  return actx.context.copyWith(
    submittedAt: DateTime.now(),
  );
}
```

### Pattern 4: Hierarchical State Machines with Namespaced Events

Complete example showing hierarchy, transient states, and namespaced events:

```yaml
name: AuthFlowMachine
context: AuthContext

# Hierarchical states
states:
  auth:
    initial: auth.idle
    states:
      idle:
        on:
          START:
            target: auth.checking

      checking:
        entry:
          action: AuthActions.checkSession
        # Transient - auto-generates auth.checking.DONE
        transient:
          - condition: AuthGuards.hasSession
            target: auth.authenticated
            emit: auth.checking.SUCCESS

          - condition: AuthGuards.noSession
            target: auth.unauthenticated
            emit: auth.checking.FAILURE

      authenticated:
        states:
          loading:
            entry:
              action: AuthActions.loadUserData
            transient:
              after: 500ms
              target: auth.authenticated.ready
              # Auto: auth.authenticated.loading.DONE

          ready:
            on:
              LOGOUT:
                target: auth.unauthenticated
                action: AuthActions.logout
                emit: auth.authenticated.ready.LOGGED_OUT

      unauthenticated:
        states:
          form:
            on:
              SUBMIT:
                target: auth.unauthenticated.submitting
                action: AuthActions.submit

          submitting:
            entry:
              action: AuthActions.authenticate
            # Emits namespaced events
            on:
              auth.unauthenticated.submitting.SUCCESS:
                target: auth.authenticated
              auth.unauthenticated.submitting.FAILURE:
                target: auth.unauthenticated.form
                action: AuthActions.setError

# Generated enum with namespaced events
enum AuthEvent {
  // Explicit events
  authIdleStart,
  authAuthenticatedReadyLogout,
  authUnauthenticatedFormSubmit,

  // Auto-generated from transient states
  authCheckingDone,
  authAuthenticatedLoadingDone,

  // Labelled events
  authCheckingSuccess,
  authCheckingFailure,
  authAuthenticatedReadyLoggedOut,
  authUnauthenticatedSubmittingSuccess,
  authUnauthenticatedSubmittingFailure,
}
```

### Pattern 5: Error Recovery

```yaml
config:
  processing:
    on:
      error:
        target: errorState
        action: ErrorActions.captureError
        emit:
          - event: retryScheduled
            after: 5000  # Auto-retry after 5s

  errorState:
    on:
      retryScheduled:
        target: processing
        action: ProcessActions.retry
```

---

## Type Safety

The code generator ensures type safety:

```dart
// ✅ Correct: ActionContext matches state machine types
static CounterContext increment(
  ActionContext<CounterState, CounterEvent, CounterContext> actx
) { ... }

// ❌ Compile error: Wrong state type
static CounterContext increment(
  ActionContext<WrongState, CounterEvent, CounterContext> actx
) { ... }

// ✅ Also correct: Simple action (no ActionContext)
static CounterContext reset(CounterContext ctx) { ... }
```

---

## Testing

### Testing Enhanced Actions

```dart
void main() {
  group('CounterActions', () {
    test('increment emits maxReached at limit', () {
      final emittedEvents = <CounterEvent>[];

      final actx = ActionContext(
        context: CounterContext(value: 9, maxValue: 10),
        currentState: CounterState.idle,
        emit: emittedEvents.add,
        history: [],
      );

      final newCtx = CounterActions.increment(actx);

      expect(newCtx.value, 10);
      expect(emittedEvents, contains(CounterEvent.maxReached));
    });

    test('increment does not emit when not at max', () {
      final emittedEvents = <CounterEvent>[];

      final actx = ActionContext(
        context: CounterContext(value: 5, maxValue: 10),
        currentState: CounterState.idle,
        emit: emittedEvents.add,
        history: [],
      );

      final newCtx = CounterActions.increment(actx);

      expect(newCtx.value, 6);
      expect(emittedEvents, isEmpty);
    });
  });
}
```

### Testing State Machine with Labelled Events

```dart
void main() {
  group('CounterStateMachine', () {
    late CounterStateMachine machine;

    setUp(() {
      machine = CounterStateMachine(
        context: CounterContext(value: 9, maxValue: 10),
        properties: testProps,
      );
    });

    test('emits maxReached when incrementing to max', () async {
      final events = <CounterEvent>[];

      machine.changes.listen((change) {
        if (change.event != null) {
          events.add(change.event!);
        }
      });

      machine.send(CounterEvent.increment);

      await Future.delayed(Duration(milliseconds: 10));

      expect(events, contains(CounterEvent.maxReached));
      expect(machine.currentState.value, CounterState.atMax);
    });
  });
}
```

---

## Benefits

### 1. **Declarative Event Orchestration**
```yaml
# Clear, declarative event chains
emit:
  - validationSuccess
  - analyticsTracked
  - cacheUpdated
```

### 2. **Type-Safe Event Emission**
```dart
// Compiler ensures events are valid
actx.emit(CounterEvent.maxReached);  // ✅
actx.emit(WrongEvent.foo);           // ❌ Compile error
```

### 3. **Testable Event Logic**
```dart
// Easy to test event emission
test('emits correct event', () {
  final emitted = <Event>[];
  final actx = ActionContext(..., emit: emitted.add);
  action(actx);
  expect(emitted, contains(Event.expected));
});
```

### 4. **State-Aware Actions**
```dart
// Actions can make decisions based on current state
if (actx.currentState == State.special) {
  actx.emit(Event.specialHandling);
}
```

### 5. **Cascading Workflows**
```yaml
# Multi-step workflows with automatic progression
step1Complete → step2Started → step2Running → complete
```

---

## Summary

Labelled events and enhanced ActionContext provide:

- ✅ Event emission from actions
- ✅ State-aware action logic
- ✅ Conditional event chains
- ✅ Delayed event emission
- ✅ Type-safe event handling
- ✅ Testable event logic
- ✅ Declarative workflow orchestration

This makes Kito state machines capable of handling complex, multi-step interactions while maintaining type safety and functional purity.

---

**See Also:**
- [State Machine Architecture](./STATE_MACHINE_ARCHITECTURE.md)
- [Context-Based Guards](./CONTEXT_BASED_GUARDS.md)
- [Examples Guide](./STATE_MACHINE_EXAMPLES.md)

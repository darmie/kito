# Context-Based Guards and Actions

**Part of:** [STATE_MACHINE_ARCHITECTURE.md](./STATE_MACHINE_ARCHITECTURE.md)
**Version:** 1.0
**Last Updated:** 2025-11-08

---

## Overview

Kito state machines use **context-based guards and actions** instead of inheritance-based implementation. This approach provides:

- ✅ **Pure functions**: Guards and actions are stateless, testable functions
- ✅ **Type safety**: Context is explicitly typed via generics
- ✅ **Composability**: Reuse guards across multiple state machines
- ✅ **Clarity**: State machine logic is separated from business logic
- ✅ **No inheritance**: No need to extend generated classes

---

## Core Concept

### The Context Type

Every state machine has an associated **Context** type that holds all the state needed for guards, actions, and business logic:

```dart
/// Context for button state machine
class ButtonContext {
  final bool enabled;
  final int clickCount;
  final String? errorMessage;

  const ButtonContext({
    this.enabled = true,
    this.clickCount = 0,
    this.errorMessage,
  });

  // Copyable for immutability
  ButtonContext copyWith({
    bool? enabled,
    int? clickCount,
    String? errorMessage,
  }) {
    return ButtonContext(
      enabled: enabled ?? this.enabled,
      clickCount: clickCount ?? this.clickCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
```

### Generic State Machine

State machines use generics to reference their context:

```dart
class ButtonStateMachine extends KitoStateMachine<
  ButtonState,      // State enum
  ButtonEvent,      // Event enum
  ButtonContext     // Context type
> {
  ButtonStateMachine({
    required ButtonContext context,
    required AnimatedWidgetProperties properties,
  }) : super(
    initial: ButtonState.idle,
    context: context,
    properties: properties,
    config: _buildConfig(),
  );
}
```

---

## Guards

### Declaration

Guards are **static functions** that take context and return a boolean:

```dart
// Pure guard functions
class ButtonGuards {
  static bool isEnabled(ButtonContext ctx) => ctx.enabled;

  static bool hasClicked(ButtonContext ctx) => ctx.clickCount > 0;

  static bool canSubmit(ButtonContext ctx) {
    return ctx.enabled && ctx.clickCount < 5;
  }

  static bool hasError(ButtonContext ctx) => ctx.errorMessage != null;
}
```

### DSL Reference

In the YAML DSL, reference guards by their **fully qualified name**:

```yaml
# button.kito.yaml
name: ButtonStateMachine
context: ButtonContext

states: [idle, hovered, pressed, loading, success, error]
events: [hover, unhover, tap, submit_success, submit_error]
initial: idle

# Declare guards (fully qualified names)
guards:
  - ButtonGuards.isEnabled
  - ButtonGuards.canSubmit
  - ButtonGuards.hasError

config:
  idle:
    on:
      hover:
        target: hovered
        guard: ButtonGuards.isEnabled  # References static function

  hovered:
    on:
      tap:
        target: pressed
        guard: ButtonGuards.canSubmit  # Multiple conditions in one guard
```

### Generated Code

The code generator produces guard references:

```dart
// Generated: button_state_machine.g.dart

class ButtonStateMachine extends KitoStateMachine<
  ButtonState,
  ButtonEvent,
  ButtonContext
> {
  static StateMachineConfig<ButtonState, ButtonEvent, ButtonContext> _buildConfig() {
    return StateMachineConfig(
      states: {
        ButtonState.idle: StateConfig(
          transitions: {
            ButtonEvent.hover: TransitionConfig(
              target: ButtonState.hovered,
              guard: ButtonGuards.isEnabled,  // Direct function reference
            ),
          },
        ),
        ButtonState.hovered: StateConfig(
          transitions: {
            ButtonEvent.tap: TransitionConfig(
              target: ButtonState.pressed,
              guard: ButtonGuards.canSubmit,
            ),
          },
        ),
      },
    );
  }
}
```

---

## Actions

### Declaration

Actions are **static functions** that take context and return a new context:

```dart
/// Pure action functions (no side effects)
class ButtonActions {
  static ButtonContext incrementClick(ButtonContext ctx) {
    return ctx.copyWith(clickCount: ctx.clickCount + 1);
  }

  static ButtonContext resetClicks(ButtonContext ctx) {
    return ctx.copyWith(clickCount: 0, errorMessage: null);
  }

  static ButtonContext setError(ButtonContext ctx, String error) {
    return ctx.copyWith(errorMessage: error);
  }

  static ButtonContext clearError(ButtonContext ctx) {
    return ctx.copyWith(errorMessage: null);
  }
}
```

### Actions with Side Effects

For actions that need side effects (API calls, logging), use **entry/exit callbacks**:

```dart
/// Actions with side effects
class ButtonSideEffects {
  static Future<void> logTransition(
    ButtonContext ctx,
    ButtonState from,
    ButtonState to,
  ) async {
    print('Transition: $from → $to');
    await analytics.logEvent('state_transition', {
      'from': from.name,
      'to': to.name,
      'clickCount': ctx.clickCount,
    });
  }

  static Future<void> submitForm(ButtonContext ctx) async {
    await api.submitForm(clickCount: ctx.clickCount);
  }
}
```

### DSL Reference

```yaml
guards:
  - ButtonGuards.isEnabled
  - ButtonGuards.canSubmit

# Declare actions
actions:
  - ButtonActions.incrementClick
  - ButtonActions.resetClicks
  - ButtonSideEffects.logTransition
  - ButtonSideEffects.submitForm

config:
  hovered:
    on:
      tap:
        target: pressed
        guard: ButtonGuards.canSubmit
        action: ButtonActions.incrementClick  # Pure context update

  pressed:
    entry:
      action: ButtonSideEffects.logTransition  # Side effect on entry
    after:
      duration: 100
      target: loading

  loading:
    entry:
      action: ButtonSideEffects.submitForm  # Async side effect
```

### Generated Code

```dart
class ButtonStateMachine extends KitoStateMachine<
  ButtonState,
  ButtonEvent,
  ButtonContext
> {
  static StateMachineConfig<ButtonState, ButtonEvent, ButtonContext> _buildConfig() {
    return StateMachineConfig(
      states: {
        ButtonState.hovered: StateConfig(
          transitions: {
            ButtonEvent.tap: TransitionConfig(
              target: ButtonState.pressed,
              guard: ButtonGuards.canSubmit,
              action: ButtonActions.incrementClick,  // Context transform
            ),
          },
        ),
        ButtonState.pressed: StateConfig(
          onEntry: ButtonSideEffects.logTransition,  // Entry callback
          transient: TransientConfig(
            after: Duration(milliseconds: 100),
            target: ButtonState.loading,
          ),
        ),
        ButtonState.loading: StateConfig(
          onEntry: ButtonSideEffects.submitForm,  // Async entry
        ),
      },
    );
  }
}
```

---

## Runtime Behavior

### Context Updates

When a transition occurs with an action:

```dart
// Pseudo-code for transition execution
void _executeTransition(Event event, TransitionConfig config) {
  // 1. Evaluate guard
  if (config.guard != null && !config.guard!(context)) {
    return; // Guard failed, no transition
  }

  // 2. Execute exit action of current state
  final currentStateConfig = _config.states[currentState.value]!;
  if (currentStateConfig.onExit != null) {
    currentStateConfig.onExit!(context, currentState.value, config.target);
  }

  // 3. Apply transition action (pure context update)
  if (config.action != null) {
    context = config.action!(context);  // Update context
  }

  // 4. Change state
  final previousState = currentState.value;
  currentState.value = config.target;

  // 5. Execute entry action of new state
  final newStateConfig = _config.states[config.target]!;
  if (newStateConfig.onEntry != null) {
    newStateConfig.onEntry!(context, previousState, config.target);
  }

  // 6. Trigger animations
  _triggerAnimations(config);
}
```

### Immutable Context Pattern

For safer state management, use **immutable contexts**:

```dart
@immutable
class ButtonContext {
  final bool enabled;
  final int clickCount;
  final String? errorMessage;

  const ButtonContext({
    this.enabled = true,
    this.clickCount = 0,
    this.errorMessage,
  });

  ButtonContext copyWith({
    bool? enabled,
    int? clickCount,
    String? errorMessage,
  }) {
    return ButtonContext(
      enabled: enabled ?? this.enabled,
      clickCount: clickCount ?? this.clickCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Actions always return new context
static ButtonContext incrementClick(ButtonContext ctx) {
  return ctx.copyWith(clickCount: ctx.clickCount + 1);
}
```

---

## Advanced Patterns

### Pattern 1: Parameterized Actions

Actions can accept additional parameters:

```dart
class FormActions {
  static FormContext setFieldValue(FormContext ctx, String field, String value) {
    final updatedFields = Map<String, String>.from(ctx.fields);
    updatedFields[field] = value;
    return ctx.copyWith(fields: updatedFields);
  }
}
```

**DSL:**

```yaml
config:
  editing:
    on:
      input:
        target: validating
        action: FormActions.setFieldValue
        params:  # Pass parameters to action
          field: "email"
          value: "${event.value}"
```

**Generated:**

```dart
TransitionConfig(
  target: FormState.validating,
  action: (ctx) => FormActions.setFieldValue(ctx, "email", event.value),
)
```

### Pattern 2: Composed Guards

Combine multiple guards:

```dart
class GuardComposers {
  static bool Function(T) and<T>(
    bool Function(T) guard1,
    bool Function(T) guard2,
  ) {
    return (ctx) => guard1(ctx) && guard2(ctx);
  }

  static bool Function(T) or<T>(
    bool Function(T) guard1,
    bool Function(T) guard2,
  ) {
    return (ctx) => guard1(ctx) || guard2(ctx);
  }

  static bool Function(T) not<T>(bool Function(T) guard) {
    return (ctx) => !guard(ctx);
  }
}

// Usage
class ButtonGuards {
  static bool canSubmit(ButtonContext ctx) {
    return GuardComposers.and(isEnabled, hasNoErrors)(ctx);
  }

  static bool isEnabled(ButtonContext ctx) => ctx.enabled;
  static bool hasNoErrors(ButtonContext ctx) => ctx.errorMessage == null;
}
```

### Pattern 3: Context with Reactive State

Integrate with Kito's reactive primitives:

```dart
class ReactiveButtonContext {
  final Signal<bool> enabled;
  final Signal<int> clickCount;
  final Computed<bool> canSubmit;

  ReactiveButtonContext({
    bool initialEnabled = true,
    int initialClicks = 0,
  }) :
    enabled = signal(initialEnabled),
    clickCount = signal(initialClicks),
    canSubmit = computed(() => enabled.value && clickCount.value < 5);
}

// Guards can access reactive values
class ButtonGuards {
  static bool canSubmit(ReactiveButtonContext ctx) => ctx.canSubmit.value;
}

// Actions update signals
class ButtonActions {
  static ReactiveButtonContext incrementClick(ReactiveButtonContext ctx) {
    ctx.clickCount.value++;
    return ctx;  // Return same instance (signals are mutable)
  }
}
```

### Pattern 4: Shared Guards Library

Create reusable guard collections:

```dart
/// Common guards for all state machines
class CommonGuards {
  static bool always<T>(T ctx) => true;
  static bool never<T>(T ctx) => false;

  static bool Function(T) equals<T, V>(
    V Function(T) selector,
    V value,
  ) {
    return (ctx) => selector(ctx) == value;
  }
}

// Usage
class ButtonGuards {
  static bool isDisabled(ButtonContext ctx) {
    return CommonGuards.equals<ButtonContext, bool>(
      (ctx) => ctx.enabled,
      false,
    )(ctx);
  }
}
```

---

## Testing

### Testing Guards

```dart
void main() {
  group('ButtonGuards', () {
    test('isEnabled returns true when enabled', () {
      final ctx = ButtonContext(enabled: true);
      expect(ButtonGuards.isEnabled(ctx), true);
    });

    test('canSubmit checks multiple conditions', () {
      final ctx = ButtonContext(enabled: true, clickCount: 3);
      expect(ButtonGuards.canSubmit(ctx), true);

      final ctx2 = ctx.copyWith(clickCount: 6);
      expect(ButtonGuards.canSubmit(ctx2), false);
    });
  });
}
```

### Testing Actions

```dart
void main() {
  group('ButtonActions', () {
    test('incrementClick increases count', () {
      final ctx = ButtonContext(clickCount: 5);
      final newCtx = ButtonActions.incrementClick(ctx);

      expect(newCtx.clickCount, 6);
      expect(ctx.clickCount, 5);  // Original unchanged
    });

    test('resetClicks clears count and error', () {
      final ctx = ButtonContext(
        clickCount: 10,
        errorMessage: 'error',
      );
      final newCtx = ButtonActions.resetClicks(ctx);

      expect(newCtx.clickCount, 0);
      expect(newCtx.errorMessage, null);
    });
  });
}
```

### Testing State Machines with Context

```dart
void main() {
  group('ButtonStateMachine', () {
    late ButtonStateMachine machine;
    late ButtonContext initialContext;

    setUp(() {
      initialContext = ButtonContext(enabled: true);
      machine = ButtonStateMachine(
        context: initialContext,
        properties: testProps,
      );
    });

    test('transition succeeds when guard passes', () {
      machine.send(ButtonEvent.hover);
      expect(machine.currentState.value, ButtonState.hovered);
    });

    test('transition fails when guard fails', () {
      // Update context to fail guard
      machine.updateContext(initialContext.copyWith(enabled: false));

      machine.send(ButtonEvent.hover);
      expect(machine.currentState.value, ButtonState.idle);  // No transition
    });

    test('action updates context', () {
      machine.send(ButtonEvent.tap);

      expect(machine.context.clickCount, 1);
    });
  });
}
```

---

## DSL Schema Updates

### Context Declaration

```yaml
name: ButtonStateMachine
description: "Button with click tracking"

# Declare context type
context: ButtonContext

states: [idle, hovered, pressed, loading]
events: [hover, tap, submit]
initial: idle

# Guards reference static functions
guards:
  - ButtonGuards.isEnabled
  - ButtonGuards.canSubmit

# Actions reference static functions
actions:
  - ButtonActions.incrementClick
  - ButtonActions.resetClicks

config:
  idle:
    on:
      hover:
        target: hovered
        guard: ButtonGuards.isEnabled

  hovered:
    on:
      tap:
        target: pressed
        guard: ButtonGuards.canSubmit
        action: ButtonActions.incrementClick
```

### Validation Rules

The code generator validates:

1. **Context type exists** and is a valid Dart class
2. **Guards are static functions** with signature `bool Function(ContextType)`
3. **Actions are static functions** with signature `ContextType Function(ContextType)`
4. **All referenced guards/actions are declared** in the `guards`/`actions` lists
5. **Guard/action references use fully qualified names** (e.g., `ButtonGuards.isEnabled`)

---

## Generated Code Structure

### Full Example

**Input (`button.kito.yaml`):**

```yaml
name: ButtonStateMachine
context: ButtonContext

states: [idle, pressed]
events: [tap, reset]
initial: idle

guards:
  - ButtonGuards.canTap

actions:
  - ButtonActions.incrementClick
  - ButtonActions.resetClicks

config:
  idle:
    on:
      tap:
        target: pressed
        guard: ButtonGuards.canTap
        action: ButtonActions.incrementClick

  pressed:
    after:
      duration: 200
      target: idle
      action: ButtonActions.resetClicks
```

**Output (`button_state_machine.g.dart`):**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from: button.kito.yaml

part of 'button.kito.dart';

enum ButtonState { idle, pressed }

enum ButtonEvent { tap, reset }

class ButtonStateMachine extends KitoStateMachine<
  ButtonState,
  ButtonEvent,
  ButtonContext  // Generic context type
> {
  ButtonStateMachine({
    required ButtonContext context,
    required AnimatedWidgetProperties properties,
  }) : super(
    initial: ButtonState.idle,
    context: context,
    properties: properties,
    config: _buildConfig(),
  );

  static StateMachineConfig<ButtonState, ButtonEvent, ButtonContext> _buildConfig() {
    return StateMachineConfig(
      states: {
        ButtonState.idle: StateConfig(
          transitions: {
            ButtonEvent.tap: TransitionConfig(
              target: ButtonState.pressed,
              guard: ButtonGuards.canTap,  // Static function reference
              action: ButtonActions.incrementClick,  // Static function reference
            ),
          },
        ),
        ButtonState.pressed: StateConfig(
          transient: TransientConfig(
            after: Duration(milliseconds: 200),
            target: ButtonState.idle,
            action: ButtonActions.resetClicks,
          ),
        ),
      },
    );
  }
}
```

**User Implementation (`button.kito.dart`):**

```dart
import 'package:kito/kito.dart';

part 'button_state_machine.g.dart';

/// Context for button state machine
@immutable
class ButtonContext {
  final bool enabled;
  final int clickCount;

  const ButtonContext({
    this.enabled = true,
    this.clickCount = 0,
  });

  ButtonContext copyWith({bool? enabled, int? clickCount}) {
    return ButtonContext(
      enabled: enabled ?? this.enabled,
      clickCount: clickCount ?? this.clickCount,
    );
  }
}

/// Guards
class ButtonGuards {
  static bool canTap(ButtonContext ctx) => ctx.enabled && ctx.clickCount < 10;
}

/// Actions
class ButtonActions {
  static ButtonContext incrementClick(ButtonContext ctx) {
    return ctx.copyWith(clickCount: ctx.clickCount + 1);
  }

  static ButtonContext resetClicks(ButtonContext ctx) {
    return ctx.copyWith(clickCount: 0);
  }
}
```

---

## Benefits of This Approach

### 1. **Testability**

Guards and actions are pure functions that are trivial to test:

```dart
test('guard logic', () {
  expect(ButtonGuards.canTap(ButtonContext(enabled: true)), true);
  expect(ButtonGuards.canTap(ButtonContext(enabled: false)), false);
});
```

### 2. **Reusability**

Share guards across state machines:

```dart
class CommonGuards {
  static bool isEnabled<T extends HasEnabled>(T ctx) => ctx.enabled;
}

class ButtonGuards {
  static bool canTap(ButtonContext ctx) => CommonGuards.isEnabled(ctx);
}

class FormGuards {
  static bool canSubmit(FormContext ctx) => CommonGuards.isEnabled(ctx);
}
```

### 3. **Type Safety**

Compiler ensures guards/actions match context type:

```dart
// Compile error: wrong context type
static bool canTap(WrongContext ctx) => ctx.enabled;
```

### 4. **Separation of Concerns**

- **DSL**: Declares state machine structure
- **Context**: Holds business state
- **Guards**: Business logic predicates
- **Actions**: State transformations
- **Generated Code**: Wires everything together

### 5. **No Inheritance**

No need to extend generated classes—just declare your guards/actions:

```dart
// No inheritance needed!
class ButtonGuards {
  static bool canTap(ButtonContext ctx) => ctx.enabled;
}
```

---

## Migration from Implementation Pattern

**Old approach (implementation-based):**

```dart
abstract class ButtonStateMachine {
  bool isEnabled();  // Abstract, must implement
}

class ButtonStateMachineImpl extends ButtonStateMachine {
  bool _enabled = true;

  @override
  bool isEnabled() => _enabled;
}
```

**New approach (context-based):**

```dart
class ButtonContext {
  final bool enabled;
  const ButtonContext({this.enabled = true});
}

class ButtonGuards {
  static bool isEnabled(ButtonContext ctx) => ctx.enabled;
}

// No inheritance!
final machine = ButtonStateMachine(
  context: ButtonContext(enabled: true),
  properties: props,
);
```

---

## Summary

Context-based guards and actions provide:

- ✅ Pure, testable functions
- ✅ Type-safe context access via generics
- ✅ Composable and reusable logic
- ✅ Clear separation of concerns
- ✅ No inheritance required
- ✅ Easy to reason about and maintain

This approach aligns perfectly with functional programming principles while maintaining the ease of use that makes Kito state machines accessible to Flutter developers.

---

**See Also:**
- [State Machine Architecture](./STATE_MACHINE_ARCHITECTURE.md)
- [Examples Guide](./STATE_MACHINE_EXAMPLES.md)
- [Temporal Integration](./TEMPORAL_GUIDE.md)

# Kito State Machine Examples & Patterns

**Companion to:** [STATE_MACHINE_ARCHITECTURE.md](./STATE_MACHINE_ARCHITECTURE.md)

This document provides practical examples and common patterns for using Kito State Machines.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Common Patterns](#common-patterns)
3. [Real-World Examples](#real-world-examples)
4. [Best Practices](#best-practices)
5. [Troubleshooting](#troubleshooting)

---

## Quick Start

### 1. Create a State Machine Definition

**`lib/state_machines/counter.kito.yaml`:**

```yaml
name: CounterStateMachine
description: "Simple counter with min/max bounds"

states: [normal, at_max, at_min]
events: [increment, decrement, reset]
initial: normal

config:
  normal:
    on:
      increment:
        target: normal
        guard: notAtMax
        action: incrementValue

      increment:
        target: at_max
        guard: willReachMax
        action: incrementValue
        animation:
          property: scale
          to: 1.2
          duration: 200
          easing: easeOutBack

      decrement:
        target: normal
        guard: notAtMin
        action: decrementValue

      decrement:
        target: at_min
        guard: willReachMin
        action: decrementValue
        animation:
          property: scale
          to: 0.9
          duration: 200
          easing: easeOutBack

      reset:
        target: normal
        action: resetValue

  at_max:
    entry:
      animation:
        property: color
        to: "#FF5722"
        duration: 300
    on:
      decrement:
        target: normal
        action: decrementValue
      reset:
        target: normal
        action: resetValue

  at_min:
    entry:
      animation:
        property: color
        to: "#2196F3"
        duration: 300
    on:
      increment:
        target: normal
        action: incrementValue
      reset:
        target: normal
        action: resetValue

properties:
  - scale: double
  - color: Color

guards:
  - notAtMax
  - willReachMax
  - notAtMin
  - willReachMin

actions:
  - incrementValue
  - decrementValue
  - resetValue
```

### 2. Generate Code

```bash
flutter pub run build_runner build
```

This generates: `lib/state_machines/counter.kito.g.dart`

### 3. Implement Guards and Actions

**`lib/state_machines/counter.kito.dart`:**

```dart
import 'package:kito/kito.dart';

part 'counter.kito.g.dart';

class CounterStateMachineImpl extends CounterStateMachine {
  static const int maxValue = 10;
  static const int minValue = 0;

  int _value = 5;
  int get value => _value;

  CounterStateMachineImpl({
    required AnimatedWidgetProperties properties,
  }) : super(properties: properties);

  // Guards
  bool notAtMax() => _value < maxValue;
  bool willReachMax() => _value + 1 >= maxValue;
  bool notAtMin() => _value > minValue;
  bool willReachMin() => _value - 1 <= minValue;

  // Actions
  void incrementValue() {
    if (_value < maxValue) {
      _value++;
    }
  }

  void decrementValue() {
    if (_value > minValue) {
      _value--;
    }
  }

  void resetValue() {
    _value = 5;
  }
}
```

### 4. Use in Flutter Widget

```dart
import 'package:flutter/material.dart';
import 'state_machines/counter.kito.dart';

class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late CounterStateMachineImpl _machine;
  late AnimatedWidgetProperties _props;

  @override
  void initState() {
    super.initState();

    _props = AnimatedWidgetProperties(
      scale: 1.0,
      color: Colors.grey,
    );

    _machine = CounterStateMachineImpl(properties: _props);

    // Listen to state changes to trigger UI updates
    _machine.changes.listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _machine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        KitoAnimatedWidget(
          properties: _props,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _props.color.value,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '${_machine.value}',
              style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () => _machine.send(CounterEvent.decrement),
              iconSize: 48,
            ),
            SizedBox(width: 32),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _machine.send(CounterEvent.reset),
              iconSize: 48,
            ),
            SizedBox(width: 32),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _machine.send(CounterEvent.increment),
              iconSize: 48,
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'State: ${_machine.currentState.value.name}',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
```

---

## Common Patterns

### Pattern 1: Loading States

**Problem:** Handle async operations with loading, success, and error states.

```yaml
name: LoadingStateMachine
states: [idle, loading, success, error]
events: [fetch, retry, reset]
initial: idle

config:
  idle:
    on:
      fetch:
        target: loading

  loading:
    entry:
      animation:
        property: rotation
        to: 6.28
        duration: 1000
        loop: infinite
    # Transitions triggered by async results
    on:
      # Programmatically sent from code
      fetch_success:
        target: success
      fetch_error:
        target: error

  success:
    entry:
      animation:
        property: opacity
        from: 0
        to: 1
        duration: 300
    after:
      duration: 3000
      target: idle

  error:
    entry:
      animation:
        property: color
        to: "#F44336"
        duration: 200
    on:
      retry:
        target: loading
      reset:
        target: idle
```

**Implementation:**

```dart
class DataFetcher extends StatefulWidget {
  @override
  State<DataFetcher> createState() => _DataFetcherState();
}

class _DataFetcherState extends State<DataFetcher> {
  late LoadingStateMachine _machine;

  @override
  void initState() {
    super.initState();
    _machine = LoadingStateMachine(properties: props);

    // Listen for loading state to trigger fetch
    _machine.changes.listen((change) {
      if (change.to == LoadingState.loading) {
        _fetchData();
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      final data = await api.fetchData();
      _machine.send(LoadingEvent.fetchSuccess);
      // Process data
    } catch (e) {
      _machine.send(LoadingEvent.fetchError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _machine.currentState.value;

    return switch (state) {
      LoadingState.idle => ElevatedButton(
          onPressed: () => _machine.send(LoadingEvent.fetch),
          child: Text('Load Data'),
        ),
      LoadingState.loading => CircularProgressIndicator(),
      LoadingState.success => Text('Data loaded!'),
      LoadingState.error => Column(
          children: [
            Text('Error loading data'),
            TextButton(
              onPressed: () => _machine.send(LoadingEvent.retry),
              child: Text('Retry'),
            ),
          ],
        ),
    };
  }
}
```

### Pattern 2: Form Validation Pipeline

**Problem:** Validate form fields with debouncing and async validation.

```yaml
name: FieldValidationMachine
states: [pristine, typing, debouncing, validating, valid, invalid]
events: [focus, input, validate_success, validate_failure, blur]
initial: pristine

config:
  pristine:
    on:
      focus:
        target: typing

  typing:
    on:
      input:
        target: debouncing

  debouncing:
    # Wait for user to stop typing
    after:
      duration: 500
      target: validating

  validating:
    entry:
      animation:
        property: borderColor
        to: "#FFC107"
        duration: 150
    on:
      validate_success:
        target: valid
      validate_failure:
        target: invalid
      input:
        # User kept typing, restart debounce
        target: debouncing

  valid:
    entry:
      animation:
        property: borderColor
        to: "#4CAF50"
        duration: 200
    on:
      input:
        target: debouncing
      blur:
        target: pristine

  invalid:
    entry:
      animation:
        property: borderColor
        to: "#F44336"
        duration: 200
    on:
      input:
        target: debouncing
      blur:
        target: pristine

properties:
  - borderColor: Color
```

**Implementation with auto-validation:**

```dart
class ValidatedTextField extends StatefulWidget {
  final Future<bool> Function(String) validator;

  @override
  State<ValidatedTextField> createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  late FieldValidationMachine _machine;
  final _controller = TextEditingController();
  String _currentValue = '';

  @override
  void initState() {
    super.initState();
    _machine = FieldValidationMachine(properties: props);

    // Auto-validate when entering validating state
    _machine.changes.listen((change) async {
      if (change.to == FieldValidationState.validating) {
        final isValid = await widget.validator(_currentValue);
        _machine.send(
          isValid
            ? FieldValidationEvent.validateSuccess
            : FieldValidationEvent.validateFailure
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        _currentValue = value;
        _machine.send(FieldValidationEvent.input);
      },
      onTap: () => _machine.send(FieldValidationEvent.focus),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: props.borderColor.value),
        ),
        suffixIcon: _buildIcon(),
      ),
    );
  }

  Widget? _buildIcon() {
    return switch (_machine.currentState.value) {
      FieldValidationState.validating => CircularProgressIndicator(),
      FieldValidationState.valid => Icon(Icons.check, color: Colors.green),
      FieldValidationState.invalid => Icon(Icons.error, color: Colors.red),
      _ => null,
    };
  }
}
```

### Pattern 3: Multi-Step Process with Rollback

**Problem:** Implement a wizard with the ability to go back and forward.

```yaml
name: WizardMachine
states: [welcome, personal_info, address, payment, confirm, submitting, complete, error]
events: [next, previous, submit, retry, restart]
initial: welcome

config:
  welcome:
    on:
      next:
        target: personal_info

  personal_info:
    on:
      next:
        target: address
        guard: isPersonalInfoValid
      previous:
        target: welcome

  address:
    on:
      next:
        target: payment
        guard: isAddressValid
      previous:
        target: personal_info

  payment:
    on:
      next:
        target: confirm
        guard: isPaymentValid
      previous:
        target: address

  confirm:
    on:
      submit:
        target: submitting
      previous:
        target: payment

  submitting:
    entry:
      animation:
        property: opacity
        to: 0.5
        duration: 200
    on:
      submit_success:
        target: complete
      submit_error:
        target: error

  complete:
    entry:
      animation:
        property: scale
        to: 1.2
        duration: 500
        easing: easeOutBack
    on:
      restart:
        target: welcome

  error:
    on:
      retry:
        target: submitting
      previous:
        target: confirm

properties:
  - opacity: double
  - scale: double

guards:
  - isPersonalInfoValid
  - isAddressValid
  - isPaymentValid
```

### Pattern 4: Gesture-Driven Interactions

**Problem:** Track drag-and-drop with hover, drag, and drop states.

```yaml
name: DraggableMachine
states: [idle, hovered, dragging, dropping, dropped, canceled]
events: [hover, unhover, drag_start, drag_update, drag_end, drop_success, drop_failure, reset]
initial: idle

config:
  idle:
    on:
      hover:
        target: hovered
        animation:
          property: elevation
          to: 4
          duration: 150

  hovered:
    on:
      unhover:
        target: idle
        animation:
          property: elevation
          to: 0
          duration: 150
      drag_start:
        target: dragging

  dragging:
    entry:
      animation:
        property: scale
        to: 1.1
        duration: 200
        easing: easeOut
    on:
      drag_update:
        target: dragging
        action: updatePosition
      drag_end:
        target: dropping

  dropping:
    # Brief transient state while checking drop target
    after:
      duration: 100
      condition: hasValidDropTarget
      target: dropped
    on:
      drop_failure:
        target: canceled

  dropped:
    entry:
      animation:
        property: scale
        to: 1.0
        duration: 300
        easing: easeOutBack
    after:
      duration: 1000
      target: idle

  canceled:
    entry:
      animation:
        property: position
        to: originalPosition
        duration: 400
        easing: easeOutCubic
    after:
      duration: 500
      target: idle

properties:
  - scale: double
  - elevation: double
  - position: Offset

actions:
  - updatePosition
```

---

## Real-World Examples

### Example 1: Async Button with Success/Error Feedback

**Full implementation:**

```dart
// async_button.kito.yaml
name: AsyncButtonMachine
states: [idle, hovered, pressed, executing, success, error]
events: [hover, unhover, press, execute_success, execute_error, reset]
initial: idle

config:
  idle:
    on:
      hover:
        target: hovered

  hovered:
    entry:
      animation:
        property: scale
        to: 1.05
        duration: 150
    on:
      unhover:
        target: idle
        animation:
          property: scale
          to: 1.0
          duration: 150
      press:
        target: pressed
        guard: isEnabled

  pressed:
    entry:
      animation:
        property: scale
        to: 0.95
        duration: 100
    after:
      duration: 100
      target: executing

  executing:
    entry:
      animation:
        property: rotation
        to: 6.28
        duration: 1000
        loop: infinite
    on:
      execute_success:
        target: success
      execute_error:
        target: error

  success:
    entry:
      animation:
        property: backgroundColor
        to: "#4CAF50"
        duration: 300
    after:
      duration: 2000
      target: idle

  error:
    entry:
      animation:
        property: backgroundColor
        to: "#F44336"
        duration: 300
    on:
      reset:
        target: idle
    after:
      duration: 3000
      target: idle

properties:
  - scale: double
  - rotation: double
  - backgroundColor: Color

guards:
  - isEnabled
```

**Widget implementation:**

```dart
class AsyncButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;
  final bool enabled;

  const AsyncButton({
    required this.onPressed,
    required this.text,
    this.enabled = true,
  });

  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  late AsyncButtonMachine _machine;
  late AnimatedWidgetProperties _props;

  @override
  void initState() {
    super.initState();

    _props = AnimatedWidgetProperties(
      scale: 1.0,
      rotation: 0.0,
      backgroundColor: Colors.blue,
    );

    _machine = AsyncButtonMachineImpl(
      properties: _props,
      isEnabled: () => widget.enabled,
    );

    _machine.changes.listen((change) {
      setState(() {});

      if (change.to == AsyncButtonState.executing) {
        _executeAction();
      }
    });
  }

  Future<void> _executeAction() async {
    try {
      await widget.onPressed();
      _machine.send(AsyncButtonEvent.executeSuccess);
    } catch (e) {
      _machine.send(AsyncButtonEvent.executeError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _machine.send(AsyncButtonEvent.hover),
      onExit: (_) => _machine.send(AsyncButtonEvent.unhover),
      child: GestureDetector(
        onTap: widget.enabled
          ? () => _machine.send(AsyncButtonEvent.press)
          : null,
        child: KitoAnimatedWidget(
          properties: _props,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _props.backgroundColor.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_machine.currentState.value == AsyncButtonState.executing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                if (_machine.currentState.value == AsyncButtonState.executing)
                  SizedBox(width: 8),
                Text(
                  _getButtonText(),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_machine.currentState.value == AsyncButtonState.success)
                  SizedBox(width: 8),
                if (_machine.currentState.value == AsyncButtonState.success)
                  Icon(Icons.check, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    return switch (_machine.currentState.value) {
      AsyncButtonState.executing => 'Processing...',
      AsyncButtonState.success => 'Success!',
      AsyncButtonState.error => 'Error',
      _ => widget.text,
    };
  }

  @override
  void dispose() {
    _machine.dispose();
    super.dispose();
  }
}
```

**Usage:**

```dart
AsyncButton(
  text: 'Submit',
  onPressed: () async {
    await Future.delayed(Duration(seconds: 2));
    // throw Exception('Test error');
  },
)
```

### Example 2: Temporal Integration for Onboarding Flow

**Scenario:** Multi-step onboarding coordinated by Reflow across multiple screens.

```yaml
# onboarding.kito.yaml
name: OnboardingMachine
states: [intro, account_setup, preferences, tutorial, complete]
events: [start, next, skip, complete_step, restart]
initial: intro

temporal:
  enabled: true
  id: onboarding_flow
  export_metrics: true

config:
  intro:
    entry:
      animation:
        property: opacity
        from: 0
        to: 1
        duration: 500
    on:
      start:
        target: account_setup

  account_setup:
    on:
      next:
        target: preferences
        guard: accountIsValid
      skip:
        target: complete

  preferences:
    on:
      next:
        target: tutorial
      skip:
        target: complete

  tutorial:
    on:
      complete_step:
        target: complete

  complete:
    entry:
      animation:
        property: scale
        to: 1.2
        duration: 600
        easing: easeOutBack

guards:
  - accountIsValid

properties:
  - opacity: double
  - scale: double
```

**Reflow workflow coordinating onboarding:**

```yaml
# reflow workflow
workflow: UserOnboarding
actors:
  - id: onboarding_flow
    type: kito_state_machine
    runtime: dart

  - id: analytics_tracker
    type: logger
    runtime: rust

  - id: backend_sync
    type: http_client
    runtime: rust

flow:
  # Track each step completion
  - onboarding_flow.account_setup → analytics_tracker.log("account_setup_viewed")
  - onboarding_flow.preferences → analytics_tracker.log("preferences_viewed")

  # Sync to backend when complete
  - onboarding_flow.complete → backend_sync.post("/users/onboarding-complete")

  # If user skips, still track it
  - onboarding_flow.skip → analytics_tracker.log("onboarding_skipped")
```

**Flutter implementation:**

```dart
class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late OnboardingTemporal _temporal;
  late ZIPConnection _connection;

  @override
  void initState() {
    super.initState();

    // Connect to Reflow for orchestration
    _connection = ZIPConnection(url: 'ws://localhost:9000/zip');
    _connection.connect();

    final machine = OnboardingMachine(properties: props);

    _temporal = OnboardingTemporal(
      id: 'onboarding_flow',
      machine: machine,
      connection: _connection,
    );

    // UI updates
    machine.changes.listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final state = _temporal.machine.currentState.value;

    return switch (state) {
      OnboardingState.intro => IntroScreen(
          onStart: () => _temporal.machine.send(OnboardingEvent.start),
        ),
      OnboardingState.accountSetup => AccountSetupScreen(
          onNext: () => _temporal.machine.send(OnboardingEvent.next),
          onSkip: () => _temporal.machine.send(OnboardingEvent.skip),
        ),
      OnboardingState.preferences => PreferencesScreen(
          onNext: () => _temporal.machine.send(OnboardingEvent.next),
          onSkip: () => _temporal.machine.send(OnboardingEvent.skip),
        ),
      OnboardingState.tutorial => TutorialScreen(
          onComplete: () => _temporal.machine.send(OnboardingEvent.completeStep),
        ),
      OnboardingState.complete => CompleteScreen(),
    };
  }

  @override
  void dispose() {
    _temporal.dispose();
    _connection.disconnect();
    super.dispose();
  }
}
```

---

## Best Practices

### 1. Keep State Machines Focused

**Good:** Single responsibility per machine
```yaml
# button_interaction.kito.yaml - handles ONLY button states
states: [idle, hovered, pressed, disabled]

# form_validation.kito.yaml - handles ONLY validation
states: [pristine, validating, valid, invalid]
```

**Bad:** Kitchen sink machine
```yaml
# everything.kito.yaml - too many responsibilities
states: [idle, loading, error, form_valid, form_invalid, button_hovered, ...]
```

### 2. Use Computed Values for Derived State

```dart
// Instead of managing separate flags
bool get isButtonEnabled {
  final state = machine.currentState.value;
  return state != ButtonState.loading && state != ButtonState.disabled;
}

// Use Kito's computed
final isButtonEnabled = computed(() {
  final state = machine.currentState.value;
  return state != ButtonState.loading && state != ButtonState.disabled;
});
```

### 3. Guard Functions Should Be Pure

**Good:**
```dart
bool isFormValid() => _emailValid && _passwordValid && _termsAccepted;
```

**Bad:**
```dart
bool isFormValid() {
  _logValidationAttempt(); // Side effect!
  return _emailValid && _passwordValid;
}
```

### 4. Use Actions for Side Effects

```yaml
config:
  loading:
    on:
      submit:
        target: success
        action: saveToDatabase  # ✅ Side effect in action
```

### 5. Transient States for Animations

Use transient states when you want an animation to complete before continuing:

```yaml
config:
  pressed:
    entry:
      animation:
        property: scale
        to: 0.95
        duration: 150
    after:
      duration: 150  # Match animation duration
      target: released
```

### 6. Hot Reload Friendly

```dart
// Create state machine in initState
@override
void initState() {
  super.initState();
  _machine = ButtonStateMachine(/*...*/);
}

// NOT in build() - will recreate on every rebuild
```

### 7. Dispose Properly

```dart
@override
void dispose() {
  _machine.dispose();  // Cleans up timers, animations, streams
  super.dispose();
}
```

---

## Troubleshooting

### Issue: State machine not transitioning

**Check:**
1. Is the event defined in the current state's `on` map?
2. Is there a guard blocking the transition?
3. Is the machine disposed?

**Debug:**
```dart
_machine.changes.listen((change) {
  print('Transition: ${change.from} → ${change.to} via ${change.event}');
});

// Check guards
print('Guard result: ${_machine.evaluateGuard(guardName)}');
```

### Issue: Animations not playing

**Check:**
1. Are properties properly wired to `AnimatedWidgetProperties`?
2. Is `KitoAnimatedWidget` wrapping your widget?
3. Is the animation configuration correct in YAML?

**Debug:**
```dart
_machine.currentAnimation?.onUpdate((progress) {
  print('Animation progress: $progress');
});
```

### Issue: Temporal not connecting to Reflow

**Check:**
1. Is Reflow running on the expected URL?
2. Is WebSocket connection established?
3. Is actor registered?

**Debug:**
```dart
_connection.messages.listen((msg) {
  print('Received ZIP message: ${msg.type}');
});

// Verify connection
await _connection.connect();
print('Connected: ${_connection.isConnected}');
```

### Issue: Build runner not generating code

**Check:**
1. Is `.kito.yaml` in the correct location?
2. Is `kito_codegen` in `dev_dependencies`?
3. Is `build.yaml` configured?

**Debug:**
```bash
# Verbose output
flutter pub run build_runner build --verbose --delete-conflicting-outputs

# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build
```

---

## Advanced Patterns

### Pattern: State Machine Composition

Coordinate multiple state machines:

```dart
class CheckoutFlow extends StatefulWidget {
  @override
  State<CheckoutFlow> createState() => _CheckoutFlowState();
}

class _CheckoutFlowState extends State<CheckoutFlow> {
  late PaymentMachine _paymentMachine;
  late ShippingMachine _shippingMachine;
  late OrderMachine _orderMachine;

  @override
  void initState() {
    super.initState();

    _paymentMachine = PaymentMachine(/*...*/);
    _shippingMachine = ShippingMachine(/*...*/);
    _orderMachine = OrderMachine(/*...*/);

    // Coordinate between machines
    _paymentMachine.changes.listen((change) {
      if (change.to == PaymentState.validated) {
        _shippingMachine.send(ShippingEvent.enableNext);
      }
    });

    _shippingMachine.changes.listen((change) {
      if (change.to == ShippingState.confirmed) {
        _orderMachine.send(OrderEvent.placeOrder);
      }
    });
  }

  // Or use Reflow/Temporal for complex coordination
}
```

### Pattern: Testing State Machines

```dart
void main() {
  group('ButtonStateMachine', () {
    late ButtonStateMachine machine;

    setUp(() {
      machine = ButtonStateMachine(properties: testProps);
    });

    tearDown(() {
      machine.dispose();
    });

    test('transitions from idle to hovered on hover event', () {
      expect(machine.currentState.value, ButtonState.idle);

      machine.send(ButtonEvent.hover);

      expect(machine.currentState.value, ButtonState.hovered);
    });

    test('respects guards', () {
      machine.send(ButtonEvent.tap);

      // Should not transition if guard fails
      expect(machine.currentState.value, ButtonState.idle);
    });

    test('emits state change events', () async {
      final changes = <StateChange>[];
      machine.changes.listen(changes.add);

      machine.send(ButtonEvent.hover);
      machine.send(ButtonEvent.tap);

      await Future.delayed(Duration(milliseconds: 10));

      expect(changes.length, 2);
      expect(changes[0].to, ButtonState.hovered);
      expect(changes[1].to, ButtonState.pressed);
    });
  });
}
```

---

## Resources

- [State Machine Architecture](./STATE_MACHINE_ARCHITECTURE.md)
- [Temporal Integration Guide](./TEMPORAL_GUIDE.md)
- [Kito Animation Docs](./ANIMATION_GUIDE.md)
- [API Reference](./API_REFERENCE.md)

---

**Last Updated:** 2025-11-08

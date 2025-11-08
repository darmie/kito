# Kito State Machine Architecture & Implementation Specification

**Version:** 1.1
**Status:** Draft
**Last Updated:** 2025-11-08
**Update:** Added context-based guards and actions (v1.1)

---

## Executive Summary

This document specifies the architecture and implementation for **Kito State Machines**, a declarative, type-safe finite state machine library designed specifically for managing complex UI interaction states in Flutter applications. The library integrates seamlessly with Kito's reactive animation system and introduces **Temporals**—proxy actors that enable state machines to participate in larger distributed workflows via the ZIP (Zeal Integration Protocol).

**Key Features:**
- Type-safe state machines with compile-time validation
- Seamless integration with Kito's reactive animation engine
- YAML-based DSL with code generation to typed Dart
- Transient states with automatic transitions
- Guarded transitions with custom predicates
- Observable state changes via Kito's reactive primitives
- **Temporals**: ZIP-compatible proxy actors for workflow orchestration
- Time-travel debugging and execution replay
- Hot-reload support

---

## Table of Contents

1. [Overview & Goals](#overview--goals)
2. [Core Concepts](#core-concepts)
3. [Architecture](#architecture)
4. [Temporals: Proxy Architecture](#temporals-proxy-architecture)
5. [DSL Design](#dsl-design)
6. [API Design](#api-design)
7. [Code Generation](#code-generation)
8. [Implementation Phases](#implementation-phases)
9. [Examples](#examples)
10. [Performance Considerations](#performance-considerations)
11. [Future Work](#future-work)

---

## Overview & Goals

### Problem Statement

Modern UI interactions often involve complex state management:
- Button states: idle → hover → pressed → loading → success/error
- Form validation: pristine → touched → validating → valid/invalid
- Drag interactions: idle → drag-start → dragging → drag-end → dropped
- Multi-step wizards with conditional navigation

Currently, developers manage these with manual `if/else` chains, boolean flags, and imperative state updates, leading to:
- **State explosion**: Hard to reason about all possible states
- **Invalid states**: `isLoading && isError` shouldn't both be true
- **Animation coordination**: Manual management of animations per state
- **Testing complexity**: Difficult to validate all state transitions

### Goals

1. **Declarative State Management**: Define states and transitions, not implementation
2. **Type Safety**: Impossible states should be impossible to represent
3. **Animation Integration**: Automatic animation triggering on state changes
4. **Reactivity**: Leverage Kito's Signal/Computed/Effect primitives
5. **Developer Experience**: Clear errors, auto-complete, hot-reload
6. **Observability**: Built-in tracing, replay, and debugging
7. **Orchestration**: Participate in larger workflows via Temporals

### Non-Goals (for v1)

- ❌ Hierarchical state machines (defer to v2)
- ❌ Parallel states (defer to v2)
- ❌ Visual editor (future work, already scoped)
- ❌ Undo/redo (can be built on top)

---

## Core Concepts

### State Machine Fundamentals

A **finite state machine (FSM)** consists of:

- **States**: A finite set of distinct conditions (e.g., `idle`, `loading`, `success`)
- **Events**: Triggers that cause state changes (e.g., `submit`, `retry`, `cancel`)
- **Transitions**: Rules defining how events move between states
- **Initial State**: The starting state
- **Context**: Typed state container accessible to guards and actions
- **Guards**: Pure static functions that conditionally allow/block transitions
- **Actions**: Pure static functions that transform context (or side effects on entry/exit)

### Kito-Specific Concepts

#### **Transient States**
States that automatically transition after a condition (time/animation completion):
```yaml
state: loading
after:
  duration: 2000
  target: success
```

#### **Animated Transitions**
Transitions can trigger Kito animations:
```yaml
transition:
  from: idle
  to: pressed
  animation:
    property: scale
    to: 0.95
    duration: 100
```

#### **Reactive State**
State machines expose reactive primitives:
```dart
final machine = ButtonStateMachine();
final isLoading = computed(() => machine.currentState.value == ButtonState.loading);
```

#### **Context-Based Guards and Actions**

State machines use **generic context types** to provide type-safe access to business logic:

```dart
// Define context type
class ButtonContext {
  final bool enabled;
  final int clickCount;

  const ButtonContext({this.enabled = true, this.clickCount = 0});

  ButtonContext copyWith({bool? enabled, int? clickCount}) {
    return ButtonContext(
      enabled: enabled ?? this.enabled,
      clickCount: clickCount ?? this.clickCount,
    );
  }
}

// Guards are pure static functions
class ButtonGuards {
  static bool canTap(ButtonContext ctx) => ctx.enabled && ctx.clickCount < 10;
}

// Actions transform context
class ButtonActions {
  static ButtonContext incrementClick(ButtonContext ctx) {
    return ctx.copyWith(clickCount: ctx.clickCount + 1);
  }
}

// State machine with generic context
class ButtonStateMachine extends KitoStateMachine<
  ButtonState,   // State enum
  ButtonEvent,   // Event enum
  ButtonContext  // Context type
> {
  ButtonStateMachine({
    required ButtonContext context,
    required AnimatedWidgetProperties properties,
  }) : super(initial: ButtonState.idle, context: context, properties: properties);
}
```

**Benefits:**
- ✅ Pure, testable functions
- ✅ Type-safe context access
- ✅ No inheritance required
- ✅ Composable and reusable

See [CONTEXT_BASED_GUARDS.md](./CONTEXT_BASED_GUARDS.md) for detailed documentation.

### Temporals

**Temporals** are proxy actors that bridge Kito state machines with Reflow workflows via ZIP protocol. They:
- Expose state machine state to Reflow for orchestration
- Accept external events from Reflow
- Report transitions for tracing and analytics
- Enable distributed state machine coordination

Think of Temporals as "ambassadors" representing Kito state machines in the larger workflow ecosystem.

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Define State Machine (YAML DSL)                        │
│     button.kito.yaml                                        │
│          │                                                  │
│          ▼                                                  │
│  2. Code Generation (build_runner)                         │
│     → button_state_machine.g.dart                          │
│          │                                                  │
│          ▼                                                  │
│  3. Use in Flutter App                                     │
│     final machine = ButtonStateMachine(...)                │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     Runtime Architecture                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────┐          │
│  │         Application Code                     │          │
│  │  machine.send(ButtonEvent.tap)               │          │
│  └────────────────┬─────────────────────────────┘          │
│                   │                                         │
│                   ▼                                         │
│  ┌──────────────────────────────────────────────┐          │
│  │      KitoStateMachine<S, E>                  │          │
│  │  - currentState: Signal<S>                   │          │
│  │  - send(event: E)                            │          │
│  │  - transition logic                          │          │
│  │  - guard evaluation                          │          │
│  └────┬────────────────────────────────┬────────┘          │
│       │                                 │                   │
│       │ triggers                        │ notifies          │
│       ▼                                 ▼                   │
│  ┌──────────────┐              ┌──────────────┐            │
│  │  Kito        │              │  Temporal    │            │
│  │  Animation   │              │  (Proxy)     │            │
│  │  Engine      │              └──────┬───────┘            │
│  └──────────────┘                     │                    │
│                                       │ ZIP Protocol        │
│                                       ▼                    │
│                              ┌──────────────┐              │
│                              │   Reflow     │              │
│                              │  (Optional)  │              │
│                              └──────────────┘              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. **State Machine Runtime**

**Location:** `packages/kito_fsm/lib/src/runtime/`

**Responsibilities:**
- Execute state transitions based on events
- Evaluate guards before transitions
- Trigger entry/exit actions
- Manage transient state timers
- Integrate with Kito animations
- Emit observable state changes

**Key Classes:**

```dart
/// Base state machine runtime with generic context
abstract class KitoStateMachine<S extends Enum, E extends Enum, C> {
  /// Current state (reactive)
  Signal<S> get currentState;

  /// Current context (mutable or immutable depending on implementation)
  C get context;

  /// Update context (for mutable contexts or signal-based contexts)
  void updateContext(C newContext);

  /// Send an event to the state machine
  void send(E event);

  /// Transition history for debugging
  List<StateTransition<S, E>> get history;

  /// Stream of state changes
  Stream<StateChange<S, E>> get changes;

  /// Dispose resources
  void dispose();
}

/// Configuration for a state
class StateConfig<S, E, C> {
  final S state;
  final Map<E, TransitionConfig<S, E, C>> transitions;
  final void Function(C context, S from, S to)? onEntry;
  final void Function(C context, S from, S to)? onExit;
  final KitoAnimation Function()? entryAnimation;
  final KitoAnimation Function()? exitAnimation;
  final TransientConfig<S, C>? transient;
}

/// Configuration for a transition
class TransitionConfig<S, E, C> {
  final S target;
  final bool Function(C context)? guard;  // Context-based guard
  final C Function(C context)? action;     // Context transformation
  final KitoAnimation Function()? animation;
}

/// Transient state configuration
class TransientConfig<S, C> {
  final Duration? after;
  final S target;
  final bool Function(C context)? condition;  // Context-based condition
  final C Function(C context)? action;         // Context transformation on transition
}

/// State change event
class StateChange<S, E> {
  final S from;
  final S to;
  final E? event;
  final DateTime timestamp;
  final Duration? transitionDuration;
}
```

#### 2. **Animation Integration Layer**

**Location:** `packages/kito_fsm/lib/src/animation/`

**Responsibilities:**
- Coordinate animations with state transitions
- Support sequential and concurrent animations
- Handle animation interruption on rapid state changes
- Provide animation completion callbacks

**Key Classes:**

```dart
/// Manages animations for state machine transitions
class StateMachineAnimationController {
  final Map<String, KitoAnimation> _activeAnimations = {};

  Future<void> playTransitionAnimation(
    KitoAnimation animation, {
    bool interruptible = true,
  }) async {
    // Implementation
  }

  void cancelAll() {
    // Implementation
  }
}

/// Builder for creating animations tied to states
class StateAnimationBuilder {
  StateAnimationBuilder onEntry(S state, KitoAnimation Function() builder);
  StateAnimationBuilder onExit(S state, KitoAnimation Function() builder);
  StateAnimationBuilder onTransition(S from, S to, KitoAnimation Function() builder);
}
```

#### 3. **Code Generator**

**Location:** `packages/kito_codegen/`

**Responsibilities:**
- Parse YAML DSL files
- Validate state machine definitions
- Generate type-safe Dart code
- Create enum definitions for states and events
- Generate state machine classes

**Pipeline:**

```
.kito.yaml
    ↓ (parse)
AST representation
    ↓ (validate)
Validated AST
    ↓ (codegen)
.g.dart file
```

---

## Temporals: Proxy Architecture

### Overview

**Temporals** are the bridge between Kito state machines and the Reflow workflow engine. They implement the ZIP (Zeal Integration Protocol) actor interface while wrapping a Kito state machine.

### Design Principles

1. **Non-Invasive**: State machines work standalone; Temporal is optional
2. **Async Communication**: ZIP messages don't block state transitions
3. **Bidirectional**: Temporals both report to and receive from Reflow
4. **Observable**: Full state machine telemetry exposed
5. **Hot-Pluggable**: Connect/disconnect at runtime

### Architecture

```
┌────────────────────────────────────────────────────────────┐
│                      Temporal                              │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────┐      ┌──────────────────────┐  │
│  │   ZIP Interface      │      │  State Machine       │  │
│  │   (Actor API)        │      │  Wrapper             │  │
│  │                      │      │                      │  │
│  │  - handleMessage()   │◄────►│  - machine ref       │  │
│  │  - getState()        │      │  - event mapping     │  │
│  │  - getMetadata()     │      │  - state mapping     │  │
│  └──────────────────────┘      └──────────────────────┘  │
│           ▲                              │                │
│           │                              ▼                │
│           │                   ┌──────────────────────┐   │
│           │                   │ KitoStateMachine<S,E>│   │
│           │                   │                      │   │
│           │                   │  - currentState      │   │
│           │                   │  - send()            │   │
│           │                   │  - history           │   │
│           │                   └──────────────────────┘   │
│           │                                              │
│           ▼                                              │
│  ┌──────────────────────┐                               │
│  │  ZIP Connection      │                               │
│  │  (WebSocket/IPC)     │                               │
│  └──────────────────────┘                               │
│           │                                              │
└───────────┼──────────────────────────────────────────────┘
            │
            ▼
     ┌──────────────┐
     │   Reflow     │
     │   Engine     │
     └──────────────┘
```

### ZIP Message Types

#### **Outbound (Temporal → Reflow)**

```dart
/// State transition notification
class TransitionMessage extends ZIPMessage {
  final String actorId;
  final String fromState;
  final String toState;
  final String? event;
  final DateTime timestamp;
}

/// State snapshot (for queries)
class SnapshotMessage extends ZIPMessage {
  final String actorId;
  final String currentState;
  final Map<String, dynamic> metadata;
  final List<String> stateHistory;
}

/// Telemetry data
class TelemetryMessage extends ZIPMessage {
  final String actorId;
  final int transitionCount;
  final Map<String, int> stateVisitCounts;
  final Map<String, Duration> stateResidenceTimes;
}
```

#### **Inbound (Reflow → Temporal)**

```dart
/// Trigger an event
class TriggerEventMessage extends ZIPMessage {
  final String event;
  final Map<String, dynamic>? context;
}

/// Query current state
class GetStateMessage extends ZIPMessage {
  final bool includeHistory;
  final bool includeMetrics;
}

/// Force state (for debugging/testing)
class ForceStateMessage extends ZIPMessage {
  final String state;
  final String reason;
}

/// Replay transition sequence
class ReplayMessage extends ZIPMessage {
  final List<String> events;
  final Duration? delayBetween;
}
```

### Temporal Implementation

**Location:** `packages/kito_temporal/`

```dart
/// Base class for all Temporals
abstract class Temporal<S extends Enum, E extends Enum> implements ZIPActor {
  final String id;
  final KitoStateMachine<S, E> machine;
  final ZIPConnection? connection;

  StreamSubscription? _stateSubscription;

  Temporal({
    required this.id,
    required this.machine,
    this.connection,
  }) {
    if (connection != null) {
      _attachToReflow();
    }
  }

  /// Attach to Reflow and start reporting
  void _attachToReflow() {
    // Listen to state machine changes
    _stateSubscription = machine.changes.listen((change) {
      connection!.send(TransitionMessage(
        actorId: id,
        fromState: change.from.name,
        toState: change.to.name,
        event: change.event?.name,
        timestamp: change.timestamp,
      ));
    });

    // Listen to Reflow messages
    connection!.messages
      .where((msg) => msg.targetActor == id)
      .listen(_handleReflowMessage);
  }

  /// Handle messages from Reflow
  void _handleReflowMessage(ZIPMessage message) {
    switch (message.type) {
      case 'TRIGGER_EVENT':
        final event = _parseEvent((message as TriggerEventMessage).event);
        machine.send(event);
        break;

      case 'GET_STATE':
        connection!.send(SnapshotMessage(
          actorId: id,
          currentState: machine.currentState.value.name,
          metadata: getMetadata(),
          stateHistory: machine.history.map((t) => t.to.name).toList(),
        ));
        break;

      case 'FORCE_STATE':
        final state = _parseState((message as ForceStateMessage).state);
        machine.forceState(state, reason: message.reason);
        break;

      case 'REPLAY':
        final msg = message as ReplayMessage;
        _replayEvents(msg.events, delayBetween: msg.delayBetween);
        break;
    }
  }

  /// Parse event from string (generated per machine)
  E _parseEvent(String event);

  /// Parse state from string (generated per machine)
  S _parseState(String state);

  /// Get metadata for this temporal
  Map<String, dynamic> getMetadata() {
    return {
      'id': id,
      'type': runtimeType.toString(),
      'currentState': machine.currentState.value.name,
      'transitionCount': machine.history.length,
      'uptime': DateTime.now().difference(machine.createdAt).inMilliseconds,
    };
  }

  /// Replay a sequence of events
  Future<void> _replayEvents(
    List<String> events, {
    Duration? delayBetween,
  }) async {
    for (final eventStr in events) {
      machine.send(_parseEvent(eventStr));
      if (delayBetween != null) {
        await Future.delayed(delayBetween);
      }
    }
  }

  /// Detach from Reflow
  void detach() {
    _stateSubscription?.cancel();
  }

  @override
  void dispose() {
    detach();
    machine.dispose();
  }
}
```

### ZIP Connection

**Location:** `packages/kito_temporal/lib/src/zip/`

```dart
/// WebSocket-based ZIP connection
class ZIPConnection {
  final String url;
  WebSocket? _socket;

  final StreamController<ZIPMessage> _messageController =
    StreamController.broadcast();

  Stream<ZIPMessage> get messages => _messageController.stream;

  Future<void> connect() async {
    _socket = await WebSocket.connect(url);
    _socket!.listen((data) {
      final message = ZIPMessage.fromJson(jsonDecode(data));
      _messageController.add(message);
    });
  }

  void send(ZIPMessage message) {
    if (_socket == null) {
      throw StateError('Not connected to Reflow');
    }
    _socket!.add(jsonEncode(message.toJson()));
  }

  Future<void> disconnect() async {
    await _socket?.close();
    await _messageController.close();
  }

  /// Register an actor with Reflow
  Future<void> registerActor(String actorId, Map<String, dynamic> metadata) async {
    send(RegisterActorMessage(
      actorId: actorId,
      actorType: 'kito_state_machine',
      metadata: metadata,
    ));
  }
}
```

### Usage Example

```dart
// Create state machine
final buttonMachine = ButtonStateMachine(
  properties: buttonProps,
  isEnabled: () => !isProcessing,
);

// Wrap in Temporal (optional)
final temporal = ButtonTemporal(
  id: 'login_button',
  machine: buttonMachine,
  connection: reflowConnection,
);

// Use normally in Flutter
ElevatedButton(
  onPressed: () => buttonMachine.send(ButtonEvent.tap),
  child: Text('Login'),
);

// Reflow can now orchestrate this button
// E.g., "When auth succeeds, trigger login_button.reset"
```

---

## DSL Design

### YAML Structure

```yaml
# Metadata
name: ButtonStateMachine
description: "Manages button interaction states with animations"
version: 1.0.0

# Context type (must be a valid Dart class)
context: ButtonContext

# Type definitions
states:
  - idle
  - hovered
  - pressed
  - loading
  - success
  - error

events:
  - hover
  - unhover
  - tap
  - submit_success
  - submit_error
  - reset

# Initial state
initial: idle

# State configurations
config:
  idle:
    on:
      hover:
        target: hovered
        animation:
          property: scale
          to: 1.05
          duration: 200
          easing: easeOut

  hovered:
    on:
      unhover:
        target: idle
        animation:
          property: scale
          to: 1.0
          duration: 150

      tap:
        target: pressed
        guard: ButtonGuards.isEnabled

  pressed:
    # Transient state
    entry:
      animation:
        property: scale
        to: 0.95
        duration: 100

    after:
      duration: 100
      target: loading

  loading:
    entry:
      animation:
        property: rotation
        to: 6.28
        duration: 1000
        loop: infinite

    on:
      submit_success:
        target: success
      submit_error:
        target: error

  success:
    entry:
      animation:
        property: color
        to: "#4CAF50"
        duration: 300

    after:
      duration: 2000
      target: idle

  error:
    entry:
      animation:
        property: color
        to: "#F44336"
        duration: 300

    on:
      reset:
        target: idle

# Animation properties required
properties:
  - scale: double
  - rotation: double
  - color: Color

# Guards (fully qualified static function names)
guards:
  - ButtonGuards.isEnabled
  - ButtonGuards.canSubmit

# Actions (fully qualified static function names)
actions:
  - ButtonActions.incrementClick
  - ButtonActions.resetState

# Temporal configuration (optional)
temporal:
  enabled: true
  id: button_interaction
  export_metrics: true
```

### DSL Validation Rules

1. **Context type must be specified** and must be a valid Dart class name
2. **All referenced states must be defined** in `states` list
3. **All referenced events must be defined** in `events` list
4. **Initial state must exist** in `states` list
5. **Transient states must have `after`** configuration
6. **Guards must be declared** in `guards` list with fully qualified names (e.g., `ClassName.functionName`)
7. **Actions must be declared** in `actions` list with fully qualified names
8. **Guard signatures must match** `bool Function(ContextType)` when generated
9. **Action signatures must match** `ContextType Function(ContextType)` for pure actions
10. **Animation properties must be declared** in `properties` list
11. **No unreachable states** (warning, not error)
12. **No ambiguous transitions** (multiple transitions for same event in one state)

---

## API Design

### Generated Code Structure

For `button.kito.yaml`, generates `button_state_machine.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from: button.kito.yaml
// Generator version: 1.0.0

part of 'button.kito.dart';

/// States for ButtonStateMachine
enum ButtonState {
  idle,
  hovered,
  pressed,
  loading,
  success,
  error,
}

/// Events for ButtonStateMachine
enum ButtonEvent {
  hover,
  unhover,
  tap,
  submitSuccess,
  submitError,
  reset,
}

/// Generated state machine implementation with context
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
    config: _buildConfig(properties),
  );

  static StateMachineConfig<ButtonState, ButtonEvent, ButtonContext> _buildConfig(
    AnimatedWidgetProperties properties,
  ) {
    return StateMachineConfig(
      states: {
        ButtonState.idle: StateConfig(
          state: ButtonState.idle,
          transitions: {
            ButtonEvent.hover: TransitionConfig(
              target: ButtonState.hovered,
              guard: ButtonGuards.isEnabled,  // Static function reference
              animation: () => animate()
                .to(properties.scale, 1.05)
                .withDuration(200)
                .withEasing(Easing.easeOut)
                .build(),
            ),
          },
        ),
        ButtonState.hovered: StateConfig(
          transitions: {
            ButtonEvent.tap: TransitionConfig(
              target: ButtonState.pressed,
              guard: ButtonGuards.canSubmit,
              action: ButtonActions.incrementClick,  // Context transformation
            ),
          },
        ),
        // ... more states
      },
    );
  }
}

/// Generated Temporal wrapper
class ButtonTemporal extends Temporal<ButtonState, ButtonEvent, ButtonContext> {
  ButtonTemporal({
    required String id,
    required ButtonStateMachine machine,
    ZIPConnection? connection,
  }) : super(id: id, machine: machine, connection: connection);

  @override
  ButtonEvent _parseEvent(String event) {
    return ButtonEvent.values.firstWhere(
      (e) => e.name == event,
      orElse: () => throw ArgumentError('Unknown event: $event'),
    );
  }

  @override
  ButtonState _parseState(String state) {
    return ButtonState.values.firstWhere(
      (s) => s.name == state,
      orElse: () => throw ArgumentError('Unknown state: $state'),
    );
  }
}
```

### Usage in Flutter

#### **1. Define Context, Guards, and Actions**

```dart
// button.kito.dart
import 'package:kito/kito.dart';

part 'button_state_machine.g.dart';

/// Context for button state machine
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

/// Guards (pure static functions)
class ButtonGuards {
  static bool isEnabled(ButtonContext ctx) => ctx.enabled;

  static bool canSubmit(ButtonContext ctx) {
    return ctx.enabled && ctx.clickCount < 10 && ctx.errorMessage == null;
  }
}

/// Actions (pure context transformations)
class ButtonActions {
  static ButtonContext incrementClick(ButtonContext ctx) {
    return ctx.copyWith(clickCount: ctx.clickCount + 1);
  }

  static ButtonContext resetState(ButtonContext ctx) {
    return ctx.copyWith(clickCount: 0, errorMessage: null);
  }
}
```

#### **2. Use in Widget**

```dart
import 'package:flutter/material.dart';
import 'button.kito.dart';

class LoginButton extends StatefulWidget {
  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  late ButtonStateMachine _machine;
  late AnimatedWidgetProperties _props;

  @override
  void initState() {
    super.initState();

    _props = AnimatedWidgetProperties(
      scale: 1.0,
      rotation: 0.0,
      color: Colors.blue,
    );

    // Create context and machine
    final initialContext = ButtonContext(enabled: true);
    _machine = ButtonStateMachine(
      context: initialContext,
      properties: _props,
    );

    // Listen to state changes
    _machine.changes.listen((change) {
      setState(() {});  // Update UI

      if (change.to == ButtonState.loading) {
        _submitForm();
      }
    });
  }

  Future<void> _submitForm() async {
    try {
      await api.submitLogin();
      _machine.send(ButtonEvent.submitSuccess);
    } catch (e) {
      // Update context with error
      _machine.updateContext(
        _machine.context.copyWith(errorMessage: e.toString())
      );
      _machine.send(ButtonEvent.submitError);
    }
  }

  @override
  void dispose() {
    _machine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _machine.send(ButtonEvent.hover),
      onExit: (_) => _machine.send(ButtonEvent.unhover),
      child: GestureDetector(
        onTap: () => _machine.send(ButtonEvent.tap),
        child: KitoAnimatedWidget(
          properties: _props,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _props.color.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_getButtonText()),
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (_machine.currentState.value) {
      case ButtonState.loading:
        return 'Loading...';
      case ButtonState.success:
        return 'Success!';
      case ButtonState.error:
        return 'Error - Retry';
      default:
        return 'Login';
    }
  }
}
```

#### **2. With Temporal Integration**

```dart
class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late ZIPConnection _reflowConnection;
  late ButtonTemporal _buttonTemporal;

  @override
  void initState() {
    super.initState();

    // Connect to Reflow
    _reflowConnection = ZIPConnection(
      url: 'ws://localhost:9000/zip',
    );
    _reflowConnection.connect();

    // Create state machine with Temporal
    final machine = ButtonStateMachine(
      properties: buttonProps,
      isEnabled: () => true,
    );

    _buttonTemporal = ButtonTemporal(
      id: 'login_button',
      machine: machine,
      connection: _reflowConnection,
    );

    // Register with Reflow
    _reflowConnection.registerActor(
      'login_button',
      {'type': 'button', 'screen': 'login'},
    );
  }

  @override
  void dispose() {
    _buttonTemporal.dispose();
    _reflowConnection.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... use _buttonTemporal.machine as before
  }
}
```

#### **3. Reactive Computed Values**

```dart
// Derive UI state from state machine
final isInteractive = computed(() {
  final state = machine.currentState.value;
  return state != ButtonState.loading && state != ButtonState.success;
});

final buttonColor = computed(() {
  switch (machine.currentState.value) {
    case ButtonState.error:
      return Colors.red;
    case ButtonState.success:
      return Colors.green;
    default:
      return Colors.blue;
  }
});

// Use in widget
ElevatedButton(
  onPressed: isInteractive.value ? _handleTap : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: buttonColor.value,
  ),
  child: Text('Submit'),
);
```

---

## Code Generation

### Generator Architecture

```
┌────────────────────────────────────────────────┐
│         kito_codegen package                   │
├────────────────────────────────────────────────┤
│                                                │
│  ┌──────────────┐     ┌──────────────────┐    │
│  │  YAML Parser │────►│ AST Builder      │    │
│  └──────────────┘     └────────┬─────────┘    │
│                                 │              │
│                                 ▼              │
│                       ┌──────────────────┐    │
│                       │   Validator      │    │
│                       └────────┬─────────┘    │
│                                 │              │
│                                 ▼              │
│                       ┌──────────────────┐    │
│                       │  Code Generator  │    │
│                       └────────┬─────────┘    │
│                                 │              │
│                                 ▼              │
│                       ┌──────────────────┐    │
│                       │  Dart Formatter  │    │
│                       └────────┬─────────┘    │
│                                 │              │
└─────────────────────────────────┼──────────────┘
                                  │
                                  ▼
                          .g.dart file
```

### Build Integration

**`build.yaml`:**

```yaml
targets:
  $default:
    builders:
      kito_codegen:
        enabled: true

builders:
  kito_codegen:
    import: "package:kito_codegen/builder.dart"
    builder_factories: ["kitoStateMachineBuilder"]
    build_extensions:
      .kito.yaml:
        - .kito.g.dart
    auto_apply: dependents
    build_to: source
```

**Usage:**

```bash
# Generate code
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch
```

### Generated Code Features

1. **Type-safe enums** for states and events
2. **State machine class** with pre-configured transitions
3. **Temporal wrapper** for ZIP integration
4. **Documentation comments** from YAML metadata
5. **Null-safety** enabled
6. **Hot-reload friendly** (no const constructors on state machine)

---

## Implementation Phases

### Phase 1: Core State Machine Runtime (2-3 weeks)

**Deliverables:**
- [ ] `KitoStateMachine<S, E>` base class
- [ ] State/Event/Transition/Config types
- [ ] Transition execution engine
- [ ] Guard evaluation
- [ ] Entry/exit actions
- [ ] State change stream
- [ ] History tracking
- [ ] Unit tests (>90% coverage)

**Package:** `kito_fsm`

### Phase 2: Animation Integration (1-2 weeks)

**Deliverables:**
- [ ] `StateMachineAnimationController`
- [ ] Animation triggering on transitions
- [ ] Entry/exit animation support
- [ ] Animation interruption handling
- [ ] Integration tests with Kito animations

**Package:** `kito_fsm`

### Phase 3: Transient States (1 week)

**Deliverables:**
- [ ] `TransientConfig` implementation
- [ ] Timer-based auto-transitions
- [ ] Condition-based auto-transitions
- [ ] Cleanup on state exit
- [ ] Tests for edge cases

**Package:** `kito_fsm`

### Phase 4: DSL & Code Generator (3-4 weeks)

**Deliverables:**
- [ ] YAML schema definition
- [ ] Parser implementation
- [ ] AST representation
- [ ] Validator with error messages
- [ ] Code generator (enums, classes, Temporals)
- [ ] `build_runner` integration
- [ ] Documentation generation
- [ ] Example `.kito.yaml` files

**Package:** `kito_codegen`

### Phase 5: ZIP Protocol & Temporals (2-3 weeks)

**Deliverables:**
- [ ] ZIP message types
- [ ] `ZIPConnection` implementation (WebSocket)
- [ ] `Temporal<S, E>` base class
- [ ] Message routing
- [ ] Actor registration
- [ ] Telemetry collection
- [ ] Replay functionality
- [ ] Integration tests with mock Reflow

**Package:** `kito_temporal`

### Phase 6: DevTools Integration (2-3 weeks)

**Deliverables:**
- [ ] Flutter DevTools extension
- [ ] State machine visualization
- [ ] Live state monitoring
- [ ] Transition history view
- [ ] Event injection UI
- [ ] State forcing for testing
- [ ] Export state diagrams

**Package:** `kito_devtools_extension`

### Phase 7: Documentation & Examples (1-2 weeks)

**Deliverables:**
- [ ] API documentation
- [ ] Tutorial: Building your first state machine
- [ ] Example: Button interactions
- [ ] Example: Form validation
- [ ] Example: Multi-step wizard
- [ ] Example: Drag-and-drop
- [ ] Example: Temporal integration
- [ ] Migration guide for existing code

**Location:** `kito/docs/`, `kito/examples/`

### Phase 8: Testing & Polish (1-2 weeks)

**Deliverables:**
- [ ] Integration tests across packages
- [ ] Performance benchmarks
- [ ] Hot-reload testing
- [ ] Error message improvements
- [ ] Code coverage >85%
- [ ] Pub.dev preparation
- [ ] Changelog and versioning

---

## Examples

### Example 1: Simple Toggle

**`toggle.kito.yaml`:**

```yaml
name: ToggleStateMachine
states: [off, on]
events: [toggle]
initial: off

config:
  off:
    on:
      toggle:
        target: on
        animation:
          property: position
          to: 1.0
          duration: 200
          easing: easeInOut

  on:
    on:
      toggle:
        target: off
        animation:
          property: position
          to: 0.0
          duration: 200
          easing: easeInOut

properties:
  - position: double
```

### Example 2: Form Validation

**`form.kito.yaml`:**

```yaml
name: FormStateMachine
states: [pristine, touched, validating, valid, invalid, submitting, success, error]
events: [focus, blur, input, validate_success, validate_failure, submit, submit_success, submit_error, reset]
initial: pristine

config:
  pristine:
    on:
      focus:
        target: touched

  touched:
    on:
      input:
        target: validating

  validating:
    entry:
      animation:
        property: opacity
        to: 0.5
        duration: 150
    on:
      validate_success:
        target: valid
      validate_failure:
        target: invalid

  valid:
    entry:
      animation:
        property: borderColor
        to: "#4CAF50"
        duration: 200
    on:
      input:
        target: validating
      submit:
        target: submitting
        guard: canSubmit

  invalid:
    entry:
      animation:
        property: borderColor
        to: "#F44336"
        duration: 200
    on:
      input:
        target: validating

  submitting:
    entry:
      animation:
        property: opacity
        to: 0.7
        duration: 300
    on:
      submit_success:
        target: success
      submit_error:
        target: error

  success:
    after:
      duration: 2000
      target: pristine

  error:
    on:
      reset:
        target: pristine

properties:
  - opacity: double
  - borderColor: Color

guards:
  - canSubmit
```

### Example 3: Multi-Step Wizard

**`wizard.kito.yaml`:**

```yaml
name: WizardStateMachine
states: [step1, step2, step3, complete]
events: [next, previous, submit, restart]
initial: step1

config:
  step1:
    on:
      next:
        target: step2
        guard: isStep1Valid
        animation:
          property: translateX
          to: -100
          duration: 300
          easing: easeInOut

  step2:
    on:
      next:
        target: step3
        guard: isStep2Valid
        animation:
          property: translateX
          to: -200
          duration: 300
          easing: easeInOut
      previous:
        target: step1
        animation:
          property: translateX
          to: 0
          duration: 300
          easing: easeInOut

  step3:
    on:
      submit:
        target: complete
        guard: isStep3Valid
      previous:
        target: step2
        animation:
          property: translateX
          to: -100
          duration: 300
          easing: easeInOut

  complete:
    entry:
      animation:
        property: scale
        to: 1.2
        duration: 500
        easing: easeOutBack
    after:
      duration: 2000
      target: step1
    on:
      restart:
        target: step1

properties:
  - translateX: double
  - scale: double

guards:
  - isStep1Valid
  - isStep2Valid
  - isStep3Valid
```

---

## Performance Considerations

### Benchmarks

Target performance metrics for v1:

| Operation | Target Latency | Notes |
|-----------|----------------|-------|
| State transition | <1ms | Pure Dart, no async |
| Animation trigger | <1ms | Schedule on next frame |
| Guard evaluation | <0.1ms | Simple boolean checks |
| History append | <0.1ms | In-memory list operation |
| ZIP notification | <5ms | Async, non-blocking |
| Event parsing | <0.5ms | String to enum lookup |

### Optimization Strategies

1. **Avoid unnecessary allocations**
   - Reuse transition objects
   - Pool animation instances
   - Lazy-load guards

2. **Batch updates**
   - Use Kito's `batch()` for multiple signal updates
   - Coalesce rapid state changes

3. **Lazy Temporal connection**
   - Only connect to Reflow when needed
   - Buffer messages if disconnected

4. **Efficient history**
   - Circular buffer with max size
   - Configurable retention

---

## Future Work

### Phase 9: Visual Editor (3-6 months)

**Scope:**
- Web-based state machine editor (adapted from Zeal)
- Drag-and-drop state nodes
- Visual transition drawing
- Animation configuration UI
- Real-time preview with Flutter embedding
- Export/import `.kito.yaml`
- State diagram auto-layout
- Collaboration features (from Zeal's CRDT)

### Phase 10: Advanced Features

**Hierarchical State Machines:**
- Nested states
- History states (shallow/deep)
- Parallel regions

**Additional Animation Features:**
- Spring physics
- Gesture-driven transitions
- Scroll-linked animations

**Developer Tools:**
- VS Code extension
- Syntax highlighting
- Live validation
- Diagram preview in editor
- Snippets library

**Testing Utilities:**
- State machine test harness
- Transition assertions
- Mock Temporals for testing

---

## Appendices

### A. Package Structure

```
kito/
├── packages/
│   ├── kito/                    # Core animation library (existing)
│   ├── kito_fsm/                # State machine runtime
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── runtime/
│   │   │   │   │   ├── state_machine.dart
│   │   │   │   │   ├── config.dart
│   │   │   │   │   ├── transition.dart
│   │   │   │   │   └── history.dart
│   │   │   │   ├── animation/
│   │   │   │   │   └── animation_controller.dart
│   │   │   │   └── types/
│   │   │   │       └── types.dart
│   │   │   └── kito_fsm.dart
│   │   └── pubspec.yaml
│   ├── kito_codegen/            # Code generator
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── parser/
│   │   │   │   ├── validator/
│   │   │   │   ├── generator/
│   │   │   │   └── ast/
│   │   │   └── builder.dart
│   │   └── pubspec.yaml
│   ├── kito_temporal/           # Temporal (ZIP proxy)
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── temporal.dart
│   │   │   │   ├── zip/
│   │   │   │   │   ├── connection.dart
│   │   │   │   │   ├── messages.dart
│   │   │   │   │   └── protocol.dart
│   │   │   │   └── telemetry/
│   │   │   │       └── metrics.dart
│   │   │   └── kito_temporal.dart
│   │   └── pubspec.yaml
│   └── kito_devtools_extension/  # DevTools integration
│       └── ...
├── docs/
│   ├── STATE_MACHINE_ARCHITECTURE.md  # This document
│   ├── GETTING_STARTED.md
│   ├── API_REFERENCE.md
│   └── TEMPORAL_GUIDE.md
└── examples/
    ├── button_state/
    ├── form_validation/
    ├── wizard_flow/
    └── temporal_integration/
```

### B. Dependencies

**`kito_fsm/pubspec.yaml`:**
```yaml
dependencies:
  kito: ^0.1.0
  meta: ^1.9.0

dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

**`kito_temporal/pubspec.yaml`:**
```yaml
dependencies:
  kito_fsm: ^0.1.0
  web_socket_channel: ^2.4.0

dev_dependencies:
  test: ^1.24.0
```

**`kito_codegen/pubspec.yaml`:**
```yaml
dependencies:
  build: ^2.4.0
  source_gen: ^1.4.0
  yaml: ^3.1.0
  code_builder: ^4.7.0
  dart_style: ^2.3.0
```

### C. References

- **XState**: https://xstate.js.org/
- **Statecharts**: https://statecharts.dev/
- **ZIP Protocol**: https://github.com/offbit-ai/zeal
- **Reflow**: https://github.com/offbit-ai/reflow
- **Kito**: https://github.com/[your-org]/kito

---

## Changelog

**v1.0.0 (2025-11-08)**
- Initial architecture specification
- Core state machine design
- Temporals (proxy) architecture
- DSL schema v1
- Implementation roadmap

---

**Document Status:** ✅ Ready for Review

**Next Steps:**
1. Review with team
2. Validate DSL design with sample use cases
3. Prototype Phase 1 (Core Runtime)
4. Gather feedback on API ergonomics

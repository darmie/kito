# Kito Temporals: Integration Guide

**Companion to:** [STATE_MACHINE_ARCHITECTURE.md](./STATE_MACHINE_ARCHITECTURE.md)

This guide covers **Temporals**—the proxy actor system that connects Kito state machines to Reflow workflows via the ZIP (Zeal Integration Protocol).

---

## Table of Contents

1. [What Are Temporals?](#what-are-temporals)
2. [When to Use Temporals](#when-to-use-temporals)
3. [Setup & Configuration](#setup--configuration)
4. [Basic Usage](#basic-usage)
5. [Advanced Patterns](#advanced-patterns)
6. [Debugging & Monitoring](#debugging--monitoring)
7. [Production Deployment](#production-deployment)

---

## What Are Temporals?

**Temporals** are lightweight proxy actors that wrap Kito state machines and enable them to participate in larger distributed workflows orchestrated by Reflow.

### Key Capabilities

- **Bidirectional Communication**: Both report to and receive commands from Reflow
- **Non-Invasive**: State machines work standalone; Temporal connection is optional
- **Observable**: Full telemetry and state history exposed to Reflow
- **Hot-Pluggable**: Connect/disconnect at runtime without restarting

### Architecture at a Glance

```
┌──────────────────┐      ZIP Protocol     ┌──────────────┐
│   Kito State     │◄────────────────────►│   Reflow     │
│   Machine        │     (WebSocket)       │   Engine     │
│   + Temporal     │                       │              │
└──────────────────┘                       └──────────────┘
```

**What Temporals Are NOT:**
- ❌ A replacement for state machines (they wrap them)
- ❌ Required for basic Kito usage (completely optional)
- ❌ A state persistence layer (use your own storage)
- ❌ A distributed state machine library (use Reflow for that)

---

## When to Use Temporals

### Use Cases Where Temporals Shine

#### 1. **Cross-Component Orchestration**

Coordinate multiple UI components in a complex flow:

```
Login Button → triggers → Form Validation → triggers → Submit Animation
     ↓                           ↓                           ↓
All managed by Reflow workflow, each wrapped in a Temporal
```

#### 2. **Analytics & Telemetry**

Track user interaction patterns:

```dart
// Reflow automatically logs all state transitions
onboarding_flow.intro → onboarding_flow.account_setup
  ↓
Analytics: "User reached account setup at 2025-11-08T10:30:00"
```

#### 3. **A/B Testing UI Flows**

Run multiple state machine variants in parallel:

```yaml
# Reflow workflow
workflow: ButtonVariantTest
actors:
  - id: variant_a
    type: kito_state_machine
    config: button_v1.kito.yaml

  - id: variant_b
    type: kito_state_machine
    config: button_v2.kito.yaml

analytics:
  - compare: click_through_rate
  - compare: time_to_complete
```

#### 4. **Integration Testing**

Replay user journeys for testing:

```dart
// Record production interactions
temporal.enableRecording();

// Later, replay in test environment
await temporal.replay(recordedEvents);
```

#### 5. **Distributed State Synchronization**

Sync state across devices (web ↔ mobile):

```yaml
# User starts auth on web
web_auth_machine.pending → reflow.notify(mobile_app)
  ↓
# Mobile app shows "Continue on mobile" prompt
mobile_auth_machine.start
```

### When NOT to Use Temporals

- ❌ Simple, isolated state machines (adds unnecessary complexity)
- ❌ Offline-first apps (requires network connection)
- ❌ Pure client-side apps with no backend orchestration
- ❌ Performance-critical real-time interactions (<16ms latency required)

---

## Setup & Configuration

### 1. Install Dependencies

**`pubspec.yaml`:**

```yaml
dependencies:
  kito: ^0.1.0
  kito_fsm: ^0.1.0
  kito_temporal: ^0.1.0  # Add this

dev_dependencies:
  kito_codegen: ^0.1.0
  build_runner: ^2.4.0
```

### 2. Enable Temporal in State Machine Definition

**`button.kito.yaml`:**

```yaml
name: ButtonStateMachine
# ... states, events, config ...

# Enable Temporal generation
temporal:
  enabled: true
  id: interactive_button  # Unique actor ID
  export_metrics: true     # Send telemetry to Reflow
  buffer_size: 100         # Message buffer if disconnected
```

### 3. Generate Code

```bash
flutter pub run build_runner build
```

This generates `ButtonTemporal` class alongside `ButtonStateMachine`.

### 4. Connect to Reflow

```dart
import 'package:kito_temporal/kito_temporal.dart';

// Create ZIP connection
final connection = ZIPConnection(
  url: 'ws://localhost:9000/zip',
  reconnect: true,  // Auto-reconnect on disconnect
);

await connection.connect();

// Create state machine
final machine = ButtonStateMachine(properties: props);

// Wrap in Temporal
final temporal = ButtonTemporal(
  id: 'login_button',
  machine: machine,
  connection: connection,
);

// Register with Reflow
await connection.registerActor(
  'login_button',
  metadata: {
    'type': 'button',
    'screen': 'login',
    'version': '1.0',
  },
);
```

---

## Basic Usage

### Example 1: Simple Temporal Connection

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ButtonTemporal _temporal;
  late ZIPConnection _connection;

  @override
  void initState() {
    super.initState();
    _setupTemporal();
  }

  Future<void> _setupTemporal() async {
    // Connect to Reflow
    _connection = ZIPConnection(url: Config.reflowUrl);
    await _connection.connect();

    // Create state machine + temporal
    final machine = ButtonStateMachine(properties: buttonProps);
    _temporal = ButtonTemporal(
      id: 'login_button',
      machine: machine,
      connection: _connection,
    );

    // Listen to state changes
    machine.changes.listen((change) {
      setState(() {});
      print('State: ${change.from} → ${change.to}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _temporal.machine.send(ButtonEvent.tap),
      child: Text('Login'),
    );
  }

  @override
  void dispose() {
    _temporal.dispose();
    _connection.disconnect();
    super.dispose();
  }
}
```

### Example 2: Conditional Temporal Connection

Only connect to Reflow in specific environments:

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Only use Temporal in dev/staging
    if (Config.environment == Environment.production) {
      return LoginScreen(useTemporal: false);
    } else {
      return LoginScreen(useTemporal: true);
    }
  }
}

class LoginScreen extends StatefulWidget {
  final bool useTemporal;

  const LoginScreen({this.useTemporal = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ButtonStateMachine _machine;
  ButtonTemporal? _temporal;
  ZIPConnection? _connection;

  @override
  void initState() {
    super.initState();

    _machine = ButtonStateMachine(properties: props);

    if (widget.useTemporal) {
      _setupTemporal();
    }
  }

  Future<void> _setupTemporal() async {
    _connection = ZIPConnection(url: Config.reflowUrl);
    await _connection!.connect();

    _temporal = ButtonTemporal(
      id: 'login_button',
      machine: _machine,
      connection: _connection,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Use machine directly (works with or without Temporal)
      onPressed: () => _machine.send(ButtonEvent.tap),
      child: Text('Login'),
    );
  }

  @override
  void dispose() {
    _temporal?.dispose();
    _connection?.disconnect();
    super.dispose();
  }
}
```

---

## Advanced Patterns

### Pattern 1: Reflow-Driven State Changes

Allow Reflow to remotely control your state machine:

**Reflow workflow:**

```yaml
workflow: OnboardingOrchestration
actors:
  - id: onboarding_ui
    type: kito_state_machine
    runtime: dart

  - id: backend
    type: http_client
    runtime: rust

flow:
  # When backend completes user creation
  - backend.user_created → onboarding_ui.trigger(next_step)

  # When user completes step
  - onboarding_ui.step_complete → backend.save_progress
```

**Flutter side (automatic):**

The `ButtonTemporal` automatically handles `trigger_event` messages from Reflow and calls `machine.send()`.

### Pattern 2: State History Replay

Debug issues by replaying state transitions:

```dart
class DebugScreen extends StatelessWidget {
  final ButtonTemporal temporal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('State History:'),
        ...temporal.machine.history.map((transition) {
          return ListTile(
            title: Text('${transition.from} → ${transition.to}'),
            subtitle: Text('Event: ${transition.event}'),
            trailing: Text(transition.timestamp.toString()),
          );
        }),
        ElevatedButton(
          onPressed: () => _replaySession(),
          child: Text('Replay Session'),
        ),
      ],
    );
  }

  Future<void> _replaySession() async {
    // Get history from Reflow
    final history = await temporal.connection.query(
      'GET_HISTORY',
      actorId: temporal.id,
    );

    // Replay events with delay
    for (final event in history.events) {
      temporal.machine.send(event);
      await Future.delayed(Duration(milliseconds: 500));
    }
  }
}
```

### Pattern 3: Multi-Device Coordination

Coordinate state across multiple devices:

**Setup:**

```yaml
# Reflow workflow
workflow: CrossDeviceAuth
actors:
  - id: web_auth
    type: kito_state_machine
    runtime: dart
    device: web

  - id: mobile_auth
    type: kito_state_machine
    runtime: dart
    device: mobile

flow:
  # User starts on web
  - web_auth.qr_displayed → mobile_auth.trigger(scan_qr)

  # User scans QR on mobile
  - mobile_auth.qr_scanned → web_auth.trigger(auth_pending)

  # Mobile confirms
  - mobile_auth.confirmed → web_auth.trigger(auth_success)
```

**Flutter web:**

```dart
class WebAuthScreen extends StatefulWidget {
  @override
  State<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends State<WebAuthScreen> {
  late AuthTemporal _temporal;

  @override
  void initState() {
    super.initState();

    final machine = AuthStateMachine(properties: props);
    _temporal = AuthTemporal(
      id: 'web_auth',
      machine: machine,
      connection: sharedConnection,
    );

    // Listen for remote triggers from mobile
    machine.changes.listen((change) {
      if (change.to == AuthState.authSuccess) {
        Navigator.push(context, DashboardRoute());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return QRCodeWidget(
      data: _temporal.machine.qrData,
    );
  }
}
```

**Flutter mobile:**

```dart
class MobileAuthScreen extends StatefulWidget {
  @override
  State<MobileAuthScreen> createState() => _MobileAuthScreenState();
}

class _MobileAuthScreenState extends State<MobileAuthScreen> {
  late AuthTemporal _temporal;

  @override
  void initState() {
    super.initState();

    final machine = AuthStateMachine(properties: props);
    _temporal = AuthTemporal(
      id: 'mobile_auth',
      machine: machine,
      connection: sharedConnection,
    );
  }

  void _onQRScanned(String data) {
    // Trigger local state change
    _temporal.machine.send(AuthEvent.qrScanned);

    // Reflow automatically notifies web_auth
  }

  @override
  Widget build(BuildContext context) {
    return QRScanner(onScanned: _onQRScanned);
  }
}
```

### Pattern 4: Telemetry & Analytics

Collect detailed metrics:

```dart
class AnalyticsService {
  final ZIPConnection connection;

  AnalyticsService(this.connection) {
    // Listen to all Temporal messages
    connection.messages
      .where((msg) => msg.type == 'TRANSITION')
      .listen(_trackTransition);
  }

  void _trackTransition(TransitionMessage msg) {
    // Log to analytics
    analytics.logEvent(
      'state_transition',
      parameters: {
        'actor_id': msg.actorId,
        'from_state': msg.fromState,
        'to_state': msg.toState,
        'event': msg.event,
        'timestamp': msg.timestamp.millisecondsSinceEpoch,
      },
    );

    // Identify funnel drop-offs
    if (msg.toState == 'error' || msg.toState == 'canceled') {
      analytics.logEvent('funnel_drop_off', parameters: {
        'step': msg.fromState,
        'reason': msg.toState,
      });
    }
  }
}
```

---

## Debugging & Monitoring

### 1. Enable Debug Logging

```dart
// In development
ZIPConnection.enableDebugLogging = true;

final connection = ZIPConnection(url: reflowUrl);
connection.messages.listen((msg) {
  print('[ZIP] ${msg.type}: ${msg.toJson()}');
});
```

### 2. Inspect Temporal State

```dart
// Get current state snapshot
final snapshot = temporal.getSnapshot();
print('Current state: ${snapshot.currentState}');
print('Transition count: ${snapshot.transitionCount}');
print('Uptime: ${snapshot.uptime}');

// Get metrics
final metrics = temporal.getMetrics();
print('State visit counts: ${metrics.stateVisitCounts}');
print('Average transition time: ${metrics.averageTransitionTime}');
```

### 3. Reflow DevTools Integration

View state machines in Reflow's visual debugger:

```bash
# Start Reflow with DevTools
reflow serve --devtools

# Open browser
http://localhost:9000/devtools
```

**Features:**
- Live state visualization
- Transition graph
- Event injection
- State forcing
- Performance metrics

### 4. Connection Health Monitoring

```dart
class TemporalHealthMonitor {
  final ZIPConnection connection;
  Timer? _healthCheckTimer;

  void start() {
    _healthCheckTimer = Timer.periodic(
      Duration(seconds: 30),
      (_) => _checkHealth(),
    );
  }

  Future<void> _checkHealth() async {
    try {
      final response = await connection.ping();
      if (response.latency > Duration(milliseconds: 100)) {
        print('⚠️ High latency: ${response.latency}');
      }
    } catch (e) {
      print('❌ Connection lost: $e');
      await connection.reconnect();
    }
  }

  void stop() {
    _healthCheckTimer?.cancel();
  }
}
```

---

## Production Deployment

### 1. Environment Configuration

```dart
class ReflowConfig {
  static String get url {
    switch (Environment.current) {
      case Environment.development:
        return 'ws://localhost:9000/zip';
      case Environment.staging:
        return 'wss://staging-reflow.yourapp.com/zip';
      case Environment.production:
        return 'wss://reflow.yourapp.com/zip';
    }
  }

  static bool get enabled {
    // Disable in production for pure client-side apps
    return Environment.current != Environment.production;
  }
}
```

### 2. Graceful Degradation

Handle connection failures gracefully:

```dart
class ResilientTemporal<S extends Enum, E extends Enum> {
  final KitoStateMachine<S, E> machine;
  Temporal<S, E>? _temporal;

  ResilientTemporal({
    required this.machine,
    required String id,
    ZIPConnection? connection,
  }) {
    if (connection != null) {
      try {
        _temporal = Temporal(
          id: id,
          machine: machine,
          connection: connection,
        );
      } catch (e) {
        print('⚠️ Failed to create Temporal, continuing without: $e');
      }
    }
  }

  // Forward to machine directly
  void send(E event) => machine.send(event);

  Signal<S> get currentState => machine.currentState;

  void dispose() {
    _temporal?.dispose();
    machine.dispose();
  }
}
```

### 3. Security Considerations

**Authentication:**

```dart
final connection = ZIPConnection(
  url: reflowUrl,
  headers: {
    'Authorization': 'Bearer ${await getAuthToken()}',
  },
);
```

**Message Validation:**

```dart
class SecureTemporal<S extends Enum, E extends Enum> extends Temporal<S, E> {
  @override
  void _handleReflowMessage(ZIPMessage message) {
    // Validate message signature
    if (!_validateSignature(message)) {
      print('⚠️ Invalid message signature, ignoring');
      return;
    }

    // Only allow whitelisted events
    if (message.type == 'TRIGGER_EVENT') {
      final event = (message as TriggerEventMessage).event;
      if (!_allowedEvents.contains(event)) {
        print('⚠️ Event not allowed: $event');
        return;
      }
    }

    super._handleReflowMessage(message);
  }

  bool _validateSignature(ZIPMessage message) {
    // Implement HMAC verification
    return true;
  }

  Set<String> get _allowedEvents => {'reset', 'refresh'};
}
```

### 4. Performance Optimization

**Message Batching:**

```dart
class BatchedTemporal<S extends Enum, E extends Enum> extends Temporal<S, E> {
  final List<ZIPMessage> _messageBuffer = [];
  Timer? _flushTimer;

  @override
  void _sendToReflow(ZIPMessage message) {
    _messageBuffer.add(message);

    _flushTimer?.cancel();
    _flushTimer = Timer(Duration(milliseconds: 100), _flush);
  }

  void _flush() {
    if (_messageBuffer.isEmpty) return;

    connection.sendBatch(_messageBuffer);
    _messageBuffer.clear();
  }
}
```

**Selective Telemetry:**

```yaml
# Only export important states
temporal:
  enabled: true
  export_metrics: true
  track_states:  # Only these states trigger notifications
    - loading
    - success
    - error
  ignore_events:  # Don't report these events
    - hover
    - unhover
```

### 5. Monitoring & Alerting

```dart
class ProductionMonitoring {
  final ZIPConnection connection;

  void setupAlerts() {
    // Alert on high error rate
    connection.messages
      .where((msg) => msg.type == 'TRANSITION')
      .map((msg) => msg as TransitionMessage)
      .where((msg) => msg.toState == 'error')
      .listen((msg) {
        _incrementErrorCount();
        if (_errorRate > 0.1) {  // 10% error rate
          _sendAlert('High error rate detected');
        }
      });

    // Alert on connection issues
    connection.onDisconnect.listen((_) {
      _sendAlert('Reflow connection lost');
    });
  }

  void _sendAlert(String message) {
    // Send to monitoring service (Sentry, etc.)
  }
}
```

---

## Best Practices

### 1. Keep Temporals Stateless

Temporals should be pure proxies—don't add state:

**Good:**
```dart
class ButtonTemporal extends Temporal<ButtonState, ButtonEvent> {
  // Just proxy logic, no state
}
```

**Bad:**
```dart
class ButtonTemporal extends Temporal<ButtonState, ButtonEvent> {
  int _clickCount = 0;  // ❌ Don't add state here!
}
```

### 2. Use Metadata for Context

Provide rich metadata when registering:

```dart
await connection.registerActor('login_button', {
  'type': 'button',
  'screen': 'login',
  'version': '1.2.0',
  'user_segment': 'premium',
  'ab_test_variant': 'A',
});
```

### 3. Handle Disconnections Gracefully

```dart
connection.onDisconnect.listen((_) {
  // Continue functioning without Reflow
  print('⚠️ Reflow disconnected, running in standalone mode');
});

connection.onReconnect.listen((_) {
  print('✅ Reflow reconnected');
  // Optionally sync state
  temporal.syncState();
});
```

### 4. Test Without Temporals

Always test state machines independently:

```dart
testWidgets('Button works without Temporal', (tester) async {
  final machine = ButtonStateMachine(properties: props);

  machine.send(ButtonEvent.tap);

  expect(machine.currentState.value, ButtonState.pressed);

  // No Temporal needed for tests!
});
```

---

## FAQ

### Q: Can I use Temporals without Reflow?

**A:** Technically yes, but you'd need to implement your own ZIP-compatible server. Temporals are designed for Reflow integration.

### Q: What happens if Reflow is down?

**A:** State machines continue to work normally. Temporals buffer messages (configurable size) and reconnect automatically.

### Q: Can I use Temporals in production?

**A:** Yes, but consider the tradeoffs:
- **Pros:** Powerful orchestration, analytics, debugging
- **Cons:** Network dependency, added complexity, latency

### Q: How much overhead do Temporals add?

**A:** Minimal (<5ms per state transition for ZIP notification, async). State transitions themselves remain <1ms.

### Q: Can multiple Temporals share one connection?

**A:** Yes! Recommended pattern:

```dart
final sharedConnection = ZIPConnection(url: reflowUrl);
await sharedConnection.connect();

final temporal1 = ButtonTemporal(id: 'btn1', machine: m1, connection: sharedConnection);
final temporal2 = FormTemporal(id: 'form1', machine: m2, connection: sharedConnection);
```

---

## Resources

- [State Machine Architecture](./STATE_MACHINE_ARCHITECTURE.md)
- [Kito Examples](./STATE_MACHINE_EXAMPLES.md)
- [ZIP Protocol Spec](https://github.com/offbit-ai/zeal/docs/ZIP_PROTOCOL.md)
- [Reflow Documentation](https://github.com/offbit-ai/reflow)

---

**Last Updated:** 2025-11-08

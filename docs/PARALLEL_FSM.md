# Parallel FSM Guide

Comprehensive guide to using Parallel State Machines in Kito.

## Table of Contents

- [Introduction](#introduction)
- [Core Concepts](#core-concepts)
- [Basic Usage](#basic-usage)
- [Communication Patterns](#communication-patterns)
- [Synchronization](#synchronization)
- [Fork-Join Pattern](#fork-join-pattern)
- [Practical Examples](#practical-examples)
- [Best Practices](#best-practices)

---

## Introduction

Parallel FSMs (Finite State Machines) allow you to run multiple independent state machines concurrently. Each state machine operates in its own "region" and can:

- Run completely independently
- Share a common context
- Communicate through event broadcasting
- Coordinate through synchronized transitions

### When to Use Parallel FSM

✅ **Use when:**
- You have multiple independent subsystems (player, enemies, UI)
- Different parts of your application have separate state lifecycles
- You need coordinated behavior across multiple state machines
- You want to model truly concurrent processes

❌ **Don't use when:**
- A simple hierarchical FSM would suffice
- States are tightly coupled (use a single FSM instead)
- You only need sequential state management

---

## Core Concepts

### Orthogonal Regions

A **region** is an independent state machine with its own states and transitions. Regions run in parallel within a parent `ParallelStateMachine`.

```dart
final playerRegion = ParallelRegion(
  id: 'player',
  stateMachine: playerFSM,
);

final enemyRegion = ParallelRegion(
  id: 'enemies',
  stateMachine: enemiesFSM,
);
```

### Configuration Modes

**Isolated Mode** (default):
- Events must be explicitly targeted to specific regions
- Maximum control over event flow

**Broadcast Mode**:
- Events sent to all regions simultaneously
- Good for global events (pause, resume, etc.)

**Synchronized Mode**:
- Regions coordinate state changes
- Useful for tightly coupled systems

---

## Basic Usage

### Creating a Parallel FSM

```dart
import 'package:kito_fsm/kito_fsm.dart';

// Define states and events for each region
enum PlayerState { idle, running, jumping }
enum PlayerEvent { run, jump, land }

enum EnemyState { patrol, chase, attack }
enum EnemyEvent { spotted, lost, hit }

// Create individual state machines
final playerFSM = StateMachine<PlayerState, PlayerEvent, PlayerContext>(
  initialState: PlayerState.idle,
  context: PlayerContext(),
);

final enemyFSM = StateMachine<EnemyState, EnemyEvent, EnemyContext>(
  initialState: EnemyState.patrol,
  context: EnemyContext(),
);

// Create regions
final playerRegion = ParallelRegion(
  id: 'player',
  stateMachine: playerFSM,
);

final enemyRegion = ParallelRegion(
  id: 'enemies',
  stateMachine: enemyFSM,
);

// Create parallel FSM
final gameFSM = ParallelStateMachine(
  regions: [playerRegion, enemyRegion],
  config: ParallelConfig.isolated, // or broadcast, synced
);
```

### Sending Events

#### To Specific Region:
```dart
gameFSM.sendToRegion('player', PlayerEvent.jump);
gameFSM.sendToRegion('enemies', EnemyEvent.spotted);
```

#### Broadcasting to All Regions:
```dart
// If using broadcast config, this goes to all regions
gameFSM.broadcast(CommonEvent.pause);
```

#### To Multiple Regions:
```dart
gameFSM.sendToRegions(
  ['player', 'enemies'],
  CommonEvent.gameOver,
);
```

### Querying State

```dart
// Get state of specific region
final playerState = gameFSM.getRegionState('player');
print('Player is: $playerState');

// Get all states
final allStates = gameFSM.getAllStates();
// Returns: {'player': PlayerState.running, 'enemies': EnemyState.chase}

// Check if region is active
if (gameFSM.isRegionActive('player')) {
  print('Player region is active');
}
```

---

## Communication Patterns

### Pattern 1: Isolated Regions

Regions don't communicate - completely independent.

```dart
final parallelFSM = ParallelStateMachine(
  regions: [region1, region2, region3],
  config: ParallelConfig.isolated,
);

// Must target each region explicitly
parallelFSM.sendToRegion('region1', Event1.start);
parallelFSM.sendToRegion('region2', Event2.begin);
```

**Use Case**: Separate UI components with independent lifecycles.

---

### Pattern 2: Broadcast Communication

All regions receive all events.

```dart
final parallelFSM = ParallelStateMachine(
  regions: [uiRegion, gameRegion, audioRegion],
  config: ParallelConfig.broadcast,
);

// Goes to all regions
parallelFSM.broadcast(GlobalEvent.pause);
```

**Use Case**: Global events like pause/resume affecting all subsystems.

---

### Pattern 3: Selective Broadcast

Targeted multi-region communication.

```dart
// Send to specific subset
parallelFSM.sendToRegions(
  ['ui', 'audio'], // Only these regions
  Event.mute,
);
```

**Use Case**: Events affecting multiple but not all regions.

---

### Pattern 4: Cross-Region Observation

React to state changes in other regions.

```dart
parallelFSM.onAnyStateChange((regionId, newState) {
  print('Region $regionId changed to $newState');

  // React to specific region changes
  if (regionId == 'player' && newState == PlayerState.dead) {
    parallelFSM.sendToRegion('ui', UIEvent.showGameOver);
  }
});
```

**Use Case**: Coordinating behavior across regions.

---

## Synchronization

### Wait for Specific States

Block until all regions reach specified states:

```dart
// Wait for both regions to be ready
await parallelFSM.waitForSync({
  'player': PlayerState.ready,
  'level': LevelState.loaded,
});

print('Game ready to start!');
parallelFSM.broadcast(GameEvent.start);
```

### Sync Callbacks

Register callbacks that fire when conditions are met:

```dart
parallelFSM.onSync(
  'allPaused',
  conditions: {
    'player': PlayerState.paused,
    'enemies': EnemyState.paused,
    'ui': UIState.paused,
  },
  callback: () {
    print('All systems paused');
    // Save game state
  },
);
```

### Check Sync State

Synchronously check if conditions are met:

```dart
final allReady = parallelFSM.areRegionsInStates({
  'player': PlayerState.ready,
  'level': LevelState.loaded,
  'ui': UIState.initialized,
});

if (allReady) {
  startGame();
}
```

---

## Fork-Join Pattern

Split execution into parallel tasks, then rejoin.

### Using Helper

```dart
await ParallelFSMHelper.forkJoin(
  [loadPlayerRegion, loadEnemiesRegion, loadUIRegion],
  joinConditions: {
    'player': LoadState.complete,
    'enemies': LoadState.complete,
    'ui': LoadState.complete,
  },
);

print('All resources loaded!');
```

### Manual Fork-Join

```dart
final parallelFSM = ParallelStateMachine(
  regions: [mainRegion],
);

// Fork: create new parallel tasks
parallelFSM.fork([
  ParallelRegion(id: 'task1', stateMachine: task1FSM),
  ParallelRegion(id: 'task2', stateMachine: task2FSM),
  ParallelRegion(id: 'task3', stateMachine: task3FSM),
]);

// Join: wait for completion and deactivate
await parallelFSM.join(
  ['task1', 'task2', 'task3'],
  {
    'task1': TaskState.complete,
    'task2': TaskState.complete,
    'task3': TaskState.complete,
  },
);

print('All tasks complete and deactivated');
```

---

## Practical Examples

### Example 1: Game with Player and Enemies

```dart
// Player FSM
enum PlayerState { idle, moving, jumping, dead }
enum PlayerEvent { move, jump, land, die }

class PlayerContext {
  final position = animatableOffset(Offset.zero);
  final health = signal(100);
}

final playerFSM = StateMachine<PlayerState, PlayerEvent, PlayerContext>(
  initialState: PlayerState.idle,
  context: PlayerContext(),
);

playerFSM.defineState(PlayerState.idle);
playerFSM.defineState(PlayerState.moving);
playerFSM.defineState(PlayerState.jumping);
playerFSM.defineState(PlayerState.dead);

playerFSM.addTransition(
  from: PlayerState.idle,
  to: PlayerState.moving,
  event: PlayerEvent.move,
);

// Enemy FSM
enum EnemyState { patrol, chase, attack, dead }
enum EnemyEvent { spotted, lost, attackPlayer, die }

class EnemyContext {
  final position = animatableOffset(Offset(100, 0));
  final health = signal(50);
}

final enemyFSM = StateMachine<EnemyState, EnemyEvent, EnemyContext>(
  initialState: EnemyState.patrol,
  context: EnemyContext(),
);

// Create parallel FSM
final gameFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(id: 'player', stateMachine: playerFSM),
    ParallelRegion(id: 'enemies', stateMachine: enemyFSM),
  ],
  config: ParallelConfig.isolated,
);

// Monitor cross-region interactions
gameFSM.onAnyStateChange((regionId, newState) {
  if (regionId == 'player' && newState == PlayerState.dead) {
    gameFSM.sendToRegion('enemies', EnemyEvent.lost);
    showGameOver();
  }

  if (regionId == 'enemies' && newState == EnemyState.chase) {
    playAlertSound();
  }
});

// Game loop
void update(double deltaTime) {
  // Update player based on input
  if (isKeyPressed(Key.space)) {
    gameFSM.sendToRegion('player', PlayerEvent.jump);
  }

  // Enemy AI decision
  if (playerNearby()) {
    gameFSM.sendToRegion('enemies', EnemyEvent.spotted);
  }
}
```

---

### Example 2: Multi-Step Form with Parallel Validation

```dart
enum ValidationState { idle, validating, valid, invalid }
enum ValidationEvent { validate, reset }

class ValidationContext {
  final isValid = signal(false);
  final errorMessage = signal('');
}

// Create validation FSM for each field
final emailValidation = StateMachine<ValidationState, ValidationEvent, ValidationContext>(
  initialState: ValidationState.idle,
  context: ValidationContext(),
);

final passwordValidation = StateMachine<ValidationState, ValidationEvent, ValidationContext>(
  initialState: ValidationState.idle,
  context: ValidationContext(),
);

// Parallel validation
final formFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(id: 'email', stateMachine: emailValidation),
    ParallelRegion(id: 'password', stateMachine: passwordValidation),
  ],
);

// Wait for all validations
Future<bool> validateForm() async {
  // Trigger validation in all regions
  formFSM.broadcast(ValidationEvent.validate);

  // Wait for all to complete
  await formFSM.waitForSync({
    'email': ValidationState.valid,
    'password': ValidationState.valid,
  });

  return formFSM.areRegionsInStates({
    'email': ValidationState.valid,
    'password': ValidationState.valid,
  });
}
```

---

### Example 3: Loading Screen with Parallel Resources

```dart
enum LoadState { notStarted, loading, loaded, error }
enum LoadEvent { start, success, fail }

// Create FSM for each resource
final createResourceFSM = (String name) {
  final fsm = StateMachine<LoadState, LoadEvent, void>(
    initialState: LoadState.notStarted,
  );

  fsm.defineState(LoadState.loading);
  fsm.defineState(LoadState.loaded);
  fsm.defineState(LoadState.error);

  fsm.addTransition(
    from: LoadState.notStarted,
    to: LoadState.loading,
    event: LoadEvent.start,
    action: () async {
      // Simulate loading
      await Future.delayed(Duration(seconds: 1));
      // Auto-transition to loaded
    },
  );

  return fsm;
};

// Create parallel loader
final loaderFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(id: 'images', stateMachine: createResourceFSM('images')),
    ParallelRegion(id: 'sounds', stateMachine: createResourceFSM('sounds')),
    ParallelRegion(id: 'data', stateMachine: createResourceFSM('data')),
  ],
);

// Start all loads
Future<void> loadAllResources() async {
  loaderFSM.broadcast(LoadEvent.start);

  // Update progress
  loaderFSM.onAnyStateChange((regionId, newState) {
    if (newState == LoadState.loaded) {
      print('$regionId loaded');
      updateProgressBar();
    }
  });

  // Wait for all to complete
  await loaderFSM.waitForSync({
    'images': LoadState.loaded,
    'sounds': LoadState.loaded,
    'data': LoadState.loaded,
  });

  print('All resources loaded!');
}
```

---

## Best Practices

### 1. Name Regions Clearly

```dart
// Good ✓
ParallelRegion(id: 'playerController', ...)
ParallelRegion(id: 'enemyAI', ...)
ParallelRegion(id: 'uiManager', ...)

// Avoid ✗
ParallelRegion(id: 'region1', ...)
ParallelRegion(id: 'r2', ...)
```

---

### 2. Choose Appropriate Configuration

```dart
// Global events → Broadcast
final globalFSM = ParallelStateMachine(
  regions: [...],
  config: ParallelConfig.broadcast,
);

// Independent systems → Isolated
final independentFSM = ParallelStateMachine(
  regions: [...],
  config: ParallelConfig.isolated,
);
```

---

### 3. Handle State Changes Gracefully

```dart
parallelFSM.onAnyStateChange((regionId, newState) {
  try {
    // Handle state change
    handleStateChange(regionId, newState);
  } catch (e) {
    print('Error handling state change: $e');
    // Recover or log
  }
});
```

---

### 4. Use Sync for Coordination

```dart
// Wait for ready states before proceeding
await parallelFSM.waitForSync({
  'audio': AudioState.initialized,
  'graphics': GraphicsState.ready,
  'input': InputState.ready,
});

startGame();
```

---

### 5. Clean Up Resources

```dart
// Deactivate regions when done
parallelFSM.deactivateRegion('temporaryTask');

// Or deactivate all
parallelFSM.deactivateAll();
```

---

### 6. Monitor Active Regions

```dart
print('Active regions: ${parallelFSM.activeRegionCount}');
print('Total regions: ${parallelFSM.regionCount}');

// Get active regions
for (final region in parallelFSM.activeRegions) {
  print('${region.id}: ${region.currentState}');
}
```

---

## Performance Considerations

1. **Limit Region Count**: More regions = more overhead
2. **Use Targeted Events**: Broadcast to all regions sparingly
3. **Dispose Inactive Regions**: Deactivate when not needed
4. **Batch State Changes**: Update multiple states together when possible

---

## Common Patterns Summary

| Pattern | Configuration | Use Case |
|---------|--------------|----------|
| **Independent** | Isolated | Separate UI components |
| **Broadcast** | Broadcast | Global events (pause/resume) |
| **Coordinated** | Synced | Tightly coupled systems |
| **Fork-Join** | Helper | Parallel tasks with join point |
| **Observer** | onAnyStateChange | Cross-region reactions |

---

## Troubleshooting

### Events Not Reaching Region

```dart
// Check if region is active
if (!parallelFSM.isRegionActive('myRegion')) {
  parallelFSM.activateRegion('myRegion');
}

// Verify region exists
final region = parallelFSM.getRegion('myRegion');
if (region == null) {
  print('Region not found!');
}
```

### Deadlock in Sync

```dart
// Set timeout for sync
final timeout = Duration(seconds: 5);

try {
  await parallelFSM
      .waitForSync(conditions)
      .timeout(timeout);
} on TimeoutException {
  print('Sync timed out - check region states');
  print(parallelFSM.getAllStates());
}
```

---

## Next Steps

- Explore [State Machine basics](/docs/STATE_MACHINE.md)
- Check [API Reference](/docs/api/REACTIVE_API.md)
- See [Examples](/packages/kito_fsm/example/)

Happy parallel state machining! 🎭

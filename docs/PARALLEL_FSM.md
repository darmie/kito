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
  - [Example 1: Game with Player and Enemies](#example-1-game-with-player-and-enemies)
  - [Example 2: Multi-Step Form with Parallel Validation](#example-2-multi-step-form-with-parallel-validation)
  - [Example 3: Loading Screen with Parallel Resources](#example-3-loading-screen-with-parallel-resources)
  - [Example 4: Dashboard with Independent Widgets](#example-4-dashboard-with-independent-widgets)
  - [Example 5: Media Player with Independent Controls](#example-5-media-player-with-independent-controls)
  - [Example 6: Settings Panel with Expandable Sections](#example-6-settings-panel-with-expandable-sections)
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
- UI components need independent loading/refresh states (dashboard widgets)
- Multiple validations can run in parallel (form fields)
- Media/player controls operate independently (playback, volume, progress)
- Settings sections expand/collapse independently (accordion panels)

❌ **Don't use when:**
- A simple hierarchical FSM would suffice
- States are tightly coupled (use a single FSM instead)
- You only need sequential state management
- Only one component is active at a time and they don't interact

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

### Example 4: Dashboard with Independent Widgets

```dart
enum WidgetState { idle, loading, loaded, error, refreshing }
enum WidgetEvent { load, refresh, error, success }

class WidgetContext {
  final data = signal<dynamic>(null);
  final errorMessage = signal<String?>(null);
  final lastUpdated = signal<DateTime?>(null);
}

// Create widget FSM factory
StateMachine<WidgetState, WidgetEvent, WidgetContext> createWidgetFSM(
  String name,
  Future<dynamic> Function() fetchData,
) {
  final context = WidgetContext();
  final fsm = StateMachine<WidgetState, WidgetEvent, WidgetContext>(
    initialState: WidgetState.idle,
    context: context,
  );

  fsm.defineState(WidgetState.loading);
  fsm.defineState(WidgetState.loaded);
  fsm.defineState(WidgetState.error);
  fsm.defineState(WidgetState.refreshing);

  fsm.addTransition(
    from: WidgetState.idle,
    to: WidgetState.loading,
    event: WidgetEvent.load,
    action: () async {
      try {
        final data = await fetchData();
        context.data.value = data;
        context.lastUpdated.value = DateTime.now();
        fsm.dispatch(WidgetEvent.success);
      } catch (e) {
        context.errorMessage.value = e.toString();
        fsm.dispatch(WidgetEvent.error);
      }
    },
  );

  fsm.addTransition(
    from: WidgetState.loading,
    to: WidgetState.loaded,
    event: WidgetEvent.success,
  );

  fsm.addTransition(
    from: WidgetState.loading,
    to: WidgetState.error,
    event: WidgetEvent.error,
  );

  // Refresh from loaded state
  fsm.addTransition(
    from: WidgetState.loaded,
    to: WidgetState.refreshing,
    event: WidgetEvent.refresh,
    action: () async {
      try {
        final data = await fetchData();
        context.data.value = data;
        context.lastUpdated.value = DateTime.now();
        fsm.dispatch(WidgetEvent.success);
      } catch (e) {
        context.errorMessage.value = e.toString();
        fsm.dispatch(WidgetEvent.error);
      }
    },
  );

  fsm.addTransition(
    from: WidgetState.refreshing,
    to: WidgetState.loaded,
    event: WidgetEvent.success,
  );

  return fsm;
}

// Dashboard with 4 independent widgets
final dashboardFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(
      id: 'salesWidget',
      stateMachine: createWidgetFSM('Sales', () => fetchSalesData()),
    ),
    ParallelRegion(
      id: 'analyticsWidget',
      stateMachine: createWidgetFSM('Analytics', () => fetchAnalytics()),
    ),
    ParallelRegion(
      id: 'notificationsWidget',
      stateMachine: createWidgetFSM('Notifications', () => fetchNotifications()),
    ),
    ParallelRegion(
      id: 'activityWidget',
      stateMachine: createWidgetFSM('Activity', () => fetchActivity()),
    ),
  ],
  config: ParallelConfig.isolated,
);

// Load all widgets on dashboard init
void initDashboard() {
  dashboardFSM.broadcast(WidgetEvent.load);

  // Track loading progress
  var loadedCount = 0;
  dashboardFSM.onAnyStateChange((regionId, newState) {
    if (newState == WidgetState.loaded) {
      loadedCount++;
      updateLoadingIndicator(loadedCount / 4);
    } else if (newState == WidgetState.error) {
      showWidgetError(regionId);
    }
  });
}

// Refresh specific widget
void refreshWidget(String widgetId) {
  dashboardFSM.sendToRegion(widgetId, WidgetEvent.refresh);
}

// Refresh all widgets
void refreshAll() {
  dashboardFSM.broadcast(WidgetEvent.refresh);
}
```

**Use Case**: Dashboard where each widget loads/refreshes independently without blocking others.

---

### Example 5: Media Player with Independent Controls

```dart
// Playback FSM
enum PlaybackState { stopped, playing, paused, buffering }
enum PlaybackEvent { play, pause, stop, buffer, ready }

final playbackFSM = StateMachine<PlaybackState, PlaybackEvent, void>(
  initialState: PlaybackState.stopped,
);

// Volume FSM
enum VolumeState { muted, low, medium, high }
enum VolumeEvent { mute, unmute, increase, decrease, setLevel }

class VolumeContext {
  final level = signal(0.5);
  final isMuted = signal(false);
}

final volumeFSM = StateMachine<VolumeState, VolumeEvent, VolumeContext>(
  initialState: VolumeState.medium,
  context: VolumeContext(),
);

// Progress FSM
enum ProgressState { idle, seeking, playing }
enum ProgressEvent { startSeek, endSeek, update }

class ProgressContext {
  final position = signal(Duration.zero);
  final duration = signal(Duration.zero);
  final seekTarget = signal(Duration.zero);
}

final progressFSM = StateMachine<ProgressState, ProgressEvent, ProgressContext>(
  initialState: ProgressState.idle,
  context: ProgressContext(),
);

// Parallel media player
final mediaPlayerFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(id: 'playback', stateMachine: playbackFSM),
    ParallelRegion(id: 'volume', stateMachine: volumeFSM),
    ParallelRegion(id: 'progress', stateMachine: progressFSM),
  ],
  config: ParallelConfig.isolated,
);

// Cross-region coordination
mediaPlayerFSM.onAnyStateChange((regionId, newState) {
  // When user seeks, pause playback briefly
  if (regionId == 'progress' && newState == ProgressState.seeking) {
    mediaPlayerFSM.sendToRegion('playback', PlaybackEvent.pause);
  }

  // Resume playback after seek completes
  if (regionId == 'progress' && newState == ProgressState.playing) {
    mediaPlayerFSM.sendToRegion('playback', PlaybackEvent.play);
  }

  // Stop progress updates when playback stops
  if (regionId == 'playback' && newState == PlaybackState.stopped) {
    mediaPlayerFSM.sendToRegion('progress', ProgressEvent.update);
  }
});

// User interactions
void togglePlayPause() {
  final playbackState = mediaPlayerFSM.getRegionState('playback');
  if (playbackState == PlaybackState.playing) {
    mediaPlayerFSM.sendToRegion('playback', PlaybackEvent.pause);
  } else {
    mediaPlayerFSM.sendToRegion('playback', PlaybackEvent.play);
  }
}

void adjustVolume(double level) {
  mediaPlayerFSM.sendToRegion('volume', VolumeEvent.setLevel);
}

void seekTo(Duration position) {
  mediaPlayerFSM.sendToRegion('progress', ProgressEvent.startSeek);
  // ... perform seek ...
  mediaPlayerFSM.sendToRegion('progress', ProgressEvent.endSeek);
}
```

**Use Case**: Media player where playback, volume, and progress controls are independent but can coordinate when needed.

---

### Example 6: Settings Panel with Expandable Sections

```dart
enum SectionState { collapsed, expanding, expanded, collapsing }
enum SectionEvent { expand, collapse, toggle }

class SectionContext {
  final height = animatableDouble(0.0);
  final isExpanded = signal(false);
}

// Create section FSM factory
StateMachine<SectionState, SectionEvent, SectionContext> createSectionFSM(
  String name,
  double expandedHeight,
) {
  final context = SectionContext();
  final fsm = StateMachine<SectionState, SectionEvent, SectionContext>(
    initialState: SectionState.collapsed,
    context: context,
  );

  fsm.defineState(SectionState.expanding);
  fsm.defineState(SectionState.expanded);
  fsm.defineState(SectionState.collapsing);

  // Expand animation
  fsm.addTransition(
    from: SectionState.collapsed,
    to: SectionState.expanding,
    event: SectionEvent.expand,
    action: () {
      context.height.animateTo(
        expandedHeight,
        duration: 300,
        curve: Curves.easeOut,
        onComplete: () => fsm.dispatch(SectionEvent.toggle),
      );
    },
  );

  fsm.addTransition(
    from: SectionState.expanding,
    to: SectionState.expanded,
    event: SectionEvent.toggle,
    action: () {
      context.isExpanded.value = true;
    },
  );

  // Collapse animation
  fsm.addTransition(
    from: SectionState.expanded,
    to: SectionState.collapsing,
    event: SectionEvent.collapse,
    action: () {
      context.height.animateTo(
        0.0,
        duration: 300,
        curve: Curves.easeIn,
        onComplete: () => fsm.dispatch(SectionEvent.toggle),
      );
    },
  );

  fsm.addTransition(
    from: SectionState.collapsing,
    to: SectionState.collapsed,
    event: SectionEvent.toggle,
    action: () {
      context.isExpanded.value = false;
    },
  );

  return fsm;
}

// Settings panel with multiple sections
final settingsPanelFSM = ParallelStateMachine(
  regions: [
    ParallelRegion(
      id: 'accountSection',
      stateMachine: createSectionFSM('Account', 200),
    ),
    ParallelRegion(
      id: 'notificationsSection',
      stateMachine: createSectionFSM('Notifications', 150),
    ),
    ParallelRegion(
      id: 'privacySection',
      stateMachine: createSectionFSM('Privacy', 180),
    ),
    ParallelRegion(
      id: 'appearanceSection',
      stateMachine: createSectionFSM('Appearance', 120),
    ),
  ],
  config: ParallelConfig.isolated,
);

// Accordion behavior: collapse others when one expands
void toggleSectionAccordion(String sectionId) {
  final currentState = settingsPanelFSM.getRegionState(sectionId);

  if (currentState == SectionState.collapsed) {
    // Collapse all other sections
    for (final region in settingsPanelFSM.activeRegions) {
      if (region.id != sectionId) {
        settingsPanelFSM.sendToRegion(region.id, SectionEvent.collapse);
      }
    }
    // Expand this section
    settingsPanelFSM.sendToRegion(sectionId, SectionEvent.expand);
  } else {
    // Just collapse this section
    settingsPanelFSM.sendToRegion(sectionId, SectionEvent.collapse);
  }
}

// Independent expansion (multiple sections can be open)
void toggleSectionIndependent(String sectionId) {
  final currentState = settingsPanelFSM.getRegionState(sectionId);

  if (currentState == SectionState.collapsed) {
    settingsPanelFSM.sendToRegion(sectionId, SectionEvent.expand);
  } else if (currentState == SectionState.expanded) {
    settingsPanelFSM.sendToRegion(sectionId, SectionEvent.collapse);
  }
}

// Expand all sections
void expandAll() {
  settingsPanelFSM.broadcast(SectionEvent.expand);
}

// Collapse all sections
void collapseAll() {
  settingsPanelFSM.broadcast(SectionEvent.collapse);
}
```

**Use Case**: Settings panel where sections can expand/collapse independently or with accordion behavior (only one open at a time).

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

| Pattern | Configuration | Use Case | Example |
|---------|--------------|----------|---------|
| **Independent** | Isolated | Separate UI components | Dashboard widgets (Ex 4), Settings sections (Ex 6) |
| **Broadcast** | Broadcast | Global events (pause/resume) | Form validation (Ex 2), Resource loading (Ex 3) |
| **Coordinated** | Synced + Observer | Tightly coupled systems | Media player controls (Ex 5) |
| **Fork-Join** | Helper | Parallel tasks with join point | Loading screen (Ex 3) |
| **Observer** | onAnyStateChange | Cross-region reactions | Game interactions (Ex 1), Media player (Ex 5) |
| **Accordion** | Isolated + Custom | One active at a time | Settings panel accordion mode (Ex 6) |

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

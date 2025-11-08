import 'dart:async';
import 'runtime/state_machine.dart';

/// Represents an orthogonal region in a parallel state machine
///
/// Each region runs independently with its own states and transitions.
/// Regions can communicate through shared context or event broadcasting.
class ParallelRegion<S, E, C> {
  /// Unique identifier for this region
  final String id;

  /// The state machine for this region
  final StateMachine<S, E, C> stateMachine;

  /// Whether this region is currently active
  bool isActive;

  ParallelRegion({
    required this.id,
    required this.stateMachine,
    this.isActive = true,
  });

  /// Get current state of this region
  S get currentState => stateMachine.currentState;

  /// Dispatch event to this region
  void dispatch(E event) {
    if (isActive) {
      stateMachine.dispatch(event);
    }
  }

  /// Activate this region
  void activate() {
    isActive = true;
  }

  /// Deactivate this region
  void deactivate() {
    isActive = false;
  }
}

/// Configuration for parallel state machine behavior
class ParallelConfig {
  /// Whether to broadcast events to all regions by default
  final bool broadcastByDefault;

  /// Whether to synchronize state changes across regions
  final bool synchronized;

  const ParallelConfig({
    this.broadcastByDefault = false,
    this.synchronized = false,
  });

  static const ParallelConfig broadcast = ParallelConfig(
    broadcastByDefault: true,
  );

  static const ParallelConfig isolated = ParallelConfig(
    broadcastByDefault: false,
  );

  static const ParallelConfig synced = ParallelConfig(
    broadcastByDefault: true,
    synchronized: true,
  );
}

/// A state machine that manages multiple orthogonal regions
///
/// Parallel state machines allow multiple independent state machines
/// to run concurrently, each in their own region. Regions can:
/// - Run completely independently
/// - Share a common context
/// - Communicate through event broadcasting
/// - Coordinate through synchronized transitions
///
/// Example:
/// ```dart
/// // Create two independent regions
/// final region1 = ParallelRegion(
///   id: 'player',
///   stateMachine: createPlayerFSM(),
/// );
///
/// final region2 = ParallelRegion(
///   id: 'enemies',
///   stateMachine: createEnemiesFSM(),
/// );
///
/// // Create parallel FSM
/// final parallelFsm = ParallelStateMachine(
///   regions: [region1, region2],
///   config: ParallelConfig.broadcast,
/// );
///
/// // Events broadcast to all regions
/// parallelFsm.broadcast(GameEvent.pause);
///
/// // Or send to specific region
/// parallelFsm.sendToRegion('player', PlayerEvent.moveLeft);
/// ```
class ParallelStateMachine<S, E, C> {
  /// All regions in this parallel state machine
  final List<ParallelRegion<S, E, C>> regions;

  /// Configuration for parallel behavior
  final ParallelConfig config;

  /// Shared context across all regions (optional)
  final C? sharedContext;

  /// Callbacks for when any region changes state
  final List<void Function(String regionId, S newState)> _onStateChangeCallbacks = [];

  /// Callbacks for synchronized state achievements
  final Map<String, void Function()> _syncCallbacks = {};

  ParallelStateMachine({
    required this.regions,
    this.config = const ParallelConfig(),
    this.sharedContext,
  }) {
    _setupRegionCallbacks();
  }

  /// Set up callbacks for each region to track state changes
  void _setupRegionCallbacks() {
    for (final region in regions) {
      // Monitor state changes in each region
      region.stateMachine.onStateChange((newState) {
        _notifyStateChange(region.id, newState);
        _checkSyncConditions();
      });
    }
  }

  /// Get a region by ID
  ParallelRegion<S, E, C>? getRegion(String id) {
    try {
      return regions.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all active regions
  List<ParallelRegion<S, E, C>> get activeRegions =>
      regions.where((r) => r.isActive).toList();

  /// Get current state of a specific region
  S? getRegionState(String regionId) {
    final region = getRegion(regionId);
    return region?.currentState;
  }

  /// Get current states of all regions
  Map<String, S> getAllStates() {
    return Map.fromEntries(
      regions.map((r) => MapEntry(r.id, r.currentState)),
    );
  }

  /// Broadcast an event to all active regions
  void broadcast(E event) {
    for (final region in activeRegions) {
      region.dispatch(event);
    }
  }

  /// Send event to specific region by ID
  void sendToRegion(String regionId, E event) {
    final region = getRegion(regionId);
    region?.dispatch(event);
  }

  /// Send event to multiple specific regions
  void sendToRegions(List<String> regionIds, E event) {
    for (final id in regionIds) {
      sendToRegion(id, event);
    }
  }

  /// Dispatch event - broadcasts or sends to specific region based on config
  void dispatch(E event, {String? targetRegion}) {
    if (targetRegion != null) {
      sendToRegion(targetRegion, event);
    } else if (config.broadcastByDefault) {
      broadcast(event);
    } else {
      throw StateError(
        'Must specify targetRegion when broadcastByDefault is false',
      );
    }
  }

  /// Register callback for state changes in any region
  void onAnyStateChange(void Function(String regionId, S newState) callback) {
    _onStateChangeCallbacks.add(callback);
  }

  /// Notify all callbacks of a state change
  void _notifyStateChange(String regionId, S newState) {
    for (final callback in _onStateChangeCallbacks) {
      callback(regionId, newState);
    }
  }

  /// Register a synchronized condition callback
  ///
  /// Callback fires when all specified regions are in the specified states.
  ///
  /// Example:
  /// ```dart
  /// parallelFsm.onSync(
  ///   'allReady',
  ///   conditions: {
  ///     'player': PlayerState.ready,
  ///     'enemies': EnemiesState.spawned,
  ///   },
  ///   callback: () => print('All systems ready!'),
  /// );
  /// ```
  void onSync(
    String id,
    Map<String, S> conditions,
    void Function() callback,
  ) {
    _syncCallbacks[id] = () {
      // Check if all conditions are met
      for (final entry in conditions.entries) {
        final regionState = getRegionState(entry.key);
        if (regionState != entry.value) {
          return; // Condition not met
        }
      }
      // All conditions met, execute callback
      callback();
    };
  }

  /// Check all sync conditions
  void _checkSyncConditions() {
    for (final callback in _syncCallbacks.values) {
      callback();
    }
  }

  /// Wait for all regions to reach specific states
  ///
  /// Returns a Future that completes when all conditions are met.
  ///
  /// Example:
  /// ```dart
  /// await parallelFsm.waitForSync({
  ///   'player': PlayerState.ready,
  ///   'ui': UIState.loaded,
  /// });
  /// print('All ready!');
  /// ```
  Future<void> waitForSync(Map<String, S> conditions) {
    final completer = Completer<void>();

    void checkConditions(String regionId, S newState) {
      for (final entry in conditions.entries) {
        final regionState = getRegionState(entry.key);
        if (regionState != entry.value) {
          return; // Not all conditions met yet
        }
      }
      // All conditions met
      completer.complete();
    }

    onAnyStateChange(checkConditions);

    // Check immediately in case conditions already met
    checkConditions('', regions.first.currentState);

    return completer.future;
  }

  /// Check if all regions are in specific states
  bool areRegionsInStates(Map<String, S> states) {
    for (final entry in states.entries) {
      final regionState = getRegionState(entry.key);
      if (regionState != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// Activate a region
  void activateRegion(String regionId) {
    getRegion(regionId)?.activate();
  }

  /// Deactivate a region
  void deactivateRegion(String regionId) {
    getRegion(regionId)?.deactivate();
  }

  /// Activate all regions
  void activateAll() {
    for (final region in regions) {
      region.activate();
    }
  }

  /// Deactivate all regions
  void deactivateAll() {
    for (final region in regions) {
      region.deactivate();
    }
  }

  /// Fork: split execution into parallel regions
  ///
  /// Creates new regions from provided state machines and activates them.
  void fork(List<ParallelRegion<S, E, C>> newRegions) {
    regions.addAll(newRegions);
    for (final region in newRegions) {
      _setupCallbacksForRegion(region);
      region.activate();
    }
  }

  /// Join: wait for specific regions to reach states, then deactivate them
  ///
  /// Returns a Future that completes when join conditions are met.
  Future<void> join(
    List<String> regionIds,
    Map<String, S> finalStates,
  ) async {
    // Wait for conditions
    await waitForSync(finalStates);

    // Deactivate the regions
    for (final id in regionIds) {
      deactivateRegion(id);
    }
  }

  void _setupCallbacksForRegion(ParallelRegion<S, E, C> region) {
    region.stateMachine.onStateChange((newState) {
      _notifyStateChange(region.id, newState);
      _checkSyncConditions();
    });
  }

  /// Get region count
  int get regionCount => regions.length;

  /// Get active region count
  int get activeRegionCount => activeRegions.length;

  /// Check if a region is active
  bool isRegionActive(String regionId) {
    return getRegion(regionId)?.isActive ?? false;
  }

  /// Reset all regions to their initial states
  void resetAll() {
    for (final region in regions) {
      // Reset to initial state
      // Note: This requires the state machine to have a reset method
      // For now, we'll just reactivate
      region.activate();
    }
  }
}

/// Helper for creating common parallel FSM patterns
class ParallelFSMHelper {
  /// Create a fork-join pattern
  ///
  /// Useful for parallel task execution that must complete before proceeding.
  static Future<void> forkJoin<S, E, C>(
    List<ParallelRegion<S, E, C>> regions,
    Map<String, S> joinConditions,
  ) async {
    final parallelFsm = ParallelStateMachine(
      regions: regions,
      config: ParallelConfig.isolated,
    );

    // Activate all regions (fork)
    parallelFsm.activateAll();

    // Wait for join conditions
    await parallelFsm.waitForSync(joinConditions);
  }

  /// Create a broadcast pattern
  ///
  /// All regions receive all events and react independently.
  static ParallelStateMachine<S, E, C> createBroadcast<S, E, C>(
    List<ParallelRegion<S, E, C>> regions,
  ) {
    return ParallelStateMachine(
      regions: regions,
      config: ParallelConfig.broadcast,
    );
  }

  /// Create an isolated pattern
  ///
  /// Each region must be targeted explicitly for events.
  static ParallelStateMachine<S, E, C> createIsolated<S, E, C>(
    List<ParallelRegion<S, E, C>> regions,
  ) {
    return ParallelStateMachine(
      regions: regions,
      config: ParallelConfig.isolated,
    );
  }
}

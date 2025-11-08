import 'package:flutter_test/flutter_test.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Media player states - hierarchical
enum MediaState {
  // Root states
  stopped,
  playing,
  paused,

  // Substates of playing
  playingNormal,
  playingBuffering,
  playingEnded,

  // Substates of paused
  pausedUser,
  pausedSystem,
}

/// Media events
enum MediaEvent {
  play,
  pause,
  stop,
  buffer,
  bufferComplete,
  end,
  systemPause,
  userPause,
}

/// Media context
class MediaContext {
  final int position;
  final int duration;
  final List<String> entryLog;
  final List<String> exitLog;

  const MediaContext({
    this.position = 0,
    this.duration = 100,
    this.entryLog = const [],
    this.exitLog = const [],
  });

  MediaContext copyWith({
    int? position,
    int? duration,
    List<String>? entryLog,
    List<String>? exitLog,
  }) {
    return MediaContext(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      entryLog: entryLog ?? this.entryLog,
      exitLog: exitLog ?? this.exitLog,
    );
  }

  MediaContext logEntry(String state) {
    return copyWith(entryLog: [...entryLog, state]);
  }

  MediaContext logExit(String state) {
    return copyWith(exitLog: [...exitLog, state]);
  }
}

/// Media player state machine with hierarchy
class MediaStateMachine
    extends KitoStateMachine<MediaState, MediaEvent, MediaContext> {
  MediaStateMachine({
    required MediaContext context,
  }) : super(
          initial: MediaState.stopped,
          context: context,
          config: _buildConfig(),
        );

  static StateMachineConfig<MediaState, MediaEvent, MediaContext>
      _buildConfig() {
    return StateMachineConfig(
      states: {
        // Stopped - atomic state
        MediaState.stopped: StateConfig(
          state: MediaState.stopped,
          transitions: {
            MediaEvent.play: TransitionConfig(
              target: MediaState.playing,
            ),
          },
          onEntry: (ctx, from, to) {
            // Log entry
          },
        ),

        // Playing - compound state with substates
        MediaState.playing: StateConfig(
          state: MediaState.playing,
          type: StateType.compound,
          initial: MediaState.playingNormal, // Auto-enter this substate
          onEntry: (ctx, from, to) {
            // Called when entering playing state
          },
          onExit: (ctx, from, to) {
            // Called when exiting playing state
          },
          transitions: {
            // Transitions defined on playing apply to all substates
            MediaEvent.pause: TransitionConfig(
              target: MediaState.paused,
            ),
            MediaEvent.stop: TransitionConfig(
              target: MediaState.stopped,
            ),
          },
          substates: {
            // Normal playback substate
            MediaState.playingNormal: StateConfig(
              state: MediaState.playingNormal,
              transitions: {
                MediaEvent.buffer: TransitionConfig(
                  target: MediaState.playingBuffering,
                ),
                MediaEvent.end: TransitionConfig(
                  target: MediaState.playingEnded,
                ),
                // pause and stop events will bubble up to parent
              },
            ),

            // Buffering substate
            MediaState.playingBuffering: StateConfig(
              state: MediaState.playingBuffering,
              transitions: {
                MediaEvent.bufferComplete: TransitionConfig(
                  target: MediaState.playingNormal,
                ),
              },
            ),

            // Ended substate
            MediaState.playingEnded: StateConfig(
              state: MediaState.playingEnded,
              transient: TransientConfig(
                after: const Duration(milliseconds: 100),
                target: MediaState.stopped,
              ),
            ),
          },
        ),

        // Paused - compound state with substates
        MediaState.paused: StateConfig(
          state: MediaState.paused,
          type: StateType.compound,
          initial: MediaState.pausedUser,
          transitions: {
            MediaEvent.play: TransitionConfig(
              target: MediaState.playing,
            ),
            MediaEvent.stop: TransitionConfig(
              target: MediaState.stopped,
            ),
          },
          substates: {
            MediaState.pausedUser: StateConfig(
              state: MediaState.pausedUser,
              transitions: {
                MediaEvent.systemPause: TransitionConfig(
                  target: MediaState.pausedSystem,
                ),
              },
            ),
            MediaState.pausedSystem: StateConfig(
              state: MediaState.pausedSystem,
              transitions: {
                MediaEvent.userPause: TransitionConfig(
                  target: MediaState.pausedUser,
                ),
              },
            ),
          },
        ),
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hierarchical States', () {
    test('should auto-enter initial substate on compound state entry', () {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      // Initially in stopped
      expect(machine.currentState.peek(), MediaState.stopped);
      expect(machine.statePath, [MediaState.stopped]);

      // Transition to playing (compound state)
      machine.send(MediaEvent.play);

      // Should auto-enter playingNormal (initial substate)
      expect(machine.currentState.peek(), MediaState.playingNormal);
      expect(machine.statePath, [MediaState.playing, MediaState.playingNormal]);

      machine.dispose();
    });

    test('should maintain state path correctly', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      // stopped → playing.playingNormal
      machine.send(MediaEvent.play);
      expect(machine.statePath, [MediaState.playing, MediaState.playingNormal]);

      await Future.delayed(const Duration(milliseconds: 10));

      // playing.playingNormal → playing.playingBuffering
      machine.send(MediaEvent.buffer);
      expect(machine.statePath,
          [MediaState.playing, MediaState.playingBuffering]);

      machine.dispose();
    });

    test('should bubble events from child to parent', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      // Currently in playing.playingNormal
      expect(machine.currentState.peek(), MediaState.playingNormal);

      // Send pause event - not defined on playingNormal, should bubble to playing
      machine.send(MediaEvent.pause);
      await Future.delayed(const Duration(milliseconds: 10));

      // Should transition to paused (and its initial substate)
      expect(machine.currentState.peek(), MediaState.pausedUser);
      expect(machine.statePath, [MediaState.paused, MediaState.pausedUser]);

      machine.dispose();
    });

    test('should transition between substates of same parent', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), MediaState.playingNormal);

      // Transition to sibling substate
      machine.send(MediaEvent.buffer);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), MediaState.playingBuffering);
      expect(machine.statePath,
          [MediaState.playing, MediaState.playingBuffering]);

      // Back to normal
      machine.send(MediaEvent.bufferComplete);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), MediaState.playingNormal);

      machine.dispose();
    });

    test('should transition between different parent branches', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      // stopped → playing.playingNormal
      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.statePath, [MediaState.playing, MediaState.playingNormal]);

      // playing.playingNormal → paused.pausedUser
      machine.send(MediaEvent.pause);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.statePath, [MediaState.paused, MediaState.pausedUser]);

      // paused.pausedUser → playing.playingNormal
      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.statePath, [MediaState.playing, MediaState.playingNormal]);

      machine.dispose();
    });

    test('should handle transitions within substates', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));
      machine.send(MediaEvent.pause);
      await Future.delayed(const Duration(milliseconds: 10));

      // In paused.pausedUser
      expect(machine.currentState.peek(), MediaState.pausedUser);

      // Transition to sibling substate
      machine.send(MediaEvent.systemPause);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), MediaState.pausedSystem);
      expect(machine.statePath, [MediaState.paused, MediaState.pausedSystem]);

      machine.dispose();
    });

    test('should stop event bubbling when transition found', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      // In playing.playingNormal
      machine.send(MediaEvent.buffer);
      await Future.delayed(const Duration(milliseconds: 10));

      // bufferComplete is defined on playingBuffering, should not bubble
      expect(machine.currentState.peek(), MediaState.playingBuffering);

      machine.send(MediaEvent.bufferComplete);
      await Future.delayed(const Duration(milliseconds: 10));

      // Should transition to playingNormal, staying in playing parent
      expect(machine.currentState.peek(), MediaState.playingNormal);
      expect(machine.statePath, [MediaState.playing, MediaState.playingNormal]);

      machine.dispose();
    });

    test('should handle transient states in hierarchy', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      // Trigger end event → playingEnded (transient)
      machine.send(MediaEvent.end);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), MediaState.playingEnded);

      // Wait for transient transition to stopped
      await Future.delayed(const Duration(milliseconds: 150));

      expect(machine.currentState.peek(), MediaState.stopped);
      expect(machine.statePath, [MediaState.stopped]);

      machine.dispose();
    });

    test('should track history with hierarchical states', () async {
      final machine = MediaStateMachine(
        context: const MediaContext(),
      );

      machine.send(MediaEvent.play);
      await Future.delayed(const Duration(milliseconds: 10));

      machine.send(MediaEvent.buffer);
      await Future.delayed(const Duration(milliseconds: 10));

      machine.send(MediaEvent.bufferComplete);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.history.length, greaterThanOrEqualTo(3));

      // Check transition records use leaf states
      expect(machine.history[0].to, MediaState.playingNormal);
      expect(machine.history[1].to, MediaState.playingBuffering);
      expect(machine.history[2].to, MediaState.playingNormal);

      machine.dispose();
    });

    test('should support deep nesting (3 levels)', () {
      final config = StateMachineConfig<DeepState, DeepEvent, int>(
        states: {
          DeepState.root: StateConfig(
            state: DeepState.root,
            type: StateType.compound,
            initial: DeepState.level1,
            substates: {
              DeepState.level1: StateConfig(
                state: DeepState.level1,
                type: StateType.compound,
                initial: DeepState.level1_a,
                transitions: {
                  DeepEvent.toB: TransitionConfig(target: DeepState.level1_b),
                },
                substates: {
                  DeepState.level1_a: StateConfig(
                    state: DeepState.level1_a,
                    type: StateType.compound,
                    initial: DeepState.level1_a_i,
                    substates: {
                      DeepState.level1_a_i: StateConfig(
                        state: DeepState.level1_a_i,
                        transitions: {
                          DeepEvent.toII:
                              TransitionConfig(target: DeepState.level1_a_ii),
                        },
                      ),
                      DeepState.level1_a_ii: StateConfig(
                        state: DeepState.level1_a_ii,
                      ),
                    },
                  ),
                  DeepState.level1_b: StateConfig(
                    state: DeepState.level1_b,
                  ),
                },
              ),
            },
          ),
        },
      );

      final machine = TestStateMachine(
        initial: DeepState.root,
        context: 0,
        config: config,
      );

      // Should auto-enter to deepest level
      expect(machine.statePath, [
        DeepState.root,
        DeepState.level1,
        DeepState.level1_a,
        DeepState.level1_a_i,
      ]);
      expect(machine.currentState.peek(), DeepState.level1_a_i);

      machine.dispose();
    });
  });
}

// Deep nesting test - states for 3-level hierarchy
enum DeepState {
  root,
  level1,
  level1_a,
  level1_a_i,
  level1_a_ii,
  level1_b,
}

enum DeepEvent { toA, toB, toI, toII }

/// Test helper for generic state machines
class TestStateMachine<S extends Enum, E extends Enum, C>
    extends KitoStateMachine<S, E, C> {
  TestStateMachine({
    required S initial,
    required C context,
    required StateMachineConfig<S, E, C> config,
  }) : super(
          initial: initial,
          context: context,
          config: config,
        );
}

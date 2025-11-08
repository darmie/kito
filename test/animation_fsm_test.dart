import 'package:flutter_test/flutter_test.dart';
import 'package:kito/kito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Animation FSM', () {
    test('should create animation with FSM', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .withDuration(1000)
          .build();

      // Should have access to FSM
      expect(anim.fsm, isNotNull);
      expect(anim.context, isNotNull);
    });

    test('should start in idle state', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      expect(anim.currentState.value, AnimState.idle);
      expect(anim.state, AnimationState.idle);
    });

    test('should transition to playing when play() is called', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();

      expect(anim.currentState.value, AnimState.playing);
      expect(anim.state, AnimationState.playing);
    });

    test('should transition to paused when pause() is called', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();
      expect(anim.currentState.value, AnimState.playing);

      anim.pause();
      expect(anim.currentState.value, AnimState.paused);
      expect(anim.state, AnimationState.paused);
    });

    test('should transition to idle when stop() is called', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();
      anim.pause();
      anim.stop();

      expect(anim.currentState.value, AnimState.idle);
      expect(anim.state, AnimationState.idle);
    });

    test('should restart from playing state', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();
      anim.restart();

      expect(anim.currentState.value, AnimState.playing);
      expect(anim.progressValue, 0.0);
    });

    test('should not pause when idle (guard prevents transition)', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      // Try to pause when idle
      anim.pause();

      // Should still be idle (guard prevented transition)
      expect(anim.currentState.value, AnimState.idle);
    });

    test('should resume from paused state', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();
      anim.pause();
      expect(anim.currentState.value, AnimState.paused);

      anim.play();
      expect(anim.currentState.value, AnimState.playing);
    });

    test('should call onBegin callback when starting', () {
      final value = animatableDouble(0.0);
      var beginCalled = false;

      final anim = animate()
          .to(value, 100.0)
          .onBegin(() {
            beginCalled = true;
          })
          .build();

      expect(beginCalled, false);

      anim.play();

      // Should be called on entry to playing from idle
      expect(beginCalled, true);
    });

    test('should track FSM state changes reactively', () {
      final value = animatableDouble(0.0);
      final states = <AnimState>[];

      final anim = animate()
          .to(value, 100.0)
          .build();

      // Track state changes
      effect(() {
        states.add(anim.currentState.value);
      });

      // Initial state
      expect(states, [AnimState.idle]);

      anim.play();
      expect(states.last, AnimState.playing);

      anim.pause();
      expect(states.last, AnimState.paused);

      anim.stop();
      expect(states.last, AnimState.idle);
    });

    test('should provide reactive progress computed', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      // Progress is a computed signal
      expect(anim.progress, isA<Computed<double>>());
      expect(anim.progress.value, 0.0);
    });

    test('should provide reactive currentLoop computed', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .withLoop(3)
          .build();

      // currentLoop is a computed signal
      expect(anim.currentLoop, isA<Computed<int>>());
      expect(anim.currentLoop.value, 0);
    });

    test('should handle seek() correctly', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.seek(0.5);

      expect(anim.progressValue, 0.5);
      expect(value.value, 50.0);
    });

    test('should clamp seek() progress to 0.0-1.0', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.seek(1.5);
      expect(anim.progressValue, 1.0);

      anim.seek(-0.5);
      expect(anim.progressValue, 0.0);
    });

    test('should dispose correctly', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      anim.play();
      anim.dispose();

      expect(anim.currentState.value, AnimState.idle);
    });

    test('should support autoplay', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .withAutoplay()
          .build();

      // Should start playing automatically
      expect(anim.currentState.value, AnimState.playing);
    });

    test('backward compatibility: state getter returns AnimationState', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      expect(anim.state, isA<AnimationState>());
      expect(anim.state, AnimationState.idle);

      anim.play();
      expect(anim.state, AnimationState.playing);
    });

    test('backward compatibility: progressValue getter', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .build();

      expect(anim.progressValue, isA<double>());
      expect(anim.progressValue, 0.0);
    });

    test('backward compatibility: currentLoopValue getter', () {
      final value = animatableDouble(0.0);

      final anim = animate()
          .to(value, 100.0)
          .withLoop(2)
          .build();

      expect(anim.currentLoopValue, isA<int>());
      expect(anim.currentLoopValue, 0);
    });
  });

  group('Animation FSM Transitions', () {
    test('valid transition: idle → playing', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      expect(anim.currentState.value, AnimState.idle);
      anim.play();
      expect(anim.currentState.value, AnimState.playing);
    });

    test('valid transition: playing → paused', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      anim.play();
      expect(anim.currentState.value, AnimState.playing);

      anim.pause();
      expect(anim.currentState.value, AnimState.paused);
    });

    test('valid transition: paused → playing', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      anim.play();
      anim.pause();
      expect(anim.currentState.value, AnimState.paused);

      anim.play();
      expect(anim.currentState.value, AnimState.playing);
    });

    test('valid transition: playing → idle (stop)', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      anim.play();
      anim.stop();
      expect(anim.currentState.value, AnimState.idle);
    });

    test('valid transition: paused → idle (stop)', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      anim.play();
      anim.pause();
      anim.stop();
      expect(anim.currentState.value, AnimState.idle);
    });

    test('valid transition: any → playing (restart)', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      // From idle
      anim.restart();
      expect(anim.currentState.value, AnimState.playing);

      // From paused
      anim.pause();
      anim.restart();
      expect(anim.currentState.value, AnimState.playing);
    });

    test('invalid transition: idle → paused (no effect)', () {
      final value = animatableDouble(0.0);
      final anim = animate().to(value, 100.0).build();

      anim.pause();
      expect(anim.currentState.value, AnimState.idle);
    });
  });
}

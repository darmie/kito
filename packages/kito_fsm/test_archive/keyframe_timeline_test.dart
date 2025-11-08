import 'package:flutter_test/flutter_test.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'package:kito/kito.dart';

/// Character animation states
enum CharacterState {
  idle,
  walking,
  jumping,
  landing,
  celebrating,
}

/// Character events
enum CharacterEvent {
  startWalk,
  stopWalk,
  jump,
  land,
  celebrate,
  celebrationComplete,
}

/// Character context with keyframe-based animations
class CharacterContext {
  final double xPosition;
  final double yPosition;
  final double scale;
  final double rotation;
  final AnimatableProperty<double>? xProp;
  final AnimatableProperty<double>? yProp;
  final AnimatableProperty<double>? scaleProp;
  final AnimatableProperty<double>? rotationProp;
  final Timeline? timeline;

  const CharacterContext({
    this.xPosition = 0.0,
    this.yPosition = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.xProp,
    this.yProp,
    this.scaleProp,
    this.rotationProp,
    this.timeline,
  });

  CharacterContext copyWith({
    double? xPosition,
    double? yPosition,
    double? scale,
    double? rotation,
    AnimatableProperty<double>? xProp,
    AnimatableProperty<double>? yProp,
    AnimatableProperty<double>? scaleProp,
    AnimatableProperty<double>? rotationProp,
    Timeline? timeline,
  }) {
    return CharacterContext(
      xPosition: xPosition ?? this.xPosition,
      yPosition: yPosition ?? this.yPosition,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      xProp: xProp ?? this.xProp,
      yProp: yProp ?? this.yProp,
      scaleProp: scaleProp ?? this.scaleProp,
      rotationProp: rotationProp ?? this.rotationProp,
      timeline: timeline,
    );
  }

  void dispose() {
    timeline?.dispose();
  }

  @override
  String toString() =>
      'CharacterContext(x: $xPosition, y: $yPosition, scale: $scale, rotation: $rotation)';
}

/// Actions with keyframe animations
class CharacterActions {
  /// Walking animation with keyframes for bobbing motion
  static CharacterContext startWalking(
    ActionContext<CharacterState, CharacterEvent, CharacterContext> actx,
  ) {
    actx.context.dispose();

    // Create animatable properties
    final xProp = animatableDouble(actx.context.xPosition);
    final yProp = animatableDouble(actx.context.yPosition);
    final scaleProp = animatableDouble(actx.context.scale);

    // Walking animation with keyframes for natural bobbing
    final walkAnimation = animate()
        .withKeyframes(yProp, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: -5.0, offset: 0.25, easing: Easing.easeInOutQuad),
          Keyframe(value: 0.0, offset: 0.5, easing: Easing.easeInOutQuad),
          Keyframe(value: -5.0, offset: 0.75, easing: Easing.easeInOutQuad),
          Keyframe(value: 0.0, offset: 1.0, easing: Easing.easeInOutQuad),
        ])
        .withKeyframes(scaleProp, [
          Keyframe(value: 1.0, offset: 0.0),
          Keyframe(value: 0.98, offset: 0.25),
          Keyframe(value: 1.0, offset: 0.5),
          Keyframe(value: 0.98, offset: 0.75),
          Keyframe(value: 1.0, offset: 1.0),
        ])
        .withDuration(800)
        .loopInfinitely()
        .withAutoplay()
        .build();

    return actx.context.copyWith(
      xProp: xProp,
      yProp: yProp,
      scaleProp: scaleProp,
    );
  }

  /// Jump animation with keyframe sequence
  static CharacterContext startJump(
    ActionContext<CharacterState, CharacterEvent, CharacterContext> actx,
  ) {
    actx.context.dispose();

    final yProp = animatableDouble(actx.context.yPosition);
    final scaleProp = animatableDouble(actx.context.scale);

    // Jump arc with keyframes
    final jumpAnimation = animate()
        .withKeyframes(yProp, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: -20.0, offset: 0.3, easing: Easing.easeOutQuad),
          Keyframe(value: -40.0, offset: 0.5, easing: Easing.easeInOutQuad),
          Keyframe(value: -20.0, offset: 0.7, easing: Easing.easeInQuad),
          Keyframe(value: 0.0, offset: 1.0, easing: Easing.easeInQuad),
        ])
        .withKeyframes(scaleProp, [
          Keyframe(value: 1.0, offset: 0.0),
          Keyframe(value: 1.1, offset: 0.5),
          Keyframe(value: 1.0, offset: 1.0),
        ])
        .withDuration(600)
        .onComplete(() {
          actx.emit(CharacterEvent.land);
        })
        .withAutoplay()
        .build();

    return actx.context.copyWith(
      yProp: yProp,
      scaleProp: scaleProp,
    );
  }

  /// Celebration with timeline (multiple coordinated animations)
  static CharacterContext startCelebration(
    ActionContext<CharacterState, CharacterEvent, CharacterContext> actx,
  ) {
    actx.context.dispose();

    final yProp = animatableDouble(actx.context.yPosition);
    final scaleProp = animatableDouble(actx.context.scale);
    final rotationProp = animatableDouble(actx.context.rotation);

    // Create timeline with multiple coordinated animations
    final timeline = Timeline();

    // Jump up animation (0-400ms)
    timeline.add(
      animate()
          .to(yProp, -30.0)
          .withDuration(400)
          .withEasing(Easing.easeOutQuad)
          .build(),
      offset: 0,
    );

    // Spin animation (100-500ms) - overlaps with jump
    timeline.add(
      animate()
          .to(rotationProp, 360.0)
          .withDuration(400)
          .withEasing(Easing.easeInOutQuad)
          .build(),
      offset: 100,
    );

    // Scale pulse (200-600ms)
    timeline.add(
      animate()
          .withKeyframes(scaleProp, [
            Keyframe(value: 1.0, offset: 0.0),
            Keyframe(value: 1.3, offset: 0.5, easing: Easing.easeOutQuad),
            Keyframe(value: 1.0, offset: 1.0, easing: Easing.easeInQuad),
          ])
          .withDuration(400)
          .build(),
      offset: 200,
    );

    // Land animation (500-700ms)
    timeline.add(
      animate()
          .to(yProp, 0.0)
          .withDuration(200)
          .withEasing(Easing.easeInQuad)
          .build(),
      offset: 500,
    );

    timeline.play();

    // Emit celebration complete after timeline duration
    Future.delayed(Duration(milliseconds: timeline.duration), () {
      actx.emit(CharacterEvent.celebrationComplete);
    });

    return actx.context.copyWith(
      yProp: yProp,
      scaleProp: scaleProp,
      rotationProp: rotationProp,
      timeline: timeline,
    );
  }

  /// Return to idle
  static CharacterContext returnToIdle(CharacterContext ctx) {
    ctx.dispose();
    return const CharacterContext();
  }
}

/// Character state machine with keyframe and timeline animations
class CharacterStateMachine extends KitoStateMachine<CharacterState,
    CharacterEvent, CharacterContext> {
  CharacterStateMachine({
    required CharacterContext context,
  }) : super(
          initial: CharacterState.idle,
          context: context,
          config: _buildConfig(),
        );

  static StateMachineConfig<CharacterState, CharacterEvent, CharacterContext>
      _buildConfig() {
    return StateMachineConfig(
      states: {
        CharacterState.idle: StateConfig(
          state: CharacterState.idle,
          transitions: {
            CharacterEvent.startWalk: TransitionConfig(
              target: CharacterState.walking,
              action: CharacterActions.startWalking,
            ),
            CharacterEvent.jump: TransitionConfig(
              target: CharacterState.jumping,
              action: CharacterActions.startJump,
            ),
            CharacterEvent.celebrate: TransitionConfig(
              target: CharacterState.celebrating,
              action: CharacterActions.startCelebration,
            ),
          },
        ),
        CharacterState.walking: StateConfig(
          state: CharacterState.walking,
          transitions: {
            CharacterEvent.stopWalk: TransitionConfig(
              target: CharacterState.idle,
              action: CharacterActions.returnToIdle,
            ),
            CharacterEvent.jump: TransitionConfig(
              target: CharacterState.jumping,
              action: CharacterActions.startJump,
            ),
          },
        ),
        CharacterState.jumping: StateConfig(
          state: CharacterState.jumping,
          transitions: {
            CharacterEvent.land: TransitionConfig(
              target: CharacterState.landing,
            ),
          },
        ),
        CharacterState.landing: StateConfig(
          state: CharacterState.landing,
          transient: TransientConfig(
            after: const Duration(milliseconds: 100),
            target: CharacterState.idle,
            action: CharacterActions.returnToIdle,
          ),
        ),
        CharacterState.celebrating: StateConfig(
          state: CharacterState.celebrating,
          transitions: {
            CharacterEvent.celebrationComplete: TransitionConfig(
              target: CharacterState.idle,
              action: CharacterActions.returnToIdle,
            ),
          },
        ),
      },
    );
  }

  @override
  void dispose() {
    context.dispose();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Keyframe and Timeline Integration', () {
    test('should integrate with keyframe animations', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      expect(machine.currentState.peek(), CharacterState.idle);

      // Trigger walking with keyframe animation
      machine.send(CharacterEvent.startWalk);

      // Verify state transitioned
      expect(machine.currentState.peek(), CharacterState.walking);

      // Verify animatable properties were created
      expect(machine.context.yProp, isNotNull);
      expect(machine.context.scaleProp, isNotNull);

      machine.dispose();
    });

    test('should handle jump animation with keyframes', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      machine.send(CharacterEvent.jump);

      expect(machine.currentState.peek(), CharacterState.jumping);
      expect(machine.context.yProp, isNotNull);
      expect(machine.context.scaleProp, isNotNull);

      machine.dispose();
    });

    test('should integrate with timeline for complex sequences', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      machine.send(CharacterEvent.celebrate);

      expect(machine.currentState.peek(), CharacterState.celebrating);

      // Verify timeline was created
      expect(machine.context.timeline, isNotNull);

      // Verify all animatable properties were created
      expect(machine.context.yProp, isNotNull);
      expect(machine.context.scaleProp, isNotNull);
      expect(machine.context.rotationProp, isNotNull);

      machine.dispose();
    });

    test('should transition between states with different animation types',
        () async {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      // Start with keyframe walking
      machine.send(CharacterEvent.startWalk);
      expect(machine.currentState.peek(), CharacterState.walking);

      await Future.delayed(const Duration(milliseconds: 50));

      // Jump (keyframe sequence)
      machine.send(CharacterEvent.jump);
      expect(machine.currentState.peek(), CharacterState.jumping);

      machine.dispose();
    });

    test('should dispose animations when changing states', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      machine.send(CharacterEvent.celebrate);
      final timeline = machine.context.timeline;
      expect(timeline, isNotNull);

      // Change state - should dispose previous animations
      machine.send(CharacterEvent.celebrationComplete);
      expect(machine.currentState.peek(), CharacterState.idle);

      machine.dispose();
    });

    test('should track transitions with different animation types', () async {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      // Walk (keyframes)
      machine.send(CharacterEvent.startWalk);
      await Future.delayed(const Duration(milliseconds: 10));

      // Jump (keyframe sequence)
      machine.send(CharacterEvent.jump);
      await Future.delayed(const Duration(milliseconds: 10));

      // Celebrate (timeline)
      // Note: Can't celebrate from jumping state in our config
      // but this demonstrates the pattern

      expect(machine.history.length, greaterThanOrEqualTo(2));

      machine.dispose();
    });

    test('mathematical verification: keyframe interpolation setup', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      machine.send(CharacterEvent.jump);

      // Verify animatable properties are initialized
      expect(machine.context.yProp, isNotNull);
      expect(machine.context.scaleProp, isNotNull);

      // Properties should start at initial values
      expect(machine.context.yProp!.value, 0.0);
      expect(machine.context.scaleProp!.value, 1.0);

      machine.dispose();
    });

    test('timeline coordination: multiple properties animated together', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      machine.send(CharacterEvent.celebrate);

      // Timeline should coordinate multiple properties
      expect(machine.context.yProp, isNotNull,
          reason: 'Y position should be animated');
      expect(machine.context.scaleProp, isNotNull,
          reason: 'Scale should be animated');
      expect(machine.context.rotationProp, isNotNull,
          reason: 'Rotation should be animated');

      expect(machine.context.timeline, isNotNull,
          reason: 'Timeline should coordinate all animations');

      machine.dispose();
    });

    test('state machine controls animation lifecycle', () async {
      final machine = CharacterStateMachine(
        context: const CharacterContext(),
      );

      // Start walking animation
      machine.send(CharacterEvent.startWalk);
      expect(machine.currentState.peek(), CharacterState.walking);
      final walkingProps = (
        yProp: machine.context.yProp,
        scaleProp: machine.context.scaleProp,
      );

      expect(walkingProps.yProp, isNotNull);

      await Future.delayed(const Duration(milliseconds: 10));

      // Stop walking - should clean up animation
      machine.send(CharacterEvent.stopWalk);
      expect(machine.currentState.peek(), CharacterState.idle);

      // Context should be reset
      expect(machine.context.yProp, isNull);

      machine.dispose();
    });

    test('context preservation across transitions', () {
      final machine = CharacterStateMachine(
        context: const CharacterContext(xPosition: 100.0, yPosition: 50.0),
      );

      expect(machine.context.xPosition, 100.0);
      expect(machine.context.yPosition, 50.0);

      machine.send(CharacterEvent.startWalk);

      // Initial position values should be preserved when creating animations
      expect(machine.context.xPosition, 100.0);

      machine.dispose();
    });
  });
}

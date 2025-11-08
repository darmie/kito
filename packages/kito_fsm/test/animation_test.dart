import 'package:flutter_test/flutter_test.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'package:kito/kito.dart';
import 'package:kito/src/types/types.dart' as kito_types;

/// Button states
enum ButtonState {
  idle,
  hovering,
  pressing,
  animatingIn,
  animatingOut,
  disabled,
}

/// Button events
enum ButtonEvent {
  hoverStart,
  hoverEnd,
  pressStart,
  pressEnd,
  enable,
  disable,
  animationComplete,
}

/// Animation context with animated properties
class ButtonContext {
  final double scale;
  final double opacity;
  final bool isEnabled;
  final KitoAnimation? currentAnimation;

  const ButtonContext({
    this.scale = 1.0,
    this.opacity = 1.0,
    this.isEnabled = true,
    this.currentAnimation,
  });

  ButtonContext copyWith({
    double? scale,
    double? opacity,
    bool? isEnabled,
    KitoAnimation? currentAnimation,
  }) {
    return ButtonContext(
      scale: scale ?? this.scale,
      opacity: opacity ?? this.opacity,
      isEnabled: isEnabled ?? this.isEnabled,
      currentAnimation: currentAnimation,
    );
  }

  void disposeAnimation() {
    currentAnimation?.dispose();
  }

  @override
  String toString() =>
      'ButtonContext(scale: $scale, opacity: $opacity, enabled: $isEnabled)';
}

/// Guards
class ButtonGuards {
  static bool isEnabled(ButtonContext ctx) => ctx.isEnabled;
  static bool isDisabled(ButtonContext ctx) => !ctx.isEnabled;
}

/// Actions with animations
class ButtonActions {
  /// Start hover animation - scale up to 1.1
  static ButtonContext startHoverAnimation(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx,
  ) {
    // Dispose previous animation if any
    actx.context.disposeAnimation();

    // Create animatable property starting from current scale
    final scaleProperty = animatableDouble(actx.context.scale);

    // Create animation
    final animation = animate()
        .to(scaleProperty, 1.1)
        .withDuration(200)
        .withEasing(Easing.easeOutQuad)
        .onComplete(() {
          // Animation completed, stay in hover state
        })
        .build();

    animation.play();

    return actx.context.copyWith(
      scale: scaleProperty.value,
      currentAnimation: animation,
    );
  }

  /// Start press animation - scale down to 0.95
  static ButtonContext startPressAnimation(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx,
  ) {
    actx.context.disposeAnimation();

    final scaleProperty = animatableDouble(actx.context.scale);

    final animation = animate()
        .to(scaleProperty, 0.95)
        .withDuration(100)
        .withEasing(Easing.easeInQuad)
        .build();

    animation.play();

    return actx.context.copyWith(
      scale: scaleProperty.value,
      currentAnimation: animation,
    );
  }

  /// Return to idle scale (1.0)
  static ButtonContext returnToIdle(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx,
  ) {
    actx.context.disposeAnimation();

    final scaleProperty = animatableDouble(actx.context.scale);

    final animation = animate()
        .to(scaleProperty, 1.0)
        .withDuration(150)
        .withEasing(Easing.easeOutQuad)
        .build();

    animation.play();

    return actx.context.copyWith(
      scale: scaleProperty.value,
      currentAnimation: animation,
    );
  }

  /// Fade out animation when disabling
  static ButtonContext startFadeOut(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx,
  ) {
    actx.context.disposeAnimation();

    final opacityProperty = animatableDouble(actx.context.opacity);

    final animation = animate()
        .to(opacityProperty, 0.3)
        .withDuration(300)
        .withEasing(Easing.easeInOutQuad)
        .onComplete(() {
          // Emit event when animation completes
          actx.emit(ButtonEvent.animationComplete);
        })
        .build();

    animation.play();

    return actx.context.copyWith(
      opacity: opacityProperty.value,
      isEnabled: false,
      currentAnimation: animation,
    );
  }

  /// Fade in animation when enabling
  static ButtonContext startFadeIn(
    ActionContext<ButtonState, ButtonEvent, ButtonContext> actx,
  ) {
    actx.context.disposeAnimation();

    final opacityProperty = animatableDouble(actx.context.opacity);

    final animation = animate()
        .to(opacityProperty, 1.0)
        .withDuration(300)
        .withEasing(Easing.easeInOutQuad)
        .onComplete(() {
          actx.emit(ButtonEvent.animationComplete);
        })
        .build();

    animation.play();

    return actx.context.copyWith(
      opacity: opacityProperty.value,
      isEnabled: true,
      currentAnimation: animation,
    );
  }
}

/// Button state machine with animations
class ButtonStateMachine
    extends KitoStateMachine<ButtonState, ButtonEvent, ButtonContext> {
  ButtonStateMachine({
    required ButtonContext context,
  }) : super(
          initial: ButtonState.idle,
          context: context,
          config: _buildConfig(),
        );

  static StateMachineConfig<ButtonState, ButtonEvent, ButtonContext>
      _buildConfig() {
    return StateMachineConfig(
      states: {
        ButtonState.idle: StateConfig(
          state: ButtonState.idle,
          transitions: {
            ButtonEvent.hoverStart: TransitionConfig(
              target: ButtonState.hovering,
              guard: ButtonGuards.isEnabled,
              action: ButtonActions.startHoverAnimation,
            ),
            ButtonEvent.disable: TransitionConfig(
              target: ButtonState.animatingOut,
              action: ButtonActions.startFadeOut,
            ),
          },
        ),
        ButtonState.hovering: StateConfig(
          state: ButtonState.hovering,
          transitions: {
            ButtonEvent.hoverEnd: TransitionConfig(
              target: ButtonState.idle,
              action: ButtonActions.returnToIdle,
            ),
            ButtonEvent.pressStart: TransitionConfig(
              target: ButtonState.pressing,
              action: ButtonActions.startPressAnimation,
            ),
          },
        ),
        ButtonState.pressing: StateConfig(
          state: ButtonState.pressing,
          transitions: {
            ButtonEvent.pressEnd: TransitionConfig(
              target: ButtonState.hovering,
              action: ButtonActions.startHoverAnimation,
            ),
          },
        ),
        ButtonState.animatingOut: StateConfig(
          state: ButtonState.animatingOut,
          transitions: {
            ButtonEvent.animationComplete: TransitionConfig(
              target: ButtonState.disabled,
            ),
          },
        ),
        ButtonState.animatingIn: StateConfig(
          state: ButtonState.animatingIn,
          transitions: {
            ButtonEvent.animationComplete: TransitionConfig(
              target: ButtonState.idle,
            ),
          },
        ),
        ButtonState.disabled: StateConfig(
          state: ButtonState.disabled,
          transitions: {
            ButtonEvent.enable: TransitionConfig(
              target: ButtonState.animatingIn,
              action: ButtonActions.startFadeIn,
            ),
          },
        ),
      },
    );
  }

  @override
  void dispose() {
    context.disposeAnimation();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Animated Button State Machine', () {
    test('should start in idle state', () {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      expect(machine.currentState.peek(), ButtonState.idle);
      expect(machine.context.scale, 1.0);
      expect(machine.context.opacity, 1.0);

      machine.dispose();
    });

    test('should animate scale on hover', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.hoverStart);

      // Wait for transition to complete
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), ButtonState.hovering);
      expect(machine.context.currentAnimation, isNotNull);

      // Animation should be playing
      final animation = machine.context.currentAnimation!;
      expect(animation.state, kito_types.AnimationState.playing);

      machine.dispose();
    });

    test('should animate scale on press', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      // First hover
      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      // Then press
      machine.send(ButtonEvent.pressStart);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), ButtonState.pressing);
      expect(machine.context.currentAnimation, isNotNull);

      machine.dispose();
    });

    test('should return to idle from hovering', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      machine.send(ButtonEvent.hoverEnd);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), ButtonState.idle);

      machine.dispose();
    });

    test('should animate opacity when disabling', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.disable);

      // Wait for transition
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), ButtonState.animatingOut);
      expect(machine.context.isEnabled, false);

      machine.dispose();
    });

    test('should complete disable animation and reach disabled state',
        () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.disable);

      // Wait for animation to complete (300ms + buffer)
      await Future.delayed(const Duration(milliseconds: 350));

      expect(machine.currentState.peek(), ButtonState.disabled);
      expect(machine.context.isEnabled, false);

      machine.dispose();
    });

    test('should animate back in when enabling', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(opacity: 0.3, isEnabled: false),
      );

      // Manually set to disabled state
      machine.currentState.value = ButtonState.disabled;

      machine.send(ButtonEvent.enable);

      // Wait for transition
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.currentState.peek(), ButtonState.animatingIn);

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 350));

      expect(machine.currentState.peek(), ButtonState.idle);
      expect(machine.context.isEnabled, true);

      machine.dispose();
    });

    test('should block hover when disabled', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(isEnabled: false),
      );

      machine.currentState.value = ButtonState.disabled;

      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      // Should stay disabled (guard blocked)
      expect(machine.currentState.peek(), ButtonState.disabled);

      machine.dispose();
    });

    test('should track multiple state changes with animations', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      // Hover
      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 50));

      // Press
      machine.send(ButtonEvent.pressStart);
      await Future.delayed(const Duration(milliseconds: 50));

      // Release
      machine.send(ButtonEvent.pressEnd);
      await Future.delayed(const Duration(milliseconds: 50));

      // End hover
      machine.send(ButtonEvent.hoverEnd);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(machine.history.length, greaterThanOrEqualTo(4));

      machine.dispose();
    });

    test('should dispose animations on state machine disposal', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      final animation = machine.context.currentAnimation;
      expect(animation, isNotNull);
      expect(animation!.state, kito_types.AnimationState.playing);

      machine.dispose();

      // Animation should be disposed (state should be idle after dispose)
      expect(animation.state, kito_types.AnimationState.idle);
    });

    test('should emit animationComplete event after fade out', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      final states = <ButtonState>[];
      machine.changes.listen((change) {
        states.add(change.to);
      });

      machine.send(ButtonEvent.disable);

      // Wait for full animation cycle
      await Future.delayed(const Duration(milliseconds: 350));

      // Should have transitioned: idle -> animatingOut -> disabled
      expect(states, contains(ButtonState.animatingOut));
      expect(states, contains(ButtonState.disabled));
      expect(machine.currentState.peek(), ButtonState.disabled);

      machine.dispose();
    });

    test('should handle rapid state changes gracefully', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      // Rapid fire events
      machine.send(ButtonEvent.hoverStart);
      machine.send(ButtonEvent.hoverEnd);
      machine.send(ButtonEvent.hoverStart);
      machine.send(ButtonEvent.pressStart);
      machine.send(ButtonEvent.pressEnd);

      await Future.delayed(const Duration(milliseconds: 100));

      // Should end in hovering state (last valid transition)
      expect(machine.currentState.peek(), ButtonState.hovering);

      machine.dispose();
    });

    test('mathematical verification: animation progress calculation', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.disable);
      await Future.delayed(const Duration(milliseconds: 10));

      final animation = machine.context.currentAnimation!;

      // Wait for 150ms (half of 300ms duration)
      await Future.delayed(const Duration(milliseconds: 150));

      // Progress should be approximately 0.5 (50%)
      expect(animation.progress, greaterThan(0.4));
      expect(animation.progress, lessThan(0.6));

      machine.dispose();
    });

    test('mathematical verification: easing function application', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(),
      );

      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      final animation = machine.context.currentAnimation!;

      // Easing.easeOutQuad should make early progress faster
      await Future.delayed(const Duration(milliseconds: 50));
      final earlyProgress = animation.progress;

      // At 50ms out of 200ms (25% time), easeOutQuad should give more than 25% progress
      // easeOutQuad(0.25) ≈ 0.4375
      expect(earlyProgress, greaterThan(0.25));

      machine.dispose();
    });

    test('context values drive animation targets correctly', () async {
      final machine = ButtonStateMachine(
        context: const ButtonContext(scale: 0.8),
      );

      // Starting scale is 0.8, should animate to 1.1 on hover
      machine.send(ButtonEvent.hoverStart);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(machine.context.currentAnimation, isNotNull);

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 250));

      // Scale should be updating during animation
      expect(machine.context.scale, greaterThan(0.8));

      machine.dispose();
    });
  });
}

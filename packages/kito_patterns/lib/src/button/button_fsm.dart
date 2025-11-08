import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Button states
enum ButtonState {
  idle,       // Normal state
  hover,      // Mouse over (web/desktop)
  pressed,    // Being pressed
  disabled,   // Cannot interact
  loading,    // Async operation in progress
}

/// Button events
enum ButtonEvent {
  hoverEnter,  // Mouse enters
  hoverExit,   // Mouse exits
  pressDown,   // Touch/click down
  pressUp,     // Touch/click up
  disable,     // Disable button
  enable,      // Enable button
  startLoading,// Start loading state
  stopLoading, // Stop loading state
}

/// Button animation configuration
class ButtonAnimationConfig {
  /// Scale when pressed
  final double pressedScale;

  /// Scale when hovered
  final double hoverScale;

  /// Animation duration (ms)
  final int duration;

  /// Animation easing
  final EasingFunction easing;

  /// Opacity when disabled
  final double disabledOpacity;

  const ButtonAnimationConfig({
    this.pressedScale = 0.95,
    this.hoverScale = 1.05,
    this.duration = 150,
    this.easing = Easing.easeOutCubic,
    this.disabledOpacity = 0.5,
  });

  /// Subtle animation
  static const ButtonAnimationConfig subtle = ButtonAnimationConfig(
    pressedScale: 0.98,
    hoverScale: 1.02,
    duration: 100,
  );

  /// Bouncy animation
  static const ButtonAnimationConfig bouncy = ButtonAnimationConfig(
    pressedScale: 0.9,
    hoverScale: 1.1,
    duration: 200,
    easing: Easing.easeOutBack,
  );

  /// No hover effect (mobile-first)
  static const ButtonAnimationConfig mobile = ButtonAnimationConfig(
    hoverScale: 1.0,
    pressedScale: 0.95,
  );
}

/// Button context
class ButtonContext {
  final ButtonAnimationConfig config;

  // Animation properties
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> elevation;

  KitoAnimation? currentAnimation;
  VoidCallback? onTap;
  bool canInteract = true;

  ButtonContext({
    required this.config,
    this.onTap,
  })  : scale = animatableDouble(1.0),
        opacity = animatableDouble(1.0),
        elevation = animatableDouble(2.0);
}

/// Button state machine
class ButtonStateMachine extends KitoStateMachine<ButtonState, ButtonEvent, ButtonContext> {
  ButtonStateMachine(ButtonContext context)
      : super(
          initial: ButtonState.idle,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<ButtonState, StateConfig<ButtonState, ButtonEvent, ButtonContext>> _buildStates() {
    return {
      ButtonState.idle: StateConfig(
        state: ButtonState.idle,
        transitions: {
          ButtonEvent.hoverEnter: TransitionConfig(
            target: ButtonState.hover,
            action: (ctx) {
              _animateToHover(ctx);
              return ctx;
            },
          ),
          ButtonEvent.pressDown: TransitionConfig(
            target: ButtonState.pressed,
            action: (ctx) {
              _animateToPressed(ctx);
              return ctx;
            },
          ),
          ButtonEvent.disable: TransitionConfig(
            target: ButtonState.disabled,
            action: (ctx) {
              _animateToDisabled(ctx);
              return ctx;
            },
          ),
          ButtonEvent.startLoading: TransitionConfig(
            target: ButtonState.loading,
            action: (ctx) {
              _animateToLoading(ctx);
              return ctx;
            },
          ),
        },
      ),

      ButtonState.hover: StateConfig(
        state: ButtonState.hover,
        transitions: {
          ButtonEvent.hoverExit: TransitionConfig(
            target: ButtonState.idle,
            action: (ctx) {
              _animateToIdle(ctx);
              return ctx;
            },
          ),
          ButtonEvent.pressDown: TransitionConfig(
            target: ButtonState.pressed,
            action: (ctx) {
              _animateToPressed(ctx);
              return ctx;
            },
          ),
          ButtonEvent.disable: TransitionConfig(
            target: ButtonState.disabled,
            action: (ctx) {
              _animateToDisabled(ctx);
              return ctx;
            },
          ),
        },
      ),

      ButtonState.pressed: StateConfig(
        state: ButtonState.pressed,
        transitions: {
          ButtonEvent.pressUp: TransitionConfig(
            target: ButtonState.idle,
            action: (ctx) {
              _animateToIdle(ctx);
              ctx.onTap?.call();
              return ctx;
            },
          ),
        },
      ),

      ButtonState.disabled: StateConfig(
        state: ButtonState.disabled,
        transitions: {
          ButtonEvent.enable: TransitionConfig(
            target: ButtonState.idle,
            action: (ctx) {
              _animateToIdle(ctx);
              return ctx;
            },
          ),
        },
      ),

      ButtonState.loading: StateConfig(
        state: ButtonState.loading,
        transitions: {
          ButtonEvent.stopLoading: TransitionConfig(
            target: ButtonState.idle,
            action: (ctx) {
              _animateToIdle(ctx);
              return ctx;
            },
          ),
        },
      ),
    };
  }

  static void _animateToIdle(ButtonContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.scale, 1.0)
        .to(ctx.opacity, 1.0)
        .to(ctx.elevation, 2.0)
        .withDuration(ctx.config.duration)
        .withEasing(ctx.config.easing)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateToHover(ButtonContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.scale, ctx.config.hoverScale)
        .to(ctx.elevation, 4.0)
        .withDuration(ctx.config.duration)
        .withEasing(ctx.config.easing)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateToPressed(ButtonContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.scale, ctx.config.pressedScale)
        .to(ctx.elevation, 1.0)
        .withDuration(ctx.config.duration ~/ 2) // Faster on press
        .withEasing(Easing.easeInCubic)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateToDisabled(ButtonContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.opacity, ctx.config.disabledOpacity)
        .to(ctx.scale, 1.0)
        .to(ctx.elevation, 0.0)
        .withDuration(ctx.config.duration)
        .withEasing(ctx.config.easing)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateToLoading(ButtonContext ctx) {
    ctx.currentAnimation?.stop();
    // Loading state: pulse animation
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 0.7)
        .to(ctx.scale, 0.98)
        .withDuration(ctx.config.duration)
        .withEasing(ctx.config.easing)
        .build();
    ctx.currentAnimation!.play();
  }
}

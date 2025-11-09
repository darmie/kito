import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Modal/Dialog states
enum ModalState {
  hidden, // Modal is not visible
  showing, // Modal is appearing
  visible, // Modal is fully visible
  hiding, // Modal is disappearing
}

/// Modal events
enum ModalEvent {
  show, // Show modal
  hide, // Hide modal
  complete, // Animation complete (internal)
}

/// Modal animation type
enum ModalAnimationType {
  fade, // Simple fade in/out
  scale, // Scale from center
  slideUp, // Slide up from bottom
  slideDown, // Slide down from top
  slideLeft, // Slide in from left
  slideRight, // Slide in from right
  bounce, // Bounce in
  zoom, // Zoom in from background
}

/// Modal animation configuration
class ModalAnimationConfig {
  /// Animation type
  final ModalAnimationType type;

  /// Show duration (ms)
  final int showDuration;

  /// Hide duration (ms)
  final int hideDuration;

  /// Show easing
  final EasingFunction showEasing;

  /// Hide easing
  final EasingFunction hideEasing;

  /// Whether to animate backdrop
  final bool animateBackdrop;

  /// Backdrop opacity when visible
  final double backdropOpacity;

  /// Initial scale (for scale animation)
  final double initialScale;

  /// Slide distance (for slide animations)
  final double slideDistance;

  const ModalAnimationConfig({
    this.type = ModalAnimationType.fade,
    this.showDuration = 300,
    this.hideDuration = 200,
    this.showEasing = Easing.easeOutCubic,
    this.hideEasing = Easing.easeInCubic,
    this.animateBackdrop = true,
    this.backdropOpacity = 0.6,
    this.initialScale = 0.7,
    this.slideDistance = 100.0,
  });

  /// Fade animation
  static const ModalAnimationConfig fade = ModalAnimationConfig(
    type: ModalAnimationType.fade,
    initialScale: 1.0,  // No scaling for fade
  );

  /// Scale from center
  static const ModalAnimationConfig scale = ModalAnimationConfig(
    type: ModalAnimationType.scale,
    showEasing: Easing.easeOutBack,
  );

  /// Slide up (bottom sheet style)
  static const ModalAnimationConfig slideUp = ModalAnimationConfig(
    type: ModalAnimationType.slideUp,
    showEasing: Easing.easeOutCubic,
    initialScale: 1.0,  // No scaling for slide
  );

  /// Slide down (top sheet style)
  static const ModalAnimationConfig slideDown = ModalAnimationConfig(
    type: ModalAnimationType.slideDown,
    showEasing: Easing.easeOutCubic,
    initialScale: 1.0,  // No scaling for slide
  );

  /// Bounce in
  static const ModalAnimationConfig bounce = ModalAnimationConfig(
    type: ModalAnimationType.bounce,
    showDuration: 500,
    showEasing: Easing.easeOutBounce,
  );
}

/// Modal context
class ModalContext {
  final ModalAnimationConfig config;

  // Animation properties
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> offsetX;
  final AnimatableProperty<double> offsetY;
  final AnimatableProperty<double> backdropOpacity;
  final AnimatableProperty<double> rotation;

  KitoAnimation? currentAnimation;
  VoidCallback? onShow;
  VoidCallback? onHide;

  // Reference to FSM for sending complete events
  ModalStateMachine? fsm;

  ModalContext({
    required this.config,
    this.onShow,
    this.onHide,
  })  : opacity = animatableDouble(0.0),
        scale = animatableDouble(config.initialScale),
        offsetX = animatableDouble(0.0),
        offsetY = animatableDouble(_getInitialOffsetY(config)),
        backdropOpacity = animatableDouble(0.0),
        rotation = animatableDouble(0.0);

  static double _getInitialOffsetY(ModalAnimationConfig config) {
    switch (config.type) {
      case ModalAnimationType.slideUp:
        return config.slideDistance;
      case ModalAnimationType.slideDown:
        return -config.slideDistance;
      default:
        return 0.0;
    }
  }
}

/// Modal state machine
class ModalStateMachine
    extends KitoStateMachine<ModalState, ModalEvent, ModalContext> {
  ModalStateMachine(ModalContext context)
      : super(
          initial: ModalState.hidden,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        ) {
    // Store reference to FSM in context
    context.fsm = this;
  }

  static Map<ModalState, StateConfig<ModalState, ModalEvent, ModalContext>>
      _buildStates() {
    return {
      ModalState.hidden: StateConfig(
        state: ModalState.hidden,
        transitions: {
          ModalEvent.show: TransitionConfig(
            target: ModalState.showing,
            action: (ctx) {
              _animateShow(ctx);
              return ctx;
            },
          ),
        },
      ),
      ModalState.showing: StateConfig(
        state: ModalState.showing,
        transitions: {
          ModalEvent.complete: TransitionConfig(
            target: ModalState.visible,
            action: (ctx) {
              ctx.onShow?.call();
              return ctx;
            },
          ),
          ModalEvent.hide: TransitionConfig(
            target: ModalState.hiding,
            action: (ctx) {
              _animateHide(ctx);
              return ctx;
            },
          ),
        },
      ),
      ModalState.visible: StateConfig(
        state: ModalState.visible,
        transitions: {
          ModalEvent.hide: TransitionConfig(
            target: ModalState.hiding,
            action: (ctx) {
              _animateHide(ctx);
              return ctx;
            },
          ),
        },
      ),
      ModalState.hiding: StateConfig(
        state: ModalState.hiding,
        transitions: {
          ModalEvent.complete: TransitionConfig(
            target: ModalState.hidden,
            action: (ctx) {
              ctx.onHide?.call();
              return ctx;
            },
          ),
        },
      ),
    };
  }

  static void _animateShow(ModalContext ctx) {
    ctx.currentAnimation?.stop();

    switch (ctx.config.type) {
      case ModalAnimationType.fade:
        _animateFadeIn(ctx);
        break;
      case ModalAnimationType.scale:
        _animateScaleIn(ctx);
        break;
      case ModalAnimationType.slideUp:
      case ModalAnimationType.slideDown:
        _animateSlideIn(ctx);
        break;
      case ModalAnimationType.bounce:
        _animateBounceIn(ctx);
        break;
      case ModalAnimationType.zoom:
        _animateZoomIn(ctx);
        break;
      default:
        _animateFadeIn(ctx);
    }
  }

  static void _animateHide(ModalContext ctx) {
    ctx.currentAnimation?.stop();

    // Most animations reverse for hiding
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 0.0)
        .to(ctx.scale, ctx.config.initialScale)
        .to(
            ctx.offsetY,
            ctx.config.type == ModalAnimationType.slideUp
                ? ctx.config.slideDistance
                : 0.0)
        .to(ctx.backdropOpacity, 0.0)
        .withDuration(ctx.config.hideDuration)
        .withEasing(ctx.config.hideEasing)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateFadeIn(ModalContext ctx) {
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .to(ctx.scale, 1.0)  // Animate scale to 1.0 for pure fade
        .to(ctx.backdropOpacity, ctx.config.backdropOpacity)
        .withDuration(ctx.config.showDuration)
        .withEasing(ctx.config.showEasing)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateScaleIn(ModalContext ctx) {
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .to(ctx.scale, 1.0)
        .to(ctx.backdropOpacity, ctx.config.backdropOpacity)
        .withDuration(ctx.config.showDuration)
        .withEasing(ctx.config.showEasing)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateSlideIn(ModalContext ctx) {
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .to(ctx.scale, 1.0)  // Animate scale to 1.0 for pure slide
        .to(ctx.offsetY, 0.0)
        .to(ctx.backdropOpacity, ctx.config.backdropOpacity)
        .withDuration(ctx.config.showDuration)
        .withEasing(ctx.config.showEasing)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateBounceIn(ModalContext ctx) {
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .to(ctx.scale, 1.0)
        .to(ctx.backdropOpacity, ctx.config.backdropOpacity)
        .withDuration(ctx.config.showDuration)
        .withEasing(Easing.easeOutBounce)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateZoomIn(ModalContext ctx) {
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .withKeyframes(ctx.scale, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: 1.1, offset: 0.7, easing: Easing.easeOutCubic),
          Keyframe(value: 1.0, offset: 1.0, easing: Easing.easeInOutCubic),
        ])
        .to(ctx.backdropOpacity, ctx.config.backdropOpacity)
        .withDuration(ctx.config.showDuration)
        .onComplete(() {
          ctx.fsm?.send(ModalEvent.complete);
        })
        .build();

    ctx.currentAnimation!.play();
  }
}

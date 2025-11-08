import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Drawer states
enum DrawerState {
  closed,    // Drawer is closed
  opening,   // Drawer is opening
  open,      // Drawer is fully open
  closing,   // Drawer is closing
}

/// Drawer events
enum DrawerEvent {
  open,      // Open drawer
  close,     // Close drawer
  toggle,    // Toggle drawer state
  complete,  // Animation complete (internal)
}

/// Drawer animation configuration
class DrawerAnimationConfig {
  /// Opening duration (ms)
  final int openDuration;

  /// Closing duration (ms)
  final int closeDuration;

  /// Easing for opening
  final EasingFunction openEasing;

  /// Easing for closing
  final EasingFunction closeEasing;

  /// Drawer width (0.0 to 1.0 of screen width)
  final double width;

  /// Whether to animate overlay
  final bool animateOverlay;

  /// Overlay opacity when open
  final double overlayOpacity;

  const DrawerAnimationConfig({
    this.openDuration = 300,
    this.closeDuration = 250,
    this.openEasing = Easing.easeOutCubic,
    this.closeEasing = Easing.easeInCubic,
    this.width = 0.75,
    this.animateOverlay = true,
    this.overlayOpacity = 0.5,
  });

  /// Smooth, elegant animation
  static const DrawerAnimationConfig smooth = DrawerAnimationConfig(
    openDuration: 350,
    closeDuration: 300,
    openEasing: Easing.easeOutCubic,
  );

  /// Fast, snappy animation
  static const DrawerAnimationConfig snappy = DrawerAnimationConfig(
    openDuration: 200,
    closeDuration: 150,
    openEasing: Easing.easeOut,
  );

  /// Bouncy animation
  static const DrawerAnimationConfig bouncy = DrawerAnimationConfig(
    openDuration: 400,
    closeDuration: 250,
    openEasing: Easing.easeOutBack,
  );
}

/// Drawer context
class DrawerContext {
  final DrawerAnimationConfig config;

  // Animation properties
  final AnimatableProperty<double> position;    // 0.0 (closed) to 1.0 (open)
  final AnimatableProperty<double> overlayOpacity;
  final AnimatableProperty<double> contentScale; // Scale content when drawer opens

  KitoAnimation? currentAnimation;
  VoidCallback? onOpen;
  VoidCallback? onClose;

  DrawerContext({
    required this.config,
    this.onOpen,
    this.onClose,
  })  : position = animatableDouble(0.0),
        overlayOpacity = animatableDouble(0.0),
        contentScale = animatableDouble(1.0);
}

/// Drawer state machine
class DrawerStateMachine extends KitoStateMachine<DrawerState, DrawerEvent, DrawerContext> {
  DrawerStateMachine(DrawerContext context)
      : super(
          initial: DrawerState.closed,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<DrawerState, StateConfig<DrawerState, DrawerEvent, DrawerContext>> _buildStates() {
    return {
      DrawerState.closed: StateConfig(
        state: DrawerState.closed,
        transitions: {
          DrawerEvent.open: TransitionConfig(
            target: DrawerState.opening,
            action: (ctx) {
              _animateOpen(ctx);
              return ctx;
            },
          ),
          DrawerEvent.toggle: TransitionConfig(
            target: DrawerState.opening,
            action: (ctx) {
              _animateOpen(ctx);
              return ctx;
            },
          ),
        },
      ),

      DrawerState.opening: StateConfig(
        state: DrawerState.opening,
        transitions: {
          DrawerEvent.complete: TransitionConfig(
            target: DrawerState.open,
            action: (ctx) {
              ctx.onOpen?.call();
              return ctx;
            },
          ),
          DrawerEvent.close: TransitionConfig(
            target: DrawerState.closing,
            action: (ctx) {
              _animateClose(ctx);
              return ctx;
            },
          ),
        },
      ),

      DrawerState.open: StateConfig(
        state: DrawerState.open,
        transitions: {
          DrawerEvent.close: TransitionConfig(
            target: DrawerState.closing,
            action: (ctx) {
              _animateClose(ctx);
              return ctx;
            },
          ),
          DrawerEvent.toggle: TransitionConfig(
            target: DrawerState.closing,
            action: (ctx) {
              _animateClose(ctx);
              return ctx;
            },
          ),
        },
      ),

      DrawerState.closing: StateConfig(
        state: DrawerState.closing,
        transitions: {
          DrawerEvent.complete: TransitionConfig(
            target: DrawerState.closed,
            action: (ctx) {
              ctx.onClose?.call();
              return ctx;
            },
          ),
          DrawerEvent.open: TransitionConfig(
            target: DrawerState.opening,
            action: (ctx) {
              _animateOpen(ctx);
              return ctx;
            },
          ),
        },
      ),
    };
  }

  static void _animateOpen(DrawerContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.position, 1.0)
        .to(ctx.overlayOpacity, ctx.config.overlayOpacity)
        .to(ctx.contentScale, 0.95) // Slightly scale content
        .withDuration(ctx.config.openDuration)
        .withEasing(ctx.config.openEasing)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateClose(DrawerContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.position, 0.0)
        .to(ctx.overlayOpacity, 0.0)
        .to(ctx.contentScale, 1.0)
        .withDuration(ctx.config.closeDuration)
        .withEasing(ctx.config.closeEasing)
        .build();
    ctx.currentAnimation!.play();
  }
}

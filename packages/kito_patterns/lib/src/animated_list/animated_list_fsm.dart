import 'package:flutter/widgets.dart';
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// States for animated list items
enum ListItemState {
  hidden,      // Not visible
  entering,    // Animating in
  visible,     // Fully visible
  exiting,     // Animating out
  removed,     // Removed from list
}

/// Events for animated list items
enum ListItemEvent {
  insert,      // Insert item
  show,        // Show item (after insert animation)
  remove,      // Remove item
  complete,    // Animation complete (internal)
}

/// Configuration for list item animations
class ListItemAnimationConfig {
  /// Animation for entering items
  final AnimationBuilder Function()? enterAnimation;

  /// Animation for exiting items
  final AnimationBuilder Function()? exitAnimation;

  /// Duration for enter animation (ms)
  final int enterDuration;

  /// Duration for exit animation (ms)
  final int exitDuration;

  /// Easing for enter animation
  final EasingFunction enterEasing;

  /// Easing for exit animation
  final EasingFunction exitEasing;

  /// Stagger delay between items (ms)
  final int staggerDelay;

  const ListItemAnimationConfig({
    this.enterAnimation,
    this.exitAnimation,
    this.enterDuration = 300,
    this.exitDuration = 200,
    this.enterEasing = Easing.easeOutCubic,
    this.exitEasing = Easing.easeInCubic,
    this.staggerDelay = 50,
  });

  /// Fade in animation
  static ListItemAnimationConfig fadeIn({
    int duration = 300,
    EasingFunction easing = Easing.easeOut,
  }) {
    return ListItemAnimationConfig(
      enterDuration: duration,
      enterEasing: easing,
    );
  }

  /// Slide in from bottom
  static ListItemAnimationConfig slideUp({
    int duration = 300,
    double distance = 50.0,
    EasingFunction easing = Easing.easeOutCubic,
  }) {
    return ListItemAnimationConfig(
      enterDuration: duration,
      enterEasing: easing,
    );
  }

  /// Scale in
  static ListItemAnimationConfig scaleIn({
    int duration = 300,
    EasingFunction easing = Easing.easeOutBack,
  }) {
    return ListItemAnimationConfig(
      enterDuration: duration,
      enterEasing: easing,
    );
  }

  /// Bounce in
  static ListItemAnimationConfig bounceIn({
    int duration = 500,
  }) {
    return ListItemAnimationConfig(
      enterDuration: duration,
      enterEasing: Easing.easeOutBounce,
    );
  }
}

/// Context for animated list item
class ListItemContext {
  final int index;
  final ListItemAnimationConfig config;

  // Animation properties
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> offsetY;
  final AnimatableProperty<double> scale;
  final AnimatableProperty<double> rotation;

  KitoAnimation? currentAnimation;
  bool isAnimating = false;

  ListItemContext({
    required this.index,
    required this.config,
  })  : opacity = animatableDouble(0.0),
        offsetY = animatableDouble(50.0),
        scale = animatableDouble(0.0),
        rotation = animatableDouble(0.0);
}

/// State machine for animated list items
class ListItemStateMachine extends KitoStateMachine<ListItemState, ListItemEvent, ListItemContext> {
  ListItemStateMachine(ListItemContext context)
      : super(
          initial: ListItemState.hidden,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<ListItemState, StateConfig<ListItemState, ListItemEvent, ListItemContext>> _buildStates() {
    return {
      ListItemState.hidden: StateConfig(
        state: ListItemState.hidden,
        transitions: {
          ListItemEvent.insert: TransitionConfig(
            target: ListItemState.entering,
            action: (ctx) {
              _startEnterAnimation(ctx);
              return ctx;
            },
          ),
        },
      ),

      ListItemState.entering: StateConfig(
        state: ListItemState.entering,
        transitions: {
          ListItemEvent.complete: TransitionConfig(
            target: ListItemState.visible,
            action: (ctx) {
              ctx.isAnimating = false;
              return ctx;
            },
          ),
          ListItemEvent.remove: TransitionConfig(
            target: ListItemState.exiting,
            action: (ctx) {
              ctx.currentAnimation?.stop();
              _startExitAnimation(ctx);
              return ctx;
            },
          ),
        },
      ),

      ListItemState.visible: StateConfig(
        state: ListItemState.visible,
        transitions: {
          ListItemEvent.remove: TransitionConfig(
            target: ListItemState.exiting,
            action: (ctx) {
              _startExitAnimation(ctx);
              return ctx;
            },
          ),
        },
      ),

      ListItemState.exiting: StateConfig(
        state: ListItemState.exiting,
        transitions: {
          ListItemEvent.complete: TransitionConfig(
            target: ListItemState.removed,
            action: (ctx) {
              ctx.isAnimating = false;
              return ctx;
            },
          ),
        },
      ),

      ListItemState.removed: StateConfig(
        state: ListItemState.removed,
        transitions: {},
      ),
    };
  }

  static void _startEnterAnimation(ListItemContext ctx) {
    ctx.isAnimating = true;

    // Default fade + slide up animation
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 1.0)
        .to(ctx.offsetY, 0.0)
        .to(ctx.scale, 1.0)
        .withDuration(ctx.config.enterDuration)
        .withEasing(ctx.config.enterEasing)
        .onComplete(() {
          // Animation will trigger complete event via external callback
        })
        .build();

    ctx.currentAnimation!.play();
  }

  static void _startExitAnimation(ListItemContext ctx) {
    ctx.isAnimating = true;

    // Default fade out + slide down animation
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 0.0)
        .to(ctx.offsetY, -20.0)
        .to(ctx.scale, 0.9)
        .withDuration(ctx.config.exitDuration)
        .withEasing(ctx.config.exitEasing)
        .onComplete(() {
          // Animation will trigger complete event via external callback
        })
        .build();

    ctx.currentAnimation!.play();
  }
}

/// Animated list controller
class AnimatedListController {
  final List<ListItemStateMachine> _items = [];
  final ListItemAnimationConfig config;

  AnimatedListController({
    this.config = const ListItemAnimationConfig(),
  });

  /// Number of items
  int get length => _items.length;

  /// Get item at index
  ListItemStateMachine operator [](int index) => _items[index];

  /// Insert item at index with stagger
  void insert(int index, {int? staggerIndex}) {
    final itemContext = ListItemContext(
      index: index,
      config: config,
    );

    final fsm = ListItemStateMachine(itemContext);

    // Set up animation completion callback
    effect(() {
      final anim = itemContext.currentAnimation;
      if (anim != null && anim.currentState.value == AnimState.completed) {
        if (fsm.currentState.value == ListItemState.entering) {
          fsm.send(ListItemEvent.complete);
        } else if (fsm.currentState.value == ListItemState.exiting) {
          fsm.send(ListItemEvent.complete);
        }
      }
    });

    _items.insert(index, fsm);

    // Apply stagger delay
    final delay = staggerIndex != null ? staggerIndex * config.staggerDelay : 0;

    if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () {
        fsm.send(ListItemEvent.insert);
      });
    } else {
      fsm.send(ListItemEvent.insert);
    }
  }

  /// Remove item at index
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      final fsm = _items[index];

      // Set up removal callback
      effect(() {
        if (fsm.currentState.value == ListItemState.removed) {
          _items.removeAt(index);
        }
      });

      fsm.send(ListItemEvent.remove);
    }
  }

  /// Insert multiple items with stagger
  void insertAll(List<int> indices) {
    for (var i = 0; i < indices.length; i++) {
      insert(indices[i], staggerIndex: i);
    }
  }

  /// Clear all items
  void clear() {
    for (var i = _items.length - 1; i >= 0; i--) {
      removeAt(i);
    }
  }

  /// Dispose all items
  void dispose() {
    for (final item in _items) {
      item.context.currentAnimation?.dispose();
      item.dispose();
    }
    _items.clear();
  }
}

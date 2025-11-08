/// Kito Patterns - Pre-built state machine patterns for common UI interactions
///
/// This library provides ready-to-use state machines for common UI patterns,
/// each with built-in animation support. Easily customize animations with
/// different keyframes, timelines, and easing functions.
///
/// ## Patterns Included:
///
/// - **AnimatedList**: List items with enter/exit animations and stagger effects
/// - **Button**: Interactive button with hover, press, disabled, and loading states
/// - **Form**: Form validation with error shake and success animations
/// - **Drawer**: Side drawer with smooth open/close animations
/// - **Modal/Dialog**: Modal dialogs with various show/hide effects
/// - **PullToRefresh**: Drag-to-refresh with configurable threshold and animations
/// - **DragShuffle**: Reorderable lists with drag-and-drop animations
/// - **DragShuffleGrid**: Reorderable grids with 2D drag-and-drop and multiple reposition modes
///
/// ## Animation Helpers:
///
/// - **Stagger**: Sequential animations with configurable delays
/// - **Grid Stagger**: Grid animations with row/column/diagonal patterns
/// - **Wave Effect**: Sine wave animation patterns
///
/// Example:
/// ```dart
/// import 'package:kito_patterns/kito_patterns.dart';
///
/// // Create animated button
/// final buttonCtx = ButtonContext(
///   config: ButtonAnimationConfig.bouncy,
///   onTap: () => print('Tapped!'),
/// );
/// final button = ButtonStateMachine(buttonCtx);
///
/// // Trigger animations via events
/// button.send(ButtonEvent.pressDown);
/// button.send(ButtonEvent.pressUp);
///
/// // Access animated values
/// print(button.context.scale.value); // Current scale
/// print(button.context.opacity.value); // Current opacity
///
/// // Create staggered list
/// final animations = StaggerHelper.createStaggeredList(
///   count: 10,
///   animationBuilder: (index) => createFadeInAnimation(index),
///   config: StaggerConfig.cascade,
/// );
/// ```
library kito_patterns;

// Animated List
export 'src/animated_list/animated_list_fsm.dart';

// Button
export 'src/button/button_fsm.dart';

// Form
export 'src/form/form_fsm.dart';

// Drawer
export 'src/drawer/drawer_fsm.dart';

// Modal/Dialog
export 'src/modal/modal_fsm.dart';

// Pull to Refresh
export 'src/pull_to_refresh/pull_to_refresh_fsm.dart';

// Drag and Shuffle
export 'src/drag_shuffle/drag_shuffle_fsm.dart';
export 'src/drag_shuffle/drag_shuffle_grid.dart';

// Animation Helpers
export 'src/helpers/stagger.dart';

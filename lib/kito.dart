/// Kito - A powerful, fine-grained reactive animation library for Flutter
///
/// Inspired by anime.js, Kito provides a clean, intuitive API for creating
/// powerful animations that work with Flutter widgets, custom paint/canvas,
/// and SVG.
library kito;

// Reactive primitives (re-exported from kito_reactive)
export 'package:kito_reactive/kito_reactive.dart';

// Animation engine
export 'src/engine/animation.dart';
export 'src/engine/animation_fsm.dart' show AnimState, AnimEvent, AnimationContext, AnimationStateMachine;
export 'src/engine/timeline.dart';
export 'src/engine/animatable.dart';
export 'src/engine/keyframe.dart';
export 'src/engine/flutter_controller_bridge.dart';

// Easing functions
export 'src/easing/easing.dart';

// Animation targets
export 'src/targets/widget_target.dart';
export 'src/targets/canvas_target.dart';
export 'src/targets/svg_target.dart';

// SVG path morphing
export 'src/svg/svg_path.dart';
export 'src/svg/svg_path_animatable.dart';

// Types
export 'src/types/types.dart';

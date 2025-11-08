/// Kito - A powerful, fine-grained reactive animation library for Flutter
///
/// Inspired by anime.js, Kito provides a clean, intuitive API for creating
/// powerful animations that work with Flutter widgets, custom paint/canvas,
/// and SVG.
library kito;

// Reactive primitives
export 'src/reactive/signal.dart';
export 'src/reactive/computed.dart';
export 'src/reactive/effect.dart';
export 'src/reactive/reactive_context.dart';

// Animation engine
export 'src/engine/animation.dart';
export 'src/engine/timeline.dart';
export 'src/engine/animatable.dart';
export 'src/engine/keyframe.dart';

// Easing functions
export 'src/easing/easing.dart';

// Animation targets
export 'src/targets/widget_target.dart';
export 'src/targets/canvas_target.dart';
export 'src/targets/svg_target.dart';

// Types
export 'src/types/types.dart';

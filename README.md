# Kito 🎬

A powerful, fine-grained reactive animation library for Flutter inspired by anime.js.

## Features

- 🔄 **Fine-grained Reactivity**: Built on a solid reactive state management foundation with Signals, Computed values, and Effects
- 🎨 **Multiple Animation Targets**: Animate Flutter widgets, custom paint/canvas, and SVG
- ⚡ **High Performance**: Optimized reactive updates and animation engine with minimal overhead
- 🎯 **Type-safe API**: Leverage Dart's type system for safe, intuitive animations
- 🌊 **Flexible Easing**: Rich collection of 30+ easing functions
- ⏱️ **Timeline Control**: Complete control over animation sequences and timelines
- 🎭 **Declarative & Imperative**: Choose the style that fits your use case
- 🎪 **Keyframe Animations**: Define complex multi-step animations with keyframes

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kito: ^0.1.0
```

Or install from path:

```yaml
dependencies:
  kito:
    path: ../kito
```

## Quick Start

### Basic Animation

```dart
import 'package:kito/kito.dart';

// Create animatable properties
final props = AnimatedWidgetProperties(
  scale: 1.0,
  rotation: 0.0,
  opacity: 1.0,
);

// Create and run animation
final animation = animate()
    .to(props.scale, 1.5, easing: Easing.easeOutBack)
    .to(props.rotation, 3.14159)
    .to(props.opacity, 0.5)
    .withDuration(1000)
    .build();

animation.play();

// Use in a widget
KitoAnimatedWidget(
  properties: props,
  child: YourWidget(),
)
```

### Reactive State Management

```dart
// Create a signal (reactive primitive)
final count = signal(0);

// Create computed values that automatically update
final doubled = computed(() => count.value * 2);
final message = computed(() =>
  count.value > 10 ? 'High!' : 'Low'
);

// Create effects that run when dependencies change
final dispose = effect(() {
  print('Count is: ${count.value}');
  print('Message: ${message.value}');
});

// Update the signal - effects run automatically
count.value = 5;  // Prints: Count is: 5, Message: Low
count.value = 15; // Prints: Count is: 15, Message: High

// Clean up
dispose();
```

### Canvas Animations

```dart
// Create canvas animation properties
final circleProps = CanvasAnimationProperties(
  position: Offset(100, 100),
  size: Size(50, 50),
  color: Colors.blue,
);

// Animate canvas properties
animate()
    .to(circleProps.position, Offset(300, 300))
    .to(circleProps.color, Colors.red)
    .withDuration(2000)
    .withEasing(Easing.easeInOutCubic)
    .build()
    .play();

// Render with custom painter
KitoCanvas(
  painter: CirclePainter(circleProps),
  size: Size(400, 400),
)
```

### Timeline Sequences

```dart
// Create multiple animations
final anim1 = animate()
    .to(box1.translateX, 100)
    .withDuration(500)
    .build();

final anim2 = animate()
    .to(box2.scale, 2.0)
    .withDuration(800)
    .build();

final anim3 = animate()
    .to(box3.rotation, 6.28)
    .withDuration(1000)
    .build();

// Sequence them
final tl = timeline()
  ..add(anim1)
  ..add(anim2)  // Plays after anim1
  ..add(anim3, position: TimelinePosition.concurrent)  // Plays with anim2
  ..play();
```

### Keyframe Animations

```dart
final colorProp = animatableColor(Colors.blue);

final colorKeyframes = keyframes<Color>()
    .at(0.0, Colors.blue)
    .at(0.33, Colors.red, easing: Easing.easeInOut)
    .at(0.66, Colors.yellow, easing: Easing.easeInOut)
    .at(1.0, Colors.green)
    .build();

animate()
    .withKeyframes(colorProp, colorKeyframes)
    .withDuration(3000)
    .loopInfinitely()
    .build()
    .play();
```

## Architecture

Kito is built on three core pillars:

### 1. Reactive State Management

Fine-grained reactive primitives inspired by SolidJS:

- **Signal**: Mutable reactive value
- **Computed**: Derived reactive value with automatic dependency tracking
- **Effect**: Side effect that runs when dependencies change
- **Batch**: Group multiple updates to run effects only once

```dart
final x = signal(10);
final y = signal(20);
final sum = computed(() => x.value + y.value);

effect(() {
  print('Sum is: ${sum.value}');
});

// Batch multiple updates
batch(() {
  x.value = 100;
  y.value = 200;
}); // Effect runs once: "Sum is: 300"
```

### 2. Animation Engine

Timeline-based animation system with:

- **Animatable Properties**: Type-safe animated values
- **Easing Functions**: 30+ built-in easing functions
- **Keyframes**: Multi-step animations
- **Direction Control**: Forward, reverse, alternate
- **Loop Control**: Finite or infinite loops
- **Callbacks**: onBegin, onUpdate, onComplete

### 3. Target Adapters

Specialized adapters for different animation targets:

- **Widget Animations**: Transform, opacity, scale, rotation
- **Canvas Animations**: Custom paint with reactive properties
- **SVG Animations**: Path morphing, stroke animations, transforms

## Easing Functions

Kito includes 30+ easing functions:

**Linear**: `linear`

**Quadratic**: `easeInQuad`, `easeOutQuad`, `easeInOutQuad`

**Cubic**: `easeInCubic`, `easeOutCubic`, `easeInOutCubic`

**Quartic**: `easeInQuart`, `easeOutQuart`, `easeInOutQuart`

**Quintic**: `easeInQuint`, `easeOutQuint`, `easeInOutQuint`

**Sinusoidal**: `easeInSine`, `easeOutSine`, `easeInOutSine`

**Exponential**: `easeInExpo`, `easeOutExpo`, `easeInOutExpo`

**Circular**: `easeInCirc`, `easeOutCirc`, `easeInOutCirc`

**Back**: `easeInBack`, `easeOutBack`, `easeInOutBack`

**Elastic**: `easeInElastic`, `easeOutElastic`, `easeInOutElastic`

**Bounce**: `easeInBounce`, `easeOutBounce`, `easeInOutBounce`

**Custom**: `cubicBezier(x1, y1, x2, y2)`, `steps(count)`

## API Reference

### Animation Builder

```dart
animate()
    .to(property, endValue, {easing, duration, delay})
    .withKeyframes(property, keyframes, {easing, duration, delay})
    .withDuration(milliseconds)
    .withDelay(milliseconds)
    .withEasing(easingFunction)
    .withLoop(count)  // or .loopInfinitely()
    .withDirection(AnimationDirection.forward | reverse | alternate)
    .withAutoplay()
    .onBegin(callback)
    .onUpdate(callback)
    .onComplete(callback)
    .build()
```

### Animation Control

```dart
animation.play()       // Start or resume
animation.pause()      // Pause
animation.restart()    // Restart from beginning
animation.seek(0.5)    // Seek to 50%
animation.stop()       // Stop and reset
animation.dispose()    // Clean up
```

### Timeline

```dart
timeline()
  .add(animation, {offset, position})
  .play()
  .pause()
  .restart()
  .seek(milliseconds)
  .stop()
  .dispose()
```

### Reactive Primitives

```dart
// Signal
final sig = signal(initialValue)
sig.value = newValue
final current = sig.value
final peeked = sig.peek()  // Read without tracking

// Computed
final comp = computed(() => expression)
final value = comp.value

// Effect
final dispose = effect(() => sideEffect)
dispose()  // Stop the effect

// Batch
batch(() {
  signal1.value = value1
  signal2.value = value2
})  // Effects run once after batch
```

## Examples

The `example/` directory contains comprehensive examples:

- **Basic Animations**: Simple property animations
- **Reactive State**: Fine-grained reactive state management
- **Canvas Animations**: Custom paint animations
- **Timeline**: Sequential and concurrent animation sequences
- **Easing Functions**: Visual comparison of all easing functions

Run the example app:

```bash
cd example
flutter run
```

## Comparison with anime.js

| Feature | anime.js | Kito |
|---------|----------|------|
| Target | Web (DOM/CSS/SVG) | Flutter (Widgets/Canvas/SVG) |
| Reactivity | No | Yes (Fine-grained) |
| Type Safety | JavaScript | Dart (Strongly typed) |
| Easing Functions | 30+ | 30+ |
| Timeline | Yes | Yes |
| Keyframes | Yes | Yes |
| Performance | requestAnimationFrame | Flutter Ticker |

## Performance Tips

1. **Use `batch()`** when updating multiple signals
2. **Dispose animations** when done to prevent memory leaks
3. **Use `peek()`** to read signals without tracking dependencies
4. **Prefer computed values** over manual calculations
5. **Mark canvas painters** with `isComplex: true` for caching

## Roadmap

- [ ] Spring physics animations
- [ ] Gesture-driven animations
- [ ] SVG path morphing (advanced)
- [ ] Integration with Flutter's AnimationController
- [ ] Performance profiling tools
- [ ] Animation presets library
- [ ] Web support optimizations

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

BSD 3-Clause License - see LICENSE file for details

## Credits

Inspired by:
- [anime.js](https://animejs.com/) - The amazing JavaScript animation library
- [SolidJS](https://www.solidjs.com/) - Fine-grained reactive system
- [Framer Motion](https://www.framer.com/motion/) - Declarative animations

Built with ❤️ for the Flutter community

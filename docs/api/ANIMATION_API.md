# Animation API Reference

Comprehensive API documentation for Kito's core animation system.

## Table of Contents

- [Animation](#animation)
- [AnimationBuilder](#animationbuilder)
- [AnimatableProperty](#animatableproperty)
- [Timeline](#timeline)
- [Keyframes](#keyframes)
- [Easing Functions](#easing-functions)

---

## Animation

The `Animation` class represents a runnable animation that can be played, paused, and controlled.

### Properties

```dart
Animation animation;

// State
bool get isPlaying;        // Whether animation is currently playing
bool get isPaused;         // Whether animation is paused
bool get isFinished;       // Whether animation has completed
double get progress;       // Current progress (0.0 to 1.0)
int get currentLoop;       // Current loop iteration

// Configuration
Duration get duration;     // Total animation duration
Duration get delay;        // Delay before animation starts
int? get loop;            // Number of loops (null for infinite)
```

### Methods

#### play()
Starts or resumes the animation.

```dart
animation.play();
```

**Returns**: `void`

**Example**:
```dart
final anim = animate()
    .to(property, 100)
    .withDuration(1000)
    .build();

anim.play();
```

---

#### pause()
Pauses the animation at its current position.

```dart
animation.pause();
```

**Returns**: `void`

**Example**:
```dart
anim.pause();
print(anim.progress); // e.g., 0.45
```

---

#### restart()
Restarts the animation from the beginning.

```dart
animation.restart();
```

**Returns**: `void`

**Example**:
```dart
anim.restart(); // Resets progress to 0 and plays
```

---

#### seek(progress)
Seeks to a specific progress point (0.0 to 1.0).

```dart
animation.seek(double progress);
```

**Parameters**:
- `progress` (double): Target progress (0.0 = start, 1.0 = end)

**Returns**: `void`

**Example**:
```dart
anim.seek(0.5);  // Jump to 50% progress
anim.seek(0.75); // Jump to 75% progress
```

---

#### stop()
Stops the animation and resets to initial state.

```dart
animation.stop();
```

**Returns**: `void`

**Example**:
```dart
anim.stop(); // progress = 0, isPlaying = false
```

---

#### dispose()
Disposes the animation and cleans up resources.

```dart
animation.dispose();
```

**Returns**: `void`

**Important**: Always dispose animations when done to prevent memory leaks.

**Example**:
```dart
@override
void dispose() {
  animation.dispose();
  super.dispose();
}
```

---

## AnimationBuilder

The `AnimationBuilder` class provides a fluent API for creating animations.

### Factory

```dart
AnimationBuilder animate();
```

**Returns**: `AnimationBuilder`

**Example**:
```dart
final builder = animate();
```

---

### Methods

#### to(property, endValue, {easing, duration, delay})
Animates a property to an end value.

```dart
AnimationBuilder to(
  AnimatableProperty property,
  dynamic endValue, {
  EasingFunction? easing,
  int? duration,
  int? delay,
});
```

**Parameters**:
- `property` (AnimatableProperty): The property to animate
- `endValue` (dynamic): Target value
- `easing` (EasingFunction?, optional): Easing function for this property
- `duration` (int?, optional): Override global duration (milliseconds)
- `delay` (int?, optional): Delay before animating this property (milliseconds)

**Returns**: `AnimationBuilder` (for chaining)

**Example**:
```dart
animate()
    .to(scale, 2.0, easing: Easing.easeOutBack)
    .to(opacity, 0.5, delay: 500)
    .build();
```

---

#### withKeyframes(property, keyframes, {easing, duration, delay})
Animates a property through keyframe values.

```dart
AnimationBuilder withKeyframes(
  AnimatableProperty property,
  Keyframes keyframes, {
  EasingFunction? easing,
  int? duration,
  int? delay,
});
```

**Parameters**:
- `property` (AnimatableProperty): The property to animate
- `keyframes` (Keyframes): Keyframe definitions
- `easing` (EasingFunction?, optional): Default easing for keyframes
- `duration` (int?, optional): Override global duration
- `delay` (int?, optional): Delay before animation

**Returns**: `AnimationBuilder`

**Example**:
```dart
final colorKeyframes = keyframes<Color>()
    .at(0.0, Colors.red)
    .at(0.5, Colors.blue)
    .at(1.0, Colors.green)
    .build();

animate()
    .withKeyframes(colorProp, colorKeyframes)
    .withDuration(2000)
    .build();
```

---

#### withDuration(milliseconds)
Sets the total animation duration.

```dart
AnimationBuilder withDuration(int milliseconds);
```

**Parameters**:
- `milliseconds` (int): Duration in milliseconds

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(scale, 1.5)
    .withDuration(1000) // 1 second
    .build();
```

---

#### withDelay(milliseconds)
Sets a delay before the animation starts.

```dart
AnimationBuilder withDelay(int milliseconds);
```

**Parameters**:
- `milliseconds` (int): Delay in milliseconds

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(opacity, 0)
    .withDelay(500) // Wait 0.5s before starting
    .build();
```

---

#### withEasing(easingFunction)
Sets the default easing function.

```dart
AnimationBuilder withEasing(EasingFunction easingFunction);
```

**Parameters**:
- `easingFunction` (EasingFunction): The easing function to use

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(scale, 1.5)
    .withEasing(Easing.easeOutElastic)
    .build();
```

---

#### withLoop(count)
Sets the number of times to loop.

```dart
AnimationBuilder withLoop(int count);
```

**Parameters**:
- `count` (int): Number of loops

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(rotation, 6.28)
    .withLoop(3) // Loop 3 times
    .build();
```

---

#### loopInfinitely()
Makes the animation loop forever.

```dart
AnimationBuilder loopInfinitely();
```

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(rotation, 6.28)
    .loopInfinitely()
    .build();
```

---

#### withDirection(direction)
Sets the playback direction.

```dart
AnimationBuilder withDirection(AnimationDirection direction);
```

**Parameters**:
- `direction` (AnimationDirection): One of:
  - `AnimationDirection.forward`: Play forward
  - `AnimationDirection.reverse`: Play backward
  - `AnimationDirection.alternate`: Alternate direction each loop

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(scale, 1.5)
    .withLoop(4)
    .withDirection(AnimationDirection.alternate)
    .build();
```

---

#### withAutoplay()
Automatically plays the animation when built.

```dart
AnimationBuilder withAutoplay();
```

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(opacity, 1)
    .withAutoplay() // Plays immediately
    .build();
```

---

#### onBegin(callback)
Registers a callback for when animation begins.

```dart
AnimationBuilder onBegin(VoidCallback callback);
```

**Parameters**:
- `callback` (VoidCallback): Function to call when animation starts

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(scale, 1.5)
    .onBegin(() => print('Animation started!'))
    .build();
```

---

#### onUpdate(callback)
Registers a callback for each animation frame.

```dart
AnimationBuilder onUpdate(VoidCallback callback);
```

**Parameters**:
- `callback` (VoidCallback): Function to call on each frame

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(progress, 100)
    .onUpdate(() => print('Progress: ${progress.value}'))
    .build();
```

---

#### onComplete(callback)
Registers a callback for when animation completes.

```dart
AnimationBuilder onComplete(VoidCallback callback);
```

**Parameters**:
- `callback` (VoidCallback): Function to call when animation finishes

**Returns**: `AnimationBuilder`

**Example**:
```dart
animate()
    .to(opacity, 0)
    .onComplete(() => setState(() => isVisible = false))
    .build();
```

---

#### build()
Builds and returns the animation.

```dart
Animation build();
```

**Returns**: `Animation`

**Example**:
```dart
final animation = animate()
    .to(scale, 1.5)
    .withDuration(1000)
    .build();

animation.play();
```

---

## AnimatableProperty

Type-safe animatable properties for different value types.

### Factory Functions

```dart
// Numeric properties
AnimatableProperty<double> animatableDouble(double initial);
AnimatableProperty<int> animatableInt(int initial);

// Geometric properties
AnimatableProperty<Offset> animatableOffset(Offset initial);
AnimatableProperty<Size> animatableSize(Size initial);

// Visual properties
AnimatableProperty<Color> animatableColor(Color initial);

// Transform properties
AnimatableProperty<Matrix4> animatableMatrix4(Matrix4 initial);
```

### Properties

```dart
AnimatableProperty<T> property;

T value;        // Current animated value
T initial;      // Initial value
```

### Example

```dart
// Create properties
final scale = animatableDouble(1.0);
final position = animatableOffset(Offset.zero);
final color = animatableColor(Colors.blue);

// Animate them
animate()
    .to(scale, 2.0)
    .to(position, Offset(100, 50))
    .to(color, Colors.red)
    .build()
    .play();

// Use in widgets
Transform.scale(
  scale: scale.value,
  child: Container(
    color: color.value,
    transform: Matrix4.translationValues(
      position.value.dx,
      position.value.dy,
      0,
    ),
  ),
)
```

---

## Timeline

The `Timeline` class sequences multiple animations.

### Factory

```dart
Timeline timeline();
```

**Returns**: `Timeline`

---

### Methods

#### add(animation, {offset, position})
Adds an animation to the timeline.

```dart
Timeline add(
  Animation animation, {
  int? offset,
  TimelinePosition? position,
});
```

**Parameters**:
- `animation` (Animation): The animation to add
- `offset` (int?, optional): Time offset in milliseconds
- `position` (TimelinePosition?, optional): When to start the animation:
  - `TimelinePosition.sequential`: After previous animation (default)
  - `TimelinePosition.concurrent`: Same time as previous animation

**Returns**: `Timeline` (for chaining)

**Example**:
```dart
timeline()
  .add(anim1)                                        // t=0
  .add(anim2)                                        // t=anim1.duration
  .add(anim3, position: TimelinePosition.concurrent) // t=anim1.duration
  .add(anim4, offset: 500)                          // t=anim1.duration+500
  .play();
```

---

#### play(), pause(), restart(), seek(), stop(), dispose()
Same as Animation methods, controls the entire timeline.

**Example**:
```dart
final tl = timeline()
  .add(fadeIn)
  .add(slideIn)
  .add(scaleUp);

tl.play();
await Future.delayed(Duration(seconds: 2));
tl.pause();
```

---

## Keyframes

The `Keyframes` class defines multi-step animations.

### Factory

```dart
KeyframesBuilder<T> keyframes<T>();
```

**Returns**: `KeyframesBuilder<T>`

---

### KeyframesBuilder Methods

#### at(progress, value, {easing})
Adds a keyframe at a specific progress point.

```dart
KeyframesBuilder<T> at(
  double progress,
  T value, {
  EasingFunction? easing,
});
```

**Parameters**:
- `progress` (double): Progress point (0.0 to 1.0)
- `value` (T): Value at this keyframe
- `easing` (EasingFunction?, optional): Easing to next keyframe

**Returns**: `KeyframesBuilder<T>`

**Example**:
```dart
keyframes<double>()
    .at(0.0, 0.0)
    .at(0.25, 1.0, easing: Easing.easeOut)
    .at(0.75, 0.5, easing: Easing.easeInOut)
    .at(1.0, 1.0)
    .build();
```

---

#### build()
Builds the keyframes.

```dart
Keyframes<T> build();
```

**Returns**: `Keyframes<T>`

**Example**:
```dart
final colorKeyframes = keyframes<Color>()
    .at(0.0, Colors.red)
    .at(0.5, Colors.yellow)
    .at(1.0, Colors.green)
    .build();

animate()
    .withKeyframes(colorProp, colorKeyframes)
    .withDuration(3000)
    .build()
    .play();
```

---

## Easing Functions

Kito provides 30+ built-in easing functions via the `Easing` class.

### Linear

```dart
Easing.linear
```

### Quadratic

```dart
Easing.easeInQuad
Easing.easeOutQuad
Easing.easeInOutQuad
```

### Cubic

```dart
Easing.easeInCubic
Easing.easeOutCubic
Easing.easeInOutCubic
```

### Quartic

```dart
Easing.easeInQuart
Easing.easeOutQuart
Easing.easeInOutQuart
```

### Quintic

```dart
Easing.easeInQuint
Easing.easeOutQuint
Easing.easeInOutQuint
```

### Sinusoidal

```dart
Easing.easeInSine
Easing.easeOutSine
Easing.easeInOutSine
```

### Exponential

```dart
Easing.easeInExpo
Easing.easeOutExpo
Easing.easeInOutExpo
```

### Circular

```dart
Easing.easeInCirc
Easing.easeOutCirc
Easing.easeInOutCirc
```

### Back

```dart
Easing.easeInBack
Easing.easeOutBack
Easing.easeInOutBack
```

### Elastic

```dart
Easing.easeInElastic
Easing.easeOutElastic
Easing.easeInOutElastic
```

### Bounce

```dart
Easing.easeInBounce
Easing.easeOutBounce
Easing.easeInOutBounce
```

### Custom Easing

```dart
// Cubic bezier curve
Easing.cubicBezier(x1, y1, x2, y2)

// Steps function
Easing.steps(count, {jumpTerm})
```

**Example**:
```dart
// Custom elastic ease
final customEasing = Easing.cubicBezier(0.68, -0.55, 0.265, 1.55);

animate()
    .to(scale, 1.5)
    .withEasing(customEasing)
    .build();

// Steps for pixel-perfect animations
animate()
    .to(progress, 100)
    .withEasing(Easing.steps(10))
    .build();
```

---

## Complete Examples

### Basic Scale Animation

```dart
final scale = animatableDouble(1.0);

final scaleAnim = animate()
    .to(scale, 1.5)
    .withDuration(500)
    .withEasing(Easing.easeOutBack)
    .build();

scaleAnim.play();

// Use in widget
Transform.scale(
  scale: scale.value,
  child: MyWidget(),
)
```

### Multi-Property Animation

```dart
final props = AnimatedWidgetProperties(
  scale: 1.0,
  rotation: 0.0,
  opacity: 1.0,
);

final anim = animate()
    .to(props.scale, 1.5, easing: Easing.easeOutBack)
    .to(props.rotation, 6.28, easing: Easing.easeInOutCubic)
    .to(props.opacity, 0.5, delay: 200)
    .withDuration(1000)
    .build();

anim.play();
```

### Keyframe Color Animation

```dart
final color = animatableColor(Colors.blue);

final colorKeyframes = keyframes<Color>()
    .at(0.0, Colors.blue)
    .at(0.33, Colors.red, easing: Easing.easeInOut)
    .at(0.66, Colors.yellow, easing: Easing.easeInOut)
    .at(1.0, Colors.green)
    .build();

animate()
    .withKeyframes(color, colorKeyframes)
    .withDuration(3000)
    .loopInfinitely()
    .build()
    .play();
```

### Timeline Sequence

```dart
final box1Opacity = animatableDouble(0);
final box2Scale = animatableDouble(0);
final box3Rotation = animatableDouble(0);

final tl = timeline()
  ..add(animate().to(box1Opacity, 1).withDuration(500).build())
  ..add(animate().to(box2Scale, 1).withDuration(800).build())
  ..add(
    animate().to(box3Rotation, 6.28).withDuration(1000).build(),
    position: TimelinePosition.concurrent,
  )
  ..play();
```

---

## Best Practices

1. **Always dispose animations** when done to prevent memory leaks
2. **Use type-safe properties** (animatableDouble, animatableColor, etc.)
3. **Chain method calls** for cleaner code
4. **Set appropriate durations** (300-500ms for UI feedback, 1000+ for emphasis)
5. **Choose easing carefully** (easeOut for entrances, easeIn for exits)
6. **Use callbacks** (onComplete) for sequencing without timelines
7. **Test on low-end devices** to ensure smooth 60fps performance

# Kito Patterns

Pre-built state machine patterns for common UI interactions with animation support.

## Overview

Kito Patterns provides a collection of ready-to-use state machines for common UI patterns. Each pattern comes with built-in animations that can be easily customized using different keyframe configurations, timelines, and easing functions.

## Features

- **Declarative State Management**: All patterns use `kito_fsm` for predictable state transitions
- **Reactive Animations**: Built on `kito_reactive` for smooth, responsive animations
- **Highly Configurable**: Multiple preset configurations with full customization support
- **Type-Safe**: Strongly-typed states, events, and contexts
- **Composable**: Mix and match patterns to create complex UIs

## Patterns Included

### 1. Animated List

List items with enter/exit animations and stagger effects.

```dart
import 'package:kito_patterns/kito_patterns.dart';

// Create controller
final controller = AnimatedListController(
  config: ListItemAnimationConfig.slideUp(
    staggerDelay: 50,
  ),
);

// Initialize items
controller.initializeItems(10);

// Insert item with animation
controller.insert(0);

// Insert multiple items with stagger
controller.insertAll([0, 1, 2, 3]);

// Remove item with animation
controller.removeAt(5);

// Access item context
final item = controller.getItem(0);
print('Opacity: ${item.opacity.value}');
print('Scale: ${item.scale.value}');
```

**States**: `hidden`, `entering`, `visible`, `exiting`, `removed`

**Preset Configs**: `fadeIn`, `slideUp`, `scaleIn`, `bounceIn`

### 2. Button

Interactive button with hover, press, disabled, and loading states.

```dart
final buttonCtx = ButtonContext(
  config: ButtonAnimationConfig.bouncy,
  onTap: () => print('Tapped!'),
);

final button = ButtonStateMachine(buttonCtx);

// Trigger interactions
button.send(ButtonEvent.hoverEnter);
button.send(ButtonEvent.pressDown);
button.send(ButtonEvent.pressUp);
button.send(ButtonEvent.hoverExit);

// Access animated values
print('Scale: ${buttonCtx.scale.value}');
print('Opacity: ${buttonCtx.opacity.value}');

// Disable button
button.send(ButtonEvent.disable);

// Show loading state
button.send(ButtonEvent.startLoading);
```

**States**: `idle`, `hover`, `pressed`, `disabled`, `loading`

**Preset Configs**: `subtle`, `bouncy`, `mobile`

### 3. Form

Form validation with error shake and success animations.

```dart
final formCtx = FormContext(
  config: FormAnimationConfig.bouncy,
  onValidate: () async {
    // Your validation logic
    return validationResult;
  },
  onSubmit: () async {
    // Your submit logic
  },
);

final form = FormStateMachine(formCtx);

// Start editing
form.send(FormEvent.startEdit);

// Validate
form.send(FormEvent.validate);

// Submit
form.send(FormEvent.submit);

// Access animated values
print('Border color intensity: ${formCtx.borderColor.value}');
print('Shake offset: ${formCtx.offsetX.value}');
print('Success scale: ${formCtx.successScale.value}');
```

**States**: `editing`, `validating`, `valid`, `invalid`, `submitting`, `success`, `error`

**Preset Configs**: `smooth`, `bouncy`, `gentle`

### 4. Drawer

Side drawer with smooth open/close animations.

```dart
final drawerCtx = DrawerContext(
  config: DrawerAnimationConfig.smooth,
);

final drawer = DrawerStateMachine(drawerCtx);

// Open drawer
drawer.send(DrawerEvent.open);

// Close drawer
drawer.send(DrawerEvent.close);

// Access animated values
print('Position: ${drawerCtx.position.value}'); // 0.0 to 1.0
print('Overlay opacity: ${drawerCtx.overlayOpacity.value}');
print('Content scale: ${drawerCtx.contentScale.value}');
```

**States**: `closed`, `opening`, `open`, `closing`

**Preset Configs**: `smooth`, `snappy`, `elastic`

### 5. Modal/Dialog

Modal dialogs with various show/hide effects.

```dart
final modalCtx = ModalContext(
  config: ModalAnimationConfig.scaleIn(
    animationType: ModalAnimationType.zoom,
  ),
);

final modal = ModalStateMachine(modalCtx);

// Show modal
modal.send(ModalEvent.show);

// Hide modal
modal.send(ModalEvent.hide);

// Access animated values
print('Scale: ${modalCtx.scale.value}');
print('Opacity: ${modalCtx.opacity.value}');
print('Y offset: ${modalCtx.offsetY.value}');
print('Backdrop: ${modalCtx.backdropOpacity.value}');
```

**States**: `hidden`, `showing`, `visible`, `hiding`

**Animation Types**: `fade`, `scale`, `slideUp`, `slideDown`, `slideLeft`, `slideRight`, `bounce`, `zoom`

**Preset Configs**: `fadeIn`, `scaleIn`, `slideUpIn`, `slideDownIn`, `bounceIn`

### 6. Pull to Refresh

Drag-to-refresh with configurable threshold and animations.

```dart
final pullToRefreshCtx = PullToRefreshContext(
  config: PullToRefreshConfig.elastic,
  onRefresh: () async {
    // Your refresh logic
    await Future.delayed(Duration(seconds: 2));
  },
);

final pullToRefresh = PullToRefreshStateMachine(pullToRefreshCtx);

// In your drag handler
void onDragStart() {
  pullToRefresh.startPull();
}

void onDragUpdate(double distance) {
  pullToRefresh.updatePullDistance(distance);
}

void onDragEnd() {
  pullToRefresh.releasePull();
}

// Access animated values
print('Pull distance: ${pullToRefreshCtx.pullDistance.value}');
print('Rotation: ${pullToRefreshCtx.rotation.value}');
print('Scale: ${pullToRefreshCtx.scale.value}');
print('Opacity: ${pullToRefreshCtx.opacity.value}');
```

**States**: `idle`, `pulling`, `threshold`, `releasing`, `refreshing`, `complete`

**Preset Configs**: `snappy`, `smooth`, `elastic`

### 7. Drag and Shuffle

Reorderable lists with drag-and-drop animations.

```dart
final dragController = DragShuffleController(
  config: DragShuffleConfig.playful,
  onReorder: (oldIndex, newIndex) {
    print('Reordered: $oldIndex -> $newIndex');
    // Update your data source
  },
);

// Initialize items
dragController.initializeItems(10);

// In your drag handlers
void onDragStart(int index) {
  dragController.startDrag(index);
}

void onDragUpdate(int index, double dx, double dy) {
  dragController.updateDragPosition(index, dx, dy);
}

void onDragHover(int targetIndex) {
  dragController.updateTargetPosition(targetIndex);
}

void onDragEnd() {
  dragController.drop();
}

// Access item values
final item = dragController.getItem(0);
print('Offset X: ${item.offsetX.value}');
print('Offset Y: ${item.offsetY.value}');
print('Scale: ${item.scale.value}');
print('Rotation: ${item.rotation.value}');
```

**States**: `idle`, `dragging`, `hovering`, `dropping`, `animating`

**Preset Configs**: `subtle`, `smooth`, `playful`

### 8. Drag and Shuffle Grid

Reorderable grids with 2D drag-and-drop animations and multiple reposition modes.

```dart
final gridController = DragShuffleGridController(
  config: DragShuffleGridConfig(
    columns: 3,
    itemWidth: 100.0,
    itemHeight: 100.0,
    horizontalGap: 8.0,
    verticalGap: 8.0,
    repositionMode: GridRepositionMode.wave,
    dragScale: 1.08,
  ),
  onReorder: (oldIndex, newIndex) {
    print('Grid reordered: $oldIndex -> $newIndex');
    // Update your data source
  },
);

// Initialize grid items
gridController.initializeItems(12); // 3x4 grid

// In your drag handlers
void onDragStart(int index) {
  gridController.startDrag(index);
}

void onDragUpdate(int index, double dx, double dy) {
  // Pass pixel offsets - controller calculates grid position
  gridController.updateDragPosition(index, dx, dy);
}

void onDragEnd() {
  gridController.drop();
}

// Access item values
final item = gridController.getItem(0);
print('Row: ${item.originalRow}, Col: ${item.originalCol}');
print('Target Row: ${item.targetRow}, Target Col: ${item.targetCol}');
print('Offset X: ${item.offsetX.value}');
print('Offset Y: ${item.offsetY.value}');
print('Scale: ${item.scale.value}');
```

**Grid Reposition Modes**:
- `simultaneous`: All items move at once
- `wave`: Items move in a wave pattern based on distance
- `radial`: Items move based on radial distance from dragged item
- `rowByRow`: Items in same row move first, then others
- `columnByColumn`: Items in same column move first, then others

**Features**:
- Automatic grid position calculation from pixel offsets
- Configurable item dimensions and gaps
- Multiple animation modes for item repositioning
- 2D displacement animations

## Animation Helpers

### Stagger

Sequential animations with configurable delays.

```dart
// Create staggered list animations
final animations = StaggerHelper.createStaggeredList(
  count: 10,
  animationBuilder: (index) {
    final value = animatableDouble(0.0);
    return animate()
        .to(value, 1.0)
        .withDuration(300)
        .build();
  },
  config: StaggerConfig.cascade,
  autoplay: true,
);

// Custom stagger config
final customConfig = StaggerConfig(
  baseDelay: 50,
  delayMultiplier: 1.2,
  maxDelay: 500,
  direction: StaggerDirection.reverse,
  timing: Easing.easeOut,
);
```

**Preset Configs**: `fast` (25ms), `normal` (50ms), `slow` (100ms), `cascade`

### Grid Stagger

Grid animations with row/column/diagonal patterns.

```dart
// Create staggered grid animations
final animations = StaggerHelper.createStaggeredGrid(
  count: 20,
  columns: 4,
  animationBuilder: (index) {
    final value = animatableDouble(0.0);
    return animate()
        .to(value, 1.0)
        .withDuration(400)
        .build();
  },
  gridConfig: GridStaggerConfig(
    mode: GridStaggerMode.diagonal,
    baseDelay: 40,
    columns: 4,
  ),
  autoplay: true,
);
```

**Grid Modes**: `row`, `column`, `diagonal`, `spiral`, `random`

### Wave Effect

Sine wave animation patterns.

```dart
// Create wave effect
final animations = StaggerHelper.createWaveEffect(
  count: 15,
  animationBuilder: (index) {
    final value = animatableDouble(0.0);
    return animate()
        .to(value, 1.0)
        .withDuration(500)
        .build();
  },
  waveLength: 5,
  baseDelay: 30,
  autoplay: true,
);
```

## Atomic Primitives

Atomic primitives are pure, reusable animation building blocks that can be applied to any component. They are composable functions that return configured animations.

### Motion Primitives

#### Elastic (Rubber Band)

```dart
final scale = animatableDouble(1.0);
final anim = createElastic(scale, 1.5, config: ElasticConfig.strong);
anim.play();
```

**Configs**: `subtle`, `strong`

#### Bounce

```dart
final posY = animatableDouble(0.0);
final anim = createBounce(posY, 100.0, config: BounceConfig.playful);
anim.play();
```

**Configs**: `subtle`, `playful`

#### Shake/Wiggle

```dart
final offsetX = animatableDouble(0.0);
final anim = createShake(offsetX, config: ShakeConfig.strong);
anim.play();
```

**Configs**: `subtle`, `strong`

#### Pulse

```dart
final scale = animatableDouble(1.0);
final anim = createPulse(scale, config: PulseConfig.infinite);
anim.play();
```

**Configs**: `subtle`, `strong`, `infinite`

#### Flash

```dart
final opacity = animatableDouble(1.0);
final anim = createFlash(opacity, config: FlashConfig.quick);
anim.play();
```

**Configs**: `quick`, `slow`

#### Swing/Pendulum

```dart
final rotation = animatableDouble(0.0);
final anim = createSwing(rotation, config: SwingConfig.strong);
anim.play();
```

**Configs**: `gentle`, `strong`

#### Jello/Wobble

```dart
final scaleX = animatableDouble(1.0);
final anim = createJello(scaleX, config: JelloConfig.strong);
anim.play();
```

**Configs**: `subtle`, `strong`

#### Heartbeat

```dart
final scale = animatableDouble(1.0);
final anim = createHeartbeat(scale, config: HeartbeatConfig.fast);
anim.play();
```

**Configs**: `slow`, `fast`

### Enter/Exit Primitives

#### Fade

```dart
// Fade in
final opacity = animatableDouble(0.0);
final anim = fadeIn(opacity, config: FadeConfig.quick);
anim.play();

// Fade out
final animOut = fadeOut(opacity);
animOut.play();
```

#### Slide

```dart
// Slide in from right
final offsetX = animatableDouble(0.0);
final anim = slideInFromRight(offsetX, 100.0, config: SlideConfig.smooth);
anim.play();

// Slide out to left
final animOut = slideOutToLeft(offsetX, 100.0);
animOut.play();
```

**Directions**: `FromRight`, `FromLeft`, `FromTop`, `FromBottom`, `ToRight`, `ToLeft`, `ToTop`, `ToBottom`

#### Scale

```dart
// Scale in
final scale = animatableDouble(0.0);
final anim = scaleIn(scale, config: ScaleConfig.elastic);
anim.play();

// Scale out
final animOut = scaleOut(scale);
animOut.play();
```

**Configs**: `quick`, `smooth`, `elastic`

#### Rotate

```dart
// Rotate in
final rotation = animatableDouble(0.0);
final anim = rotateIn(rotation, fromDegrees: 180.0);
anim.play();

// Rotate out
final animOut = rotateOut(rotation, toDegrees: 180.0);
animOut.play();
```

#### Combination Primitives

```dart
// Fade + Scale
final opacity = animatableDouble(0.0);
final scale = animatableDouble(0.0);
final anim = fadeScaleIn(opacity, scale);
anim.play();

// Slide + Fade
final offsetY = animatableDouble(0.0);
final anim2 = slideFadeIn(opacity, offsetY, 50.0);
anim2.play();

// Zoom (scale + fade with bounce)
final anim3 = zoomIn(scale, opacity);
anim3.play();

// Flip (3D-like rotation)
final rotation = animatableDouble(0.0);
final anim4 = flipIn(rotation, opacity);
anim4.play();
```

### Timing Primitives

#### Chain (Sequential)

```dart
chain([
  fadeIn(opacity1),
  scaleIn(scale),
  slideInFromBottom(offsetY, 100.0),
], gap: 100); // 100ms gap between each
```

#### Parallel (Simultaneous)

```dart
parallel([
  fadeIn(opacity),
  scaleIn(scale),
  rotateIn(rotation),
]);
```

#### Delay

```dart
final anim = delay(
  fadeIn(opacity),
  milliseconds: 500,
);
```

#### Repeat

```dart
repeat(
  createPulse(scale),
  times: 5,
  gap: 200,
);
```

#### Yoyo (Back and Forth)

```dart
yoyo(
  slideInFromRight(offsetX, 100.0),
  times: 3,
);
```

#### Spring (Physics-based)

```dart
final anim = spring(
  property: scale,
  target: 1.5,
  stiffness: 200.0,
  damping: 10.0,
);
anim.play();
```

#### Momentum (Inertia)

```dart
final anim = momentum(
  property: offsetX,
  velocity: 500.0,
  friction: 0.95,
);
anim.play();
```

#### Crossfade

```dart
crossfade(
  outOpacity: opacity1,
  inOpacity: opacity2,
  duration: 400,
);
```

#### Ping-Pong

```dart
pingPong(
  property: scale,
  from: 1.0,
  to: 1.3,
  times: 5,
);
```

## Customization

All patterns support full customization through configuration classes:

```dart
// Custom button config
final customButtonConfig = ButtonAnimationConfig(
  pressedScale: 0.85,
  hoverScale: 1.15,
  disabledOpacity: 0.4,
  loadingOpacity: 0.7,
  duration: 200,
  easing: Easing.easeInOutCubic,
);

// Custom modal config
final customModalConfig = ModalAnimationConfig(
  animationType: ModalAnimationType.zoom,
  showDuration: 400,
  hideDuration: 300,
  showEasing: Easing.easeOutBack,
  hideEasing: Easing.easeInCubic,
  backdropOpacity: 0.8,
);

// Custom pull-to-refresh config
final customPullConfig = PullToRefreshConfig(
  threshold: 100.0,
  maxPullDistance: 150.0,
  releaseDuration: 350,
  releaseEasing: Easing.easeOutElastic,
  rotationSpeed: 450.0,
  thresholdScale: 1.4,
);
```

## Advanced Usage

### Combining Patterns

```dart
// Button with modal
final buttonCtx = ButtonContext(
  config: ButtonAnimationConfig.bouncy,
  onTap: () {
    modal.send(ModalEvent.show);
  },
);

final modalCtx = ModalContext(
  config: ModalAnimationConfig.scaleIn(),
);

final button = ButtonStateMachine(buttonCtx);
final modal = ModalStateMachine(modalCtx);
```

### Custom Keyframes

```dart
// Form with custom shake animation
final formConfig = FormAnimationConfig(
  shakeIntensity: 15.0,
  shakeDuration: 400,
  // Shake uses keyframes internally
);

// Or create your own keyframe-based animations
final customAnim = animate()
    .withKeyframes(property, [
      Keyframe(value: 0.0, offset: 0.0),
      Keyframe(value: 10.0, offset: 0.25, easing: Easing.easeOut),
      Keyframe(value: -10.0, offset: 0.5, easing: Easing.easeInOut),
      Keyframe(value: 5.0, offset: 0.75, easing: Easing.easeOut),
      Keyframe(value: 0.0, offset: 1.0),
    ])
    .build();
```

### Reactive State Tracking

```dart
// Track button state changes
effect(() {
  final state = button.currentState.value;
  print('Button state changed to: $state');

  if (state == ButtonState.pressed) {
    // Do something when pressed
  }
});

// Track animation progress
effect(() {
  final opacity = modalCtx.opacity.value;
  print('Modal opacity: $opacity');
});
```

## Best Practices

1. **Choose the Right Pattern**: Use pre-built patterns when they match your use case
2. **Start with Presets**: Begin with preset configs and customize only what you need
3. **Dispose Properly**: Always dispose state machines and controllers when done
4. **Use Effects**: Track state changes reactively with `effect()`
5. **Combine Patterns**: Build complex UIs by combining multiple patterns
6. **Test States**: Test state transitions independently from UI rendering

## Examples

See the `example/` directory for complete working examples of each pattern.

## Contributing

Contributions are welcome! Please feel free to submit a PR with new patterns or improvements to existing ones.

## License

BSD 3-Clause License - see [LICENSE](LICENSE) for details.

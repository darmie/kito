# Kito Animation Cookbook

Practical recipes for common animation patterns.

## Table of Contents

- [UI Feedback](#ui-feedback)
- [Page Transitions](#page-transitions)
- [List Animations](#list-animations)
- [Loading States](#loading-states)
- [Form Interactions](#form-interactions)
- [Gesture Animations](#gesture-animations)
- [Complex Compositions](#complex-compositions)
- [Performance Patterns](#performance-patterns)

---

## UI Feedback

### Recipe 1: Button Press Animation

**Use Case**: Provide tactile feedback when user taps a button.

```dart
class PressableButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const PressableButton({required this.onTap, required this.child});

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  final scale = animatableDouble(1.0);
  final opacity = animatableDouble(1.0);

  void _onTapDown() {
    animate()
        .to(scale, 0.95)
        .to(opacity, 0.7)
        .withDuration(100)
        .withEasing(Easing.easeOut)
        .build()
        .play();
  }

  void _onTapUp() {
    animate()
        .to(scale, 1.0)
        .to(opacity, 1.0)
        .withDuration(100)
        .withEasing(Easing.easeOutBack)
        .build()
        .play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) {
        _onTapUp();
        widget.onTap();
      },
      onTapCancel: _onTapUp,
      child: ReactiveBuilder(
        builder: (context) {
          return Transform.scale(
            scale: scale.value,
            child: Opacity(
              opacity: opacity.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
```

**Usage**:
```dart
PressableButton(
  onTap: () => print('Tapped!'),
  child: Container(
    padding: EdgeInsets.all(16),
    color: Colors.blue,
    child: Text('Press Me'),
  ),
)
```

---

### Recipe 2: Success/Error Feedback

**Use Case**: Visual feedback for form submission or API calls.

```dart
class FeedbackAnimation extends StatelessWidget {
  final isSuccess = signal(false);
  final isError = signal(false);
  final scale = animatableDouble(1.0);
  final color = animatableColor(Colors.blue);

  void showSuccess() {
    isSuccess.value = true;

    // Scale bump
    createBounce(scale, 1.2, config: BounceConfig.light).play();

    // Color change
    animate()
        .to(color, Colors.green)
        .withDuration(300)
        .build()
        .play();

    // Reset after delay
    Future.delayed(Duration(seconds: 2), () {
      isSuccess.value = false;
      animate().to(color, Colors.blue).withDuration(300).build().play();
    });
  }

  void showError() {
    isError.value = true;

    // Shake animation
    createShake(scale, config: ShakeConfig.medium).play();

    // Color change
    animate()
        .to(color, Colors.red)
        .withDuration(300)
        .build()
        .play();

    // Reset after delay
    Future.delayed(Duration(seconds: 2), () {
      isError.value = false;
      animate().to(color, Colors.blue).withDuration(300).build().play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSuccess.value) Icon(Icons.check, color: Colors.white),
                if (isError.value) Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  isSuccess.value ? 'Success!' :
                  isError.value ? 'Error!' :
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## Page Transitions

### Recipe 3: Fade-Slide Page Transition

**Use Case**: Smooth transition between pages with combined effects.

```dart
class FadeSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeSlideTransition({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition> {
  final opacity = animatableDouble(0.0);
  final position = animatableOffset(Offset(0, 20));

  @override
  void initState() {
    super.initState();

    // Entrance animation
    final anim = animate()
        .to(opacity, 1.0)
        .to(position, Offset.zero)
        .withDuration(widget.duration.inMilliseconds)
        .withEasing(Easing.easeOutCubic)
        .withAutoplay()
        .build();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Transform.translate(
          offset: position.value,
          child: Opacity(
            opacity: opacity.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
```

**Usage**:
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        FadeSlideTransition(child: NewPage()),
    transitionDuration: Duration(milliseconds: 300),
  ),
)
```

---

### Recipe 4: Hero-Style Shared Element Transition

**Use Case**: Smooth transition of an element between pages.

```dart
class SharedElementTransition {
  static Future<void> animateBetweenPages({
    required BuildContext context,
    required Rect startRect,
    required Rect endRect,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final position = animatableOffset(startRect.topLeft);
    final size = animatableSize(startRect.size);

    // Show overlay
    final overlay = OverlayEntry(
      builder: (context) => ReactiveBuilder(
        builder: (context) {
          return Positioned(
            left: position.value.dx,
            top: position.value.dy,
            child: SizedBox(
              width: size.value.width,
              height: size.value.height,
              child: child,
            ),
          );
        },
      ),
    );

    Overlay.of(context)!.insert(overlay);

    // Animate to end position
    await animate()
        .to(position, endRect.topLeft)
        .to(size, endRect.size)
        .withDuration(duration.inMilliseconds)
        .withEasing(Easing.easeInOutCubic)
        .build()
        .play();

    overlay.remove();
  }
}
```

---

## List Animations

### Recipe 5: Staggered List Entrance

**Use Case**: Items fade in one by one when list appears.

```dart
class StaggeredList extends StatefulWidget {
  final List<Widget> children;

  const StaggeredList({required this.children});

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList> {
  late List<AnimatableProperty<double>> opacities;
  late List<AnimatableProperty<Offset>> positions;

  @override
  void initState() {
    super.initState();

    // Create animatable properties
    opacities = List.generate(
      widget.children.length,
      (_) => animatableDouble(0.0),
    );

    positions = List.generate(
      widget.children.length,
      (_) => animatableOffset(Offset(0, 20)),
    );

    // Stagger animations
    _animateIn();
  }

  void _animateIn() {
    final animations = <Animation>[];

    for (var i = 0; i < widget.children.length; i++) {
      final anim = animate()
          .to(opacities[i], 1.0)
          .to(positions[i], Offset.zero)
          .withDuration(400)
          .withEasing(Easing.easeOutCubic)
          .build();

      animations.add(anim);
    }

    // Stagger with 100ms delay
    staggerStart(animations, delayMs: 100);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return ListView.builder(
          itemCount: widget.children.length,
          itemBuilder: (context, index) {
            return Transform.translate(
              offset: positions[index].value,
              child: Opacity(
                opacity: opacities[index].value,
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}
```

---

### Recipe 6: Animated List Item Removal

**Use Case**: Smooth removal animation for list items.

```dart
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  final Duration duration;

  const AnimatedListItem({
    required this.child,
    required this.onRemove,
    this.duration = const Duration(milliseconds: 300),
  });

  final opacity = animatableDouble(1.0);
  final offset = animatableOffset(Offset.zero);
  final height = animatableDouble(1.0);

  Future<void> animateRemoval() async {
    final anim = animate()
        .to(offset, Offset(-300, 0))
        .to(opacity, 0.0)
        .to(height, 0.0)
        .withDuration(duration.inMilliseconds)
        .withEasing(Easing.easeInCubic)
        .build();

    await anim.play();
    onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return SizeTransition(
          sizeFactor: AlwaysStoppedAnimation(height.value),
          child: Transform.translate(
            offset: offset.value,
            child: Opacity(
              opacity: opacity.value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
```

---

## Loading States

### Recipe 7: Shimmer Loading Effect

**Use Case**: Skeleton loading animation for content placeholders.

```dart
class ShimmerLoader extends StatefulWidget {
  final Widget child;

  const ShimmerLoader({required this.child});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> {
  final shimmerPosition = animatableDouble(-1.0);

  @override
  void initState() {
    super.initState();

    // Infinite shimmer animation
    animate()
        .to(shimmerPosition, 1.0)
        .withDuration(1500)
        .withEasing(Easing.linear)
        .loopInfinitely()
        .withAutoplay()
        .build();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                shimmerPosition.value - 0.3,
                shimmerPosition.value,
                shimmerPosition.value + 0.3,
              ],
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
```

---

### Recipe 8: Pulse Loading Indicator

**Use Case**: Pulsing animation for loading states.

```dart
class PulseLoader extends StatefulWidget {
  final Color color;
  final double size;

  const PulseLoader({
    this.color = Colors.blue,
    this.size = 50,
  });

  @override
  State<PulseLoader> createState() => _PulseLoaderState();
}

class _PulseLoaderState extends State<PulseLoader> {
  final scale = animatableDouble(1.0);
  final opacity = animatableDouble(1.0);

  @override
  void initState() {
    super.initState();

    // Pulse animation
    createPulse(scale, config: PulseConfig.medium).play();

    // Fade animation
    pingPong(
      property: opacity,
      from: 0.3,
      to: 1.0,
      duration: 800,
      times: -1, // infinite
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Transform.scale(
          scale: scale.value,
          child: Opacity(
            opacity: opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

---

## Form Interactions

### Recipe 9: Animated Text Field Validation

**Use Case**: Visual feedback for form field validation.

```dart
class AnimatedTextField extends StatefulWidget {
  final String? Function(String?) validator;

  const AnimatedTextField({required this.validator});

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
  final controller = TextEditingController();
  final borderColor = animatableColor(Colors.grey);
  final shakeOffset = animatableDouble(0.0);
  final errorOpacity = animatableDouble(0.0);
  String? errorText;

  void _validate(String value) {
    final error = widget.validator(value);

    if (error != null) {
      // Show error
      setState(() => errorText = error);

      // Shake animation
      createShake(shakeOffset, config: ShakeConfig.medium).play();

      // Red border
      animate()
          .to(borderColor, Colors.red)
          .withDuration(300)
          .build()
          .play();

      // Show error text
      animate()
          .to(errorOpacity, 1.0)
          .withDuration(300)
          .build()
          .play();
    } else {
      // Success
      errorText = null;

      // Green border
      animate()
          .to(borderColor, Colors.green)
          .withDuration(300)
          .build()
          .play();

      // Hide error text
      animate()
          .to(errorOpacity, 0.0)
          .withDuration(300)
          .build()
          .play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: Offset(shakeOffset.value, 0),
              child: TextField(
                controller: controller,
                onChanged: _validate,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: borderColor.value,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            Opacity(
              opacity: errorOpacity.value,
              child: Text(
                errorText ?? '',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Gesture Animations

### Recipe 10: Swipeable Card

**Use Case**: Card that can be swiped away like Tinder.

```dart
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const SwipeableCard({
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  final position = animatableOffset(Offset.zero);
  final rotation = animatableDouble(0.0);
  final scale = animatableDouble(1.0);

  Offset? dragStart;
  final swipeThreshold = 100.0;

  void _onPanStart(DragStartDetails details) {
    dragStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (dragStart == null) return;

    final delta = details.localPosition - dragStart!;
    position.value = delta;
    rotation.value = (delta.dx / 200).clamp(-0.26, 0.26); // ±15 degrees
  }

  void _onPanEnd(DragEndDetails details) {
    if (position.value.dx.abs() > swipeThreshold) {
      _swipeAway(position.value.dx > 0);
    } else {
      _snapBack();
    }
  }

  Future<void> _swipeAway(bool right) async {
    final targetX = right ? 400.0 : -400.0;

    await animate()
        .to(position, Offset(targetX, -100))
        .to(rotation, right ? 0.4 : -0.4)
        .to(scale, 0.8)
        .withDuration(300)
        .withEasing(Easing.easeInCubic)
        .build()
        .play();

    if (right) {
      widget.onSwipeRight();
    } else {
      widget.onSwipeLeft();
    }
  }

  void _snapBack() {
    animate()
        .to(position, Offset.zero)
        .to(rotation, 0.0)
        .to(scale, 1.0)
        .withDuration(300)
        .withEasing(Easing.easeOutBack)
        .build()
        .play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: ReactiveBuilder(
        builder: (context) {
          return Transform.translate(
            offset: position.value,
            child: Transform.rotate(
              angle: rotation.value,
              child: Transform.scale(
                scale: scale.value,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

### Recipe 11: Pull-to-Refresh

**Use Case**: Custom pull-to-refresh implementation.

```dart
class CustomPullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomPullToRefresh({
    required this.child,
    required this.onRefresh,
  });

  @override
  State<CustomPullToRefresh> createState() => _CustomPullToRefreshState();
}

class _CustomPullToRefreshState extends State<CustomPullToRefresh> {
  final pullOffset = animatableDouble(0.0);
  final refreshRotation = animatableDouble(0.0);
  final refreshOpacity = animatableDouble(0.0);

  bool isRefreshing = false;
  final threshold = 80.0;

  void _onVerticalDrag(DragUpdateDetails details) {
    if (isRefreshing) return;

    final delta = details.delta.dy;
    if (pullOffset.value > 0 || delta > 0) {
      pullOffset.value = (pullOffset.value + delta).clamp(0.0, threshold * 1.5);

      // Update refresh indicator
      final progress = (pullOffset.value / threshold).clamp(0.0, 1.0);
      refreshOpacity.value = progress;
      refreshRotation.value = progress * 6.28; // Full rotation
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (pullOffset.value >= threshold) {
      _triggerRefresh();
    } else {
      _reset();
    }
  }

  Future<void> _triggerRefresh() async {
    setState(() => isRefreshing = true);

    // Snap to threshold
    animate()
        .to(pullOffset, threshold)
        .withDuration(200)
        .build()
        .play();

    // Spin indicator
    animate()
        .to(refreshRotation, refreshRotation.value + 12.56) // 2 rotations
        .withDuration(1000)
        .loopInfinitely()
        .build()
        .play();

    // Call refresh callback
    await widget.onRefresh();

    // Reset
    setState(() => isRefreshing = false);
    _reset();
  }

  void _reset() {
    animate()
        .to(pullOffset, 0.0)
        .to(refreshOpacity, 0.0)
        .withDuration(300)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onVerticalDrag,
      onVerticalDragEnd: _onDragEnd,
      child: ReactiveBuilder(
        builder: (context) {
          return Stack(
            children: [
              // Refresh indicator
              Positioned(
                top: pullOffset.value - 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: refreshOpacity.value,
                    child: Transform.rotate(
                      angle: refreshRotation.value,
                      child: Icon(
                        Icons.refresh,
                        size: 32,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Transform.translate(
                offset: Offset(0, pullOffset.value),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## Complex Compositions

### Recipe 12: Multi-Step Onboarding

**Use Case**: Step-by-step wizard with page transitions.

```dart
class OnboardingFlow extends StatefulWidget {
  final List<Widget> pages;

  const OnboardingFlow({required this.pages});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int currentPage = 0;
  late List<AnimatableProperty<Offset>> positions;
  late List<AnimatableProperty<double>> opacities;

  @override
  void initState() {
    super.initState();

    positions = List.generate(
      widget.pages.length,
      (_) => animatableOffset(Offset.zero),
    );

    opacities = List.generate(
      widget.pages.length,
      (_) => animatableDouble(0.0),
    );

    // Show first page
    _showPage(0);
  }

  void _showPage(int index) {
    animate()
        .to(positions[index], Offset.zero)
        .to(opacities[index], 1.0)
        .withDuration(500)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();
  }

  Future<void> nextPage() async {
    if (currentPage >= widget.pages.length - 1) return;

    // Slide out current
    await animate()
        .to(positions[currentPage], Offset(-400, 0))
        .to(opacities[currentPage], 0.0)
        .withDuration(400)
        .build()
        .play();

    // Update index
    setState(() => currentPage++);

    // Slide in next
    positions[currentPage].value = Offset(400, 0);
    _showPage(currentPage);
  }

  Future<void> previousPage() async {
    if (currentPage <= 0) return;

    // Slide out current
    await animate()
        .to(positions[currentPage], Offset(400, 0))
        .to(opacities[currentPage], 0.0)
        .withDuration(400)
        .build()
        .play();

    // Update index
    setState(() => currentPage--);

    // Slide in previous
    positions[currentPage].value = Offset(-400, 0);
    _showPage(currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Stack(
          children: [
            // Pages
            ...widget.pages.asMap().entries.map((entry) {
              final index = entry.key;
              if (index != currentPage) return SizedBox.shrink();

              return Transform.translate(
                offset: positions[index].value,
                child: Opacity(
                  opacity: opacities[index].value,
                  child: entry.value,
                ),
              );
            }),

            // Navigation
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentPage > 0)
                    TextButton(
                      onPressed: previousPage,
                      child: Text('Back'),
                    ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: currentPage < widget.pages.length - 1
                        ? nextPage
                        : null,
                    child: Text(
                      currentPage < widget.pages.length - 1
                          ? 'Next'
                          : 'Done',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Performance Patterns

### Recipe 13: Batch Updates

**Use Case**: Update multiple signals efficiently.

```dart
class BatchUpdateExample extends StatelessWidget {
  final x = signal(0);
  final y = signal(0);
  final sum = computed(() => x.value + y.value);

  void updateBoth(int newX, int newY) {
    // Good: batch updates
    batch(() {
      x.value = newX;
      y.value = newY;
    }); // Effects run once

    // Bad: separate updates
    // x.value = newX; // Effects run
    // y.value = newY; // Effects run again
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Text('Sum: ${sum.value}');
      },
    );
  }
}
```

---

### Recipe 14: Debounced Animation Trigger

**Use Case**: Prevent excessive animation triggers.

```dart
class DebouncedAnimator {
  final position = animatableOffset(Offset.zero);
  Timer? _debounceTimer;

  void moveToDebounced(Offset target, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(delay, () {
      animate()
          .to(position, target)
          .withDuration(400)
          .build()
          .play();
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
```

---

## Tips & Best Practices

### Choosing Animation Duration

- **Micro-interactions**: 100-200ms (button press, toggle)
- **Small movements**: 200-300ms (slide, fade)
- **Medium transitions**: 300-500ms (page change, modal)
- **Large animations**: 500-800ms (complex sequences)
- **Background effects**: 1000+ ms (ambient animations)

### Choosing Easing Functions

- **Entrances**: `easeOut` or `easeOutBack` (starts fast, ends slow)
- **Exits**: `easeIn` or `easeInBack` (starts slow, ends fast)
- **Both**: `easeInOut` (smooth both ends)
- **Bouncy**: `easeOutBounce` (playful feedback)
- **Elastic**: `easeOutElastic` (exaggerated spring)
- **Smooth**: `easeOutCubic` (most natural)

### Performance Tips

1. **Batch signal updates** when changing multiple values
2. **Use `peek()`** to read without tracking dependencies
3. **Dispose animations** when widgets are disposed
4. **Limit simultaneous animations** (max 5-10 at once)
5. **Use atomic primitives** instead of building from scratch
6. **Test on low-end devices** to ensure 60fps

### Common Mistakes to Avoid

❌ **Don't**: Create animations in build method
✅ **Do**: Create animations in initState

❌ **Don't**: Forget to dispose animations
✅ **Do**: Always dispose in dispose()

❌ **Don't**: Use setState with Kito
✅ **Do**: Use signals and ReactiveBuilder

❌ **Don't**: Update signals in effect body without peek
✅ **Do**: Use peek() to avoid circular dependencies

❌ **Don't**: Animate every property change
✅ **Do**: Only animate meaningful transitions

---

## Next Steps

1. **Explore the demos**: See `/demo/lib/screens/` for more examples
2. **Read API docs**: Check `/docs/api/` for detailed reference
3. **Try combinations**: Mix and match primitives for custom effects
4. **Profile performance**: Use Flutter DevTools to optimize

Happy cooking! 🍳

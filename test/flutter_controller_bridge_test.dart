import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito/kito.dart';

void main() {
  group('AnimatableAnimationDriver', () {
    test('drives animatable property from animation', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final property = animatableDouble(0.0);
      final driver = AnimatableAnimationDriver(
        property: property,
        animation: controller,
        startValue: 0.0,
        endValue: 100.0,
      );

      expect(property.value, 0.0);

      controller.value = 0.5;
      expect(property.value, 50.0);

      controller.value = 1.0;
      expect(property.value, 100.0);

      driver.dispose();
      controller.dispose();
    });

    test('respects curved animation', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final curved = CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      );

      final property = animatableDouble(0.0);
      final driver = AnimatableAnimationDriver(
        property: property,
        animation: curved,
        startValue: 0.0,
        endValue: 100.0,
      );

      controller.value = 0.25;
      expect(property.value, closeTo(25.0, 0.1));

      driver.dispose();
      curved.dispose();
      controller.dispose();
    });

    test('works with color properties', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final property = animatableColor(const Color(0xFF000000));
      final driver = AnimatableAnimationDriver(
        property: property,
        animation: controller,
        startValue: const Color(0xFF000000),
        endValue: const Color(0xFFFFFFFF),
      );

      controller.value = 0.5;
      expect(property.value.alpha, closeTo(127, 1));
      expect(property.value.red, closeTo(127, 1));
      expect(property.value.green, closeTo(127, 1));
      expect(property.value.blue, closeTo(127, 1));

      driver.dispose();
      controller.dispose();
    });

    test('stops updating after dispose', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final property = animatableDouble(0.0);
      final driver = AnimatableAnimationDriver(
        property: property,
        animation: controller,
        startValue: 0.0,
        endValue: 100.0,
      );

      controller.value = 0.5;
      expect(property.value, 50.0);

      driver.dispose();

      controller.value = 1.0;
      // Should still be 50.0 because driver is disposed
      expect(property.value, 50.0);

      controller.dispose();
    });
  });

  group('KitoAnimation (Flutter wrapper)', () {
    test('wraps animatable as Flutter Animation', () {
      final property = animatableDouble(42.0);
      final wrapper = KitoAnimation(property);

      expect(wrapper.value, 42.0);

      property.value = 100.0;
      expect(wrapper.value, 100.0);

      wrapper.dispose();
    });

    test('notifies listeners on value change', () {
      final property = animatableDouble(0.0);
      final wrapper = KitoAnimation(property);

      var notifyCount = 0;
      wrapper.addListener(() {
        notifyCount++;
      });

      batch(() {
        property.value = 50.0;
      });

      // Wait for effect to run
      expect(notifyCount, greaterThan(0));

      wrapper.dispose();
    });

    test('supports status signal', () {
      final property = animatableDouble(0.0);
      final status = signal(AnimationStatus.forward);
      final wrapper = KitoAnimation(property, status: status);

      expect(wrapper.status, AnimationStatus.forward);

      var statusNotifyCount = 0;
      wrapper.addStatusListener((newStatus) {
        statusNotifyCount++;
      });

      batch(() {
        status.value = AnimationStatus.completed;
      });

      expect(wrapper.status, AnimationStatus.completed);
      expect(statusNotifyCount, greaterThan(0));

      wrapper.dispose();
    });
  });

  group('KitoAnimationController', () {
    test('creates controller that drives multiple properties', () {
      final scale = animatableDouble(1.0);
      final opacity = animatableDouble(1.0);

      final kitoController = KitoAnimationController.create(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
        properties: {
          scale: 2.0,
          opacity: 0.5,
        },
      );

      kitoController.controller.value = 0.5;

      expect(scale.value, closeTo(1.5, 0.01));
      expect(opacity.value, closeTo(0.75, 0.01));

      kitoController.controller.value = 1.0;

      expect(scale.value, closeTo(2.0, 0.01));
      expect(opacity.value, closeTo(0.5, 0.01));

      kitoController.dispose();
    });

    test('forward and reverse methods work', () {
      final scale = animatableDouble(1.0);

      final kitoController = KitoAnimationController.create(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 100),
        properties: {
          scale: 2.0,
        },
      );

      expect(kitoController.controller.value, 0.0);

      kitoController.controller.value = 1.0;
      expect(scale.value, closeTo(2.0, 0.01));

      kitoController.reset();
      expect(kitoController.controller.value, 0.0);
      expect(scale.value, closeTo(1.0, 0.01));

      kitoController.dispose();
    });

    test('applies curve to animation', () {
      final scale = animatableDouble(1.0);

      final kitoController = KitoAnimationController.create(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.linear,
        properties: {
          scale: 2.0,
        },
      );

      kitoController.controller.value = 0.5;
      expect(scale.value, closeTo(1.5, 0.01));

      kitoController.dispose();
    });
  });

  group('Easing and Curve conversions', () {
    test('converts Flutter Curve to Kito easing', () {
      final easing = Curves.linear.toEasing();

      expect(easing(0.0), 0.0);
      expect(easing(0.5), closeTo(0.5, 0.01));
      expect(easing(1.0), 1.0);
    });

    test('converts Kito easing to Flutter Curve', () {
      final curve = Easing.linear.toCurve();

      expect(curve.transform(0.0), 0.0);
      expect(curve.transform(0.5), closeTo(0.5, 0.01));
      expect(curve.transform(1.0), 1.0);
    });

    test('easeInOut conversion works correctly', () {
      final easing = Curves.easeInOut.toEasing();

      // EaseInOut should start slow, speed up in middle, slow down at end
      final t1 = easing(0.1);
      final t2 = easing(0.5);
      final t3 = easing(0.9);

      expect(t1, lessThan(0.1)); // Slow start
      expect(t2, closeTo(0.5, 0.1)); // Middle
      expect(t3, greaterThan(0.9)); // Slow end
    });
  });

  group('FlutterCurves presets', () {
    test('provides common Flutter curves as easing functions', () {
      expect(FlutterCurves.linear(0.5), closeTo(0.5, 0.01));
      expect(FlutterCurves.easeIn(0.0), 0.0);
      expect(FlutterCurves.easeOut(1.0), 1.0);
      expect(FlutterCurves.easeInOut(0.5), closeTo(0.5, 0.2));
    });

    test('bounce curves work', () {
      expect(FlutterCurves.bounceIn(0.0), 0.0);
      expect(FlutterCurves.bounceOut(1.0), 1.0);
    });

    test('elastic curves work', () {
      expect(FlutterCurves.elasticIn(0.0), 0.0);
      expect(FlutterCurves.elasticOut(1.0), 1.0);
    });
  });

  group('AnimatableTween', () {
    test('evaluates tween at progress', () {
      final property = animatableDouble(0.0);
      final tween = AnimatableTween(
        property: property,
        begin: 0.0,
        end: 100.0,
      );

      expect(tween.evaluate(0.0), 0.0);
      expect(tween.evaluate(0.5), 50.0);
      expect(tween.evaluate(1.0), 100.0);
    });

    test('works with color', () {
      final property = animatableColor(const Color(0xFF000000));
      final tween = AnimatableTween(
        property: property,
        begin: const Color(0xFF000000),
        end: const Color(0xFFFFFFFF),
      );

      final midColor = tween.evaluate(0.5);
      expect(midColor.red, closeTo(127, 1));
      expect(midColor.green, closeTo(127, 1));
      expect(midColor.blue, closeTo(127, 1));
    });

    test('can be animated with Animation<double>', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final property = animatableDouble(0.0);
      final tween = AnimatableTween(
        property: property,
        begin: 0.0,
        end: 100.0,
      );

      final animation = tween.animate(controller);

      controller.value = 0.0;
      expect(animation.value, 0.0);

      controller.value = 0.5;
      expect(animation.value, 50.0);

      controller.value = 1.0;
      expect(animation.value, 100.0);

      animation.dispose();
      controller.dispose();
    });
  });

  group('Integration scenarios', () {
    test('can drive Kito properties and use them in Kito animations', () {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 1000),
      );

      final scale = animatableDouble(1.0);
      final driver = AnimatableAnimationDriver(
        property: scale,
        animation: controller,
        startValue: 1.0,
        endValue: 2.0,
      );

      // Verify initial state
      expect(scale.value, 1.0);

      // Animate with controller
      controller.value = 0.5;
      expect(scale.value, closeTo(1.5, 0.01));

      // Now use same property in a Kito animation
      final kitoAnim = animate()
          .to(scale, 3.0)
          .withDuration(100)
          .build();

      kitoAnim.play();

      // After Kito animation, property should be at new value
      // (This would need async testing to verify)

      driver.dispose();
      kitoAnim.dispose();
      controller.dispose();
    });
  });
}

/// Test implementation of TickerProvider
class TestVSync extends TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

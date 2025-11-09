import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kito/kito.dart';

void main() {
  testWidgets('ReactiveBuilder rebuilds when signal changes',
      (WidgetTester tester) async {
    final counter = animatableDouble(0.0);
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactiveBuilder(
            builder: (_) {
              buildCount++;
              return Text('Count: ${counter.value}');
            },
          ),
        ),
      ),
    );

    // Initial build
    expect(buildCount, 1);
    expect(find.text('Count: 0.0'), findsOneWidget);

    // Change the signal
    counter.value = 1.0;
    await tester.pump();

    // Should have rebuilt
    expect(buildCount, greaterThan(1));
    expect(find.text('Count: 1.0'), findsOneWidget);

    // Change again
    final previousBuildCount = buildCount;
    counter.value = 2.0;
    await tester.pump();

    // Should have rebuilt again
    expect(buildCount, greaterThan(previousBuildCount));
    expect(find.text('Count: 2.0'), findsOneWidget);
  });

  testWidgets('Animation updates ReactiveBuilder',
      (WidgetTester tester) async {
    final scale = animatableDouble(1.0);
    int buildCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactiveBuilder(
            builder: (_) {
              buildCount++;
              return Transform.scale(
                scale: scale.value,
                child: const Text('Animated'),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Animated'), findsOneWidget);
    final initialBuildCount = buildCount;

    // Create and play animation
    final animation = animate().to(scale, 2.0, duration: 200).build();
    animation.play();

    // Pump a few frames - the animation should be running
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should have caused rebuilds (animation is updating the signal)
    expect(buildCount, greaterThan(initialBuildCount));

    // Value should have changed from initial
    expect(scale.value, isNot(equals(1.0)));

    animation.dispose();
  });
}

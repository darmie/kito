import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

class BasicAnimationExample extends StatefulWidget {
  const BasicAnimationExample({super.key});

  @override
  State<BasicAnimationExample> createState() => _BasicAnimationExampleState();
}

class _BasicAnimationExampleState extends State<BasicAnimationExample> {
  late AnimatedWidgetProperties boxProps;
  KitoAnimation? animation;

  @override
  void initState() {
    super.initState();
    boxProps = AnimatedWidgetProperties(
      scale: 1.0,
      rotation: 0.0,
      opacity: 1.0,
    );
  }

  void _animate() {
    animation?.dispose();

    animation = animate()
        .to(boxProps.scale, 1.5, easing: Easing.easeOutBack)
        .to(boxProps.rotation, 3.14159, easing: Easing.easeInOutCubic)
        .to(boxProps.opacity, 0.5)
        .withDuration(1500)
        .withDirection(AnimationDirection.alternate)
        .withLoop(2)
        .build();

    animation!.play();
  }

  @override
  void dispose() {
    animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Animations'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            KitoAnimatedWidget(
              properties: boxProps,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _animate,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Animate'),
            ),
          ],
        ),
      ),
    );
  }
}

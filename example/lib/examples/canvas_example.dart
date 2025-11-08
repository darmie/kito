import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

class CanvasExample extends StatefulWidget {
  const CanvasExample({super.key});

  @override
  State<CanvasExample> createState() => _CanvasExampleState();
}

class _CanvasExampleState extends State<CanvasExample> {
  late CanvasAnimationProperties circleProps;
  KitoAnimation? animation;

  @override
  void initState() {
    super.initState();

    circleProps = CanvasAnimationProperties(
      position: const Offset(150, 150),
      size: const Size(50, 50),
      color: Colors.blue,
      scale: 1.0,
    );
  }

  void _animate() {
    animation?.dispose();

    animation = animate()
        .to(circleProps.position, const Offset(150, 300),
            easing: Easing.easeInOutBack)
        .to(circleProps.scale, 2.0, easing: Easing.easeOutElastic)
        .to(circleProps.color, Colors.red)
        .withDuration(2000)
        .withDirection(AnimationDirection.alternate)
        .loopInfinitely()
        .build();

    animation!.play();
  }

  void _stop() {
    animation?.stop();
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
        title: const Text('Canvas Animations'),
      ),
      body: Column(
        children: [
          Expanded(
            child: KitoCanvas(
              painter: CirclePainter(circleProps),
              size: const Size(300, 400),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _animate,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Animate'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

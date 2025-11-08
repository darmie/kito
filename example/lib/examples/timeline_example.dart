import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';

class TimelineExample extends StatefulWidget {
  const TimelineExample({super.key});

  @override
  State<TimelineExample> createState() => _TimelineExampleState();
}

class _TimelineExampleState extends State<TimelineExample> {
  late AnimatedWidgetProperties box1Props;
  late AnimatedWidgetProperties box2Props;
  late AnimatedWidgetProperties box3Props;
  Timeline? timeline;

  @override
  void initState() {
    super.initState();

    box1Props = AnimatedWidgetProperties(translateX: -200);
    box2Props = AnimatedWidgetProperties(translateY: -200);
    box3Props = AnimatedWidgetProperties(scale: 0);
  }

  void _animateSequential() {
    timeline?.dispose();

    final anim1 = animate()
        .to(box1Props.translateX, 0, easing: Easing.easeOutBack)
        .withDuration(800)
        .build();

    final anim2 = animate()
        .to(box2Props.translateY, 0, easing: Easing.easeOutBack)
        .withDuration(800)
        .build();

    final anim3 = animate()
        .to(box3Props.scale, 1.0, easing: Easing.easeOutElastic)
        .withDuration(1000)
        .build();

    timeline = Timeline()
      ..add(anim1)
      ..add(anim2)
      ..add(anim3)
      ..play();
  }

  void _animateConcurrent() {
    timeline?.dispose();

    final anim1 = animate()
        .to(box1Props.translateX, 0, easing: Easing.easeOutBack)
        .withDuration(800)
        .build();

    final anim2 = animate()
        .to(box2Props.translateY, 0, easing: Easing.easeOutBack)
        .withDuration(800)
        .build();

    final anim3 = animate()
        .to(box3Props.scale, 1.0, easing: Easing.easeOutElastic)
        .withDuration(1000)
        .build();

    timeline = Timeline()
      ..add(anim1)
      ..add(anim2, position: TimelinePosition.concurrent)
      ..add(anim3, position: TimelinePosition.concurrent)
      ..play();
  }

  void _reset() {
    timeline?.stop();
    setState(() {
      box1Props.translateX.value = -200;
      box2Props.translateY.value = -200;
      box3Props.scale.value = 0;
    });
  }

  @override
  void dispose() {
    timeline?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Animations'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KitoAnimatedWidget(
                    properties: box1Props,
                    child: _buildBox(Colors.red),
                  ),
                  const SizedBox(height: 16),
                  KitoAnimatedWidget(
                    properties: box2Props,
                    child: _buildBox(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  KitoAnimatedWidget(
                    properties: box3Props,
                    child: _buildBox(Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _animateSequential,
                      child: const Text('Sequential'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _animateConcurrent,
                      child: const Text('Concurrent'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

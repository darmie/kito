import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

class EasingExample extends StatefulWidget {
  const EasingExample({super.key});

  @override
  State<EasingExample> createState() => _EasingExampleState();
}

class _EasingExampleState extends State<EasingExample> {
  final List<_EasingDemo> _demos = [];
  final List<({String name, EasingFunction fn})> _easings = [
    (name: 'Linear', fn: Easing.linear),
    (name: 'EaseInQuad', fn: Easing.easeInQuad),
    (name: 'EaseOutQuad', fn: Easing.easeOutQuad),
    (name: 'EaseInOutQuad', fn: Easing.easeInOutQuad),
    (name: 'EaseInCubic', fn: Easing.easeInCubic),
    (name: 'EaseOutCubic', fn: Easing.easeOutCubic),
    (name: 'EaseInOutBack', fn: Easing.easeInOutBack),
    (name: 'EaseOutElastic', fn: Easing.easeOutElastic),
    (name: 'EaseOutBounce', fn: Easing.easeOutBounce),
  ];

  @override
  void initState() {
    super.initState();
    for (final easing in _easings) {
      _demos.add(_EasingDemo(
        name: easing.name,
        easing: easing.fn,
      ));
    }
  }

  void _animateAll() {
    for (final demo in _demos) {
      demo.animate();
    }
  }

  @override
  void dispose() {
    for (final demo in _demos) {
      demo.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easing Functions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _demos.length,
              itemBuilder: (context, index) {
                final demo = _demos[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demo.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            KitoAnimatedWidget(
                              properties: demo.props,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: _animateAll,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Animate All'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EasingDemo {
  final String name;
  final EasingFunction easing;
  late AnimatedWidgetProperties props;
  KitoAnimation? animation;

  _EasingDemo({
    required this.name,
    required this.easing,
  }) {
    props = AnimatedWidgetProperties(translateX: 0);
  }

  void animate() {
    animation?.dispose();

    // Get screen width - 80 (40 for box width, 40 for padding)
    const maxTranslate = 300.0;

    animation = animate()
        .to(props.translateX, maxTranslate, easing: easing)
        .withDuration(1500)
        .withDirection(AnimationDirection.alternate)
        .withLoop(1)
        .build();

    animation!.play();
  }

  void dispose() {
    animation?.dispose();
  }
}

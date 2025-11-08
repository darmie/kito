import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

/// Example demonstrating Flutter AnimationController integration with Kito
///
/// This file shows three main integration patterns:
/// 1. Drive Kito animatables with AnimationController
/// 2. Convert Kito animations to AnimationController
/// 3. Use Flutter Curves with Kito animations

void main() {
  runApp(const FlutterControllerIntegrationApp());
}

class FlutterControllerIntegrationApp extends StatelessWidget {
  const FlutterControllerIntegrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito Flutter Controller Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExamplesHomePage(),
    );
  }
}

class ExamplesHomePage extends StatelessWidget {
  const ExamplesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kito ↔ Flutter Controller'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Drive Kito with AnimationController',
            'Use Flutter\'s AnimationController to drive Kito properties',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ControllerDrivesKitoExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Use Flutter Curves with Kito',
            'Apply Flutter\'s built-in curves to Kito animations',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FlutterCurvesExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'KitoAnimationController',
            'Unified controller managing multiple Kito properties',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const KitoControllerExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Side-by-side Comparison',
            'Compare Kito and Flutter animations',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComparisonExample(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 1: Drive Kito animatables with Flutter's AnimationController
class ControllerDrivesKitoExample extends StatefulWidget {
  const ControllerDrivesKitoExample({super.key});

  @override
  State<ControllerDrivesKitoExample> createState() =>
      _ControllerDrivesKitoExampleState();
}

class _ControllerDrivesKitoExampleState
    extends State<ControllerDrivesKitoExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;
  late final AnimatableProperty<double> scale;
  late final AnimatableProperty<double> opacity;
  late final AnimatableAnimationDriver<double> scaleDriver;
  late final AnimatableAnimationDriver<double> opacityDriver;

  @override
  void initState() {
    super.initState();

    // Create AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Apply a curve
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // Create Kito animatable properties
    scale = animatableDouble(1.0);
    opacity = animatableDouble(0.0);

    // Drive Kito properties with AnimationController
    scaleDriver = AnimatableAnimationDriver(
      property: scale,
      animation: _curvedAnimation,
      startValue: 1.0,
      endValue: 1.5,
    );

    opacityDriver = AnimatableAnimationDriver(
      property: opacity,
      animation: _curvedAnimation,
      startValue: 0.0,
      endValue: 1.0,
    );
  }

  @override
  void dispose() {
    scaleDriver.dispose();
    opacityDriver.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AnimationController → Kito'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: opacity.value,
                  child: Transform.scale(
                    scale: scale.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                if (_controller.status == AnimationStatus.completed) {
                  _controller.reverse();
                } else {
                  _controller.forward();
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Animate'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 2: Use Flutter Curves with Kito
class FlutterCurvesExample extends StatefulWidget {
  const FlutterCurvesExample({super.key});

  @override
  State<FlutterCurvesExample> createState() => _FlutterCurvesExampleState();
}

class _FlutterCurvesExampleState extends State<FlutterCurvesExample> {
  final scale = animatableDouble(1.0);
  KitoAnimation? animation;

  void _animate(Curve curve) {
    animation?.dispose();

    // Convert Flutter Curve to Kito easing function
    final easing = curve.toEasing();

    animation = animate()
        .to(scale, 1.5)
        .withDuration(800)
        .withEasing(easing)
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
        title: const Text('Flutter Curves with Kito'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _SignalListenable(scale.signal),
              builder: (context, child) {
                return Transform.scale(
                  scale: scale.value,
                  child: child,
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => _animate(Curves.bounceOut),
                  child: const Text('Bounce'),
                ),
                ElevatedButton(
                  onPressed: () => _animate(Curves.elasticOut),
                  child: const Text('Elastic'),
                ),
                ElevatedButton(
                  onPressed: () => _animate(Curves.easeInOutCubic),
                  child: const Text('Ease In Out'),
                ),
                ElevatedButton(
                  onPressed: () => _animate(Curves.fastOutSlowIn),
                  child: const Text('Fast Out Slow In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: KitoAnimationController - unified controller
class KitoControllerExample extends StatefulWidget {
  const KitoControllerExample({super.key});

  @override
  State<KitoControllerExample> createState() => _KitoControllerExampleState();
}

class _KitoControllerExampleState extends State<KitoControllerExample>
    with SingleTickerProviderStateMixin {
  late final KitoAnimationController kitoController;
  late final AnimatableProperty<double> scale;
  late final AnimatableProperty<double> opacity;
  late final AnimatableProperty<double> rotation;

  @override
  void initState() {
    super.initState();

    scale = animatableDouble(1.0);
    opacity = animatableDouble(1.0);
    rotation = animatableDouble(0.0);

    // Create KitoAnimationController that manages multiple properties
    kitoController = KitoAnimationController.create(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutBack,
      properties: {
        scale: 1.5,
        opacity: 0.5,
        rotation: 3.14159, // π radians (180 degrees)
      },
    );
  }

  @override
  void dispose() {
    kitoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KitoAnimationController'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: kitoController.controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: rotation.value,
                  child: Transform.scale(
                    scale: scale.value,
                    child: Opacity(
                      opacity: opacity.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => kitoController.forward(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Forward'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => kitoController.reverse(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Reverse'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => kitoController.reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 4: Side-by-side comparison
class ComparisonExample extends StatefulWidget {
  const ComparisonExample({super.key});

  @override
  State<ComparisonExample> createState() => _ComparisonExampleState();
}

class _ComparisonExampleState extends State<ComparisonExample>
    with SingleTickerProviderStateMixin {
  // Flutter's approach
  late final AnimationController _flutterController;
  late final Animation<double> _flutterScale;

  // Kito's approach
  late final AnimatableProperty<double> kitoScale;
  late final KitoAnimation kitoAnimation;

  @override
  void initState() {
    super.initState();

    // Flutter setup
    _flutterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _flutterScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _flutterController, curve: Curves.elasticOut),
    );

    // Kito setup
    kitoScale = animatableDouble(1.0);
    kitoAnimation = animate()
        .to(kitoScale, 1.5)
        .withDuration(1000)
        .withEasing(Easing.easeOutElastic)
        .build();
  }

  @override
  void dispose() {
    _flutterController.dispose();
    kitoAnimation.dispose();
    super.dispose();
  }

  void _animateBoth() {
    _flutterController.forward(from: 0);
    kitoAnimation.restart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Side-by-Side Comparison'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flutter AnimationController
                Column(
                  children: [
                    const Text(
                      'Flutter AnimationController',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _flutterController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _flutterScale.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                // Kito Animation
                Column(
                  children: [
                    const Text(
                      'Kito Animation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _SignalListenable(kitoScale.signal),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: kitoScale.value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _animateBoth,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Animate Both'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to make Signal work with AnimatedBuilder
class _SignalListenable<T> extends ChangeNotifier {
  final Signal<T> _signal;
  late final void Function() _dispose;

  _SignalListenable(this._signal) {
    _dispose = effect(() {
      _signal.value; // Track dependency
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

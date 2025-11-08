import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';

/// Example demonstrating Kito performance profiling tools
///
/// This file shows how to:
/// 1. Profile individual animations
/// 2. Use the performance overlay
/// 3. View detailed metrics
/// 4. Detect performance issues

void main() {
  runApp(const PerformanceProfilingApp());
}

class PerformanceProfilingApp extends StatelessWidget {
  const PerformanceProfilingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito Performance Profiling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProfilingExamplesPage(),
    );
  }
}

class ProfilingExamplesPage extends StatelessWidget {
  const ProfilingExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Profiling'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Performance Overlay',
            'Real-time FPS monitoring overlay',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PerformanceOverlayExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Animation Profiling',
            'Profile specific animations and view metrics',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AnimationProfilingExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Performance Comparison',
            'Compare different animation strategies',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PerformanceComparisonExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Batch Profiling',
            'Profile multiple animations at once',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BatchProfilingExample(),
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

/// Example 1: Performance Overlay
class PerformanceOverlayExample extends StatefulWidget {
  const PerformanceOverlayExample({super.key});

  @override
  State<PerformanceOverlayExample> createState() =>
      _PerformanceOverlayExampleState();
}

class _PerformanceOverlayExampleState
    extends State<PerformanceOverlayExample> {
  late final AnimatableProperty<double> scale;
  late final AnimatableProperty<double> rotation;
  KitoAnimation? animation;

  @override
  void initState() {
    super.initState();
    scale = animatableDouble(1.0);
    rotation = animatableDouble(0.0);
  }

  void _startAnimation() {
    animation?.dispose();

    animation = animate()
        .to(scale, 1.5)
        .to(rotation, 6.28)
        .withDuration(2000)
        .withEasing(Easing.easeInOutCubic)
        .withDirection(AnimationDirection.alternate)
        .loopInfinitely()
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
    return KitoPerformanceOverlay(
      enabled: true,
      position: PerformanceOverlayPosition.topRight,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Performance Overlay'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _SignalListenable(scale.signal),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: rotation.value,
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
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _startAnimation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Animation'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Watch the performance overlay in the top-right corner',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 2: Animation Profiling with Metrics
class AnimationProfilingExample extends StatefulWidget {
  const AnimationProfilingExample({super.key});

  @override
  State<AnimationProfilingExample> createState() =>
      _AnimationProfilingExampleState();
}

class _AnimationProfilingExampleState extends State<AnimationProfilingExample> {
  late final AnimatableProperty<double> scale;
  KitoAnimation? animation;
  AnimationMetrics? metrics;

  @override
  void initState() {
    super.initState();
    scale = animatableDouble(1.0);
    AnimationProfiler().enableAutoProfiling();
  }

  void _runProfiledAnimation() {
    animation?.dispose();

    setState(() {
      metrics = null;
    });

    animation = animate()
        .to(scale, 2.0)
        .withDuration(1000)
        .withEasing(Easing.easeOutElastic)
        .build()
        .withProfiling('elastic-animation');

    animation!.onComplete(() {
      setState(() {
        metrics = AnimationProfiler().getMetrics('elastic-animation');
      });
    });

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
        title: const Text('Animation Profiling'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _runProfiledAnimation,
                icon: const Icon(Icons.analytics),
                label: const Text('Run Profiled Animation'),
              ),
              const SizedBox(height: 32),
              if (metrics != null)
                PerformanceStats(
                  metrics: metrics!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 3: Performance Comparison
class PerformanceComparisonExample extends StatefulWidget {
  const PerformanceComparisonExample({super.key});

  @override
  State<PerformanceComparisonExample> createState() =>
      _PerformanceComparisonExampleState();
}

class _PerformanceComparisonExampleState
    extends State<PerformanceComparisonExample> {
  AnimationMetrics? fastMetrics;
  AnimationMetrics? slowMetrics;

  @override
  void initState() {
    super.initState();
    AnimationProfiler().enableAutoProfiling();
  }

  void _runFastAnimation() {
    final scale = animatableDouble(1.0);

    final animation = animate()
        .to(scale, 1.5)
        .withDuration(300)
        .withEasing(Easing.easeOutCubic)
        .build()
        .withProfiling('fast-animation');

    animation.onComplete(() {
      setState(() {
        fastMetrics = AnimationProfiler().getMetrics('fast-animation');
      });
    });

    animation.play();
  }

  void _runSlowAnimation() {
    final scale = animatableDouble(1.0);

    final animation = animate()
        .to(scale, 1.5)
        .withDuration(2000)
        .withEasing(Easing.easeInOutQuint)
        .build()
        .withProfiling('slow-animation');

    animation.onComplete(() {
      setState(() {
        slowMetrics = AnimationProfiler().getMetrics('slow-animation');
      });
    });

    animation.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _runFastAnimation,
                  child: const Text('Fast Animation\n(300ms)'),
                ),
                ElevatedButton(
                  onPressed: _runSlowAnimation,
                  child: const Text('Slow Animation\n(2000ms)'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (fastMetrics != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fast Animation Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PerformanceStats(metrics: fastMetrics!),
                  const SizedBox(height: 16),
                  FrameTimeline(
                    frameTimings: fastMetrics!.frameTimings,
                    height: 80,
                  ),
                ],
              ),
            const SizedBox(height: 32),
            if (slowMetrics != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Slow Animation Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PerformanceStats(metrics: slowMetrics!),
                  const SizedBox(height: 16),
                  FrameTimeline(
                    frameTimings: slowMetrics!.frameTimings,
                    height: 80,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Example 4: Batch Profiling
class BatchProfilingExample extends StatefulWidget {
  const BatchProfilingExample({super.key});

  @override
  State<BatchProfilingExample> createState() => _BatchProfilingExampleState();
}

class _BatchProfilingExampleState extends State<BatchProfilingExample> {
  final BatchProfiler _batchProfiler = BatchProfiler();
  String? summary;

  void _runBatch() {
    final animationIds = ['anim1', 'anim2', 'anim3', 'anim4'];
    _batchProfiler.startBatch(animationIds);

    // Run multiple animations
    for (int i = 0; i < animationIds.length; i++) {
      final scale = animatableDouble(1.0);
      final duration = 500 + (i * 200);

      final animation = animate()
          .to(scale, 1.5)
          .withDuration(duration)
          .withEasing(Easing.easeInOutCubic)
          .build()
          .withProfiling(animationIds[i]);

      animation.play();

      // Stop profiling when the last animation completes
      if (i == animationIds.length - 1) {
        animation.onComplete(() {
          setState(() {
            _batchProfiler.stopBatch();
            summary = _batchProfiler.getSummary();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Profiling'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _runBatch,
                icon: const Icon(Icons.batch_prediction),
                label: const Text('Run Batch of 4 Animations'),
              ),
              const SizedBox(height: 32),
              if (summary != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      summary!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to make Signal work with AnimatedBuilder
class _SignalListenable extends ChangeNotifier {
  final Signal _signal;
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

import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

/// Example demonstrating SVG path morphing capabilities
///
/// This file shows how to:
/// 1. Parse SVG path data strings
/// 2. Create morphing animations between shapes
/// 3. Use the animatable SVG path property
/// 4. Create complex shape transitions

void main() {
  runApp(const SvgPathMorphingApp());
}

class SvgPathMorphingApp extends StatelessWidget {
  const SvgPathMorphingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito SVG Path Morphing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MorphingExamplesPage(),
    );
  }
}

class MorphingExamplesPage extends StatelessWidget {
  const MorphingExamplesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Path Morphing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Simple Shape Morph',
            'Circle to square transformation',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SimpleShapeMorphExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Star to Pentagon',
            'Complex polygon morphing',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StarToPentagonExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Icon Morphing',
            'Morph between different icon shapes',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const IconMorphingExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Path Animation Loop',
            'Continuous morphing loop between multiple shapes',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PathLoopExample(),
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

/// Example 1: Simple shape morphing (circle to square)
class SimpleShapeMorphExample extends StatefulWidget {
  const SimpleShapeMorphExample({super.key});

  @override
  State<SimpleShapeMorphExample> createState() =>
      _SimpleShapeMorphExampleState();
}

class _SimpleShapeMorphExampleState extends State<SimpleShapeMorphExample> {
  late final SvgAnimationProperties props;
  late final SvgPath circlePath;
  late final SvgPath squarePath;
  KitoAnimation? animation;

  @override
  void initState() {
    super.initState();

    props = SvgAnimationProperties(
      morphProgress: 0.0,
      fillColor: Colors.blue,
      strokeColor: Colors.blueAccent,
      strokeWidth: 2.0,
    );

    // Create a circle using SVG path
    circlePath = SvgPath.fromString(
      'M 50,10 A 40,40 0 1,1 50,90 A 40,40 0 1,1 50,10 Z',
    );

    // Create a square
    squarePath = SvgPath.fromString(
      'M 10,10 L 90,10 L 90,90 L 10,90 Z',
    );
  }

  void _morph() {
    animation?.dispose();

    final targetProgress = props.morphProgress.value < 0.5 ? 1.0 : 0.0;

    animation = animate()
        .to(props.morphProgress, targetProgress)
        .withDuration(1000)
        .withEasing(Easing.easeInOutCubic)
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
        title: const Text('Circle ↔ Square'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: svgMorphPath(
                startPath: circlePath,
                endPath: squarePath,
                properties: props,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _morph,
              icon: const Icon(Icons.transform),
              label: const Text('Morph'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 2: Star to Pentagon
class StarToPentagonExample extends StatefulWidget {
  const StarToPentagonExample({super.key});

  @override
  State<StarToPentagonExample> createState() => _StarToPentagonExampleState();
}

class _StarToPentagonExampleState extends State<StarToPentagonExample> {
  late final SvgAnimationProperties props;
  KitoAnimation? animation;

  // 5-pointed star
  final String starPath =
      'M 50,10 L 61,35 L 88,35 L 67,52 L 76,79 L 50,62 L 24,79 L 33,52 L 12,35 L 39,35 Z';

  // Pentagon
  final String pentagonPath =
      'M 50,10 L 90,35 L 73,75 L 27,75 L 10,35 Z';

  @override
  void initState() {
    super.initState();

    props = SvgAnimationProperties(
      morphProgress: 0.0,
      fillColor: Colors.amber,
      strokeColor: Colors.orange,
      strokeWidth: 3.0,
    );
  }

  void _morph() {
    animation?.dispose();

    final targetProgress = props.morphProgress.value < 0.5 ? 1.0 : 0.0;

    animation = animate()
        .to(props.morphProgress, targetProgress)
        .withDuration(1200)
        .withEasing(Easing.easeInOutBack)
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
        title: const Text('Star ↔ Pentagon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: svgMorphPathString(
                startPathData: starPath,
                endPathData: pentagonPath,
                properties: props,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _morph,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Transform'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 3: Icon morphing
class IconMorphingExample extends StatefulWidget {
  const IconMorphingExample({super.key});

  @override
  State<IconMorphingExample> createState() => _IconMorphingExampleState();
}

class _IconMorphingExampleState extends State<IconMorphingExample> {
  late final SvgAnimationProperties props;
  int currentShapeIndex = 0;
  KitoAnimation? animation;

  // Simple icon paths (play, pause, stop)
  final List<String> iconPaths = [
    // Play button (triangle)
    'M 20,10 L 80,50 L 20,90 Z',
    // Pause button (two rectangles)
    'M 25,10 L 40,10 L 40,90 L 25,90 Z M 60,10 L 75,10 L 75,90 L 60,90 Z',
    // Stop button (square)
    'M 20,20 L 80,20 L 80,80 L 20,80 Z',
  ];

  @override
  void initState() {
    super.initState();

    props = SvgAnimationProperties(
      morphProgress: 0.0,
      fillColor: Colors.green,
      strokeColor: Colors.greenAccent,
      strokeWidth: 2.0,
    );
  }

  void _morphToNext() {
    animation?.dispose();

    // Reset progress and change shape
    props.morphProgress.value = 0.0;
    setState(() {
      currentShapeIndex = (currentShapeIndex + 1) % iconPaths.length;
    });

    // Animate morph
    animation = animate()
        .to(props.morphProgress, 1.0)
        .withDuration(800)
        .withEasing(Easing.easeInOutCubic)
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
    final startIndex = currentShapeIndex;
    final endIndex = (currentShapeIndex + 1) % iconPaths.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Morphing'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: svgMorphPathString(
                startPathData: iconPaths[startIndex],
                endPathData: iconPaths[endIndex],
                properties: props,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _morphToNext,
              icon: const Icon(Icons.skip_next),
              label: const Text('Next Shape'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 4: Continuous morphing loop
class PathLoopExample extends StatefulWidget {
  const PathLoopExample({super.key});

  @override
  State<PathLoopExample> createState() => _PathLoopExampleState();
}

class _PathLoopExampleState extends State<PathLoopExample> {
  late final SvgAnimationProperties props;
  late final AnimatableSvgPath animatablePath;
  KitoAnimation? animation;

  // Multiple shapes to morph between
  final List<String> shapes = [
    'M 50,10 A 40,40 0 1,1 50,90 A 40,40 0 1,1 50,10 Z', // Circle
    'M 10,10 L 90,10 L 90,90 L 10,90 Z', // Square
    'M 50,10 L 90,90 L 10,90 Z', // Triangle
    'M 50,10 L 61,35 L 88,35 L 67,52 L 76,79 L 50,62 L 24,79 L 33,52 L 12,35 L 39,35 Z', // Star
  ];

  int currentShapeIndex = 0;

  @override
  void initState() {
    super.initState();

    props = SvgAnimationProperties(
      fillColor: Colors.purple,
      strokeColor: Colors.purpleAccent,
      strokeWidth: 2.0,
    );

    animatablePath = animatableSvgPathString(shapes[0]);

    _startLoop();
  }

  void _startLoop() {
    _morphToNext();
  }

  void _morphToNext() {
    animation?.dispose();

    final nextIndex = (currentShapeIndex + 1) % shapes.length;
    final targetPath = SvgPath.fromString(shapes[nextIndex]);

    animation = animate()
        .to(animatablePath, targetPath)
        .withDuration(1500)
        .withEasing(Easing.easeInOutCubic)
        .onComplete(() {
          setState(() {
            currentShapeIndex = nextIndex;
          });
          // Continue the loop after a delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _morphToNext();
            }
          });
        })
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
        title: const Text('Continuous Loop'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _PathListenable(animatablePath.signal),
              builder: (context, _) {
                final path = animatablePath.value.toPath();
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: _SimpleSvgPainter(
                    path: path,
                    fillColor: props.fillColor.value,
                    strokeColor: props.strokeColor.value,
                    strokeWidth: props.strokeWidth.value,
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Text(
              'Shape ${currentShapeIndex + 1} of ${shapes.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple painter for SVG paths
class _SimpleSvgPainter extends CustomPainter {
  final ui.Path path;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  _SimpleSvgPainter({
    required this.path,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_SimpleSvgPainter oldDelegate) {
    return path != oldDelegate.path ||
        fillColor != oldDelegate.fillColor ||
        strokeColor != oldDelegate.strokeColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// Helper to make Signal work with AnimatedBuilder
class _PathListenable extends ChangeNotifier {
  final Signal<SvgPath> _signal;
  late final void Function() _dispose;

  _PathListenable(this._signal) {
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

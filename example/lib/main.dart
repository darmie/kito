import 'package:flutter/material.dart';
import 'examples/basic_animation_example.dart';
import 'examples/reactive_example.dart';
import 'examples/canvas_example.dart';
import 'examples/timeline_example.dart';
import 'examples/easing_example.dart';

void main() {
  runApp(const KitoExampleApp());
}

class KitoExampleApp extends StatelessWidget {
  const KitoExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito Animation Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplesList(),
    );
  }
}

class ExamplesList extends StatelessWidget {
  const ExamplesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kito Animation Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ExampleCard(
            title: 'Basic Animations',
            description: 'Simple property animations with easing',
            icon: Icons.animation,
            onTap: () => _navigate(context, const BasicAnimationExample()),
          ),
          _ExampleCard(
            title: 'Reactive State',
            description: 'Fine-grained reactivity with signals and computed values',
            icon: Icons.sync,
            onTap: () => _navigate(context, const ReactiveExample()),
          ),
          _ExampleCard(
            title: 'Canvas Animations',
            description: 'Custom paint and canvas animations',
            icon: Icons.brush,
            onTap: () => _navigate(context, const CanvasExample()),
          ),
          _ExampleCard(
            title: 'Timeline',
            description: 'Sequence multiple animations',
            icon: Icons.timeline,
            onTap: () => _navigate(context, const TimelineExample()),
          ),
          _ExampleCard(
            title: 'Easing Functions',
            description: 'Compare different easing functions',
            icon: Icons.show_chart,
            onTap: () => _navigate(context, const EasingExample()),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ExampleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

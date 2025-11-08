import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';

class ReactiveExample extends StatefulWidget {
  const ReactiveExample({super.key});

  @override
  State<ReactiveExample> createState() => _ReactiveExampleState();
}

class _ReactiveExampleState extends State<ReactiveExample> {
  late Signal<int> count;
  late Computed<int> doubled;
  late Computed<int> quadrupled;
  late Computed<String> message;

  @override
  void initState() {
    super.initState();

    // Create reactive signals
    count = signal(0);

    // Create computed values that automatically update
    doubled = computed(() => count.value * 2);
    quadrupled = computed(() => doubled.value * 2);
    message = computed(() {
      final c = count.value;
      if (c == 0) return 'Click the button!';
      if (c < 5) return 'Getting started...';
      if (c < 10) return 'Keep going!';
      return 'You\'re on fire! 🔥';
    });
  }

  void _increment() {
    setState(() {
      count.value++;
    });
  }

  void _reset() {
    setState(() {
      count.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactive State'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message.value,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _StatCard(
                label: 'Count',
                value: count.value.toString(),
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _StatCard(
                label: 'Doubled',
                value: doubled.value.toString(),
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _StatCard(
                label: 'Quadrupled',
                value: quadrupled.value.toString(),
                color: Colors.orange,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _increment,
                    icon: const Icon(Icons.add),
                    label: const Text('Increment'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/reactive_builder.dart';
import '../widgets/demo_card.dart';

class InteractiveDemoScreen extends StatelessWidget {
  const InteractiveDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Patterns'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.2,
        children: const [
          _PullToRefreshDemo(),
          _DragShuffleListDemo(),
        ],
      ),
    );
  }
}

// Pull-to-Refresh Demo
class _PullToRefreshDemo extends StatefulWidget {
  const _PullToRefreshDemo();

  @override
  State<_PullToRefreshDemo> createState() => _PullToRefreshDemoState();
}

class _PullToRefreshDemoState extends State<_PullToRefreshDemo> {
  late final pullOffset = animatableDouble(0.0);
  late final refreshRotation = animatableDouble(0.0);
  late final refreshOpacity = animatableDouble(0.0);
  late final refreshScale = animatableDouble(1.0);

  bool isRefreshing = false;
  bool isPulling = false;
  final threshold = 80.0;
  int refreshCount = 0;

  void _trigger() {
    // Reset
    refreshCount = 0;
    isPulling = false;
    isRefreshing = false;

    // Simulate pull-to-refresh sequence
    _simulatePull();
  }

  void _simulatePull() async {
    isPulling = true;

    // Pull down animation
    final pullAnim = animate()
        .to(pullOffset, threshold + 20)
        .to(refreshOpacity, 1.0)
        .to(refreshScale, 1.2)
        .withDuration(800)
        .withEasing(Easing.easeOutCubic)
        .build();

    pullAnim.play();

    // Start rotating
    _startRotation();

    // Wait then release
    await Future.delayed(const Duration(milliseconds: 1000));

    // Trigger refresh
    setState(() => isRefreshing = true);

    // Snap to threshold
    final snapAnim = animate()
        .to(pullOffset, threshold)
        .to(refreshScale, 1.0)
        .withDuration(300)
        .withEasing(Easing.easeOutBack)
        .build();

    snapAnim.play();

    // Simulate refresh work
    await Future.delayed(const Duration(milliseconds: 1500));

    // Complete
    setState(() {
      isRefreshing = false;
      isPulling = false;
      refreshCount++;
    });

    // Hide animation
    final hideAnim = animate()
        .to(pullOffset, 0.0)
        .to(refreshOpacity, 0.0)
        .to(refreshRotation, 0.0)
        .withDuration(400)
        .withEasing(Easing.easeInCubic)
        .build();

    hideAnim.play();
  }

  void _startRotation() {
    if (isRefreshing || isPulling) {
      final rotAnim = animate()
          .to(refreshRotation, refreshRotation.value + 360.0)
          .withDuration(1000)
          .withEasing(Easing.linear)
          .onComplete(() => _startRotation())
          .build();

      rotAnim.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Pull-to-Refresh',
      description: 'Interactive pull gesture pattern',
      onTrigger: _trigger,
      codeSnippet: '''final fsm = PullToRefreshStateMachine(
  config: PullToRefreshConfig.elastic,
  onRefresh: () async {
    await fetchData();
  },
);

// User pulls down
fsm.dispatch(PullToRefreshEvent.startPull);
fsm.dispatch(PullToRefreshEvent.updatePull);
fsm.dispatch(PullToRefreshEvent.release);''',
      child: ReactiveBuilder(
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Refresh indicator
              SizedBox(
                height: 60,
                child: Opacity(
                  opacity: refreshOpacity.value,
                  child: Transform.scale(
                    scale: refreshScale.value,
                    child: Transform.rotate(
                      angle: refreshRotation.value * (3.14159 / 180),
                      child: Icon(
                        isRefreshing ? Icons.refresh : Icons.arrow_downward,
                        size: 40,
                        color: Color.lerp(
                          Colors.grey,
                          Theme.of(context).colorScheme.primary,
                          (pullOffset.value / threshold).clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content area
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, pullOffset.value),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            size: 40,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Content',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Offset: ${pullOffset.value.toStringAsFixed(0)}px',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (pullOffset.value >= threshold)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '✓ Threshold reached!',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (refreshCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Refreshed: $refreshCount',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
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

// Drag-Shuffle List Demo
class _DragShuffleListDemo extends StatefulWidget {
  const _DragShuffleListDemo();

  @override
  State<_DragShuffleListDemo> createState() => _DragShuffleListDemoState();
}

class _DragShuffleListDemoState extends State<_DragShuffleListDemo> {
  final items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];
  final positions = <int, AnimatableProperty<double>>{};
  int? draggingIndex;
  int swapCount = 0;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < items.length; i++) {
      positions[i] = animatableDouble(i * 50.0);
    }
  }

  void _trigger() {
    // Reset
    swapCount = 0;
    setState(() {
      final originalItems = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];
      items.clear();
      items.addAll(originalItems);
    });

    // Simulate drag and shuffle sequence
    _simulateShuffle();
  }

  void _simulateShuffle() async {
    // Shuffle: swap item 0 and item 2
    await _animateSwap(0, 2);
    await Future.delayed(const Duration(milliseconds: 800));

    // Shuffle: swap item 1 and item 3
    await _animateSwap(1, 3);
    await Future.delayed(const Duration(milliseconds: 800));

    // Shuffle: swap item 0 and item 1
    await _animateSwap(0, 1);
  }

  Future<void> _animateSwap(int index1, int index2) async {
    setState(() {
      draggingIndex = index1;
      swapCount++;
    });

    // Get target positions
    final pos1 = positions[index1]!.value;
    final pos2 = positions[index2]!.value;

    // Animate positions
    final anim1 = animate()
        .to(positions[index1]!, pos2)
        .withDuration(400)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final anim2 = animate()
        .to(positions[index2]!, pos1)
        .withDuration(400)
        .withEasing(Easing.easeInOutCubic)
        .build();

    anim1.play();
    anim2.play();

    // Swap in items array
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      final temp = items[index1];
      items[index1] = items[index2];
      items[index2] = temp;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      draggingIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Drag-Shuffle List',
      description: 'Reorderable items with drag',
      onTrigger: _trigger,
      codeSnippet: '''final fsm = DragShuffleListStateMachine(
  items: items,
  positions: positions,
  config: DragShuffleConfig.playful,
  repositionMode: RepositionMode.swap,
);

// User drags item
fsm.dispatch(DragShuffleEvent.startDrag);
fsm.dispatch(DragShuffleEvent.hoverTarget);
fsm.dispatch(DragShuffleEvent.drop);''',
      child: ReactiveBuilder(
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Stack(
                  children: List.generate(items.length, (i) {
                    final isDragging = draggingIndex == i;
                    return Positioned(
                      left: 16,
                      right: 16,
                      top: positions[i]!.value,
                      child: Transform.scale(
                        scale: isDragging ? 1.05 : 1.0,
                        child: Transform.rotate(
                          angle: isDragging ? 0.05 : 0.0,
                          child: Opacity(
                            opacity: isDragging ? 0.9 : 1.0,
                            child: Container(
                              height: 42,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isDragging
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: isDragging
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  width: isDragging ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.drag_indicator,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    items[i],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: isDragging ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              if (swapCount > 0)
                Text(
                  'Swaps: $swapCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

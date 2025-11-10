import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/demo_card.dart';
import '../widgets/clickable_demo.dart';
import '../widgets/swipe_to_delete_demo_widget.dart';

class InteractiveDemoScreen extends StatelessWidget {
  const InteractiveDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Patterns'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 900 ? 2 : 3);
            final padding = constraints.maxWidth < 600 ? 16.0 : 24.0;
            final spacing = constraints.maxWidth < 600 ? 16.0 : 24.0;

            return GridView.count(
              padding: EdgeInsets.all(padding),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1.2,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                _PullToRefreshDemo(),
                _DragShuffleListDemo(),
                _DragShuffleGridDemo(),
                _SwipeToDeleteDemo(),
              ],
            );
          },
        ),
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

  late final Signal<bool> isRefreshing;
  late final Signal<int> refreshCount;
  final threshold = 80.0;
  KitoAnimation? currentAnimation;

  @override
  void initState() {
    super.initState();
    isRefreshing = signal(false);
    refreshCount = signal(0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (isRefreshing.value) return;

    // Update pull offset based on drag
    final newOffset =
        (pullOffset.value + details.delta.dy).clamp(0.0, threshold + 40);
    pullOffset.value = newOffset;

    // Update indicator visibility and scale
    final progress = (newOffset / threshold).clamp(0.0, 1.0);
    refreshOpacity.value = progress;
    refreshScale.value = 0.8 + (progress * 0.4); // Scale from 0.8 to 1.2
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (isRefreshing.value) return;

    if (pullOffset.value >= threshold) {
      // Trigger refresh
      _startRefresh();
    } else {
      // Snap back
      _snapBack();
    }
  }

  void _startRefresh() async {
    isRefreshing.value = true;

    // Snap to threshold
    currentAnimation?.stop();
    currentAnimation = animate()
        .to(pullOffset, threshold)
        .to(refreshScale, 1.0)
        .withDuration(300)
        .withEasing(Easing.easeOutBack)
        .build();
    currentAnimation!.play();

    // Start rotation
    _startRotation();

    // Simulate refresh work
    await Future.delayed(const Duration(milliseconds: 2000));

    // Complete
    isRefreshing.value = false;
    refreshCount.value++;

    // Hide
    _snapBack();
  }

  void _snapBack() {
    currentAnimation?.stop();
    currentAnimation = animate()
        .to(pullOffset, 0.0)
        .to(refreshOpacity, 0.0)
        .to(refreshRotation, 0.0)
        .to(refreshScale, 1.0)
        .withDuration(400)
        .withEasing(Easing.easeOutCubic)
        .build();
    currentAnimation!.play();
  }

  void _startRotation() {
    if (!isRefreshing.value) return;

    currentAnimation = animate()
        .to(refreshRotation, refreshRotation.value + 360.0)
        .withDuration(1000)
        .withEasing(Easing.linear)
        .onComplete(() => _startRotation())
        .build();
    currentAnimation!.play();
  }

  @override
  void dispose() {
    currentAnimation?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Pull-to-Refresh',
      description: 'Drag down to refresh',
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
      child: Builder(
        builder: (context) => ReactiveBuilder(
          builder: (_) => GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Container(
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
                          isRefreshing.value
                              ? Icons.refresh
                              : Icons.arrow_downward,
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.list,
                              size: 40,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Drag Down',
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
                                  '✓ Release to refresh!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            if (refreshCount.value > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Refreshed: ${refreshCount.value}',
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
  late final DragShuffleController<String> controller;
  late final Signal<int> swapCount;
  final itemHeight = 50.0;

  @override
  void initState() {
    super.initState();
    swapCount = signal(0);

    controller = DragShuffleController<String>(
      config: DragShuffleConfig.playful,
      onReorder: (newOrder) {
        swapCount.value++;
      },
    );

    controller.initializeItems(['Item 1', 'Item 2', 'Item 3', 'Item 4'], itemHeight: itemHeight);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Drag-Shuffle List',
      description: 'Drag items to reorder',
      codeSnippet: '''final controller = DragShuffleController<String>(
  config: DragShuffleConfig.playful,
  onReorder: (newOrder) {
    print('New order: \$newOrder');
  },
);

controller.initializeItems(['Item 1', 'Item 2', ...]);

// User drags item
controller.startDrag(visualIndex);
controller.updateTargetPosition(newTargetIndex);
controller.drop();''',
      child: Builder(
        builder: (context) => ReactiveBuilder(
          builder: (_) {
            // Access frameCounter to trigger rebuild on animation frames
            controller.frameCounter;

          // Calculate dynamic height: (items * itemHeight) + padding
          final numItems = controller.currentOrder.length;
          final totalItemsHeight = numItems * itemHeight;
          const containerPadding = 32.0; // 16 top + 16 bottom
          final containerHeight = totalItemsHeight + containerPadding;

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth - 32;
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: List.generate(controller.currentOrder.length, (i) {
                          final item = controller.getItemAt(i);
                          final ctx = controller.getContextAt(i);

                          return Positioned(
                            left: 16,
                            width: itemWidth,
                            top: ctx.absoluteY.value,
                            child: DragTarget<int>(
                              onAcceptWithDetails: (details) {
                                controller.drop();
                              },
                              onWillAcceptWithDetails: (details) {
                                controller.updateTargetPosition(i);
                                return true;
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Draggable<int>(
                                  data: i,
                                  onDragStarted: () => controller.startDrag(i),
                                  onDragEnd: (_) => controller.drop(),
                                  feedback: Transform.scale(
                                    scale: ctx.scale.value,
                                    child: Transform.rotate(
                                      angle: ctx.rotation.value * (3.14159 / 180),
                                      child: Container(
                                        width: itemWidth,
                                        height: 42,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(2),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.drag_indicator,
                                              size: 20,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              item,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  feedbackOffset: const Offset(-16, 0),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _buildListItem(context, item, ctx, false),
                                  ),
                                  child: _buildListItem(context, item, ctx, false),
                                );
                              },
                            ),
                          );
                        }),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if (swapCount.value > 0)
                  Text(
                    'Swaps: ${swapCount.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String item, DragItemContext ctx, bool isActive) {
    return Transform.scale(
      scale: ctx.scale.value,
      child: Transform.rotate(
        angle: ctx.rotation.value * (3.14159 / 180),
        child: Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: ctx.elevation.value > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: ctx.elevation.value,
                      offset: Offset(0, ctx.elevation.value / 2),
                    ),
                  ]
                : null,
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
                item,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Drag-Shuffle Grid Demo
class _DragShuffleGridDemo extends StatelessWidget {
  const _DragShuffleGridDemo();

  @override
  Widget build(BuildContext context) {
    return const _DragShuffleGridDemoContent();
  }
}

class _DragShuffleGridDemoContent extends StatefulWidget {
  const _DragShuffleGridDemoContent();

  @override
  State<_DragShuffleGridDemoContent> createState() => _DragShuffleGridDemoContentState();
}

class _DragShuffleGridDemoContentState extends State<_DragShuffleGridDemoContent> {
  late final DragShuffleGridController<int> controller;
  late final Signal<int> swapCount;
  late final Signal<GridRepositionMode> currentMode;

  final columns = 3;
  final itemSize = 55.0;
  final gap = 8.0;

  @override
  void initState() {
    super.initState();
    swapCount = signal(0);
    currentMode = signal(GridRepositionMode.wave);

    controller = DragShuffleGridController<int>(
      config: DragShuffleGridConfig(
        columns: columns,
        itemWidth: itemSize,
        itemHeight: itemSize,
        horizontalGap: gap,
        verticalGap: gap,
        repositionMode: currentMode.value,
      ),
      onReorder: (newOrder) {
        swapCount.value++;
      },
    );

    controller.initializeItems(List.generate(9, (i) => i + 1));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Drag-Shuffle Grid',
      description: 'Drag items to reorder in 2D grid',
      codeSnippet: '''final controller = DragShuffleGridController<int>(
  config: DragShuffleGridConfig(
    columns: 3,
    itemWidth: 55,
    itemHeight: 55,
    repositionMode: GridRepositionMode.wave,
  ),
  onReorder: (newOrder) {
    print('New order: \$newOrder');
  },
);

controller.initializeItems([1, 2, 3, 4, 5, 6, 7, 8, 9]);

// User drags item
controller.startDrag(visualIndex);
controller.updateTargetPosition(newTargetIndex);
controller.drop();''',
      child: Builder(
        builder: (context) => ReactiveBuilder(
          builder: (_) {
            // Access frameCounter to trigger rebuild on animation frames
            controller.frameCounter;

          final gridWidth = columns * (itemSize + gap);
          final gridHeight = columns * (itemSize + gap);

          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: gridWidth,
                  height: gridHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Stack(
                    children: List.generate(controller.currentOrder.length, (i) {
                      final item = controller.getItemAt(i);
                      final ctx = controller.getContextAt(i);

                      return Positioned(
                        left: ctx.absoluteX.value,
                        top: ctx.absoluteY.value,
                        child: DragTarget<int>(
                          onAcceptWithDetails: (details) {
                            controller.drop();
                          },
                          onWillAcceptWithDetails: (details) {
                            controller.updateTargetPosition(i);
                            return true;
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Draggable<int>(
                              data: i,
                              onDragStarted: () => controller.startDrag(i),
                              onDragEnd: (_) => controller.drop(),
                              feedback: Transform.scale(
                                scale: ctx.scale.value,
                                child: Transform.rotate(
                                  angle: ctx.rotation.value * (3.14159 / 180),
                                  child: Container(
                                    width: itemSize,
                                    height: itemSize,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$item',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              feedbackOffset: Offset(-itemSize / 2, -itemSize / 2),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _buildGridItem(context, item, ctx, false),
                              ),
                              child: _buildGridItem(context, item, ctx, false),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                // Mode selector
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _modeChip(context, GridRepositionMode.wave, 'Wave'),
                    _modeChip(context, GridRepositionMode.simultaneous, 'Simul'),
                    _modeChip(context, GridRepositionMode.radial, 'Radial'),
                    _modeChip(context, GridRepositionMode.rowByRow, 'Row'),
                    _modeChip(context, GridRepositionMode.columnByColumn, 'Col'),
                  ],
                ),
                const SizedBox(height: 8),
                if (swapCount.value > 0)
                  Text(
                    'Swaps: ${swapCount.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, int item, GridItemContext ctx, bool isActive) {
    return Transform.scale(
      scale: ctx.scale.value,
      child: Transform.rotate(
        angle: ctx.rotation.value * (3.14159 / 180),
        child: Container(
          width: itemSize,
          height: itemSize,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: ctx.elevation.value > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: ctx.elevation.value,
                      offset: Offset(0, ctx.elevation.value / 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$item',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(BuildContext context, GridRepositionMode mode, String label) {
    return Builder(
      builder: (context) => ReactiveBuilder(
        builder: (_) {
          final isSelected = currentMode.value == mode;
          return GestureDetector(
          onTap: () => currentMode.value = mode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
            ),
          ),
        );
        },
      ),
    );
  }
}


// Swipe to Delete Demo (FSM-based)
typedef _SwipeToDeleteDemo = SwipeToDeleteDemo;

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
          _DragShuffleGridDemo(),
          _SwipeToDeleteDemo(),
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

// Drag-Shuffle Grid Demo
class _DragShuffleGridDemo extends StatefulWidget {
  const _DragShuffleGridDemo();

  @override
  State<_DragShuffleGridDemo> createState() => _DragShuffleGridDemoState();
}

class _DragShuffleGridDemoState extends State<_DragShuffleGridDemo> {
  final gridItems = List.generate(9, (i) => i + 1);
  final gridPositions = <int, AnimatableProperty<Offset>>{};
  int? draggingIndex;
  int swapCount = 0;
  GridRepositionMode currentMode = GridRepositionMode.wave;

  final columns = 3;
  final itemSize = 55.0;
  final gap = 8.0;

  @override
  void initState() {
    super.initState();
    _initPositions();
  }

  void _initPositions() {
    for (var i = 0; i < gridItems.length; i++) {
      final row = i ~/ columns;
      final col = i % columns;
      gridPositions[i] = animatableOffset(
        Offset(col * (itemSize + gap), row * (itemSize + gap)),
      );
    }
  }

  Offset _getPositionForIndex(int index) {
    final row = index ~/ columns;
    final col = index % columns;
    return Offset(col * (itemSize + gap), row * (itemSize + gap));
  }

  void _trigger() {
    // Reset
    swapCount = 0;
    setState(() {
      for (var i = 0; i < gridItems.length; i++) {
        gridItems[i] = i + 1;
      }
    });

    // Simulate grid shuffle sequence
    _simulateGridShuffle();
  }

  void _simulateGridShuffle() async {
    // Shuffle: swap corners
    await _animateGridSwap(0, 8); // Top-left with bottom-right
    await Future.delayed(const Duration(milliseconds: 900));

    // Shuffle: swap middle edges
    await _animateGridSwap(1, 7); // Top-middle with bottom-middle
    await Future.delayed(const Duration(milliseconds: 900));

    // Shuffle: swap center with corner
    await _animateGridSwap(4, 2); // Center with top-right
  }

  Future<void> _animateGridSwap(int index1, int index2) async {
    setState(() {
      draggingIndex = index1;
      swapCount++;
    });

    // Get target positions
    final targetPos1 = _getPositionForIndex(index2);
    final targetPos2 = _getPositionForIndex(index1);

    // Determine animation delays based on mode
    final delays = _calculateDelays(index1, index2);

    // Animate with stagger
    Future.delayed(Duration(milliseconds: delays[index1]), () {
      final anim1 = animate()
          .to(gridPositions[index1]!, targetPos1)
          .withDuration(450)
          .withEasing(Easing.easeInOutCubic)
          .build();
      anim1.play();
    });

    Future.delayed(Duration(milliseconds: delays[index2]), () {
      final anim2 = animate()
          .to(gridPositions[index2]!, targetPos2)
          .withDuration(450)
          .withEasing(Easing.easeInOutCubic)
          .build();
      anim2.play();
    });

    // Swap in items array
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      final temp = gridItems[index1];
      gridItems[index1] = gridItems[index2];
      gridItems[index2] = temp;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      draggingIndex = null;
    });
  }

  Map<int, int> _calculateDelays(int index1, int index2) {
    final delays = <int, int>{};

    switch (currentMode) {
      case GridRepositionMode.simultaneous:
        delays[index1] = 0;
        delays[index2] = 0;
        break;

      case GridRepositionMode.wave:
        final row1 = index1 ~/ columns;
        final row2 = index2 ~/ columns;
        delays[index1] = row1 * 50;
        delays[index2] = row2 * 50;
        break;

      case GridRepositionMode.radial:
        // Delay based on distance from center
        final center = 4; // Middle of 3x3 grid
        final dist1 = (index1 - center).abs();
        final dist2 = (index2 - center).abs();
        delays[index1] = dist1 * 40;
        delays[index2] = dist2 * 40;
        break;

      case GridRepositionMode.rowByRow:
        final row1 = index1 ~/ columns;
        final row2 = index2 ~/ columns;
        delays[index1] = row1 * 80;
        delays[index2] = row2 * 80;
        break;

      case GridRepositionMode.columnByColumn:
        final col1 = index1 % columns;
        final col2 = index2 % columns;
        delays[index1] = col1 * 80;
        delays[index2] = col2 * 80;
        break;
    }

    return delays;
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Drag-Shuffle Grid',
      description: 'Reorderable 2D grid items',
      onTrigger: _trigger,
      codeSnippet: '''final fsm = DragShuffleGridStateMachine(
  items: items,
  positions: positions,
  config: DragShuffleGridConfig(
    columns: 3,
    itemWidth: 50,
    itemHeight: 50,
    repositionMode: GridRepositionMode.wave,
  ),
);

// User drags grid item
fsm.dispatch(DragShuffleEvent.startDrag);
fsm.dispatch(DragShuffleEvent.drop);''',
      child: ReactiveBuilder(
        builder: (_) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: columns * (itemSize + gap),
                height: columns * (itemSize + gap),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Stack(
                  children: List.generate(gridItems.length, (i) {
                    final isDragging = draggingIndex == i;
                    final position = gridPositions[i]!.value;

                    return Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: Transform.scale(
                        scale: isDragging ? 1.08 : 1.0,
                        child: Transform.rotate(
                          angle: isDragging ? 0.05 : 0.0,
                          child: Opacity(
                            opacity: isDragging ? 0.9 : 1.0,
                            child: Container(
                              width: itemSize,
                              height: itemSize,
                              decoration: BoxDecoration(
                                color: isDragging
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: isDragging
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  width: isDragging ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${gridItems[i]}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: isDragging ? FontWeight.w700 : FontWeight.w600,
                                    color: isDragging
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
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

  Widget _modeChip(BuildContext context, GridRepositionMode mode, String label) {
    return GestureDetector(
      onTap: () => setState(() => currentMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: currentMode == mode
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: currentMode == mode
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            fontWeight: currentMode == mode ? FontWeight.w600 : FontWeight.normal,
            color: currentMode == mode ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}

// List item data class
class ListItem {
  final int id;
  final String title;
  final IconData icon;
  final Color color;
  final AnimatableProperty<Offset> swipeOffset;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;
  bool isDeleted = false;

  ListItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  })  : swipeOffset = animatableOffset(Offset.zero),
        opacity = animatableDouble(1.0),
        scale = animatableDouble(1.0);
}

// Swipe to Delete Demo
class _SwipeToDeleteDemo extends StatefulWidget {
  const _SwipeToDeleteDemo();

  @override
  State<_SwipeToDeleteDemo> createState() => _SwipeToDeleteDemoState();
}

class _SwipeToDeleteDemoState extends State<_SwipeToDeleteDemo> {
  List<ListItem> items = [];
  int? swipingItemId;
  Offset? dragStart;
  final swipeThreshold = 80.0;
  int deleteCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    items = [
      ListItem(
        id: 1,
        title: 'Email',
        icon: Icons.email,
        color: const Color(0xFF3498DB),
      ),
      ListItem(
        id: 2,
        title: 'Message',
        icon: Icons.message,
        color: const Color(0xFF2ECC71),
      ),
      ListItem(
        id: 3,
        title: 'Task',
        icon: Icons.task_alt,
        color: const Color(0xFFF39C12),
      ),
      ListItem(
        id: 4,
        title: 'Note',
        icon: Icons.note,
        color: const Color(0xFFE74C3C),
      ),
    ];
  }

  void _trigger() {
    _reset();
  }

  void _reset() {
    setState(() {
      _initializeItems();
      deleteCount = 0;
    });
  }

  void _onPanStart(ListItem item, DragStartDetails details) {
    if (swipingItemId != null) return;

    setState(() {
      swipingItemId = item.id;
      dragStart = details.localPosition;
    });
  }

  void _onPanUpdate(ListItem item, DragUpdateDetails details) {
    if (swipingItemId != item.id || dragStart == null) return;

    final deltaX = details.localPosition.dx - dragStart!.dx;

    setState(() {
      item.swipeOffset.value = Offset(deltaX, 0);
    });
  }

  void _onPanEnd(ListItem item, DragEndDetails details) {
    if (swipingItemId != item.id) return;

    final swipeDistance = item.swipeOffset.value.dx.abs();

    if (swipeDistance > swipeThreshold) {
      _deleteItem(item);
    } else {
      _snapBack(item);
    }

    setState(() {
      swipingItemId = null;
      dragStart = null;
    });
  }

  Future<void> _deleteItem(ListItem item) async {
    final targetX = item.swipeOffset.value.dx > 0 ? 300.0 : -300.0;

    final deleteAnim = animate()
        .to(item.swipeOffset, Offset(targetX, 0))
        .to(item.opacity, 0.0)
        .to(item.scale, 0.8)
        .withDuration(300)
        .withEasing(Easing.easeInCubic)
        .build();

    deleteAnim.play();

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      item.isDeleted = true;
      deleteCount++;
    });
  }

  void _snapBack(ListItem item) {
    final snapAnim = animate()
        .to(item.swipeOffset, Offset.zero)
        .withDuration(300)
        .withEasing(Easing.easeOutBack)
        .build();

    snapAnim.play();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Swipe to Delete',
      description: 'Gesture-based item removal',
      onTrigger: _trigger,
      codeSnippet: '''
void _onPanUpdate(details) {
  final deltaX = details.dx - dragStart.dx;
  item.swipeOffset.value = Offset(deltaX, 0);
}

void _onPanEnd(details) {
  if (item.swipeOffset.dx.abs() > threshold) {
    _deleteItem(item);
  } else {
    _snapBack(item);
  }
}

void _deleteItem(item) {
  final targetX = item.swipeOffset.dx > 0
      ? 300.0 : -300.0;

  animate()
    .to(item.swipeOffset, Offset(targetX, 0))
    .to(item.opacity, 0.0)
    .to(item.scale, 0.8)
    .withDuration(300)
    .build()
    .play();
}
''',
      child: ReactiveBuilder(
        builder: (context) {
          return _buildList(context);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final activeItems = items.where((item) => !item.isDeleted).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: activeItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All items deleted',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: activeItems.length,
                    itemBuilder: (context, index) {
                      final item = activeItems[index];
                      return _buildItem(context, item);
                    },
                  ),
          ),
          if (deleteCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Deleted: $deleteCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, ListItem item) {
    final isSwiping = swipingItemId == item.id;
    final swipeProgress = (item.swipeOffset.value.dx.abs() / swipeThreshold).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Delete indicator background
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(swipeProgress),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: item.swipeOffset.value.dx > 0
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error.withOpacity(swipeProgress),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Item card
          Transform.translate(
            offset: item.swipeOffset.value,
            child: Transform.scale(
              scale: item.scale.value,
              child: Opacity(
                opacity: item.opacity.value,
                child: GestureDetector(
                  onPanStart: (details) => _onPanStart(item, details),
                  onPanUpdate: (details) => _onPanUpdate(item, details),
                  onPanEnd: (details) => _onPanEnd(item, details),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSwiping
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                        width: isSwiping ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSwiping ? 0.2 : 0.1),
                          blurRadius: isSwiping ? 8 : 4,
                          offset: Offset(0, isSwiping ? 4 : 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: item.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSwiping ? FontWeight.w600 : FontWeight.normal,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.drag_indicator,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

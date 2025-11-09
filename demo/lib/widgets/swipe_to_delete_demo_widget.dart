import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import 'demo_card.dart';
import 'clickable_demo.dart';

/// Demo item model
class SwipeItem {
  final int id;
  final String title;
  final IconData icon;
  final Color color;

  const SwipeItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// Swipe to Delete Demo using FSM
class SwipeToDeleteDemo extends StatefulWidget {
  const SwipeToDeleteDemo({super.key});

  @override
  State<SwipeToDeleteDemo> createState() => _SwipeToDeleteDemoState();
}

class _SwipeToDeleteDemoState extends State<SwipeToDeleteDemo> {
  static const _initialItems = [
    SwipeItem(
      id: 1,
      title: 'Email',
      icon: Icons.email,
      color: Color(0xFF3498DB),
    ),
    SwipeItem(
      id: 2,
      title: 'Message',
      icon: Icons.message,
      color: Color(0xFF2ECC71),
    ),
    SwipeItem(
      id: 3,
      title: 'Task',
      icon: Icons.task_alt,
      color: Color(0xFFF39C12),
    ),
    SwipeItem(
      id: 4,
      title: 'Note',
      icon: Icons.note,
      color: Color(0xFFE74C3C),
    ),
  ];

  final Map<int, SwipeToDeleteStateMachine> _machines = {};
  final Map<int, Offset> _dragStarts = {}; // Per-item drag start tracking
  late final Signal<List<SwipeItem>> items;
  late final Signal<int> deleteCount;

  @override
  void initState() {
    super.initState();
    items = signal(List.from(_initialItems));
    deleteCount = signal(0);
    _initializeMachines();
  }

  void _initializeMachines() {
    for (final item in items.value) {
      _machines[item.id] = SwipeToDeleteStateMachine(
        SwipeContext(
          config: const SwipeAnimationConfig(
            deleteThreshold: 80.0,
            useElasticSnapBack: true,
          ),
          onDelete: () => _deleteItem(item.id),
        ),
      );
    }
  }

  void _deleteItem(int itemId) {
    items.value = items.value.where((i) => i.id != itemId).toList();
    // Don't dispose machine yet - let it finish animations
    deleteCount.value++;
  }

  void _trigger() {
    _reset();
  }

  void _reset() {
    for (final machine in _machines.values) {
      machine.dispose();
    }
    _machines.clear();
    items.value = List.from(_initialItems);
    deleteCount.value = 0;
    _initializeMachines();
  }

  @override
  void dispose() {
    for (final machine in _machines.values) {
      machine.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Swipe to Delete',
      description: 'FSM-based gesture removal with rubberband (swipe to test)',
      codeSnippet: '''
final machine = SwipeToDeleteStateMachine(
  SwipeContext(
    config: SwipeAnimationConfig(),
    onDelete: () => removeItem(),
  ),
);

// Gesture handlers
onHorizontalDragStart: (_) =>
  machine.send(SwipeEvent.dragStart),
onHorizontalDragUpdate: (d) =>
  machine.updateDrag(d.delta.dx),
onHorizontalDragEnd: (_) =>
  machine.send(SwipeEvent.dragEnd),
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => ReactiveBuilder(
          builder: (context) {
            return _buildList(context);
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: items.value.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_sweep,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'All items deleted',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: items.value.length,
                    itemBuilder: (context, index) {
                      final item = items.value[index];
                      return _buildItem(context, item);
                    },
                  ),
          ),
          if (deleteCount.value > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Deleted: ${deleteCount.value}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, SwipeItem item) {
    final machine = _machines[item.id];
    if (machine == null) return const SizedBox.shrink(); // Item deleted
    final ctx = machine.context;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ReactiveBuilder(
        builder: (_) {
          final swipeProgress = (ctx.swipeOffset.value.dx.abs() / 80.0).clamp(0.0, 1.0);

          return Stack(
            children: [
              // Delete indicator background
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withOpacity(ctx.backgroundOpacity.value),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: ctx.swipeOffset.value.dx > 0
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(ctx.backgroundOpacity.value),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Item card
              Transform.translate(
                offset: ctx.swipeOffset.value,
                child: Transform.scale(
                  scale: ctx.scale.value,
                  child: Opacity(
                    opacity: ctx.opacity.value,
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        _dragStarts[item.id] = details.localPosition;
                        machine.send(SwipeEvent.dragStart);
                      },
                      onHorizontalDragUpdate: (details) {
                        final dragStart = _dragStarts[item.id];
                        if (dragStart == null) return;
                        final deltaX = details.localPosition.dx - dragStart.dx;
                        machine.updateDrag(deltaX);
                      },
                      onHorizontalDragEnd: (details) {
                        _dragStarts.remove(item.id);
                        machine.send(SwipeEvent.dragEnd);
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: machine.currentState.value == SwipeState.dragging
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.2),
                            width: machine.currentState.value == SwipeState.dragging ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  machine.currentState.value == SwipeState.dragging ? 0.2 : 0.1),
                              blurRadius: machine.currentState.value == SwipeState.dragging ? 8 : 4,
                              offset: Offset(0, machine.currentState.value == SwipeState.dragging ? 4 : 2),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: machine.currentState.value == SwipeState.dragging
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.drag_indicator,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
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
          );
        },
      ),
    );
  }
}

import 'package:kito_patterns/kito_patterns.dart';
import 'package:kito/kito.dart';

void main() {
  print('=== Kito Patterns Examples ===\n');

  // Example 1: Animated List
  animatedListExample();

  // Example 2: Button
  buttonExample();

  // Example 3: Form
  formExample();

  // Example 4: Drawer
  drawerExample();

  // Example 5: Modal
  modalExample();

  // Example 6: Pull to Refresh
  pullToRefreshExample();

  // Example 7: Drag and Shuffle
  dragShuffleExample();

  // Example 8: Drag and Shuffle Grid
  dragShuffleGridExample();

  // Example 9: Stagger Helpers
  staggerExample();
}

void animatedListExample() {
  print('--- Animated List Example ---');

  final controller = AnimatedListController(
    config: ListItemAnimationConfig.slideUp(
      staggerDelay: 50,
    ),
  );

  // Initialize 5 items
  controller.initializeItems(5);

  // Insert item with animation
  controller.insert(0);

  // Access item properties
  final item = controller.getItem(0);
  print('Item 0 state: ${item.fsm.currentState.value}');
  print('Item 0 opacity: ${item.opacity.value}');

  controller.dispose();
  print('');
}

void buttonExample() {
  print('--- Button Example ---');

  final buttonCtx = ButtonContext(
    config: ButtonAnimationConfig.bouncy,
    onTap: () => print('Button tapped!'),
  );

  final button = ButtonStateMachine(buttonCtx);

  // Simulate interactions
  print('Initial state: ${button.currentState.value}');

  button.send(ButtonEvent.hoverEnter);
  print('After hover: ${button.currentState.value}');
  print('Scale: ${buttonCtx.scale.value}');

  button.send(ButtonEvent.pressDown);
  print('After press down: ${button.currentState.value}');

  button.send(ButtonEvent.pressUp);
  print('After press up: ${button.currentState.value}');

  button.send(ButtonEvent.hoverExit);
  print('After hover exit: ${button.currentState.value}');

  button.dispose();
  print('');
}

void formExample() {
  print('--- Form Example ---');

  final formCtx = FormContext(
    config: FormAnimationConfig.bouncy,
    onValidate: () async {
      print('Validating...');
      await Future.delayed(Duration(milliseconds: 500));
      return true; // validation passed
    },
    onSubmit: () async {
      print('Submitting...');
      await Future.delayed(Duration(milliseconds: 1000));
    },
  );

  final form = FormStateMachine(formCtx);

  print('Initial state: ${form.currentState.value}');

  form.send(FormEvent.startEdit);
  print('Editing state: ${form.currentState.value}');

  // Note: In real usage, these would be async
  form.send(FormEvent.validate);
  print('Validating state: ${form.currentState.value}');

  form.dispose();
  print('');
}

void drawerExample() {
  print('--- Drawer Example ---');

  final drawerCtx = DrawerContext(
    config: DrawerAnimationConfig.smooth,
  );

  final drawer = DrawerStateMachine(drawerCtx);

  print('Initial state: ${drawer.currentState.value}');
  print('Position: ${drawerCtx.position.value}');

  drawer.send(DrawerEvent.open);
  print('After open: ${drawer.currentState.value}');

  drawer.send(DrawerEvent.close);
  print('After close: ${drawer.currentState.value}');

  drawer.dispose();
  print('');
}

void modalExample() {
  print('--- Modal Example ---');

  final modalCtx = ModalContext(
    config: ModalAnimationConfig.scaleIn(
      animationType: ModalAnimationType.zoom,
    ),
  );

  final modal = ModalStateMachine(modalCtx);

  print('Initial state: ${modal.currentState.value}');
  print('Opacity: ${modalCtx.opacity.value}');
  print('Scale: ${modalCtx.scale.value}');

  modal.send(ModalEvent.show);
  print('After show: ${modal.currentState.value}');

  modal.send(ModalEvent.hide);
  print('After hide: ${modal.currentState.value}');

  modal.dispose();
  print('');
}

void pullToRefreshExample() {
  print('--- Pull to Refresh Example ---');

  final pullToRefreshCtx = PullToRefreshContext(
    config: PullToRefreshConfig.elastic,
    onRefresh: () async {
      print('Refreshing data...');
      await Future.delayed(Duration(seconds: 1));
      print('Refresh complete!');
    },
  );

  final pullToRefresh = PullToRefreshStateMachine(pullToRefreshCtx);

  print('Initial state: ${pullToRefresh.currentState.value}');

  // Simulate pull gesture
  pullToRefresh.startPull();
  print('Started pulling: ${pullToRefresh.currentState.value}');

  pullToRefresh.updatePullDistance(50.0);
  print('Pull distance: ${pullToRefreshCtx.pullDistance.value}');
  print('Rotation: ${pullToRefreshCtx.rotation.value}');

  pullToRefresh.updatePullDistance(90.0);
  print('Pull distance crossed threshold: ${pullToRefresh.currentState.value}');

  pullToRefresh.releasePull();
  print('Released: ${pullToRefresh.currentState.value}');

  pullToRefresh.dispose();
  print('');
}

void dragShuffleExample() {
  print('--- Drag and Shuffle Example ---');

  final dragController = DragShuffleController(
    config: DragShuffleConfig.playful,
    onReorder: (oldIndex, newIndex) {
      print('Reordered: $oldIndex -> $newIndex');
    },
  );

  // Initialize 5 items
  dragController.initializeItems(5);

  print('Initialized ${dragController.items.length} items');

  // Simulate drag gesture
  dragController.startDrag(0);
  print('Started dragging item 0');

  final item = dragController.getItem(0);
  print('Item 0 scale: ${item.scale.value}');

  dragController.updateDragPosition(0, 10.0, 50.0);
  print('Updated drag position');
  print('Item 0 offset X: ${item.offsetX.value}');
  print('Item 0 offset Y: ${item.offsetY.value}');

  dragController.updateTargetPosition(2);
  print('Updated target position to index 2');

  dragController.drop();
  print('Dropped item');

  dragController.dispose();
  print('');
}

void dragShuffleGridExample() {
  print('--- Drag and Shuffle Grid Example ---');

  final gridController = DragShuffleGridController(
    config: DragShuffleGridConfig(
      columns: 3,
      itemWidth: 100.0,
      itemHeight: 100.0,
      horizontalGap: 8.0,
      verticalGap: 8.0,
      repositionMode: GridRepositionMode.wave,
      dragScale: 1.08,
    ),
    onReorder: (oldIndex, newIndex) {
      print('Grid reordered: $oldIndex -> $newIndex');
    },
  );

  // Initialize 9 items (3x3 grid)
  gridController.initializeItems(9);

  print('Initialized ${gridController.items.length} grid items');
  print('Grid has ${gridController.rowCount} rows');

  // Simulate drag gesture
  gridController.startDrag(0);
  print('Started dragging item 0');

  final item = gridController.getItem(0);
  print('Item 0 position: Row ${item.originalRow}, Col ${item.originalCol}');
  print('Item 0 scale: ${item.scale.value}');

  // Simulate dragging to a different position
  gridController.updateDragPosition(0, 220.0, 110.0);
  print('Updated drag position');
  print('Item 0 offset X: ${item.offsetX.value}');
  print('Item 0 offset Y: ${item.offsetY.value}');

  // Drop
  gridController.drop();
  print('Dropped item');
  print('Item 0 target position: Row ${item.targetRow}, Col ${item.targetCol}');

  gridController.dispose();
  print('');
}

void staggerExample() {
  print('--- Stagger Helpers Example ---');

  // Create staggered list animations
  print('Creating staggered list animations...');
  final listAnims = StaggerHelper.createStaggeredList(
    count: 5,
    animationBuilder: (index) {
      final value = animatableDouble(0.0);
      return animate()
          .to(value, 1.0)
          .withDuration(300)
          .build();
    },
    config: StaggerConfig.cascade,
    autoplay: false,
  );
  print('Created ${listAnims.length} staggered animations');

  // Create staggered grid animations
  print('Creating staggered grid animations...');
  final gridAnims = StaggerHelper.createStaggeredGrid(
    count: 9,
    columns: 3,
    animationBuilder: (index) {
      final value = animatableDouble(0.0);
      return animate()
          .to(value, 1.0)
          .withDuration(400)
          .build();
    },
    gridConfig: GridStaggerConfig(
      mode: GridStaggerMode.diagonal,
      baseDelay: 40,
      columns: 3,
    ),
    autoplay: false,
  );
  print('Created ${gridAnims.length} grid animations');

  // Create wave effect
  print('Creating wave effect animations...');
  final waveAnims = StaggerHelper.createWaveEffect(
    count: 10,
    animationBuilder: (index) {
      final value = animatableDouble(0.0);
      return animate()
          .to(value, 1.0)
          .withDuration(500)
          .build();
    },
    waveLength: 5,
    baseDelay: 30,
    autoplay: false,
  );
  print('Created ${waveAnims.length} wave animations');

  // Clean up
  for (final anim in [...listAnims, ...gridAnims, ...waveAnims]) {
    anim.dispose();
  }

  print('');
}

import 'package:flutter/material.dart' hide Easing, FormState;
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/demo_card.dart';

class PatternsDemoScreen extends StatelessWidget {
  const PatternsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Patterns'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 1.2,
        children: const [
          _ButtonPatternDemo(),
          _FormPatternDemo(),
          _DrawerPatternDemo(),
          _ModalPatternDemo(),
          _ToastPatternDemo(),
        ],
      ),
    );
  }
}

// Button Pattern Demo
class _ButtonPatternDemo extends StatefulWidget {
  const _ButtonPatternDemo();

  @override
  State<_ButtonPatternDemo> createState() => _ButtonPatternDemoState();
}

class _ButtonPatternDemoState extends State<_ButtonPatternDemo> {
  late final ButtonContext buttonContext;
  late final ButtonStateMachine buttonFsm;
  int clickCount = 0;

  @override
  void initState() {
    super.initState();
    buttonContext = ButtonContext(
      config: ButtonAnimationConfig.bouncy,
      onTap: () {
        setState(() => clickCount++);
      },
    );
    buttonFsm = ButtonStateMachine(buttonContext);
  }

  void _trigger() {
    // Reset
    clickCount = 0;
    buttonFsm.send(ButtonEvent.enable);

    // Simulate button interactions
    Future.delayed(const Duration(milliseconds: 100), () {
      buttonFsm.send(ButtonEvent.pressDown);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      buttonFsm.send(ButtonEvent.pressUp);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      buttonFsm.send(ButtonEvent.startLoading);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      buttonFsm.send(ButtonEvent.stopLoading);
    });
  }

  @override
  void dispose() {
    buttonContext.currentAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Button States',
      description: 'FSM with hover, press, loading',
      onTrigger: _trigger,
      codeSnippet: '''final ctx = ButtonContext(
  config: ButtonAnimationConfig.bouncy,
);
final fsm = ButtonStateMachine(ctx);

// Dispatch events
fsm.dispatch(ButtonEvent.pressDown);
fsm.dispatch(ButtonEvent.pressUp);
fsm.dispatch(ButtonEvent.startLoading);''',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ReactiveBuilder(
              builder: (_) => MouseRegion(
                onEnter: (_) => buttonFsm.send(ButtonEvent.hoverEnter),
                onExit: (_) => buttonFsm.send(ButtonEvent.hoverExit),
                child: GestureDetector(
                  onTapDown: (_) => buttonFsm.send(ButtonEvent.pressDown),
                  onTapUp: (_) => buttonFsm.send(ButtonEvent.pressUp),
                  onTapCancel: () => buttonFsm.send(ButtonEvent.enable),
                  child: Transform.scale(
                    scale: buttonContext.scale.value,
                    child: Opacity(
                      opacity: buttonContext.opacity.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: buttonFsm.currentState == ButtonState.loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Click Me',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ReactiveBuilder(
              builder: (_) => Text(
                'State: ${buttonFsm.currentState.value.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (clickCount > 0)
              Text(
                'Clicks: $clickCount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

// Form Pattern Demo
class _FormPatternDemo extends StatefulWidget {
  const _FormPatternDemo();

  @override
  State<_FormPatternDemo> createState() => _FormPatternDemoState();
}

class _FormPatternDemoState extends State<_FormPatternDemo> {
  late final FormContext formContext;
  late final FormStateMachine formFsm;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    formContext = FormContext(
      config: const FormAnimationConfig(),
      onSubmit: () {
        // Simulate async submission
        Future.delayed(const Duration(seconds: 1), () {
          if (_controller.text.length >= 3) {
            formFsm.send(FormEvent.submitSuccess);
          } else {
            formContext.errorMessage = 'Submission failed';
            formFsm.send(FormEvent.submitError);
          }
        });
      },
    );
    formFsm = FormStateMachine(formContext);
  }

  void _trigger() {
    // Reset
    _controller.text = '';
    formFsm.send(FormEvent.reset);

    // Simulate form flow
    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.text = 'ab'; // Too short
      formFsm.send(FormEvent.validate);
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      formFsm.send(FormEvent.validationFailed);
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _controller.text = 'valid input';
      formFsm.send(FormEvent.validate);
    });

    Future.delayed(const Duration(milliseconds: 1700), () {
      formFsm.send(FormEvent.validationPassed);
    });

    Future.delayed(const Duration(milliseconds: 2200), () {
      formFsm.send(FormEvent.submit);
    });
  }

  @override
  void dispose() {
    formContext.currentAnimation?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Form Validation',
      description: 'FSM with validation feedback',
      onTrigger: _trigger,
      codeSnippet: '''final ctx = FormContext(
  config: FormAnimationConfig(),
);
final fsm = FormStateMachine(ctx);

// Dispatch validation events
fsm.dispatch(FormEvent.validate);
fsm.dispatch(FormEvent.validationFailed);
fsm.dispatch(FormEvent.submit);''',
      child: Center(
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ReactiveBuilder(
                builder: (_) => Transform.translate(
                  offset: Offset(formContext.offsetX.value, 0),
                  child: Opacity(
                    opacity: formContext.opacity.value,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Enter text...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(
                            color: Color.lerp(
                              Colors.grey,
                              Colors.red,
                              formContext.borderColor.value,
                            )!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(
                            color: Color.lerp(
                              Colors.grey,
                              Colors.red,
                              formContext.borderColor.value,
                            )!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(2),
                          borderSide: BorderSide(
                            color: Color.lerp(
                              Theme.of(context).colorScheme.primary,
                              Colors.red,
                              formContext.borderColor.value,
                            )!,
                            width: 2,
                          ),
                        ),
                        suffixIcon: formFsm.currentState == FormState.success
                            ? Transform.scale(
                                scale: formContext.successScale.value,
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) {
                        if (formFsm.currentState == FormState.invalid) {
                          formFsm.send(FormEvent.input);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ReactiveBuilder(
                builder: (_) => Text(
                  'State: ${formFsm.currentState.value.name}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Drawer Pattern Demo
class _DrawerPatternDemo extends StatefulWidget {
  const _DrawerPatternDemo();

  @override
  State<_DrawerPatternDemo> createState() => _DrawerPatternDemoState();
}

class _DrawerPatternDemoState extends State<_DrawerPatternDemo> {
  late final DrawerContext drawerContext;
  late final DrawerStateMachine drawerFsm;

  @override
  void initState() {
    super.initState();
    drawerContext = DrawerContext(
      config: DrawerAnimationConfig.bouncy,
    );
    drawerFsm = DrawerStateMachine(drawerContext);
  }

  void _trigger() {
    drawerFsm.send(DrawerEvent.toggle);
    Future.delayed(const Duration(milliseconds: 1500), () {
      drawerFsm.send(DrawerEvent.toggle);
    });
  }

  @override
  void dispose() {
    drawerContext.currentAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Drawer Slide',
      description: 'FSM with slide transition',
      onTrigger: _trigger,
      codeSnippet: '''final ctx = DrawerContext(
  config: DrawerAnimationConfig.bouncy,
);
final fsm = DrawerStateMachine(ctx);

// Toggle drawer
fsm.dispatch(DrawerEvent.toggle);''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => SizedBox(
            width: 300,
            height: 200,
            child: Stack(
              children: [
                // Main content
                Transform.scale(
                  scale: drawerContext.contentScale.value,
                  child: Container(
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.web, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Main Content',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'State: ${drawerFsm.currentState.value.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Overlay
                if (drawerContext.overlayOpacity.value > 0)
                  Opacity(
                    opacity: drawerContext.overlayOpacity.value,
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                // Drawer
                Positioned(
                  left: -225 + (225 * drawerContext.position.value),
                  top: 0,
                  bottom: 0,
                  width: 225,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.menu, size: 24),
                        const SizedBox(height: 16),
                        Text(
                          'Drawer Menu',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _drawerItem(context, Icons.home, 'Home'),
                        _drawerItem(context, Icons.settings, 'Settings'),
                        _drawerItem(context, Icons.info, 'About'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Modal Pattern Demo
class _ModalPatternDemo extends StatefulWidget {
  const _ModalPatternDemo();

  @override
  State<_ModalPatternDemo> createState() => _ModalPatternDemoState();
}

class _ModalPatternDemoState extends State<_ModalPatternDemo> {
  late final ModalContext modalContext;
  late final ModalStateMachine modalFsm;
  ModalAnimationType currentType = ModalAnimationType.scale;

  @override
  void initState() {
    super.initState();
    _createModal(currentType);
  }

  void _createModal(ModalAnimationType type) {
    modalContext = ModalContext(
      config: _getConfigForType(type),
    );
    modalFsm = ModalStateMachine(modalContext);
  }

  ModalAnimationConfig _getConfigForType(ModalAnimationType type) {
    switch (type) {
      case ModalAnimationType.fade:
        return ModalAnimationConfig.fade;
      case ModalAnimationType.scale:
        return ModalAnimationConfig.scale;
      case ModalAnimationType.slideUp:
        return ModalAnimationConfig.slideUp;
      case ModalAnimationType.bounce:
        return ModalAnimationConfig.bounce;
      default:
        return ModalAnimationConfig.scale;
    }
  }

  void _trigger() {
    modalFsm.send(ModalEvent.show);
    Future.delayed(const Duration(milliseconds: 1500), () {
      modalFsm.send(ModalEvent.hide);
    });
  }

  @override
  void dispose() {
    modalContext.currentAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Modal Dialog',
      description: 'FSM with multiple animations',
      onTrigger: _trigger,
      codeSnippet: '''final ctx = ModalContext(
  config: ModalAnimationConfig.scale,
);
final fsm = ModalStateMachine(ctx);

// Show/hide modal
fsm.dispatch(ModalEvent.show);
fsm.dispatch(ModalEvent.hide);''',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ReactiveBuilder(
              builder: (_) => SizedBox(
                width: 300,
                height: 150,
                child: Stack(
                  children: [
                    // Backdrop
                    if (modalContext.backdropOpacity.value > 0)
                      Opacity(
                        opacity: modalContext.backdropOpacity.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    // Modal
                    if (modalContext.opacity.value > 0)
                      Center(
                        child: Opacity(
                          opacity: modalContext.opacity.value,
                          child: Transform.scale(
                            scale: modalContext.scale.value,
                            child: Transform.translate(
                              offset: Offset(
                                modalContext.offsetX.value,
                                modalContext.offsetY.value,
                              ),
                              child: Container(
                                width: 200,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline, size: 32),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Modal Dialog',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentType.name,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ModalAnimationType.values.take(4).map((type) {
                return ChoiceChip(
                  label: Text(
                    type.name,
                    style: const TextStyle(fontSize: 10),
                  ),
                  selected: currentType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        currentType = type;
                        _createModal(type);
                      });
                    }
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Toast notification data class
class ToastNotification {
  final int id;
  final String message;
  final IconData icon;
  final Color color;
  final AnimatableProperty<Offset> position;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> scale;
  bool isDismissed = false;

  ToastNotification({
    required this.id,
    required this.message,
    required this.icon,
    required this.color,
  })  : position = animatableOffset(const Offset(300, 0)),
        opacity = animatableDouble(0.0),
        scale = animatableDouble(0.9);
}

// Toast Pattern Demo
class _ToastPatternDemo extends StatefulWidget {
  const _ToastPatternDemo();

  @override
  State<_ToastPatternDemo> createState() => _ToastPatternDemoState();
}

class _ToastPatternDemoState extends State<_ToastPatternDemo> {
  List<ToastNotification> toasts = [];
  int nextToastId = 0;
  int toastCount = 0;

  final toastTypes = [
    ('Success', Icons.check_circle, Color(0xFF2ECC71)),
    ('Info', Icons.info, Color(0xFF3498DB)),
    ('Warning', Icons.warning, Color(0xFFF39C12)),
    ('Error', Icons.error, Color(0xFFE74C3C)),
  ];

  void _trigger() {
    _showRandomToast();
  }

  void _showRandomToast() {
    final typeIndex = toastCount % toastTypes.length;
    final toastType = toastTypes[typeIndex];

    final toast = ToastNotification(
      id: nextToastId++,
      message: toastType.$1,
      icon: toastType.$2,
      color: toastType.$3,
    );

    setState(() {
      toasts.add(toast);
      toastCount++;
    });

    // Show animation
    _showToast(toast);

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !toast.isDismissed) {
        _dismissToast(toast);
      }
    });
  }

  Future<void> _showToast(ToastNotification toast) async {
    final showAnim = animate()
        .to(toast.position, Offset.zero)
        .to(toast.opacity, 1.0)
        .to(toast.scale, 1.0)
        .withDuration(400)
        .withEasing(Easing.easeOutBack)
        .build();

    showAnim.play();
  }

  Future<void> _dismissToast(ToastNotification toast) async {
    if (toast.isDismissed) return;

    final dismissAnim = animate()
        .to(toast.position, const Offset(300, 0))
        .to(toast.opacity, 0.0)
        .to(toast.scale, 0.9)
        .withDuration(300)
        .withEasing(Easing.easeInCubic)
        .build();

    dismissAnim.play();

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      toast.isDismissed = true;
      toasts.remove(toast);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Toast Notifications',
      description: 'Animated notification pattern',
      onTrigger: _trigger,
      codeSnippet: '''
// Show toast with slide + fade
final showAnim = animate()
    .to(toast.position, Offset.zero)
    .to(toast.opacity, 1.0)
    .to(toast.scale, 1.0)
    .withDuration(400)
    .withEasing(Easing.easeOutBack)
    .build();

showAnim.play();

// Auto-dismiss after 2 seconds
Future.delayed(Duration(seconds: 2), () {
  final dismissAnim = animate()
      .to(toast.position, Offset(300, 0))
      .to(toast.opacity, 0.0)
      .withDuration(300)
      .build();

  dismissAnim.play();
});
''',
      child: ReactiveBuilder(
        builder: (context) {
          return _buildToastContainer(context);
        },
      ),
    );
  }

  Widget _buildToastContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Empty state
                if (toasts.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications',
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
                  ),

                // Toast notifications stack
                ...toasts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final toast = entry.value;
                  return _buildToast(context, toast, index);
                }),
              ],
            ),
          ),
          if (toastCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Shown: $toastCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active: ${toasts.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToast(BuildContext context, ToastNotification toast, int index) {
    return Positioned(
      top: index * 64.0,
      right: 0,
      left: 0,
      child: Transform.translate(
        offset: toast.position.value,
        child: Transform.scale(
          scale: toast.scale.value,
          child: Opacity(
            opacity: toast.opacity.value,
            child: GestureDetector(
              onTap: () => _dismissToast(toast),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: toast.color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      toast.icon,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      toast.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

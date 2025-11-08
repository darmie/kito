import 'package:flutter/material.dart';
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import 'package:kito_reactive/kito_reactive.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_card.dart';
import '../widgets/reactive_builder.dart';

class PrimitivesDemoScreen extends StatelessWidget {
  const PrimitivesDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Atomic Primitives',
      subtitle: 'Pure, composable animation building blocks',
      tabs: const [
        Tab(text: 'Motion'),
        Tab(text: 'Enter/Exit'),
        Tab(text: 'Timing'),
      ],
      tabViews: const [
        _MotionPrimitivesTab(),
        _EnterExitPrimitivesTab(),
        _TimingPrimitivesTab(),
      ],
    );
  }
}

class _MotionPrimitivesTab extends StatelessWidget {
  const _MotionPrimitivesTab();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 3,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      childAspectRatio: 1.2,
      children: const [
        _ElasticDemo(),
        _BounceDemo(),
        _ShakeDemo(),
        _PulseDemo(),
        _FlashDemo(),
        _SwingDemo(),
        _JelloDemo(),
        _HeartbeatDemo(),
      ],
    );
  }
}

class _ElasticDemo extends StatefulWidget {
  const _ElasticDemo();

  @override
  State<_ElasticDemo> createState() => _ElasticDemoState();
}

class _ElasticDemoState extends State<_ElasticDemo> {
  late final scale = animatableDouble(1.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 1.0;
    _animation = createElastic(scale, 1.5, config: ElasticConfig.strong);
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Elastic',
      description: 'Rubber band oscillation',
      onTrigger: _trigger,
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createElastic(
  scale, 1.5,
  config: ElasticConfig.strong,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.scale(
            scale: scale.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BounceDemo extends StatefulWidget {
  const _BounceDemo();

  @override
  State<_BounceDemo> createState() => _BounceDemoState();
}

class _BounceDemoState extends State<_BounceDemo> {
  late final offsetY = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    offsetY.value = 0.0;
    _animation = createBounce(offsetY, -100.0, config: BounceConfig.playful);
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Bounce',
      description: 'Decreasing amplitude bounces',
      onTrigger: _trigger,
      codeSnippet: '''
final offsetY = animatableDouble(0.0);
final anim = createBounce(
  offsetY, 100.0,
  config: BounceConfig.playful,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.translate(
            offset: Offset(0, offsetY.value),
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShakeDemo extends StatefulWidget {
  const _ShakeDemo();

  @override
  State<_ShakeDemo> createState() => _ShakeDemoState();
}

class _ShakeDemoState extends State<_ShakeDemo> {
  late final offsetX = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    offsetX.value = 0.0;
    _animation = createShake(offsetX, config: ShakeConfig.strong);
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Shake',
      description: 'Error indication wiggle',
      onTrigger: _trigger,
      codeSnippet: '''
final offsetX = animatableDouble(0.0);
final anim = createShake(
  offsetX,
  config: ShakeConfig.strong,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.translate(
            offset: Offset(offsetX.value, 0),
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDemo extends StatefulWidget {
  const _PulseDemo();

  @override
  State<_PulseDemo> createState() => _PulseDemoState();
}

class _PulseDemoState extends State<_PulseDemo> {
  late final scale = animatableDouble(1.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 1.0;
    _animation = createPulse(scale, config: const PulseConfig(pulses: 3));
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Pulse',
      description: 'Rhythmic scaling',
      onTrigger: _trigger,
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createPulse(
  scale,
  config: PulseConfig.strong,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.scale(
            scale: scale.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashDemo extends StatefulWidget {
  const _FlashDemo();

  @override
  State<_FlashDemo> createState() => _FlashDemoState();
}

class _FlashDemoState extends State<_FlashDemo> {
  late final opacity = animatableDouble(1.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    opacity.value = 1.0;
    _animation = createFlash(opacity, config: FlashConfig.quick);
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Flash',
      description: 'Opacity flashing',
      onTrigger: _trigger,
      codeSnippet: '''
final opacity = animatableDouble(1.0);
final anim = createFlash(
  opacity,
  config: FlashConfig.quick,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Opacity(
            opacity: opacity.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications, color: Colors.white, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwingDemo extends StatefulWidget {
  const _SwingDemo();

  @override
  State<_SwingDemo> createState() => _SwingDemoState();
}

class _SwingDemoState extends State<_SwingDemo> {
  late final rotation = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    rotation.value = 0.0;
    _animation = createSwing(rotation, config: SwingConfig.strong);
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Swing',
      description: 'Pendulum rotation',
      onTrigger: _trigger,
      codeSnippet: '''
final rotation = animatableDouble(0.0);
final anim = createSwing(
  rotation,
  config: SwingConfig.strong,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.rotate(
            angle: rotation.value * (3.14159 / 180),
            child: Container(
              width: 60,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JelloDemo extends StatefulWidget {
  const _JelloDemo();

  @override
  State<_JelloDemo> createState() => _JelloDemoState();
}

class _JelloDemoState extends State<_JelloDemo> {
  late final scaleX = animatableDouble(1.0);
  late final scaleY = animatableDouble(1.0);
  KitoAnimation? _animX;
  KitoAnimation? _animY;

  void _trigger() {
    _animX?.dispose();
    _animY?.dispose();
    scaleX.value = 1.0;
    scaleY.value = 1.0;
    _animX = createJello(scaleX, axis: 'x', config: JelloConfig.strong);
    _animY = createJello(scaleY, axis: 'y', config: JelloConfig.strong);
    _animX!.play();
    _animY!.play();
  }

  @override
  void dispose() {
    _animX?.dispose();
    _animY?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Jello',
      description: 'Gelatinous wobble',
      onTrigger: _trigger,
      codeSnippet: '''
final scaleX = animatableDouble(1.0);
final anim = createJello(
  scaleX,
  config: JelloConfig.strong,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform(
            transform: Matrix4.identity()
              ..scale(scaleX.value, scaleY.value),
            alignment: Alignment.center,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartbeatDemo extends StatefulWidget {
  const _HeartbeatDemo();

  @override
  State<_HeartbeatDemo> createState() => _HeartbeatDemoState();
}

class _HeartbeatDemoState extends State<_HeartbeatDemo> {
  late final scale = animatableDouble(1.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 1.0;
    _animation = createHeartbeat(scale, config: const HeartbeatConfig(beats: 2));
    _animation!.play();
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Heartbeat',
      description: 'Double-pulse effect',
      onTrigger: _trigger,
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createHeartbeat(
  scale,
  config: HeartbeatConfig.fast,
);
anim.play();''',
      child: Center(
        child: ReactiveBuilder(
          builder: (_) => Transform.scale(
            scale: scale.value,
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFF43F5E),
              size: 80,
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterExitPrimitivesTab extends StatelessWidget {
  const _EnterExitPrimitivesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Enter/Exit Primitives - Coming soon'),
    );
  }
}

class _TimingPrimitivesTab extends StatelessWidget {
  const _TimingPrimitivesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Timing Primitives - Coming soon'),
    );
  }
}

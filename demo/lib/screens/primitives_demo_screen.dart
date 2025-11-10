import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_patterns/kito_patterns.dart';
import '../widgets/demo_scaffold.dart';
import '../widgets/demo_card.dart';
import '../widgets/clickable_demo.dart';

class PrimitivesDemoScreen extends StatelessWidget {
  const PrimitivesDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoScaffold(
      title: 'Atomic Primitives',
      subtitle: 'Pure, composable animation building blocks',
      tabs: [
        Tab(text: 'Motion'),
        Tab(text: 'Enter/Exit'),
        Tab(text: 'Timing'),
      ],
      tabViews: [
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
    return LayoutBuilder(
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
      },
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
      description: 'Rubber band oscillation (click to animate)',
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createElastic(
  scale, 1.5,
  config: ElasticConfig.strong,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
      description: 'Decreasing amplitude bounces (click to animate)',
      codeSnippet: '''
final offsetY = animatableDouble(0.0);
final anim = createBounce(
  offsetY, 100.0,
  config: BounceConfig.playful,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
      description: 'Error indication wiggle (click to animate)',
      codeSnippet: '''
final offsetX = animatableDouble(0.0);
final anim = createShake(
  offsetX,
  config: ShakeConfig.strong,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
                  child:
                      Icon(Icons.error_outline, color: Colors.white, size: 32),
                ),
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
      description: 'Rhythmic scaling (click to animate)',
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createPulse(
  scale,
  config: PulseConfig.strong,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
      description: 'Opacity flashing (click to animate)',
      codeSnippet: '''
final opacity = animatableDouble(1.0);
final anim = createFlash(
  opacity,
  config: FlashConfig.quick,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
                child: const Icon(Icons.notifications,
                    color: Colors.white, size: 40),
              ),
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
      description: 'Pendulum rotation (click to animate)',
      codeSnippet: '''
final rotation = animatableDouble(0.0);
final anim = createSwing(
  rotation,
  config: SwingConfig.strong,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
      description: 'Gelatinous wobble (click to animate)',
      codeSnippet: '''
final scaleX = animatableDouble(1.0);
final anim = createJello(
  scaleX,
  config: JelloConfig.strong,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform(
              transform: Matrix4.identity()..scale(scaleX.value, scaleY.value),
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
    _animation =
        createHeartbeat(scale, config: const HeartbeatConfig(beats: 2));
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
      description: 'Double-pulse effect (click to animate)',
      codeSnippet: '''
final scale = animatableDouble(1.0);
final anim = createHeartbeat(
  scale,
  config: HeartbeatConfig.fast,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
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
      ),
    );
  }
}

class _EnterExitPrimitivesTab extends StatelessWidget {
  const _EnterExitPrimitivesTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
          children: const [
            _FadeInDemo(),
            _SlideInDemo(),
            _ScaleInDemo(),
            _ZoomInDemo(),
            _FlipInDemo(),
            _RotateInDemo(),
            _SlideFadeDemo(),
            _FadeScaleDemo(),
          ],
        );
      },
    );
  }
}

class _FadeInDemo extends StatefulWidget {
  const _FadeInDemo();

  @override
  State<_FadeInDemo> createState() => _FadeInDemoState();
}

class _FadeInDemoState extends State<_FadeInDemo> {
  late final opacity = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    opacity.value = 0.0;
    _animation = fadeIn(opacity, config: FadeConfig.quick);
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
      title: 'Fade In',
      description: 'Simple opacity transition (click to animate)',
      codeSnippet: '''
final opacity = animatableDouble(0.0);
final anim = fadeIn(
  opacity,
  config: FadeConfig.quick,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideInDemo extends StatefulWidget {
  const _SlideInDemo();

  @override
  State<_SlideInDemo> createState() => _SlideInDemoState();
}

class _SlideInDemoState extends State<_SlideInDemo> {
  late final offsetY = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    offsetY.value = 0.0;
    _animation = slideInFromBottom(offsetY, 100.0, config: SlideConfig.smooth);
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
      title: 'Slide In',
      description: 'Slide from bottom (click to animate)',
      codeSnippet: '''
final offsetY = animatableDouble(0.0);
final anim = slideInFromBottom(
  offsetY, 100.0,
  config: SlideConfig.smooth,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.translate(
              offset: Offset(0, offsetY.value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child:
                      Icon(Icons.arrow_upward, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleInDemo extends StatefulWidget {
  const _ScaleInDemo();

  @override
  State<_ScaleInDemo> createState() => _ScaleInDemoState();
}

class _ScaleInDemoState extends State<_ScaleInDemo> {
  late final scale = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 0.0;
    _animation = scaleIn(scale, config: ScaleConfig.elastic);
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
      title: 'Scale In',
      description: 'Grow with elastic easing (click to animate)',
      codeSnippet: '''
final scale = animatableDouble(0.0);
final anim = scaleIn(
  scale,
  config: ScaleConfig.elastic,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.scale(
              scale: scale.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6B6B),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomInDemo extends StatefulWidget {
  const _ZoomInDemo();

  @override
  State<_ZoomInDemo> createState() => _ZoomInDemoState();
}

class _ZoomInDemoState extends State<_ZoomInDemo> {
  late final scale = animatableDouble(0.0);
  late final opacity = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 0.0;
    opacity.value = 0.0;
    _animation = zoomIn(scale, opacity);
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
      title: 'Zoom In',
      description: 'Scale + fade with bounce (click to animate)',
      codeSnippet: '''
final scale = animatableDouble(0.0);
final opacity = animatableDouble(0.0);
final anim = zoomIn(scale, opacity);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A4A4A),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.zoom_in, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipInDemo extends StatefulWidget {
  const _FlipInDemo();

  @override
  State<_FlipInDemo> createState() => _FlipInDemoState();
}

class _FlipInDemoState extends State<_FlipInDemo> {
  late final rotation = animatableDouble(0.0);
  late final opacity = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    rotation.value = 0.0;
    opacity.value = 0.0;
    _animation = flipIn(rotation, opacity);
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
      title: 'Flip In',
      description: '3D-like rotation (click to animate)',
      codeSnippet: '''
final rotation = animatableDouble(0.0);
final opacity = animatableDouble(0.0);
final anim = flipIn(rotation, opacity);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotation.value * (3.14159 / 180)),
                alignment: Alignment.center,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Icon(Icons.flip, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotateInDemo extends StatefulWidget {
  const _RotateInDemo();

  @override
  State<_RotateInDemo> createState() => _RotateInDemoState();
}

class _RotateInDemoState extends State<_RotateInDemo> {
  late final rotation = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    rotation.value = 0.0;
    _animation = rotateIn(rotation, fromDegrees: 180.0);
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
      title: 'Rotate In',
      description: 'Clockwise rotation (click to animate)',
      codeSnippet: '''
final rotation = animatableDouble(0.0);
final anim = rotateIn(
  rotation,
  fromDegrees: 180.0,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.rotate(
              angle: rotation.value * (3.14159 / 180),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2691E),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child:
                      Icon(Icons.rotate_right, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideFadeDemo extends StatefulWidget {
  const _SlideFadeDemo();

  @override
  State<_SlideFadeDemo> createState() => _SlideFadeDemoState();
}

class _SlideFadeDemoState extends State<_SlideFadeDemo> {
  late final opacity = animatableDouble(0.0);
  late final offsetX = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    opacity.value = 0.0;
    offsetX.value = 0.0;
    _animation = slideFadeIn(opacity, offsetX, 50.0);
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
      title: 'Slide + Fade',
      description: 'Combined slide and fade (click to animate)',
      codeSnippet: '''
final opacity = animatableDouble(0.0);
final offsetX = animatableDouble(0.0);
final anim = slideFadeIn(
  opacity, offsetX, 50.0,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform.translate(
                offset: Offset(offsetX.value, 0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B6B6B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward,
                        color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FadeScaleDemo extends StatefulWidget {
  const _FadeScaleDemo();

  @override
  State<_FadeScaleDemo> createState() => _FadeScaleDemoState();
}

class _FadeScaleDemoState extends State<_FadeScaleDemo> {
  late final opacity = animatableDouble(0.0);
  late final scale = animatableDouble(0.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    opacity.value = 0.0;
    scale.value = 0.0;
    _animation = fadeScaleIn(opacity, scale);
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
      title: 'Fade + Scale',
      description: 'Combined fade and scale (click to animate)',
      codeSnippet: '''
final opacity = animatableDouble(0.0);
final scale = animatableDouble(0.0);
final anim = fadeScaleIn(
  opacity, scale,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4A4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Center(
                    child: Icon(Icons.star, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimingPrimitivesTab extends StatelessWidget {
  const _TimingPrimitivesTab();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
          children: const [
            _ChainDemo(),
            _ParallelDemo(),
            _SpringDemo(),
            _PingPongDemo(),
            _YoyoDemo(),
            _StaggerDemo(),
          ],
        );
      },
    );
  }
}

class _ChainDemo extends StatefulWidget {
  const _ChainDemo();

  @override
  State<_ChainDemo> createState() => _ChainDemoState();
}

class _ChainDemoState extends State<_ChainDemo> {
  late final scale = animatableDouble(1.0);
  late final rotation = animatableDouble(0.0);
  late final opacity = animatableDouble(1.0);

  void _trigger() {
    scale.value = 1.0;
    rotation.value = 0.0;
    opacity.value = 1.0;

    final anim1 = scaleIn(scale,
        config: const ScaleConfig(fromScale: 1.0, toScale: 1.5, duration: 300));
    final anim2 = rotateIn(rotation,
        fromDegrees: 360.0, config: const RotateConfig(duration: 400));
    final anim3 = fadeOut(opacity,
        config:
            const FadeConfig(fromOpacity: 1.0, toOpacity: 0.0, duration: 300));

    chain([anim1, anim2, anim3], gap: 100);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Chain',
      description: 'Sequential animations (click to animate)',
      codeSnippet: '''
final anim1 = scaleIn(scale);
final anim2 = rotateIn(rotation);
final anim3 = fadeOut(opacity);

chain([anim1, anim2, anim3],
  gap: 100,
);''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: Transform.rotate(
                  angle: rotation.value * (3.14159 / 180),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Icon(Icons.link, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParallelDemo extends StatefulWidget {
  const _ParallelDemo();

  @override
  State<_ParallelDemo> createState() => _ParallelDemoState();
}

class _ParallelDemoState extends State<_ParallelDemo> {
  late final scale = animatableDouble(0.0);
  late final rotation = animatableDouble(0.0);
  late final opacity = animatableDouble(0.0);

  void _trigger() {
    scale.value = 0.0;
    rotation.value = 0.0;
    opacity.value = 0.0;

    final anim1 = scaleIn(scale, config: const ScaleConfig(duration: 500));
    final anim2 = rotateIn(rotation,
        fromDegrees: 360.0, config: const RotateConfig(duration: 500));
    final anim3 = fadeIn(opacity, config: const FadeConfig(duration: 500));

    parallel([anim1, anim2, anim3]);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Parallel',
      description: 'Simultaneous animations (click to animate)',
      codeSnippet: '''
final anim1 = scaleIn(scale);
final anim2 = rotateIn(rotation);
final anim3 = fadeIn(opacity);

parallel([anim1, anim2, anim3]);''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: Transform.rotate(
                  angle: rotation.value * (3.14159 / 180),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2691E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Center(
                      child: Icon(Icons.layers, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpringDemo extends StatefulWidget {
  const _SpringDemo();

  @override
  State<_SpringDemo> createState() => _SpringDemoState();
}

class _SpringDemoState extends State<_SpringDemo> {
  late final scale = animatableDouble(1.0);
  KitoAnimation? _animation;

  void _trigger() {
    _animation?.dispose();
    scale.value = 1.0;
    _animation = spring(
      property: scale,
      target: 1.5,
      stiffness: 200.0,
      damping: 10.0,
    );
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
      title: 'Spring',
      description: 'Physics-based motion (click to animate)',
      codeSnippet: '''
final anim = spring(
  property: scale,
  target: 1.5,
  stiffness: 200.0,
  damping: 10.0,
);
anim.play();''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.scale(
              scale: scale.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6B6B),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Icon(Icons.timeline, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PingPongDemo extends StatefulWidget {
  const _PingPongDemo();

  @override
  State<_PingPongDemo> createState() => _PingPongDemoState();
}

class _PingPongDemoState extends State<_PingPongDemo> {
  late final scale = animatableDouble(1.0);

  void _trigger() {
    scale.value = 1.0;
    pingPong(
      property: scale,
      from: 1.0,
      to: 1.4,
      duration: 400,
      times: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Ping-Pong',
      description: 'Oscillate between values (click to animate)',
      codeSnippet: '''
pingPong(
  property: scale,
  from: 1.0,
  to: 1.4,
  times: 4,
);''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.scale(
              scale: scale.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A4A4A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child:
                      Icon(Icons.compare_arrows, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _YoyoDemo extends StatefulWidget {
  const _YoyoDemo();

  @override
  State<_YoyoDemo> createState() => _YoyoDemoState();
}

class _YoyoDemoState extends State<_YoyoDemo> {
  late final offsetX = animatableDouble(0.0);

  void _trigger() {
    offsetX.value = 0.0;
    final anim = slideInFromRight(offsetX, 60.0,
        config: const SlideConfig(duration: 300));
    yoyo(anim, times: 2);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Yoyo',
      description: 'Back and forth motion (click to animate)',
      codeSnippet: '''
final anim = slideInFromRight(
  offsetX, 60.0,
);
yoyo(anim, times: 2);''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: ReactiveBuilder(
            builder: (_) => Transform.translate(
              offset: Offset(offsetX.value, 0),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Center(
                  child: Icon(Icons.sync_alt, color: Colors.white, size: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggerDemo extends StatefulWidget {
  const _StaggerDemo();

  @override
  State<_StaggerDemo> createState() => _StaggerDemoState();
}

class _StaggerDemoState extends State<_StaggerDemo> {
  final scales = [
    animatableDouble(0.0),
    animatableDouble(0.0),
    animatableDouble(0.0),
    animatableDouble(0.0),
  ];

  void _trigger() {
    for (final s in scales) {
      s.value = 0.0;
    }

    final anims = scales
        .map((s) => scaleIn(s, config: const ScaleConfig(duration: 300)))
        .toList();
    staggerStart(anims, delayMs: 100);
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Stagger',
      description: 'Delayed starts (click to animate)',
      codeSnippet: '''
final anims = scales.map((s) =>
  scaleIn(s)
).toList();

staggerStart(anims, delayMs: 100);''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (_) => Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ReactiveBuilder(
                  builder: (_) => Transform.scale(
                    scale: scales[i].value,
                    child: Container(
                      width: 20,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2691E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

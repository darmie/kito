import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'demo_card.dart';
import 'clickable_demo.dart';

/// Heat map cell data model
class HeatMapCell {
  final int row;
  final int col;
  final double value;

  const HeatMapCell({
    required this.row,
    required this.col,
    required this.value,
  });
}

/// Heat map state machine states
enum HeatMapState { idle, updating, animating }

enum HeatMapEvent { startUpdate, updateComplete, hover, leave }

class HeatMapContext {
  final void Function() onUpdate;

  HeatMapContext({required this.onUpdate});
}

/// Heat map FSM
class HeatMapFSM extends KitoStateMachine<HeatMapState, HeatMapEvent, HeatMapContext> {
  HeatMapFSM(HeatMapContext context)
      : super(
          initial: HeatMapState.idle,
          context: context,
          config: StateMachineConfig(
            states: {
              HeatMapState.idle: StateConfig(
                state: HeatMapState.idle,
                transitions: {
                  HeatMapEvent.startUpdate: TransitionConfig(
                    target: HeatMapState.updating,
                  ),
                },
              ),
              HeatMapState.updating: StateConfig(
                state: HeatMapState.updating,
                onEntry: (context, from, to) => context.onUpdate(),
                transitions: {
                  HeatMapEvent.updateComplete: TransitionConfig(
                    target: HeatMapState.animating,
                  ),
                },
              ),
              HeatMapState.animating: StateConfig(
                state: HeatMapState.animating,
                transitions: {
                  HeatMapEvent.updateComplete: TransitionConfig(
                    target: HeatMapState.idle,
                  ),
                },
              ),
            },
          ),
        );
}

/// Heat map painter using canvas
class HeatMapPainter extends KitoPainter {
  final List<List<double>> data;
  final double maxValue;
  final int? hoveredRow;
  final int? hoveredCol;

  HeatMapPainter(
    super.properties, {
    required this.data,
    required this.maxValue,
    this.hoveredRow,
    this.hoveredCol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final rows = data.length;
    final cols = data[0].length;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final value = data[row][col];
        final normalizedValue = maxValue > 0 ? value / maxValue : 0.0;

        // Apply progress animation
        final animatedValue = normalizedValue * properties.pathProgress.value;

        // Color gradient from blue (cold) to red (hot)
        final color = Color.lerp(
          const Color(0xFF3498DB),
          const Color(0xFFE74C3C),
          animatedValue,
        )!;

        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );

        // Apply scale if hovered
        final isHovered = row == hoveredRow && col == hoveredCol;
        if (isHovered) {
          canvas.save();
          final center = rect.center;
          canvas.translate(center.dx, center.dy);
          canvas.scale(properties.scale.value);
          canvas.translate(-center.dx, -center.dy);
        }

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, paint);

        // Draw border
        final borderPaint = Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isHovered ? 2.0 : 1.0;

        canvas.drawRect(rect, borderPaint);

        if (isHovered) {
          canvas.restore();
        }
      }
    }
  }
}

/// Heat map demo widget
class HeatMapDemo extends StatefulWidget {
  const HeatMapDemo({super.key});

  @override
  State<HeatMapDemo> createState() => _HeatMapDemoState();
}

class _HeatMapDemoState extends State<HeatMapDemo> {
  static const int rows = 10;
  static const int cols = 15;

  late final Signal<List<List<double>>> heatMapData;
  late final Signal<double> maxValue;
  late final Signal<int?> hoveredRow;
  late final Signal<int?> hoveredCol;
  late final HeatMapFSM fsm;
  late final CanvasAnimationProperties canvasProps;

  Timer? _updateTimer;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    heatMapData = signal(_generateInitialData());
    maxValue = signal(100.0);
    hoveredRow = signal(null);
    hoveredCol = signal(null);

    canvasProps = CanvasAnimationProperties(
      pathProgress: 0.0,
      scale: 1.0,
    );

    fsm = HeatMapFSM(
      HeatMapContext(
        onUpdate: _updateHeatMapData,
      ),
    );

    _startAnimation();
  }

  List<List<double>> _generateInitialData() {
    return List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) => _random.nextDouble() * 100,
      ),
    );
  }

  void _updateHeatMapData() {
    // Simulate real-time data update with smooth transitions
    final newData = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) {
          final oldValue = heatMapData.value[row][col];
          final delta = (_random.nextDouble() - 0.5) * 20;
          return (oldValue + delta).clamp(0.0, 100.0);
        },
      ),
    );

    heatMapData.value = newData;
    maxValue.value = 100.0;

    // Animate the update
    animate()
        .to(canvasProps.pathProgress, 1.0)
        .withDuration(800)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();
  }

  void _startAnimation() {
    // Reset progress
    canvasProps.pathProgress.value = 0.0;

    // Initial animation
    animate()
        .to(canvasProps.pathProgress, 1.0)
        .withDuration(1200)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();

    // Start periodic updates
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        canvasProps.pathProgress.value = 0.0;
        fsm.send(HeatMapEvent.startUpdate);
        Future.delayed(const Duration(milliseconds: 100), () {
          fsm.send(HeatMapEvent.updateComplete);
        });
      }
    });
  }

  void _trigger() {
    canvasProps.pathProgress.value = 0.0;
    heatMapData.value = _generateInitialData();
    _startAnimation();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    fsm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Real-time Heat Map',
      description: 'Animated heat map visualization with live data updates',
      codeSnippet: '''
// Heat map with canvas painter
final painter = HeatMapPainter(
  canvasProps,
  data: heatMapData.value,
  maxValue: maxValue.value,
);

animate(
  canvasProps.pathProgress,
  to: 1.0,
  duration: Duration(milliseconds: 800),
  easing: Easing.easeOutCubic,
);
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (context) => ReactiveBuilder(
          builder: (_) {
            return MouseRegion(
              onHover: (event) {
                final size = context.size;
                if (size != null) {
                  final cellWidth = size.width / cols;
                  final cellHeight = size.height / rows;
                  final col = (event.localPosition.dx / cellWidth).floor();
                  final row = (event.localPosition.dy / cellHeight).floor();

                  if (col >= 0 && col < cols && row >= 0 && row < rows) {
                    hoveredRow.value = row;
                    hoveredCol.value = col;

                    // Animate scale on hover
                    animate()
                        .to(canvasProps.scale, 1.1)
                        .withDuration(150)
                        .withEasing(Easing.easeOutCubic)
                        .build()
                        .play();
                  }
                }
              },
              onExit: (_) {
                hoveredRow.value = null;
                hoveredCol.value = null;
                animate()
                    .to(canvasProps.scale, 1.0)
                    .withDuration(150)
                    .withEasing(Easing.easeOutCubic)
                    .build()
                    .play();
              },
              child: KitoCanvas(
                painter: HeatMapPainter(
                  canvasProps,
                  data: heatMapData.value,
                  maxValue: maxValue.value,
                  hoveredRow: hoveredRow.value,
                  hoveredCol: hoveredCol.value,
                ),
                size: const Size(double.infinity, 300),
                willChange: true,
                isComplex: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

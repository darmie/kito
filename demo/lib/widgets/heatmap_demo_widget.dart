import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'demo_card.dart';
import 'clickable_demo.dart';

/// System monitoring heat map showing CPU-style utilization over time
/// Data point representing a metric at a specific time
class MetricData {
  final double timestamp;
  final List<double> values; // Multiple metrics (CPU cores, memory, etc.)

  const MetricData({
    required this.timestamp,
    required this.values,
  });
}

/// Heat map state machine states
enum HeatMapState { idle, updating, animating }

enum HeatMapEvent { startUpdate, updateComplete }

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
                    target: HeatMapState.idle,
                  ),
                },
              ),
            },
          ),
        );
}

/// CPU/System monitoring style heat map painter
class SystemHeatMapPainter extends KitoPainter {
  final List<MetricData> dataPoints;
  final int numMetrics;
  final double maxValue;
  final List<String> metricLabels;

  SystemHeatMapPainter(
    super.properties, {
    required this.dataPoints,
    required this.numMetrics,
    required this.maxValue,
    required this.metricLabels,
  });

  Color _getHeatColor(double value) {
    final normalized = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    // Color gradient: green (low) -> yellow (medium) -> red (high)
    if (normalized < 0.5) {
      return Color.lerp(
        const Color(0xFF2ECC71), // Green
        const Color(0xFFF39C12), // Yellow
        normalized * 2,
      )!;
    } else {
      return Color.lerp(
        const Color(0xFFF39C12), // Yellow
        const Color(0xFFE74C3C), // Red
        (normalized - 0.5) * 2,
      )!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || numMetrics == 0) return;

    final metricHeight = size.height / numMetrics;
    final timeStep = size.width / (dataPoints.length - 1).clamp(1, double.infinity);

    // Draw heat map with gradient rectangles
    for (int metricIndex = 0; metricIndex < numMetrics; metricIndex++) {
      final y = metricIndex * metricHeight;

      for (int i = 0; i < dataPoints.length - 1; i++) {
        final data = dataPoints[i];
        final nextData = dataPoints[i + 1];

        if (metricIndex >= data.values.length) continue;

        final value = data.values[metricIndex];
        final nextValue = metricIndex < nextData.values.length
            ? nextData.values[metricIndex]
            : value;

        final x = i * timeStep;
        final width = timeStep + 1; // Add 1 to prevent gaps

        // Create gradient rect
        final rect = Rect.fromLTWH(x, y, width, metricHeight);

        // Use shader for smooth gradient between data points
        final gradient = ui.Gradient.linear(
          Offset(x, y + metricHeight / 2),
          Offset(x + width, y + metricHeight / 2),
          [
            _getHeatColor(value),
            _getHeatColor(nextValue),
          ],
        );

        final paint = Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill;

        // Apply progress animation
        if (properties.pathProgress.value < 1.0) {
          final progress = properties.pathProgress.value;
          final visibleWidth = size.width * progress;
          if (x < visibleWidth) {
            final clippedRect = Rect.fromLTWH(
              x,
              y,
              (x + width > visibleWidth) ? (visibleWidth - x) : width,
              metricHeight,
            );
            canvas.drawRect(clippedRect, paint);
          }
        } else {
          canvas.drawRect(rect, paint);
        }
      }

      // Draw metric label
      if (metricIndex < metricLabels.length && properties.pathProgress.value > 0.5) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: metricLabels[metricIndex],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(8, y + (metricHeight - textPainter.height) / 2),
        );
      }

      // Draw separator line
      if (metricIndex < numMetrics - 1) {
        final linePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(0, y + metricHeight),
          Offset(size.width, y + metricHeight),
          linePaint,
        );
      }
    }
  }
}

/// System monitoring heat map demo widget
class HeatMapDemo extends StatefulWidget {
  const HeatMapDemo({super.key});

  @override
  State<HeatMapDemo> createState() => _HeatMapDemoState();
}

class _HeatMapDemoState extends State<HeatMapDemo> {
  static const int numMetrics = 4; // CPU, Memory, Network, Disk
  static const int maxDataPoints = 60; // Show last 60 time points
  static const List<String> metricLabels = [
    'CPU',
    'Memory',
    'Network',
    'Disk I/O',
  ];

  late final Signal<List<MetricData>> dataPoints;
  late final HeatMapFSM fsm;
  late final CanvasAnimationProperties canvasProps;

  Timer? _updateTimer;
  final math.Random _random = math.Random();
  double _currentTime = 0;

  @override
  void initState() {
    super.initState();

    dataPoints = signal(_generateInitialData());

    canvasProps = CanvasAnimationProperties(
      pathProgress: 0.0,
    );

    fsm = HeatMapFSM(
      HeatMapContext(
        onUpdate: _addNewDataPoint,
      ),
    );

    _startAnimation();
  }

  List<MetricData> _generateInitialData() {
    final data = <MetricData>[];
    for (int i = 0; i < maxDataPoints; i++) {
      data.add(MetricData(
        timestamp: _currentTime++,
        values: List.generate(numMetrics, (_) => _random.nextDouble() * 100),
      ));
    }
    return data;
  }

  void _addNewDataPoint() {
    final currentData = List<MetricData>.from(dataPoints.value);

    // Add new data point
    currentData.add(MetricData(
      timestamp: _currentTime++,
      values: List.generate(numMetrics, (i) {
        // Smooth transition from previous value
        final prevValue = currentData.isNotEmpty && i < currentData.last.values.length
            ? currentData.last.values[i]
            : 50.0;
        final delta = (_random.nextDouble() - 0.5) * 30;
        return (prevValue + delta).clamp(0.0, 100.0);
      }),
    ));

    // Keep only last maxDataPoints
    if (currentData.length > maxDataPoints) {
      currentData.removeAt(0);
    }

    dataPoints.value = currentData;

    // Quick animation for new data
    canvasProps.pathProgress.value = 0.95;
    animate()
        .to(canvasProps.pathProgress, 1.0)
        .withDuration(200)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();
  }

  void _startAnimation() {
    // Initial animation
    canvasProps.pathProgress.value = 0.0;
    animate()
        .to(canvasProps.pathProgress, 1.0)
        .withDuration(1500)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();

    // Start periodic updates (simulate real-time data)
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        fsm.send(HeatMapEvent.startUpdate);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            fsm.send(HeatMapEvent.updateComplete);
          }
        });
      }
    });
  }

  void _trigger() {
    canvasProps.pathProgress.value = 0.0;
    _currentTime = 0;
    dataPoints.value = _generateInitialData();

    animate()
        .to(canvasProps.pathProgress, 1.0)
        .withDuration(1500)
        .withEasing(Easing.easeOutCubic)
        .build()
        .play();
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
      title: 'System Monitoring Heat Map',
      description: 'Real-time CPU/system metrics visualization with gradient heat colors',
      codeSnippet: '''
// System monitoring heat map
final painter = SystemHeatMapPainter(
  canvasProps,
  dataPoints: dataPoints.value,
  numMetrics: 4,
  maxValue: 100.0,
  metricLabels: ['CPU', 'Memory', 'Network', 'Disk I/O'],
);

// Add new data point every 500ms
Timer.periodic(Duration(milliseconds: 500), (_) {
  fsm.send(HeatMapEvent.startUpdate);
});
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (context) => Builder(
          builder: (builderContext) => ReactiveBuilder(
            builder: (_) {
              return SizedBox(
                height: 300,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return KitoCanvas(
                      painter: SystemHeatMapPainter(
                        canvasProps,
                        dataPoints: dataPoints.value,
                        numMetrics: numMetrics,
                        maxValue: 100.0,
                        metricLabels: metricLabels,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      willChange: true,
                      isComplex: true,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import 'demo_card.dart';
import 'clickable_demo.dart';

/// Real-time scrolling area chart with gradient fills
/// Similar to climate/monitoring dashboards

/// Data point for time series
class DataPoint {
  final double timestamp;
  final double value;

  const DataPoint({
    required this.timestamp,
    required this.value,
  });
}

/// Chart state machine
enum ChartState { idle, updating, animating }

enum ChartEvent { startUpdate, updateComplete }

class ChartContext {
  final void Function() onUpdate;

  ChartContext({required this.onUpdate});
}

/// Chart FSM
class ChartFSM extends KitoStateMachine<ChartState, ChartEvent, ChartContext> {
  ChartFSM(ChartContext context)
      : super(
          initial: ChartState.idle,
          context: context,
          config: StateMachineConfig(
            states: {
              ChartState.idle: StateConfig(
                state: ChartState.idle,
                transitions: {
                  ChartEvent.startUpdate: TransitionConfig(
                    target: ChartState.updating,
                  ),
                },
              ),
              ChartState.updating: StateConfig(
                state: ChartState.updating,
                onEntry: (context, from, to) => context.onUpdate(),
                transitions: {
                  ChartEvent.updateComplete: TransitionConfig(
                    target: ChartState.idle,
                  ),
                },
              ),
            },
          ),
        );
}

/// Scrolling area chart painter with gradient fills
class ScrollingAreaChartPainter extends KitoPainter {
  final List<DataPoint> dataPoints;
  final double minValue;
  final double maxValue;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final double scrollOffset;

  ScrollingAreaChartPainter(
    super.properties, {
    required this.dataPoints,
    required this.minValue,
    required this.maxValue,
    required this.lineColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    this.scrollOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty || maxValue <= minValue) return;

    final valueRange = maxValue - minValue;
    final padding = 20.0;
    final chartHeight = size.height - padding * 2;
    final chartWidth = size.width;

    // Calculate x step based on data points
    final xStep = chartWidth / (dataPoints.length - 1).clamp(1, double.infinity);

    // Build path for area fill
    final path = ui.Path();
    final linePath = ui.Path();

    bool firstPoint = true;
    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final normalizedValue = ((point.value - minValue) / valueRange).clamp(0.0, 1.0);

      // Apply scroll offset and progress animation
      final x = (i * xStep) - scrollOffset + (chartWidth * (1 - properties.pathProgress.value));
      final y = padding + chartHeight - (normalizedValue * chartHeight);

      // Skip points outside visible area
      if (x < -xStep || x > chartWidth + xStep) continue;

      if (firstPoint) {
        path.moveTo(x, size.height - padding);
        path.lineTo(x, y);
        linePath.moveTo(x, y);
        firstPoint = false;
      } else {
        // Smooth curve using quadratic bezier
        if (i > 0 && i < dataPoints.length) {
          final prevPoint = dataPoints[i - 1];
          final prevNormalized = ((prevPoint.value - minValue) / valueRange).clamp(0.0, 1.0);
          final prevX = ((i - 1) * xStep) - scrollOffset + (chartWidth * (1 - properties.pathProgress.value));
          final prevY = padding + chartHeight - (prevNormalized * chartHeight);

          final controlX = (prevX + x) / 2;

          path.quadraticBezierTo(controlX, prevY, x, y);
          linePath.quadraticBezierTo(controlX, prevY, x, y);
        }
      }
    }

    // Close the area path
    if (!firstPoint) {
      final lastX = (dataPoints.length - 1) * xStep - scrollOffset + (chartWidth * (1 - properties.pathProgress.value));
      path.lineTo(lastX, size.height - padding);
      path.close();

      // Draw gradient fill
      final gradient = ui.Gradient.linear(
        Offset(0, padding),
        Offset(0, size.height - padding),
        [
          gradientStartColor.withValues(alpha: 0.7),
          gradientEndColor.withValues(alpha: 0.1),
        ],
      );

      final fillPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);

      // Draw line
      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw grid lines
    _drawGrid(canvas, size, padding, chartHeight);

    // Draw axis labels
    _drawLabels(canvas, size, padding, chartHeight);
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double chartHeight) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double padding, double chartHeight) {
    if (properties.pathProgress.value < 0.8) return;

    // Draw min/max labels
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.6),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // Max value label
    final maxText = TextPainter(
      text: TextSpan(text: maxValue.toStringAsFixed(0), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    maxText.layout();
    maxText.paint(canvas, Offset(4, padding - 12));

    // Min value label
    final minText = TextPainter(
      text: TextSpan(text: minValue.toStringAsFixed(0), style: textStyle),
      textDirection: TextDirection.ltr,
    );
    minText.layout();
    minText.paint(canvas, Offset(4, size.height - padding - 2));
  }
}

/// Scrolling area chart demo widget
class HeatMapDemo extends StatefulWidget {
  const HeatMapDemo({super.key});

  @override
  State<HeatMapDemo> createState() => _HeatMapDemoState();
}

class _HeatMapDemoState extends State<HeatMapDemo> {
  static const int maxDataPoints = 100;
  static const double updateInterval = 200.0; // milliseconds

  late final Signal<List<DataPoint>> cpuData;
  late final Signal<List<DataPoint>> memoryData;
  late final Signal<List<DataPoint>> networkData;
  late final ChartFSM fsm;
  late final CanvasAnimationProperties cpuProps;
  late final CanvasAnimationProperties memoryProps;
  late final CanvasAnimationProperties networkProps;
  late final CanvasAnimationProperties scrollProps;

  Timer? _updateTimer;
  final math.Random _random = math.Random();
  double _currentTime = 0;

  @override
  void initState() {
    super.initState();

    cpuData = signal(_generateInitialData());
    memoryData = signal(_generateInitialData());
    networkData = signal(_generateInitialData());

    cpuProps = CanvasAnimationProperties(pathProgress: 0.0);
    memoryProps = CanvasAnimationProperties(pathProgress: 0.0);
    networkProps = CanvasAnimationProperties(pathProgress: 0.0);
    scrollProps = CanvasAnimationProperties(rotation: 0.0); // Using rotation for scroll offset

    fsm = ChartFSM(
      ChartContext(onUpdate: _addNewDataPoint),
    );

    _startAnimation();
  }

  List<DataPoint> _generateInitialData() {
    final data = <DataPoint>[];
    double value = 30 + _random.nextDouble() * 40;

    for (int i = 0; i < maxDataPoints; i++) {
      // Generate smooth random walk
      value += (_random.nextDouble() - 0.5) * 10;
      value = value.clamp(10.0, 90.0);

      data.add(DataPoint(
        timestamp: _currentTime + i,
        value: value,
      ));
    }

    return data;
  }

  void _addNewDataPoint() {
    // Add new data point to each series
    _addPointToSeries(cpuData);
    _addPointToSeries(memoryData);
    _addPointToSeries(networkData);

    _currentTime++;

    // Animate scroll offset
    final currentOffset = scrollProps.rotation.value;
    animate()
        .to(scrollProps.rotation, currentOffset + 2.0)
        .withDuration(updateInterval.toInt())
        .withEasing(Easing.linear)
        .build()
        .play();
  }

  void _addPointToSeries(Signal<List<DataPoint>> series) {
    final currentData = List<DataPoint>.from(series.value);

    // Generate new value based on previous
    final prevValue = currentData.isNotEmpty ? currentData.last.value : 50.0;
    final delta = (_random.nextDouble() - 0.5) * 15;
    final newValue = (prevValue + delta).clamp(10.0, 90.0);

    currentData.add(DataPoint(
      timestamp: _currentTime + maxDataPoints,
      value: newValue,
    ));

    // Keep only last maxDataPoints
    if (currentData.length > maxDataPoints) {
      currentData.removeAt(0);
    }

    series.value = currentData;
  }

  void _startAnimation() {
    // Set charts to fully visible immediately for real-time display
    cpuProps.pathProgress.value = 1.0;
    memoryProps.pathProgress.value = 1.0;
    networkProps.pathProgress.value = 1.0;

    // Start periodic updates immediately - real-time streaming
    _updateTimer = Timer.periodic(Duration(milliseconds: updateInterval.toInt()), (_) {
      if (mounted) {
        fsm.send(ChartEvent.startUpdate);
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            fsm.send(ChartEvent.updateComplete);
          }
        });
      }
    });
  }

  void _trigger() {
    // Reset to initial state for demo trigger
    _currentTime = 0;
    scrollProps.rotation.value = 0.0;
    cpuData.value = _generateInitialData();
    memoryData.value = _generateInitialData();
    networkData.value = _generateInitialData();

    // Keep fully visible for real-time display
    cpuProps.pathProgress.value = 1.0;
    memoryProps.pathProgress.value = 1.0;
    networkProps.pathProgress.value = 1.0;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    fsm.dispose();
    super.dispose();
  }

  Widget _buildChart({
    required String label,
    required List<DataPoint> dataPoints,
    required CanvasAnimationProperties props,
    required Color lineColor,
    required Color gradientStart,
    required Color gradientEnd,
    required double scrollOffset,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return KitoCanvas(
                painter: ScrollingAreaChartPainter(
                  props,
                  dataPoints: dataPoints,
                  minValue: 0.0,
                  maxValue: 100.0,
                  lineColor: lineColor,
                  gradientStartColor: gradientStart,
                  gradientEndColor: gradientEnd,
                  scrollOffset: scrollOffset,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
                willChange: true,
                isComplex: true,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Real-time Streaming Charts',
      description: 'Live data visualization with scrolling gradient area charts',
      codeSnippet: '''
// Scrolling area chart with gradient fills
final painter = ScrollingAreaChartPainter(
  props,
  dataPoints: cpuData.value,
  minValue: 0.0,
  maxValue: 100.0,
  lineColor: Color(0xFF3498DB),
  gradientStartColor: Color(0xFF3498DB),
  gradientEndColor: Color(0xFF3498DB).withValues(alpha: 0.1),
  scrollOffset: scrollProps.rotation.value,
);

// Update every 200ms
Timer.periodic(Duration(milliseconds: 200), (_) {
  fsm.send(ChartEvent.startUpdate);
});
''',
      child: ClickableDemo(
        onTrigger: _trigger,
        builder: (context) => Builder(
          builder: (builderContext) => ReactiveBuilder(
            builder: (_) {
              // Access all signals here to establish reactive dependencies
              final cpuDataValue = cpuData.value;
              final memoryDataValue = memoryData.value;
              final networkDataValue = networkData.value;
              final scrollOffsetValue = scrollProps.rotation.value;

              return SizedBox(
                height: 300,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildChart(
                        label: 'CPU Usage',
                        dataPoints: cpuDataValue,
                        props: cpuProps,
                        lineColor: const Color(0xFF3498DB),
                        gradientStart: const Color(0xFF3498DB),
                        gradientEnd: const Color(0xFF3498DB),
                        scrollOffset: scrollOffsetValue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildChart(
                        label: 'Memory',
                        dataPoints: memoryDataValue,
                        props: memoryProps,
                        lineColor: const Color(0xFF9B59B6),
                        gradientStart: const Color(0xFF9B59B6),
                        gradientEnd: const Color(0xFF9B59B6),
                        scrollOffset: scrollOffsetValue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildChart(
                        label: 'Network',
                        dataPoints: networkDataValue,
                        props: networkProps,
                        lineColor: const Color(0xFF2ECC71),
                        gradientStart: const Color(0xFF2ECC71),
                        gradientEnd: const Color(0xFF2ECC71),
                        scrollOffset: scrollOffsetValue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

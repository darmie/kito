import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:kito_reactive/kito_reactive.dart';
import 'animation_profiler.dart';

/// Performance overlay widget that displays FPS and other metrics
class KitoPerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final PerformanceOverlayPosition position;
  final Color backgroundColor;
  final Color textColor;
  final Color graphColor;

  const KitoPerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.position = PerformanceOverlayPosition.topRight,
    this.backgroundColor = const Color(0xCC000000),
    this.textColor = Colors.white,
    this.graphColor = Colors.greenAccent,
  });

  @override
  State<KitoPerformanceOverlay> createState() => _KitoPerformanceOverlayState();
}

class _KitoPerformanceOverlayState extends State<KitoPerformanceOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.enabled) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _monitor.recordFrame();
    setState(() {});
  }

  @override
  void didUpdateWidget(KitoPerformanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _ticker.start();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            top: widget.position.isTop ? 8 : null,
            bottom: widget.position.isBottom ? 8 : null,
            left: widget.position.isLeft ? 8 : null,
            right: widget.position.isRight ? 8 : null,
            child: _buildOverlay(),
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    final snapshot = _monitor.currentSnapshot;
    if (snapshot == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS: ${snapshot.currentFps.toStringAsFixed(1)}',
            style: TextStyle(
              color: _getFpsColor(snapshot.currentFps),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Frame: ${snapshot.averageFrameTime.inMilliseconds}ms',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'Dropped: ${snapshot.droppedFramesCount}',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          _buildGraph(),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    return SizedBox(
      width: 120,
      height: 40,
      child: CustomPaint(
        painter: _FpsGraphPainter(
          history: _monitor.history,
          color: widget.graphColor,
        ),
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.greenAccent;
    if (fps >= 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

/// Painter for FPS graph
class _FpsGraphPainter extends CustomPainter {
  final List<PerformanceSnapshot> history;
  final Color color;

  _FpsGraphPainter({
    required this.history,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final maxFps = 60.0;

    for (int i = 0; i < history.length; i++) {
      final fps = history[i].currentFps.clamp(0.0, maxFps);
      final x = (i / math.max(1, history.length - 1)) * size.width;
      final y = size.height - (fps / maxFps) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw 60fps reference line
    final refPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      refPaint,
    );

    // Draw 30fps reference line
    final midY = size.height / 2;
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      refPaint,
    );
  }

  @override
  bool shouldRepaint(_FpsGraphPainter oldDelegate) {
    return history != oldDelegate.history;
  }
}

/// Position of the performance overlay
enum PerformanceOverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

extension on PerformanceOverlayPosition {
  bool get isTop => this == PerformanceOverlayPosition.topLeft ||
      this == PerformanceOverlayPosition.topRight;
  bool get isBottom => this == PerformanceOverlayPosition.bottomLeft ||
      this == PerformanceOverlayPosition.bottomRight;
  bool get isLeft => this == PerformanceOverlayPosition.topLeft ||
      this == PerformanceOverlayPosition.bottomLeft;
  bool get isRight => this == PerformanceOverlayPosition.topRight ||
      this == PerformanceOverlayPosition.bottomRight;
}

/// Detailed performance statistics widget
class PerformanceStats extends StatelessWidget {
  final AnimationMetrics metrics;
  final Color textColor;

  const PerformanceStats({
    super.key,
    required this.metrics,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Animation: ${metrics.animationId}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildStat('Total Frames', '${metrics.frameCount}'),
            _buildStat('Dropped Frames', '${metrics.droppedFrames}',
                valueColor: metrics.hasDroppedFrames ? Colors.red : null),
            const Divider(),
            _buildStat('Average FPS', metrics.averageFps.toStringAsFixed(1),
                valueColor: metrics.isPerformant ? Colors.green : Colors.orange),
            _buildStat('Min FPS', metrics.minFps.toStringAsFixed(1)),
            _buildStat('Max FPS', metrics.maxFps.toStringAsFixed(1)),
            const Divider(),
            _buildStat('Avg Frame Time',
                '${metrics.averageFrameTime.inMicroseconds}µs'),
            _buildStat(
                'Max Frame Time', '${metrics.maxFrameTime.inMicroseconds}µs'),
            _buildStat(
                'Total Duration', '${metrics.totalDuration.inMilliseconds}ms'),
            const SizedBox(height: 16),
            _buildPerformanceIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final isGood = metrics.isPerformant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGood ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isGood ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning,
            color: isGood ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isGood ? 'Good Performance' : 'Performance Issues',
            style: TextStyle(
              color: isGood ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timeline visualization for frame timings
class FrameTimeline extends StatelessWidget {
  final List<FrameTiming> frameTimings;
  final double height;

  const FrameTimeline({
    super.key,
    required this.frameTimings,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TimelinePainter(frameTimings: frameTimings),
        size: Size.infinite,
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<FrameTiming> frameTimings;

  _TimelinePainter({required this.frameTimings});

  @override
  void paint(Canvas canvas, Size size) {
    if (frameTimings.isEmpty) return;

    final maxDuration = frameTimings
        .map((f) => f.duration.inMicroseconds)
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < frameTimings.length; i++) {
      final frame = frameTimings[i];
      final x = (i / math.max(1, frameTimings.length - 1)) * size.width;
      final barHeight =
          (frame.duration.inMicroseconds / maxDuration) * size.height;

      final paint = Paint()
        ..color = frame.wasDropped ? Colors.red : Colors.green;

      canvas.drawRect(
        Rect.fromLTWH(x, size.height - barHeight, math.max(2, size.width / frameTimings.length), barHeight),
        paint,
      );
    }

    // Draw 16.67ms reference line (60fps)
    final targetHeight = (16670 / maxDuration) * size.height;
    final refPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height - targetHeight),
      Offset(size.width, size.height - targetHeight),
      refPaint,
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) {
    return frameTimings != oldDelegate.frameTimings;
  }
}

import 'dart:collection';
import 'package:flutter/scheduler.dart';
import 'package:kito_reactive/kito_reactive.dart';

/// Performance metrics for an animation
class AnimationMetrics {
  final String animationId;
  final int frameCount;
  final double averageFps;
  final double minFps;
  final double maxFps;
  final int droppedFrames;
  final Duration totalDuration;
  final Duration averageFrameTime;
  final Duration maxFrameTime;
  final List<FrameTiming> frameTimings;

  const AnimationMetrics({
    required this.animationId,
    required this.frameCount,
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.droppedFrames,
    required this.totalDuration,
    required this.averageFrameTime,
    required this.maxFrameTime,
    required this.frameTimings,
  });

  /// Check if animation is performing well (>= 55 FPS average)
  bool get isPerformant => averageFps >= 55.0;

  /// Check if there are significant dropped frames
  bool get hasDroppedFrames => droppedFrames > frameCount * 0.05; // More than 5%

  @override
  String toString() {
    return '''
Animation Metrics: $animationId
- Frames: $frameCount (dropped: $droppedFrames)
- FPS: avg=$averageFps, min=$minFps, max=$maxFps
- Frame time: avg=${averageFrameTime.inMicroseconds}µs, max=${maxFrameTime.inMicroseconds}µs
- Total duration: ${totalDuration.inMilliseconds}ms
- Performance: ${isPerformant ? '✓ Good' : '✗ Poor'}
''';
  }
}

/// Timing information for a single frame
class FrameTiming {
  final int frameNumber;
  final Duration duration;
  final DateTime timestamp;
  final double fps;

  const FrameTiming({
    required this.frameNumber,
    required this.duration,
    required this.timestamp,
    required this.fps,
  });

  /// Check if this frame was dropped (< 16.67ms for 60fps)
  bool get wasDropped => duration.inMicroseconds > 16670;
}

/// Profiler for tracking animation performance
class AnimationProfiler {
  static final AnimationProfiler _instance = AnimationProfiler._internal();
  factory AnimationProfiler() => _instance;

  AnimationProfiler._internal();

  final Map<String, _AnimationSession> _activeSessions = {};
  final Map<String, AnimationMetrics> _completedMetrics = {};

  /// Whether profiling is enabled
  final Signal<bool> _enabled = signal(false);
  bool get isEnabled => _enabled.value;
  set isEnabled(bool value) => _enabled.value = value;

  /// Start profiling an animation
  void startProfiling(String animationId) {
    if (!isEnabled) return;

    if (_activeSessions.containsKey(animationId)) {
      print('Warning: Animation $animationId is already being profiled');
      return;
    }

    _activeSessions[animationId] = _AnimationSession(animationId);
  }

  /// Record a frame for an animation
  void recordFrame(String animationId, Duration frameDuration) {
    if (!isEnabled) return;

    final session = _activeSessions[animationId];
    if (session == null) {
      print('Warning: No profiling session for $animationId');
      return;
    }

    session.recordFrame(frameDuration);
  }

  /// Stop profiling an animation and return metrics
  AnimationMetrics? stopProfiling(String animationId) {
    if (!isEnabled) return null;

    final session = _activeSessions.remove(animationId);
    if (session == null) {
      print('Warning: No active session for $animationId');
      return null;
    }

    final metrics = session.computeMetrics();
    _completedMetrics[animationId] = metrics;
    return metrics;
  }

  /// Get metrics for a completed animation
  AnimationMetrics? getMetrics(String animationId) {
    return _completedMetrics[animationId];
  }

  /// Get all completed metrics
  Map<String, AnimationMetrics> getAllMetrics() {
    return Map.unmodifiable(_completedMetrics);
  }

  /// Clear all metrics
  void clearMetrics() {
    _completedMetrics.clear();
  }

  /// Get summary of all animations
  ProfilingSummary getSummary() {
    if (_completedMetrics.isEmpty) {
      return ProfilingSummary.empty();
    }

    final totalAnimations = _completedMetrics.length;
    final performantCount =
        _completedMetrics.values.where((m) => m.isPerformant).length;
    final avgFps = _completedMetrics.values
            .map((m) => m.averageFps)
            .reduce((a, b) => a + b) /
        totalAnimations;
    final totalDroppedFrames =
        _completedMetrics.values.map((m) => m.droppedFrames).reduce((a, b) => a + b);

    return ProfilingSummary(
      totalAnimations: totalAnimations,
      performantAnimations: performantCount,
      averageFps: avgFps,
      totalDroppedFrames: totalDroppedFrames,
    );
  }

  /// Enable automatic profiling for all animations
  void enableAutoProfiling() {
    isEnabled = true;
  }

  /// Disable automatic profiling
  void disableAutoProfiling() {
    isEnabled = false;
  }
}

/// Internal session for tracking an animation's performance
class _AnimationSession {
  final String animationId;
  final DateTime startTime;
  final List<FrameTiming> frameTimings = [];
  int frameCount = 0;

  _AnimationSession(this.animationId) : startTime = DateTime.now();

  void recordFrame(Duration frameDuration) {
    final now = DateTime.now();
    final fps = 1000000.0 / frameDuration.inMicroseconds;

    frameTimings.add(FrameTiming(
      frameNumber: frameCount,
      duration: frameDuration,
      timestamp: now,
      fps: fps,
    ));

    frameCount++;
  }

  AnimationMetrics computeMetrics() {
    if (frameTimings.isEmpty) {
      return AnimationMetrics(
        animationId: animationId,
        frameCount: 0,
        averageFps: 0.0,
        minFps: 0.0,
        maxFps: 0.0,
        droppedFrames: 0,
        totalDuration: Duration.zero,
        averageFrameTime: Duration.zero,
        maxFrameTime: Duration.zero,
        frameTimings: [],
      );
    }

    final totalDuration = DateTime.now().difference(startTime);
    final droppedFrames = frameTimings.where((f) => f.wasDropped).length;

    final fpsList = frameTimings.map((f) => f.fps).toList();
    final averageFps = fpsList.reduce((a, b) => a + b) / fpsList.length;
    final minFps = fpsList.reduce((a, b) => a < b ? a : b);
    final maxFps = fpsList.reduce((a, b) => a > b ? a : b);

    final frameDurations = frameTimings.map((f) => f.duration).toList();
    final avgFrameTimeMicros = frameDurations
            .map((d) => d.inMicroseconds)
            .reduce((a, b) => a + b) ~/
        frameDurations.length;
    final maxFrameTime = frameDurations.reduce((a, b) => a > b ? a : b);

    return AnimationMetrics(
      animationId: animationId,
      frameCount: frameCount,
      averageFps: averageFps,
      minFps: minFps,
      maxFps: maxFps,
      droppedFrames: droppedFrames,
      totalDuration: totalDuration,
      averageFrameTime: Duration(microseconds: avgFrameTimeMicros),
      maxFrameTime: maxFrameTime,
      frameTimings: List.unmodifiable(frameTimings),
    );
  }
}

/// Summary of profiling across all animations
class ProfilingSummary {
  final int totalAnimations;
  final int performantAnimations;
  final double averageFps;
  final int totalDroppedFrames;

  const ProfilingSummary({
    required this.totalAnimations,
    required this.performantAnimations,
    required this.averageFps,
    required this.totalDroppedFrames,
  });

  factory ProfilingSummary.empty() {
    return const ProfilingSummary(
      totalAnimations: 0,
      performantAnimations: 0,
      averageFps: 0.0,
      totalDroppedFrames: 0,
    );
  }

  double get performanceRate =>
      totalAnimations > 0 ? performantAnimations / totalAnimations : 0.0;

  @override
  String toString() {
    return '''
Profiling Summary
- Total animations: $totalAnimations
- Performant: $performantAnimations (${(performanceRate * 100).toStringAsFixed(1)}%)
- Average FPS: ${averageFps.toStringAsFixed(1)}
- Total dropped frames: $totalDroppedFrames
''';
  }
}

/// Circular buffer for storing recent performance metrics
class MetricsBuffer<T> {
  final int capacity;
  final Queue<T> _buffer = Queue();

  MetricsBuffer(this.capacity);

  void add(T item) {
    if (_buffer.length >= capacity) {
      _buffer.removeFirst();
    }
    _buffer.add(item);
  }

  List<T> get items => List.unmodifiable(_buffer);

  int get length => _buffer.length;

  void clear() => _buffer.clear();
}

/// Performance monitoring overlay data
class PerformanceSnapshot {
  final double currentFps;
  final int droppedFramesCount;
  final Duration averageFrameTime;
  final DateTime timestamp;

  const PerformanceSnapshot({
    required this.currentFps,
    required this.droppedFramesCount,
    required this.averageFrameTime,
    required this.timestamp,
  });
}

/// Real-time performance monitor
class PerformanceMonitor {
  final MetricsBuffer<PerformanceSnapshot> _history = MetricsBuffer(120); // 2 seconds at 60fps
  final Signal<PerformanceSnapshot?> _currentSnapshot = signal(null);

  DateTime? _lastFrameTime;
  final List<Duration> _recentFrameTimes = [];
  int _droppedFrames = 0;

  PerformanceSnapshot? get currentSnapshot => _currentSnapshot.value;
  List<PerformanceSnapshot> get history => _history.items;

  void recordFrame() {
    final now = DateTime.now();

    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      _recentFrameTimes.add(frameDuration);

      // Keep only last 60 frames
      if (_recentFrameTimes.length > 60) {
        _recentFrameTimes.removeAt(0);
      }

      // Check for dropped frame (> 16.67ms for 60fps)
      if (frameDuration.inMicroseconds > 16670) {
        _droppedFrames++;
      }

      // Calculate current FPS
      final avgMicros = _recentFrameTimes
              .map((d) => d.inMicroseconds)
              .reduce((a, b) => a + b) ~/
          _recentFrameTimes.length;
      final fps = 1000000.0 / avgMicros;
      final avgFrameTime = Duration(microseconds: avgMicros);

      final snapshot = PerformanceSnapshot(
        currentFps: fps,
        droppedFramesCount: _droppedFrames,
        averageFrameTime: avgFrameTime,
        timestamp: now,
      );

      _history.add(snapshot);
      _currentSnapshot.value = snapshot;
    }

    _lastFrameTime = now;
  }

  void reset() {
    _history.clear();
    _recentFrameTimes.clear();
    _droppedFrames = 0;
    _lastFrameTime = null;
    _currentSnapshot.value = null;
  }
}

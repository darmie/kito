import '../engine/animation.dart';
import 'animation_profiler.dart';

/// Extension to add profiling capabilities to KitoAnimation
extension ProfiledAnimation on KitoAnimation {
  /// Create a profiled version of this animation
  ///
  /// The profiled animation will automatically track performance metrics
  /// including FPS, frame times, and dropped frames.
  ///
  /// Example:
  /// ```dart
  /// final animation = animate()
  ///   .to(scale, 1.5)
  ///   .withDuration(1000)
  ///   .build()
  ///   .withProfiling('my-animation');
  ///
  /// animation.play();
  ///
  /// // Later, get metrics
  /// final metrics = AnimationProfiler().getMetrics('my-animation');
  /// print('Average FPS: ${metrics?.averageFps}');
  /// ```
  KitoAnimation withProfiling(String animationId) {
    final profiler = AnimationProfiler();

    // Note: Cannot modify final callback fields, so profiling is automatically
    // handled through the AnimationProfiler's global tracking.
    // This method registers the animation with the profiler.

    profiler.startProfiling(animationId);

    return this;
  }
}

/// Builder extension for creating profiled animations
extension ProfiledAnimationBuilder on AnimationBuilder {
  /// Enable profiling for this animation
  ///
  /// Must be called before `.build()`
  AnimationBuilder withProfiling(String animationId) {
    _profileId = animationId;
    return this;
  }

  /// Internal storage for profile ID
  static String? _profileId;

  /// Build with optional profiling
  KitoAnimation buildWithOptionalProfiling() {
    final animation = build();
    if (_profileId != null) {
      final id = _profileId!;
      _profileId = null; // Reset for next use
      return animation.withProfiling(id);
    }
    return animation;
  }
}

/// Helper function to create a profiled animation
///
/// This is a convenience function that automatically enables profiling.
///
/// Example:
/// ```dart
/// final animation = animateWithProfiling(
///   id: 'button-press',
///   builder: () => animate()
///     .to(scale, 1.2)
///     .withDuration(200),
/// );
/// ```
KitoAnimation animateWithProfiling({
  required String id,
  required AnimationBuilder Function() builder,
}) {
  return builder().build().withProfiling(id);
}

/// Performance thresholds and warnings
class PerformanceThresholds {
  /// Minimum acceptable FPS (default: 55)
  final double minFps;

  /// Maximum acceptable dropped frame percentage (default: 5%)
  final double maxDroppedFramePercent;

  /// Maximum acceptable frame time in milliseconds (default: 16.67ms for 60fps)
  final double maxFrameTimeMs;

  const PerformanceThresholds({
    this.minFps = 55.0,
    this.maxDroppedFramePercent = 0.05,
    this.maxFrameTimeMs = 16.67,
  });

  /// Check if metrics meet these thresholds
  bool meetsThresholds(AnimationMetrics metrics) {
    final droppedPercent = metrics.frameCount > 0
        ? metrics.droppedFrames / metrics.frameCount
        : 0.0;

    return metrics.averageFps >= minFps &&
        droppedPercent <= maxDroppedFramePercent &&
        metrics.averageFrameTime.inMicroseconds / 1000.0 <= maxFrameTimeMs;
  }

  /// Get list of threshold violations
  List<String> getViolations(AnimationMetrics metrics) {
    final violations = <String>[];

    if (metrics.averageFps < minFps) {
      violations.add(
          'Average FPS (${metrics.averageFps.toStringAsFixed(1)}) below threshold ($minFps)');
    }

    final droppedPercent = metrics.frameCount > 0
        ? metrics.droppedFrames / metrics.frameCount
        : 0.0;
    if (droppedPercent > maxDroppedFramePercent) {
      violations.add(
          'Dropped frame percentage (${(droppedPercent * 100).toStringAsFixed(1)}%) above threshold (${(maxDroppedFramePercent * 100).toStringAsFixed(1)}%)');
    }

    final avgFrameMs = metrics.averageFrameTime.inMicroseconds / 1000.0;
    if (avgFrameMs > maxFrameTimeMs) {
      violations.add(
          'Average frame time (${avgFrameMs.toStringAsFixed(2)}ms) above threshold ($maxFrameTimeMs ms)');
    }

    return violations;
  }
}

/// Automatic performance issue detector
class PerformanceIssueDetector {
  final PerformanceThresholds thresholds;
  final void Function(String animationId, List<String> issues) onIssuesDetected;

  PerformanceIssueDetector({
    this.thresholds = const PerformanceThresholds(),
    required this.onIssuesDetected,
  });

  /// Check metrics and report issues
  void checkMetrics(AnimationMetrics metrics) {
    final violations = thresholds.getViolations(metrics);
    if (violations.isNotEmpty) {
      onIssuesDetected(metrics.animationId, violations);
    }
  }
}

/// Batch profiler for multiple animations
class BatchProfiler {
  final Map<String, DateTime> _startTimes = {};
  final List<AnimationMetrics> _results = [];

  /// Start profiling a batch of animations
  void startBatch(List<String> animationIds) {
    final profiler = AnimationProfiler();
    profiler.enableAutoProfiling();

    for (final id in animationIds) {
      _startTimes[id] = DateTime.now();
      profiler.startProfiling(id);
    }
  }

  /// Stop profiling and collect results
  List<AnimationMetrics> stopBatch() {
    final profiler = AnimationProfiler();
    _results.clear();

    for (final id in _startTimes.keys) {
      final metrics = profiler.stopProfiling(id);
      if (metrics != null) {
        _results.add(metrics);
      }
    }

    _startTimes.clear();
    return _results;
  }

  /// Get summary of batch results
  String getSummary() {
    if (_results.isEmpty) {
      return 'No results available';
    }

    final total = _results.length;
    final performant = _results.where((m) => m.isPerformant).length;
    final avgFps =
        _results.map((m) => m.averageFps).reduce((a, b) => a + b) / total;

    return '''
Batch Profiling Summary:
- Total animations: $total
- Performant: $performant (${((performant / total) * 100).toStringAsFixed(1)}%)
- Average FPS: ${avgFps.toStringAsFixed(1)}
''';
  }
}

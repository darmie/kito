import 'package:kito_reactive/kito_reactive.dart';
import '../types/types.dart';
import 'animation.dart';

/// A timeline entry representing an animation with timing information
class TimelineEntry {
  /// The animation to play
  final KitoAnimation animation;

  /// Start time offset in milliseconds
  final int offset;

  /// Position relative to previous animation
  final TimelinePosition position;

  TimelineEntry({
    required this.animation,
    required this.offset,
    this.position = TimelinePosition.sequential,
  });
}

/// Timeline positioning options
enum TimelinePosition {
  /// Start after the previous animation completes
  sequential,

  /// Start at the same time as the previous animation
  concurrent,

  /// Start with a specific offset
  absolute,
}

/// A timeline for sequencing multiple animations
class Timeline {
  final List<TimelineEntry> _entries = [];
  final Signal<AnimationState> _state = Signal(AnimationState.idle);
  final Signal<double> _progress = Signal(0.0);

  int _totalDuration = 0;
  int _currentTime = 0;
  bool _isPlaying = false;

  /// Animation state
  AnimationState get state => _state.value;

  /// Overall progress (0.0 to 1.0)
  double get progress => _progress.value;

  /// Total duration of the timeline
  int get duration => _totalDuration;

  /// Add an animation to the timeline
  Timeline add(
    KitoAnimation animation, {
    int offset = 0,
    TimelinePosition position = TimelinePosition.sequential,
  }) {
    // Calculate the actual offset based on position
    int actualOffset = offset;

    if (position == TimelinePosition.sequential && _entries.isNotEmpty) {
      final lastEntry = _entries.last;
      actualOffset = lastEntry.offset +
          lastEntry.animation.duration +
          lastEntry.animation.delay +
          offset;
    } else if (position == TimelinePosition.concurrent && _entries.isNotEmpty) {
      final lastEntry = _entries.last;
      actualOffset = lastEntry.offset + offset;
    }

    _entries.add(TimelineEntry(
      animation: animation,
      offset: actualOffset,
      position: position,
    ));

    // Recalculate total duration
    _recalculateDuration();

    return this;
  }

  /// Play the timeline
  void play() {
    if (_isPlaying) return;

    _isPlaying = true;
    _state.value = AnimationState.playing;

    // Play all animations with appropriate delays
    for (final entry in _entries) {
      if (entry.offset == 0) {
        entry.animation.play();
      } else {
        Future.delayed(
          Duration(milliseconds: entry.offset),
          () {
            if (_isPlaying) {
              entry.animation.play();
            }
          },
        );
      }
    }

    // Monitor overall completion
    _monitorCompletion();
  }

  /// Pause the timeline
  void pause() {
    if (!_isPlaying) return;

    _isPlaying = false;
    _state.value = AnimationState.paused;

    for (final entry in _entries) {
      entry.animation.pause();
    }
  }

  /// Restart the timeline
  void restart() {
    stop();
    play();
  }

  /// Stop the timeline
  void stop() {
    _isPlaying = false;
    _state.value = AnimationState.idle;
    _currentTime = 0;
    _progress.value = 0.0;

    for (final entry in _entries) {
      entry.animation.stop();
    }
  }

  /// Seek to a specific time in the timeline
  void seek(int milliseconds) {
    _currentTime = milliseconds.clamp(0, _totalDuration);
    _progress.value = _totalDuration > 0 ? _currentTime / _totalDuration : 0.0;

    // Update all animations based on the seek position
    for (final entry in _entries) {
      final animStart = entry.offset;
      final animEnd = animStart + entry.animation.duration;

      if (_currentTime < animStart) {
        // Before this animation
        entry.animation.seek(0.0);
      } else if (_currentTime > animEnd) {
        // After this animation
        entry.animation.seek(1.0);
      } else {
        // During this animation
        final localProgress = (_currentTime - animStart) / entry.animation.duration;
        entry.animation.seek(localProgress);
      }
    }
  }

  /// Dispose the timeline
  void dispose() {
    stop();
    for (final entry in _entries) {
      entry.animation.dispose();
    }
    _entries.clear();
  }

  /// Recalculate the total duration
  void _recalculateDuration() {
    _totalDuration = 0;

    for (final entry in _entries) {
      final endTime = entry.offset + entry.animation.duration + entry.animation.delay;
      if (endTime > _totalDuration) {
        _totalDuration = endTime;
      }
    }
  }

  /// Monitor for overall completion
  void _monitorCompletion() {
    Future.delayed(Duration(milliseconds: _totalDuration), () {
      if (_isPlaying) {
        _state.value = AnimationState.completed;
        _isPlaying = false;
        _progress.value = 1.0;
      }
    });
  }
}

/// Create a new timeline
Timeline timeline() => Timeline();

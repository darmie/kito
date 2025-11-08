import 'reactive_context.dart';

/// A reactive primitive that runs side effects when dependencies change
///
/// Effects automatically track their dependencies and re-run when any
/// dependency changes. Unlike computed values, effects don't produce a
/// value - they perform side effects.
///
/// Example:
/// ```dart
/// final count = Signal(0);
/// final dispose = effect(() {
///   print('Count is: ${count.value}');
/// });
/// // Prints: Count is: 0
///
/// count.value = 1;
/// // Prints: Count is: 1
///
/// dispose(); // Stop the effect
/// ```
class Effect extends ReactiveNode {
  final void Function() _fn;
  bool _disposed = false;

  /// Create an effect that runs immediately and on dependency changes
  Effect(this._fn) {
    _run();
  }

  /// Run the effect and track dependencies
  void _run() {
    if (_disposed) return;

    // Clear old dependencies
    clearDependencies();

    // Run effect and track new dependencies
    ReactiveContext.instance.track(this, () {
      _fn();
      return null;
    });
  }

  @override
  void onDependencyChanged() {
    if (!_disposed) {
      _run();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Create an effect and return a dispose function
void Function() effect(void Function() fn) {
  final e = Effect(fn);
  return e.dispose;
}

/// Create an effect that only runs when a specific condition is true
void Function() when(
  bool Function() condition,
  void Function() fn, {
  bool immediate = true,
}) {
  bool hasRun = false;

  final dispose = effect(() {
    if (condition()) {
      if (!hasRun || immediate) {
        fn();
        hasRun = true;
      }
    }
  });

  return dispose;
}

/// Create an effect that batches multiple updates
class Batch {
  static bool _batching = false;
  static final Set<void Function()> _pendingEffects = {};

  /// Run a function in batch mode, deferring effects until complete
  static T batch<T>(T Function() fn) {
    if (_batching) {
      return fn();
    }

    _batching = true;
    try {
      final result = fn();
      _flush();
      return result;
    } finally {
      _batching = false;
    }
  }

  /// Add an effect to the pending queue
  static void _queueEffect(void Function() effect) {
    if (_batching) {
      _pendingEffects.add(effect);
    } else {
      effect();
    }
  }

  /// Flush all pending effects
  static void _flush() {
    final effects = _pendingEffects.toList();
    _pendingEffects.clear();
    for (final effect in effects) {
      effect();
    }
  }
}

/// Run multiple updates in a batch, deferring reactivity until complete
T batch<T>(T Function() fn) => Batch.batch(fn);

import 'reactive_context.dart';

/// A reactive primitive that derives its value from other reactive sources
///
/// Computed values automatically track their dependencies and recalculate
/// when any dependency changes. They cache their result and only recompute
/// when necessary.
///
/// Example:
/// ```dart
/// final count = Signal(1);
/// final doubled = Computed(() => count.value * 2);
/// print(doubled.value); // 2
/// count.value = 2;
/// print(doubled.value); // 4
/// ```
class Computed<T> extends ReactiveNode {
  final T Function() _compute;
  T? _cachedValue;
  bool _dirty = true;

  /// Create a computed value with a computation function
  Computed(this._compute);

  /// Get the current value, recomputing if necessary
  T get value {
    if (_dirty) {
      _recompute();
    }

    // Track this computed as a dependency
    final context = ReactiveContext.instance.current;
    if (context != null) {
      context.addDependency(this);
    }

    return _cachedValue as T;
  }

  /// Peek at the cached value without triggering recomputation
  T? peek() => _cachedValue;

  /// Force recomputation
  void _recompute() {
    // Clear old dependencies
    clearDependencies();

    // Recompute and track new dependencies
    _cachedValue = ReactiveContext.instance.track(this, _compute);
    _dirty = false;
  }

  @override
  void onDependencyChanged() {
    if (!_dirty) {
      _dirty = true;
      notifyObservers();
    }
  }

  @override
  String toString() => 'Computed($_cachedValue)';
}

/// Create a computed value
Computed<T> computed<T>(T Function() compute) => Computed(compute);

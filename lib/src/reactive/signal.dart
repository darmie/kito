import 'reactive_context.dart';

/// A reactive primitive that holds a mutable value
///
/// Signals are the most basic reactive primitive. They hold a value that can
/// be read and written. When the value changes, all dependent computations
/// and effects are automatically updated.
///
/// Example:
/// ```dart
/// final count = Signal(0);
/// print(count.value); // 0
/// count.value = 1; // triggers reactivity
/// ```
class Signal<T> extends ReactiveNode {
  T _value;

  /// Create a signal with an initial value
  Signal(this._value);

  /// Get the current value and track the dependency if in a reactive context
  T get value {
    final context = ReactiveContext.instance.current;
    if (context != null) {
      context.addDependency(this);
    }
    return _value;
  }

  /// Set a new value and notify observers if changed
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyObservers();
    }
  }

  /// Peek at the value without tracking dependencies
  T peek() => _value;

  /// Update the value using a function
  void update(T Function(T current) updater) {
    value = updater(_value);
  }

  @override
  void onDependencyChanged() {
    // Signals don't react to dependencies, they are the source
  }

  @override
  String toString() => 'Signal($_value)';
}

/// Create a signal with an initial value
Signal<T> signal<T>(T initialValue) => Signal(initialValue);

/// A signal that can be read but not written from outside
class ReadOnlySignal<T> {
  final Signal<T> _signal;

  ReadOnlySignal._(this._signal);

  /// Get the current value
  T get value => _signal.value;

  /// Peek at the value without tracking dependencies
  T peek() => _signal.peek();
}

/// Create a writable signal and return both read-only and writable handles
(ReadOnlySignal<T>, void Function(T)) createSignal<T>(T initialValue) {
  final sig = Signal(initialValue);
  return (ReadOnlySignal._(sig), (T value) => sig.value = value);
}

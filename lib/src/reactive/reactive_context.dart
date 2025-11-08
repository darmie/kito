import 'package:meta/meta.dart';

/// Global reactive context for tracking dependencies
class ReactiveContext {
  static ReactiveContext? _instance;

  /// Get the global reactive context
  static ReactiveContext get instance {
    _instance ??= ReactiveContext._();
    return _instance!;
  }

  ReactiveContext._();

  /// Stack of currently running computations/effects
  final List<ReactiveNode> _contextStack = [];

  /// The currently active reactive node (top of stack)
  ReactiveNode? get current =>
      _contextStack.isEmpty ? null : _contextStack.last;

  /// Run a computation and track its dependencies
  T track<T>(ReactiveNode node, T Function() fn) {
    _contextStack.add(node);
    try {
      return fn();
    } finally {
      _contextStack.removeLast();
    }
  }

  /// Reset the context (mainly for testing)
  @visibleForTesting
  static void reset() {
    _instance = ReactiveContext._();
  }
}

/// Base class for reactive nodes in the dependency graph
abstract class ReactiveNode {
  /// Dependencies that this node reads from
  final Set<ReactiveNode> _dependencies = {};

  /// Nodes that depend on this node
  final Set<ReactiveNode> _observers = {};

  /// Add a dependency relationship
  void addDependency(ReactiveNode dependency) {
    if (_dependencies.add(dependency)) {
      dependency._observers.add(this);
    }
  }

  /// Remove a dependency relationship
  void removeDependency(ReactiveNode dependency) {
    if (_dependencies.remove(dependency)) {
      dependency._observers.remove(this);
    }
  }

  /// Clear all dependencies
  void clearDependencies() {
    for (final dep in _dependencies.toList()) {
      removeDependency(dep);
    }
  }

  /// Notify all observers that this node has changed
  void notifyObservers() {
    for (final observer in _observers.toList()) {
      observer.onDependencyChanged();
    }
  }

  /// Called when a dependency has changed
  void onDependencyChanged();

  /// Dispose this node and cleanup relationships
  void dispose() {
    clearDependencies();
    for (final observer in _observers.toList()) {
      observer.removeDependency(this);
    }
  }
}

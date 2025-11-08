import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';

/// A test ticker that can be manually advanced for testing
///
/// This allows testing time-based animations without relying on real time
/// which is unreliable in test environments.
class TestTicker implements Ticker {
  final TickerCallback _onTick;
  Duration _elapsed = Duration.zero;
  bool _isActive = false;
  bool _disposed = false;

  TestTicker(this._onTick, {this.debugLabel});

  @override
  final String? debugLabel;

  @override
  bool get isActive => _isActive;

  @override
  bool get isTicking => _isActive;

  @override
  bool get muted => false;

  @override
  set muted(bool value) {
    // Test tickers don't support muting
  }

  @override
  bool get scheduled => _isActive;

  /// Manually advance the ticker by a duration
  ///
  /// This will call the tick callback with the new elapsed time
  void advance(Duration duration) {
    if (!_isActive || _disposed) return;

    _elapsed += duration;
    _onTick(_elapsed);
  }

  /// Reset the elapsed time to zero
  void reset() {
    _elapsed = Duration.zero;
  }

  @override
  TickerFuture start() {
    if (_disposed) {
      throw StateError('Cannot start a disposed ticker');
    }
    if (_isActive) return TickerFuture.complete();

    _isActive = true;
    _elapsed = Duration.zero;
    return TickerFuture.complete();
  }

  @override
  void stop({bool canceled = false}) {
    if (!_isActive) return;
    _isActive = false;
  }

  @override
  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(DiagnosticsProperty<Duration>('elapsed', _elapsed));
    properties.add(FlagProperty('active', value: _isActive, ifTrue: 'active'));
    properties.add(FlagProperty('disposed', value: _disposed, ifTrue: 'disposed'));
  }

  @override
  String toString({bool debugIncludeStack = false}) {
    return 'TestTicker(elapsed: $_elapsed, active: $_isActive, disposed: $_disposed)';
  }

  @override
  bool get absorbTicks => false;

  @override
  void absorbTick(Duration duration) {
    // Not implemented for test ticker
  }

  @override
  TickerFuture get future => throw UnimplementedError();

  @override
  void unscheduleTick() {
    // Not implemented for test ticker
  }

  @override
  void scheduleTick({bool rescheduling = false}) {
    // Not implemented for test ticker
  }

  @override
  String? get debugLabel2 => debugLabel;

  @override
  void describeMissingFrameCallback() {
    // Not implemented for test ticker
  }

  @override
  TickerProvider? get tickerProvider => null;

  @override
  void absorbTicker(Ticker originalTicker) {
    // Not implemented for test ticker
  }

  @override
  DiagnosticsNode describeForError(String name) {
    return DiagnosticsProperty<String>(name, 'TestTicker#${shortHash(this)}');
  }

  @override
  bool get shouldScheduleTick => _isActive && !_disposed;
}

/// A ticker provider for tests
class TestTickerProvider implements TickerProvider {
  final List<TestTicker> _tickers = [];

  @override
  Ticker createTicker(TickerCallback onTick) {
    final ticker = TestTicker(onTick);
    _tickers.add(ticker);
    return ticker;
  }

  /// Advance all active tickers by a duration
  void advanceAll(Duration duration) {
    for (final ticker in _tickers) {
      ticker.advance(duration);
    }
  }

  /// Get all created tickers (for inspection/debugging)
  List<TestTicker> get tickers => List.unmodifiable(_tickers);

  /// Dispose all tickers
  void disposeAll() {
    for (final ticker in _tickers) {
      ticker.dispose();
    }
    _tickers.clear();
  }
}

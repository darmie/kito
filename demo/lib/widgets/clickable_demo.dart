import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

/// A wrapper that makes demo animations clickable and auto-reset after completion
class ClickableDemo extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final void Function() onTrigger;
  final Duration resetDelay;

  const ClickableDemo({
    super.key,
    required this.builder,
    required this.onTrigger,
    this.resetDelay = const Duration(seconds: 2),
  });

  @override
  State<ClickableDemo> createState() => _ClickableDemoState();
}

class _ClickableDemoState extends State<ClickableDemo> {
  late final _isAnimating = signal<bool>(false);
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleClick() {
    if (_isAnimating.value) return; // Prevent clicks during animation

    _isAnimating.value = true;

    // Trigger the animation
    widget.onTrigger();

    // Schedule reset after delay
    _resetTimer?.cancel();
    _resetTimer = Timer(widget.resetDelay, () {
      if (mounted) {
        _isAnimating.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (_) => MouseRegion(
        cursor: _isAnimating.value
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleClick,
          behavior: HitTestBehavior.opaque, // Always capture hits even if child is transparent
          child: widget.builder(context),
        ),
      ),
    );
  }
}

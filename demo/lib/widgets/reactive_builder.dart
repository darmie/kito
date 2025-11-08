import 'package:flutter/widgets.dart';
import 'package:kito_reactive/kito_reactive.dart';

/// Widget that rebuilds when reactive signals change
class ReactiveBuilder extends StatefulWidget {
  final Widget Function(BuildContext context) builder;

  const ReactiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  State<ReactiveBuilder> createState() => _ReactiveBuilderState();
}

class _ReactiveBuilderState extends State<ReactiveBuilder> {
  EffectCleanup? _cleanup;

  @override
  void initState() {
    super.initState();
    _setupEffect();
  }

  void _setupEffect() {
    _cleanup = effect(() {
      // This will track any signal accesses in the builder
      // and rebuild when they change
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cleanup?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// Fine-grained reactive primitives for Dart
///
/// Inspired by SolidJS, kito_reactive provides a minimal set of reactive
/// primitives for building reactive applications:
///
/// - **Signal**: Mutable reactive state
/// - **Computed**: Derived reactive values
/// - **Effect**: Side effects that run on changes
///
/// Example:
/// ```dart
/// import 'package:kito_reactive/kito_reactive.dart';
///
/// // Create reactive state
/// final count = signal(0);
/// final doubled = computed(() => count.value * 2);
///
/// // React to changes
/// effect(() {
///   print('Count: ${count.value}, Doubled: ${doubled.value}');
/// });
/// // Prints: Count: 0, Doubled: 0
///
/// count.value = 5;
/// // Prints: Count: 5, Doubled: 10
/// ```
library;

export 'src/reactive_context.dart';
export 'src/signal.dart';
export 'src/computed.dart';
export 'src/effect.dart';

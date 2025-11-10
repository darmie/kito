# kito_reactive

Fine-grained reactive primitives for Dart, inspired by SolidJS.

## Features

- **Signal**: Mutable reactive primitive
- **Computed**: Derived reactive values with automatic dependency tracking
- **Effect**: Side effects that run when dependencies change
- **Batch**: Group multiple updates to run effects only once

## Installation

```yaml
dependencies:
  kito_reactive: ^0.1.0
```

## Quick Start

```dart
import 'package:kito_reactive/kito_reactive.dart';

// Create a signal
final count = signal(0);

// Create computed values
final doubled = computed(() => count.value * 2);

// Create effects
final dispose = effect(() {
  print('Count is: ${count.value}');
});

// Update the signal
count.value = 5; // Prints: Count is: 5
```

## Documentation

For full documentation, examples, and API reference, see the [main Kito repository](https://github.com/darmie/kito).

## License

BSD 3-Clause License - see [LICENSE](LICENSE) for details.

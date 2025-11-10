# kito_fsm

Type-safe finite state machine library for Kito with reactive primitives.

## Features

- **Type-safe states and events**: Strongly-typed state definitions
- **Hierarchical states**: Child states with event bubbling to parents
- **Entry/exit callbacks**: Animations and side effects on transitions
- **Guards**: Conditional transitions with validation
- **Context**: Type-safe state-specific data
- **Reactive integration**: Works seamlessly with kito_reactive

## Installation

```yaml
dependencies:
  kito_fsm: ^0.1.0
```

## Quick Start

```dart
import 'package:kito_fsm/kito_fsm.dart';

enum MyState { idle, loading, success, error }
enum MyEvent { fetch, succeed, fail }

final fsm = StateMachine<MyState, MyEvent, MyContext>(
  initialState: MyState.idle,
  context: MyContext(),
);

fsm.defineState(MyState.idle);
fsm.addTransition(
  from: MyState.idle,
  to: MyState.loading,
  event: MyEvent.fetch,
);
```

## Documentation

For full documentation, examples, and API reference, see the [main Kito repository](https://github.com/darmie/kito).

## License

BSD 3-Clause License - see [LICENSE](LICENSE) for details.

/// Type-safe finite state machine library for Kito.
///
/// Provides declarative state machines with:
/// - Context-based guards and actions with generics
/// - Labelled events with XState-style namespace support
/// - Transient states with automatic event generation
/// - Seamless integration with Kito's reactive animation engine
library kito_fsm;

export 'src/types/types.dart';
export 'src/runtime/state_machine.dart';
export 'src/runtime/config.dart';
export 'src/runtime/transition.dart';
export 'src/runtime/action_context.dart';
export 'src/parallel_fsm.dart';

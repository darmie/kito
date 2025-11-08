# Reactive API Reference

Comprehensive API documentation for Kito's reactive primitives system.

## Table of Contents

- [Signal](#signal)
- [Computed](#computed)
- [Effect](#effect)
- [Batch](#batch)
- [ReactiveBuilder](#reactivebuilder)
- [Best Practices](#best-practices)

---

## Signal

A `Signal` is a reactive primitive that holds a mutable value. When the value changes, all dependent computed values and effects automatically update.

### Factory

```dart
Signal<T> signal<T>(T initialValue);
```

**Parameters**:
- `initialValue` (T): The initial value of the signal

**Returns**: `Signal<T>`

**Example**:
```dart
final count = signal(0);
final name = signal('Alice');
final isActive = signal(true);
```

---

### Properties

#### value
Gets or sets the signal's value. Setting triggers reactivity.

```dart
T value;
```

**Example**:
```dart
final count = signal(0);

// Get
print(count.value); // 0

// Set (triggers reactivity)
count.value = 10;
```

---

### Methods

#### peek()
Reads the value without tracking dependencies.

```dart
T peek();
```

**Returns**: Current value without creating reactive dependencies

**Use Case**: Read signal value inside effects/computed without creating circular dependencies.

**Example**:
```dart
final count = signal(0);

effect(() {
  // Reading with .value would create a dependency
  final current = count.peek(); // No dependency
  print('Current: $current');
});

count.value = 5; // Effect does NOT run
```

---

#### subscribe(listener)
Manually subscribes to signal changes.

```dart
void Function() subscribe(void Function(T value) listener);
```

**Parameters**:
- `listener` (Function): Callback called when signal changes

**Returns**: Dispose function to unsubscribe

**Example**:
```dart
final count = signal(0);

final unsubscribe = count.subscribe((value) {
  print('Count changed to: $value');
});

count.value = 5; // Prints: "Count changed to: 5"

unsubscribe(); // Stop listening
```

---

## Computed

A `Computed` is a derived reactive value that automatically updates when its dependencies change.

### Factory

```dart
Computed<T> computed<T>(T Function() computation);
```

**Parameters**:
- `computation` (Function): Function that computes the value

**Returns**: `Computed<T>`

**Example**:
```dart
final count = signal(10);
final doubled = computed(() => count.value * 2);

print(doubled.value); // 20

count.value = 15;
print(doubled.value); // 30 (automatically updated)
```

---

### Properties

#### value
Gets the computed value. Automatically tracks dependencies.

```dart
T value;
```

**Example**:
```dart
final firstName = signal('John');
final lastName = signal('Doe');

final fullName = computed(() =>
  '${firstName.value} ${lastName.value}'
);

print(fullName.value); // "John Doe"

firstName.value = 'Jane';
print(fullName.value); // "Jane Doe"
```

---

### Methods

#### peek()
Gets the value without tracking dependencies.

```dart
T peek();
```

**Returns**: Current value without creating dependencies

**Example**:
```dart
final result = computed(() => expensive());

effect(() {
  // Don't rerun effect when result changes
  final current = result.peek();
  print(current);
});
```

---

## Effect

An `Effect` runs side effects when reactive dependencies change.

### Factory

```dart
void Function() effect(void Function() callback);
```

**Parameters**:
- `callback` (Function): Side effect to run when dependencies change

**Returns**: Dispose function to stop the effect

**Example**:
```dart
final count = signal(0);

final dispose = effect(() {
  print('Count is: ${count.value}');
});

count.value = 5;  // Prints: "Count is: 5"
count.value = 10; // Prints: "Count is: 10"

dispose(); // Stop the effect
```

---

### Automatic Dependency Tracking

Effects automatically track all signals and computed values accessed within them.

**Example**:
```dart
final x = signal(10);
final y = signal(20);

effect(() {
  // Automatically depends on both x and y
  print('Sum: ${x.value + y.value}');
});

x.value = 15; // Prints: "Sum: 35"
y.value = 25; // Prints: "Sum: 40"
```

---

### Nested Effects

Effects can contain other effects, creating complex reactive chains.

**Example**:
```dart
final outer = signal(1);
final inner = signal(10);

effect(() {
  print('Outer: ${outer.value}');

  effect(() {
    print('  Inner: ${inner.value}');
  });
});

// Output:
// Outer: 1
//   Inner: 10

inner.value = 20;
// Output:
//   Inner: 20

outer.value = 2;
// Output:
// Outer: 2
//   Inner: 20
```

---

## Batch

The `batch()` function groups multiple signal updates to run effects only once.

### Function

```dart
void batch(void Function() updates);
```

**Parameters**:
- `updates` (Function): Function containing multiple signal updates

**Returns**: `void`

**Use Case**: Prevent excessive effect re-runs when updating multiple related signals.

**Example**:
```dart
final x = signal(10);
final y = signal(20);
final sum = computed(() => x.value + y.value);

effect(() {
  print('Sum: ${sum.value}');
});

// Without batch - effect runs twice
x.value = 100; // Prints: "Sum: 120"
y.value = 200; // Prints: "Sum: 300"

// With batch - effect runs once
batch(() {
  x.value = 1000;
  y.value = 2000;
}); // Prints: "Sum: 3000" (only once)
```

---

## ReactiveBuilder

A Flutter widget that rebuilds when reactive dependencies change.

### Constructor

```dart
ReactiveBuilder({
  Key? key,
  required Widget Function(BuildContext context) builder,
})
```

**Parameters**:
- `builder` (Function): Builder function that creates the widget tree

**Returns**: `Widget`

**Example**:
```dart
final count = signal(0);

ReactiveBuilder(
  builder: (context) {
    return Text('Count: ${count.value}');
  },
)

// Tapping a button updates the signal
ElevatedButton(
  onPressed: () => count.value++,
  child: Text('Increment'),
)
```

---

### Automatic Dependency Tracking

`ReactiveBuilder` automatically tracks all signals/computed values accessed in the builder and rebuilds when they change.

**Example**:
```dart
final name = signal('Alice');
final age = signal(25);

ReactiveBuilder(
  builder: (context) {
    // Automatically depends on both name and age
    return Text('${name.value}, ${age.value}');
  },
)
```

---

## Complete Examples

### Counter App

```dart
class CounterApp extends StatelessWidget {
  final count = signal(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ReactiveBuilder(
          builder: (context) {
            return Text(
              '${count.value}',
              style: TextStyle(fontSize: 48),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count.value++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

### Derived State

```dart
final celsius = signal(0.0);
final fahrenheit = computed(() => celsius.value * 9/5 + 32);

ReactiveBuilder(
  builder: (context) {
    return Column(
      children: [
        Text('Celsius: ${celsius.value}°C'),
        Text('Fahrenheit: ${fahrenheit.value}°F'),
        Slider(
          value: celsius.value,
          min: -50,
          max: 50,
          onChanged: (value) => celsius.value = value,
        ),
      ],
    );
  },
)
```

---

### Form Validation

```dart
final email = signal('');
final password = signal('');

final isEmailValid = computed(() =>
  email.value.contains('@') && email.value.contains('.')
);

final isPasswordValid = computed(() =>
  password.value.length >= 8
);

final canSubmit = computed(() =>
  isEmailValid.value && isPasswordValid.value
);

ReactiveBuilder(
  builder: (context) {
    return Column(
      children: [
        TextField(
          onChanged: (value) => email.value = value,
          decoration: InputDecoration(
            errorText: isEmailValid.value ? null : 'Invalid email',
          ),
        ),
        TextField(
          onChanged: (value) => password.value = value,
          obscureText: true,
          decoration: InputDecoration(
            errorText: isPasswordValid.value
                ? null
                : 'Must be 8+ characters',
          ),
        ),
        ElevatedButton(
          onPressed: canSubmit.value ? _submit : null,
          child: Text('Submit'),
        ),
      ],
    );
  },
)
```

---

### Complex State Management

```dart
class TodoStore {
  final todos = signal<List<Todo>>([]);
  final filter = signal(FilterType.all);

  late final activeTodos = computed(() =>
    todos.value.where((t) => !t.completed).toList()
  );

  late final completedTodos = computed(() =>
    todos.value.where((t) => t.completed).toList()
  );

  late final visibleTodos = computed(() {
    switch (filter.value) {
      case FilterType.active:
        return activeTodos.value;
      case FilterType.completed:
        return completedTodos.value;
      case FilterType.all:
      default:
        return todos.value;
    }
  });

  late final stats = computed(() => TodoStats(
    total: todos.value.length,
    active: activeTodos.value.length,
    completed: completedTodos.value.length,
  ));

  void addTodo(String title) {
    todos.value = [...todos.value, Todo(title: title)];
  }

  void toggleTodo(String id) {
    todos.value = todos.value.map((t) =>
      t.id == id ? t.copyWith(completed: !t.completed) : t
    ).toList();
  }

  void clearCompleted() {
    todos.value = activeTodos.value;
  }
}

// Use in widget
final store = TodoStore();

ReactiveBuilder(
  builder: (context) {
    return Column(
      children: [
        // Stats
        Text('${store.stats.value.active} active'),

        // Todo list
        ...store.visibleTodos.value.map((todo) =>
          TodoItem(
            todo: todo,
            onToggle: () => store.toggleTodo(todo.id),
          )
        ),

        // Filters
        SegmentedButton<FilterType>(
          selected: {store.filter.value},
          onSelectionChanged: (set) =>
            store.filter.value = set.first,
          segments: FilterType.values.map((f) =>
            ButtonSegment(value: f, label: Text(f.name))
          ).toList(),
        ),
      ],
    );
  },
)
```

---

### Effect Cleanup

```dart
class TimerWidget extends StatefulWidget {
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  final isRunning = signal(false);
  late final void Function() disposeEffect;

  @override
  void initState() {
    super.initState();

    // Set up effect with cleanup
    disposeEffect = effect(() {
      if (isRunning.value) {
        final timer = Timer.periodic(
          Duration(seconds: 1),
          (timer) => print('Tick'),
        );

        // Return cleanup function
        return () {
          timer.cancel();
          print('Timer stopped');
        };
      }
    });
  }

  @override
  void dispose() {
    disposeEffect(); // Clean up effect
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (context) {
        return Switch(
          value: isRunning.value,
          onChanged: (value) => isRunning.value = value,
        );
      },
    );
  }
}
```

---

## Best Practices

### 1. Use Signals for Mutable State

```dart
// Good ✓
final count = signal(0);
count.value++;

// Avoid ✗
int count = 0;
setState(() => count++);
```

---

### 2. Use Computed for Derived Values

```dart
// Good ✓
final doubled = computed(() => count.value * 2);

// Avoid ✗
int getDoubled() => count.value * 2;
```

---

### 3. Use peek() to Avoid Circular Dependencies

```dart
// Good ✓
effect(() {
  final current = count.peek();
  count.value = current + 1; // No circular dependency
});

// Avoid ✗
effect(() {
  count.value = count.value + 1; // Infinite loop!
});
```

---

### 4. Batch Related Updates

```dart
// Good ✓
batch(() {
  x.value = 10;
  y.value = 20;
  z.value = 30;
}); // Effects run once

// Avoid ✗
x.value = 10; // Effects run
y.value = 20; // Effects run
z.value = 30; // Effects run
```

---

### 5. Dispose Effects Properly

```dart
// Good ✓
final dispose = effect(() => /* ... */);

@override
void dispose() {
  dispose();
  super.dispose();
}

// Avoid ✗ (memory leak)
effect(() => /* ... */);
// Never disposed
```

---

### 6. Keep Computed Functions Pure

```dart
// Good ✓
final sum = computed(() => a.value + b.value);

// Avoid ✗
final sum = computed(() {
  print('Computing'); // Side effect
  return a.value + b.value;
});
```

---

### 7. Use ReactiveBuilder for UI Updates

```dart
// Good ✓
ReactiveBuilder(
  builder: (context) => Text('${count.value}'),
)

// Avoid ✗ (manual setState)
StatefulWidget with setState
```

---

## Performance Tips

1. **Use `peek()`** when you don't need reactivity
2. **Batch updates** when changing multiple signals
3. **Keep computed functions fast** - they run on every dependency change
4. **Dispose effects** to prevent memory leaks
5. **Use granular ReactiveBuilders** instead of one large builder
6. **Avoid nested ReactiveBuilders** when possible
7. **Mark expensive computations** with memoization

---

## Common Patterns

### Toggle Boolean

```dart
final isOpen = signal(false);
isOpen.value = !isOpen.value;
```

---

### Update Object

```dart
final user = signal(User(name: 'Alice', age: 25));

// Create new object to trigger reactivity
user.value = user.value.copyWith(age: 26);
```

---

### Update List

```dart
final items = signal<List<String>>([]);

// Add item
items.value = [...items.value, 'new item'];

// Remove item
items.value = items.value.where((i) => i != 'old').toList();

// Update item
items.value = items.value.map((i) =>
  i == 'target' ? 'updated' : i
).toList();
```

---

### Debounced Updates

```dart
final searchQuery = signal('');
Timer? _debounceTimer;

void updateSearch(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 300), () {
    searchQuery.value = query;
  });
}
```

---

## Debugging

### Log Signal Changes

```dart
final count = signal(0);

effect(() {
  print('count changed to: ${count.value}');
});
```

### Track Computation Frequency

```dart
int computeCount = 0;

final expensive = computed(() {
  computeCount++;
  print('Computed $computeCount times');
  return /* expensive calculation */;
});
```

### Visualize Dependencies

```dart
final a = signal(1);
final b = signal(2);
final c = computed(() => a.value + b.value);
final d = computed(() => c.value * 2);

effect(() {
  print('Dependency chain: a -> c -> d = ${d.value}');
});
```

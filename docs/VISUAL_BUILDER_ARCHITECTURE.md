# Kito Visual Builder Architecture
## Low-Code Flutter App Builder with Origami-Style Workflows

### Overview
This document outlines the architecture for building a visual, low-code Flutter app builder on top of Kito, combining Framer's component-based approach with Origami's node-based workflow system.

---

## Current Kito Strengths

### ✅ Already Implemented

1. **Animation System**
   - Declarative API: `animate().to(property, value).withDuration().build()`
   - Keyframes and timelines
   - Multiple targets (Widget, Canvas, SVG)
   - Performance profiling

2. **State Machines**
   - Parallel FSM with orthogonal regions
   - Context-based guards and actions
   - Event-driven architecture
   - Perfect for visual workflow nodes

3. **Reactive System**
   - Signal-based reactivity (like Framer variables)
   - Computed values and automatic effects
   - Efficient dependency tracking

4. **UI Pattern Library**
   - Pre-built components with FSM integration
   - Drag interactions, gestures
   - Animation presets and motion primitives

---

## Required Components for Visual Builder

### 1. Node-Based Workflow System (Origami-Style)

```dart
/// Visual programming node system
class WorkflowNode {
  final String id;
  final String type; // 'animation', 'logic', 'input', 'output', 'component'
  final Map<String, NodePort> inputs;
  final Map<String, NodePort> outputs;
  final Signal<Map<String, dynamic>> state;

  /// Execute node logic
  Future<void> execute(Map<String, dynamic> inputValues);
}

/// Port for connecting nodes
class NodePort {
  final String id;
  final PortType type; // number, boolean, string, color, component, event
  final Signal value;
  final List<Connection> connections;
}

/// Connection between nodes
class Connection {
  final NodePort source;
  final NodePort target;
  final Signal<bool> enabled;
}

/// Visual workflow graph
class WorkflowGraph {
  final Map<String, WorkflowNode> nodes;
  final List<Connection> connections;

  /// Execute the workflow based on events
  Future<void> execute(String startNodeId);

  /// Export to Dart code
  String generateCode();
}
```

**Node Types Needed:**
- **Input Nodes**: User events (tap, drag, scroll), sensors, timers
- **Logic Nodes**: Conditionals, loops, math operations, state management
- **Animation Nodes**: Kito animations, transitions, springs
- **Component Nodes**: Flutter widgets, custom components
- **Output Nodes**: UI rendering, navigation, API calls

### 2. Visual Component Editor (Framer-Style)

```dart
/// Visual component with properties
class VisualComponent {
  final String id;
  final ComponentType type; // container, text, image, button, custom
  final Signal<ComponentProperties> properties;
  final List<VisualComponent> children;
  final WorkflowGraph interactions; // Attached workflows

  /// Design mode properties
  final Signal<LayoutConstraints> constraints;
  final Signal<ResponsiveBreakpoints> breakpoints;

  /// Animation states
  final Map<String, AnimationState> states; // hover, pressed, active

  /// Generate Flutter widget
  Widget toWidget();
}

/// Component properties
class ComponentProperties {
  // Layout
  double? width, height;
  EdgeInsets? padding, margin;
  AlignmentGeometry? alignment;

  // Styling
  Color? backgroundColor;
  BoxDecoration? decoration;
  TextStyle? textStyle;

  // Animations
  Map<String, AnimationConfig> animations;

  // State
  Map<String, Signal> bindings; // Bind to reactive state
}

/// Animation configuration
class AnimationConfig {
  final String trigger; // 'onTap', 'onHover', 'onAppear', 'custom'
  final List<AnimationTarget> targets;
  final int duration;
  final EasingFunction easing;
  final int? delay;
  final int? loop;
}
```

### 3. Canvas-Based Editor

```dart
/// Visual canvas for designing
class DesignCanvas extends StatefulWidget {
  final Signal<List<VisualComponent>> components;
  final Signal<VisualComponent?> selectedComponent;
  final Signal<CanvasTransform> transform; // zoom, pan

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (_) => Stack(
        children: [
          // Grid background
          GridPaper(interval: 10),

          // Components
          ...components.value.map((c) => DraggableComponent(c)),

          // Selection overlay
          if (selectedComponent.value != null)
            SelectionOverlay(selectedComponent.value!),

          // Guides and snapping
          AlignmentGuides(),
        ],
      ),
    );
  }
}

/// Draggable/resizable component on canvas
class DraggableComponent extends StatelessWidget {
  final VisualComponent component;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: component.properties.value.x,
      top: component.properties.value.y,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Update position
          component.properties.value = component.properties.value.copyWith(
            x: component.properties.value.x + details.delta.dx,
            y: component.properties.value.y + details.delta.dy,
          );
        },
        child: ResizableBox(
          child: component.toWidget(),
          onResize: (size) => updateSize(component, size),
        ),
      ),
    );
  }
}
```

### 4. Properties Panel (Inspector)

```dart
/// Properties editor for selected component
class PropertiesPanel extends StatelessWidget {
  final Signal<VisualComponent?> selectedComponent;

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      builder: (_) {
        final component = selectedComponent.value;
        if (component == null) return EmptyState();

        return ListView(
          children: [
            // Layout section
            PropertySection(
              title: 'Layout',
              children: [
                NumberInput(
                  label: 'Width',
                  value: component.properties.value.width,
                  onChanged: (v) => updateWidth(component, v),
                ),
                NumberInput(
                  label: 'Height',
                  value: component.properties.value.height,
                  onChanged: (v) => updateHeight(component, v),
                ),
                // Padding, margin, etc.
              ],
            ),

            // Style section
            PropertySection(
              title: 'Style',
              children: [
                ColorPicker(
                  label: 'Background',
                  value: component.properties.value.backgroundColor,
                  onChanged: (c) => updateColor(component, c),
                ),
                // Border, shadow, etc.
              ],
            ),

            // Animation section
            PropertySection(
              title: 'Animations',
              children: [
                AnimationsList(component.properties.value.animations),
                AddAnimationButton(component),
              ],
            ),

            // Interactions section
            PropertySection(
              title: 'Interactions',
              children: [
                WorkflowsList(component.interactions),
                AddWorkflowButton(component),
              ],
            ),
          ],
        );
      },
    );
  }
}
```

### 5. Workflow Editor (Origami-Style)

```dart
/// Visual workflow editor with nodes
class WorkflowEditor extends StatefulWidget {
  final WorkflowGraph graph;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid background
        GridPaper(color: Colors.grey.shade800),

        // Connections
        CustomPaint(
          painter: ConnectionsPainter(graph.connections),
        ),

        // Nodes
        ...graph.nodes.values.map((node) =>
          Positioned(
            left: node.position.dx,
            top: node.position.dy,
            child: WorkflowNodeWidget(node),
          ),
        ),

        // Node palette
        Positioned(
          left: 20,
          top: 20,
          child: NodePalette(),
        ),
      ],
    );
  }
}

/// Visual representation of a node
class WorkflowNodeWidget extends StatelessWidget {
  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(8),
            color: getNodeTypeColor(node.type),
            child: Text(node.type.toUpperCase()),
          ),

          // Input ports
          ...node.inputs.values.map((port) =>
            NodePortWidget(port, isInput: true),
          ),

          // Node content (based on type)
          NodeContent(node),

          // Output ports
          ...node.outputs.values.map((port) =>
            NodePortWidget(port, isInput: false),
          ),
        ],
      ),
    );
  }
}
```

### 6. Code Generation System

```dart
/// Generate Flutter code from visual components
class CodeGenerator {
  /// Generate complete Flutter app
  String generateApp(Project project) {
    return '''
import 'package:flutter/material.dart';
import 'package:kito/kito.dart';

void main() {
  runApp(${project.name}App());
}

class ${project.name}App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ${generateScreen(project.homeScreen)},
    );
  }
}

${project.screens.map(generateScreen).join('\n\n')}
''';
  }

  /// Generate screen widget
  String generateScreen(VisualComponent screen) {
    return '''
class ${screen.name} extends StatefulWidget {
  @override
  State<${screen.name}> createState() => _${screen.name}State();
}

class _${screen.name}State extends State<${screen.name}> {
  ${generateStateVariables(screen)}

  ${generateAnimations(screen)}

  ${generateWorkflows(screen)}

  @override
  Widget build(BuildContext context) {
    return ${generateWidget(screen)};
  }
}
''';
  }

  /// Generate animation code
  String generateAnimations(VisualComponent component) {
    return component.properties.value.animations.entries.map((entry) {
      final name = entry.key;
      final config = entry.value;

      return '''
late final KitoAnimation _${name}Animation;

void _init${name}Animation() {
  _${name}Animation = animate()
    ${config.targets.map((t) => '.to(${t.property}, ${t.value})').join('\n    ')}
    .withDuration(${config.duration})
    .withEasing(Easing.${config.easing.name})
    ${config.loop != null ? '.withLoop(${config.loop})' : ''}
    .build();
}

void _trigger${name}Animation() {
  _${name}Animation.play();
}
''';
    }).join('\n\n');
  }

  /// Generate workflow code (FSM)
  String generateWorkflows(VisualComponent component) {
    return component.interactions.nodes.values.map((node) {
      // Convert visual workflow to FSM code
      return generateNodeCode(node);
    }).join('\n\n');
  }
}
```

### 7. Component Library System

```dart
/// Reusable component library
class ComponentLibrary {
  final Map<String, ComponentTemplate> templates;
  final Map<String, ComponentVariant> variants;

  /// Create component from template
  VisualComponent createFromTemplate(String templateId, {
    Map<String, dynamic>? overrides,
  }) {
    final template = templates[templateId]!;
    return template.instantiate(overrides);
  }
}

/// Component template
class ComponentTemplate {
  final String id;
  final String name;
  final String category; // 'Basic', 'Forms', 'Navigation', 'Custom'
  final ComponentProperties defaultProperties;
  final List<ComponentProperty> exposedProperties;
  final WorkflowGraph? defaultWorkflow;

  /// Create instance
  VisualComponent instantiate(Map<String, dynamic>? overrides);
}

/// Exposed property for configuration
class ComponentProperty {
  final String name;
  final PropertyType type; // string, number, color, boolean, enum
  final dynamic defaultValue;
  final List<PropertyValidator> validators;
}
```

---

## Implementation Roadmap

### Phase 1: Core Infrastructure (Weeks 1-4)
- [ ] Node-based workflow system
- [ ] WorkflowGraph execution engine
- [ ] Basic node types (input, logic, output)
- [ ] Connection system and validation

### Phase 2: Visual Editor (Weeks 5-8)
- [ ] Canvas-based component editor
- [ ] Drag-and-drop components
- [ ] Resize and transform handles
- [ ] Selection and multi-select
- [ ] Alignment guides and snapping

### Phase 3: Properties System (Weeks 9-12)
- [ ] Properties panel UI
- [ ] Property editors (color, number, text, etc.)
- [ ] Animation configuration UI
- [ ] State binding system

### Phase 4: Workflow Editor (Weeks 13-16)
- [ ] Visual workflow canvas
- [ ] Node palette and library
- [ ] Connection drawing and editing
- [ ] Node execution visualization
- [ ] Debugging tools

### Phase 5: Code Generation (Weeks 17-20)
- [ ] Component to Flutter widget conversion
- [ ] Animation code generation
- [ ] FSM/workflow code generation
- [ ] Complete app scaffolding
- [ ] Export and build system

### Phase 6: Component Library (Weeks 21-24)
- [ ] Template system
- [ ] Component variants
- [ ] Custom component creation
- [ ] Import/export components
- [ ] Shared component libraries

### Phase 7: Advanced Features (Weeks 25-28)
- [ ] Responsive design tools
- [ ] Theme system integration
- [ ] API integration nodes
- [ ] Database/storage nodes
- [ ] Authentication workflows
- [ ] Navigation system

### Phase 8: Collaboration & Publishing (Weeks 29-32)
- [ ] Multi-user collaboration
- [ ] Version control
- [ ] Publishing to app stores
- [ ] Live preview on devices
- [ ] Analytics and monitoring

---

## Key Integrations with Existing Kito

### 1. Animation System Integration
```dart
// Visual workflow node for Kito animation
class AnimationNode extends WorkflowNode {
  @override
  Future<void> execute(Map<String, dynamic> inputs) async {
    final property = inputs['property'] as AnimatableProperty;
    final target = inputs['target'];
    final duration = inputs['duration'] as int;
    final easing = inputs['easing'] as EasingFunction;

    // Use existing Kito animation system
    final animation = animate()
      .to(property, target)
      .withDuration(duration)
      .withEasing(easing)
      .build();

    await animation.play();

    outputs['onComplete'].value = true;
  }
}
```

### 2. FSM Integration
```dart
// Visual workflow converts to FSM
class WorkflowToFSMConverter {
  KitoStateMachine convertToFSM(WorkflowGraph graph) {
    // Convert workflow nodes to FSM states
    final states = graph.nodes.values.map((node) =>
      node.type // e.g., 'idle', 'animating', 'complete'
    ).toSet();

    // Convert connections to transitions
    final transitions = graph.connections.map((conn) =>
      Transition(
        from: conn.source.node.type,
        to: conn.target.node.type,
        event: conn.event,
        guard: conn.condition,
      )
    ).toList();

    return KitoStateMachine(
      initialState: states.first,
      // ... FSM configuration
    );
  }
}
```

### 3. Reactive Bindings
```dart
// Bind workflow outputs to component properties
class ReactiveBinding {
  void bindWorkflowToProperty(
    WorkflowNode node,
    String outputPort,
    VisualComponent component,
    String property,
  ) {
    // Use Kito's reactive system
    effect(() {
      final outputValue = node.outputs[outputPort]!.value.value;
      component.properties.value = component.properties.value.copyWith(
        property: outputValue,
      );
    });
  }
}
```

---

## Example: Button with Hover Animation

### Visual Workflow:
```
[Mouse Enter] → [Animation: Scale Up] → [Set State: Hovered]
     ↓                                          ↓
[Mouse Exit]  → [Animation: Scale Down] → [Set State: Default]
```

### Generated Code:
```dart
class CustomButton extends StatefulWidget {
  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  final scale = animatableDouble(1.0);
  late final ButtonFSM _fsm;

  @override
  void initState() {
    super.initState();
    _initFSM();
  }

  void _initFSM() {
    _fsm = ButtonFSM(
      onHover: () {
        animate()
          .to(scale, 1.1)
          .withDuration(200)
          .withEasing(Easing.easeOutCubic)
          .build()
          .play();
      },
      onHoverExit: () {
        animate()
          .to(scale, 1.0)
          .withDuration(200)
          .withEasing(Easing.easeOutCubic)
          .build()
          .play();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _fsm.send(ButtonEvent.hover),
      onExit: (_) => _fsm.send(ButtonEvent.hoverExit),
      child: ReactiveBuilder(
        builder: (_) => Transform.scale(
          scale: scale.value,
          child: ElevatedButton(
            onPressed: () => _fsm.send(ButtonEvent.tap),
            child: Text('Click Me'),
          ),
        ),
      ),
    );
  }
}
```

---

## Competitive Advantages

### vs. Framer
✅ **Better**: Flutter native (not web-based)
✅ **Better**: Full state machine support
✅ **Better**: More powerful animation system with timelines
✅ **Similar**: Component-based design

### vs. Origami
✅ **Better**: Full app generation (not just prototypes)
✅ **Better**: Modern Flutter widgets
✅ **Similar**: Node-based workflows
✅ **Similar**: Patch-based logic

### vs. FlutterFlow
✅ **Better**: More powerful animation system
✅ **Better**: Visual workflow logic (not just forms)
✅ **Better**: Component variants and reusability
✅ **Better**: FSM-based state management

---

## Conclusion

**Yes, Kito provides an excellent foundation!** The combination of:
- Declarative animation system
- FSM architecture
- Reactive state management
- UI pattern library

...makes it uniquely positioned to build a visual builder that's:
1. **More powerful than Framer** (FSM + timelines)
2. **More practical than Origami** (generates real apps)
3. **More designer-friendly than traditional IDEs** (visual workflows)

The key is building the visual layer on top while leveraging Kito's existing strengths for the runtime.

import 'package:flutter/material.dart';
import 'primitives_demo_screen.dart';
import 'patterns_demo_screen.dart';
import 'interactive_demo_screen.dart';
import 'compositions_demo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.animation,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kito Animation System',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Declarative state machines & reactive animations for Flutter',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Demo categories
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: GridView.count(
                      padding: const EdgeInsets.all(24),
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.5,
                      shrinkWrap: true,
                      children: [
                        _DemoCard(
                          title: 'Atomic Primitives',
                          description:
                              'Motion, enter/exit, and timing primitives',
                          icon: Icons.widgets,
                          color: const Color(0xFF8B4513), // Reddish-brown
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrimitivesDemoScreen(),
                            ),
                          ),
                        ),
                        _DemoCard(
                          title: 'UI Patterns',
                          description:
                              'Button, form, drawer, modal, and more',
                          icon: Icons.dashboard_customize,
                          color: const Color(0xFFD2691E), // Cardboard brown
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PatternsDemoScreen(),
                            ),
                          ),
                        ),
                        _DemoCard(
                          title: 'Interactive Patterns',
                          description:
                              'Drag-to-refresh, reorderable lists & grids',
                          icon: Icons.touch_app,
                          color: const Color(0xFF6B6B6B), // Gray
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InteractiveDemoScreen(),
                            ),
                          ),
                        ),
                        _DemoCard(
                          title: 'Complex Compositions',
                          description:
                              'Combining primitives & patterns',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFF4A4A4A), // Dark gray
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CompositionsDemoScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        opacity: _isHovered ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Card(
          color: widget.color,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.icon,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

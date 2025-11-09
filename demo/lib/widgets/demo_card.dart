import 'package:flutter/material.dart' hide Easing;
import 'package:flutter/services.dart';

class DemoCard extends StatefulWidget {
  final String title;
  final String description;
  final String codeSnippet;
  final Widget child;

  const DemoCard({
    super.key,
    required this.title,
    required this.description,
    required this.codeSnippet,
    required this.child,
  });

  @override
  State<DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<DemoCard> {
  bool _showingCode = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.codeSnippet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showingCode ? Icons.visibility : Icons.code,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showingCode = !_showingCode),
                  tooltip: _showingCode ? 'Show demo' : 'Show code',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _showingCode
                ? _buildCodeView()
                : widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dart',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              TextButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(2),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  widget.codeSnippet,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onBackground,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

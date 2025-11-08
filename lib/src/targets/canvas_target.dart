import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:kito_reactive/kito_reactive.dart';
import '../engine/animatable.dart';

/// Properties for canvas/custom paint animations
class CanvasAnimationProperties {
  /// Position
  final AnimatableProperty<Offset> position;

  /// Size
  final AnimatableProperty<Size> size;

  /// Color
  final AnimatableProperty<Color> color;

  /// Stroke width
  final AnimatableProperty<double> strokeWidth;

  /// Rotation (in radians)
  final AnimatableProperty<double> rotation;

  /// Scale
  final AnimatableProperty<double> scale;

  /// Path progress (0.0 to 1.0) for path animations
  final AnimatableProperty<double> pathProgress;

  CanvasAnimationProperties({
    Offset position = Offset.zero,
    Size size = const Size(100, 100),
    Color color = const Color(0xFF000000),
    double strokeWidth = 1.0,
    double rotation = 0.0,
    double scale = 1.0,
    double pathProgress = 1.0,
  })  : position = animatableOffset(position),
        size = animatableSize(size),
        color = animatableColor(color),
        strokeWidth = animatableDouble(strokeWidth),
        rotation = animatableDouble(rotation),
        scale = animatableDouble(scale),
        pathProgress = animatableDouble(pathProgress);
}

/// A custom painter that uses reactive animation properties
abstract class KitoPainter extends CustomPainter {
  /// Animation properties
  final CanvasAnimationProperties properties;

  /// Create a painter with animation properties
  KitoPainter(this.properties) : super(repaint: _PropertiesListenable(properties));

  @override
  void paint(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// Helper to get a paint object with current properties
  Paint get fillPaint {
    return Paint()
      ..color = properties.color.value
      ..strokeWidth = properties.strokeWidth.value
      ..style = PaintingStyle.fill;
  }

  /// Helper to get a stroke paint object
  Paint get strokePaint {
    return Paint()
      ..color = properties.color.value
      ..strokeWidth = properties.strokeWidth.value
      ..style = PaintingStyle.stroke;
  }

  /// Apply transformations to the canvas based on properties
  void applyTransform(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.translate(center.dx, center.dy);
    canvas.rotate(properties.rotation.value);
    canvas.scale(properties.scale.value);
    canvas.translate(-center.dx, -center.dy);
  }
}

/// A listenable that notifies when any property changes
class _PropertiesListenable extends ChangeNotifier {
  final CanvasAnimationProperties _properties;

  _PropertiesListenable(this._properties) {
    _setupListeners();
  }

  void _setupListeners() {
    // Set up listeners for all signals
    // In production, this would use effects properly
  }

  void _notifyChange() {
    notifyListeners();
  }
}

/// A widget that renders a KitoPainter
class KitoCanvas extends StatelessWidget {
  /// The painter to use
  final KitoPainter painter;

  /// The size of the canvas
  final Size? size;

  /// Whether to repaint when the painter changes
  final bool isComplex;

  /// Whether this will change frequently
  final bool willChange;

  const KitoCanvas({
    super.key,
    required this.painter,
    this.size,
    this.isComplex = false,
    this.willChange = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: painter,
      size: size ?? Size.infinite,
      isComplex: isComplex,
      willChange: willChange,
    );
  }
}

/// Example painters for common shapes

/// Circle painter
class CirclePainter extends KitoPainter {
  CirclePainter(super.properties);

  @override
  void paint(Canvas canvas, Size size) {
    final center = properties.position.value;
    final radius = properties.size.value.width / 2;

    canvas.drawCircle(center, radius, fillPaint);
  }
}

/// Rectangle painter
class RectanglePainter extends KitoPainter {
  RectanglePainter(super.properties);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: properties.position.value,
      width: properties.size.value.width,
      height: properties.size.value.height,
    );

    canvas.drawRect(rect, fillPaint);
  }
}

/// Path painter with progress
class PathPainter extends KitoPainter {
  final ui.Path path;

  PathPainter(super.properties, this.path);

  @override
  void paint(Canvas canvas, Size size) {
    applyTransform(canvas, size);

    // Extract path up to current progress
    final metrics = path.computeMetrics();
    final extractedPath = ui.Path();

    for (final metric in metrics) {
      final length = metric.length * properties.pathProgress.value;
      final extracted = metric.extractPath(0, length);
      extractedPath.addPath(extracted, Offset.zero);
    }

    canvas.drawPath(extractedPath, strokePaint);
  }
}

/// Create a canvas animation widget
KitoCanvas kitoCanvas({
  required KitoPainter painter,
  Size? size,
  bool isComplex = false,
  bool willChange = true,
}) {
  return KitoCanvas(
    painter: painter,
    size: size,
    isComplex: isComplex,
    willChange: willChange,
  );
}

import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import '../engine/animatable.dart';
import '../reactive/signal.dart';

/// Properties for SVG animations
class SvgAnimationProperties {
  /// Path morphing progress (for shape transitions)
  final AnimatableProperty<double> morphProgress;

  /// Stroke dash offset (for line drawing animations)
  final AnimatableProperty<double> dashOffset;

  /// Stroke dash array length
  final AnimatableProperty<double> dashLength;

  /// Fill opacity
  final AnimatableProperty<double> fillOpacity;

  /// Stroke opacity
  final AnimatableProperty<double> strokeOpacity;

  /// Transform properties
  final AnimatableProperty<Offset> translate;
  final AnimatableProperty<double> rotate;
  final AnimatableProperty<double> scale;

  /// Color properties
  final AnimatableProperty<Color> fillColor;
  final AnimatableProperty<Color> strokeColor;

  /// Stroke width
  final AnimatableProperty<double> strokeWidth;

  SvgAnimationProperties({
    double morphProgress = 1.0,
    double dashOffset = 0.0,
    double dashLength = 0.0,
    double fillOpacity = 1.0,
    double strokeOpacity = 1.0,
    Offset translate = Offset.zero,
    double rotate = 0.0,
    double scale = 1.0,
    Color fillColor = const Color(0xFF000000),
    Color strokeColor = const Color(0xFF000000),
    double strokeWidth = 1.0,
  })  : morphProgress = animatableDouble(morphProgress),
        dashOffset = animatableDouble(dashOffset),
        dashLength = animatableDouble(dashLength),
        fillOpacity = animatableDouble(fillOpacity),
        strokeOpacity = animatableDouble(strokeOpacity),
        translate = animatableOffset(translate),
        rotate = animatableDouble(rotate),
        scale = animatableDouble(scale),
        fillColor = animatableColor(fillColor),
        strokeColor = animatableColor(strokeColor),
        strokeWidth = animatableDouble(strokeWidth);
}

/// SVG shape renderer with animation support
abstract class KitoSvgShape extends CustomPainter {
  final SvgAnimationProperties properties;

  KitoSvgShape(this.properties) : super(repaint: _SvgPropertiesListenable(properties));

  @override
  void paint(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// Get fill paint with current properties
  Paint get fillPaint {
    return Paint()
      ..color = properties.fillColor.value.withOpacity(
        properties.fillOpacity.value.clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.fill;
  }

  /// Get stroke paint with current properties
  Paint get strokePaint {
    return Paint()
      ..color = properties.strokeColor.value.withOpacity(
        properties.strokeOpacity.value.clamp(0.0, 1.0),
      )
      ..strokeWidth = properties.strokeWidth.value
      ..style = PaintingStyle.stroke;
  }

  /// Apply transform to canvas
  void applyTransform(Canvas canvas) {
    canvas.translate(properties.translate.value.dx, properties.translate.value.dy);
    canvas.rotate(properties.rotate.value);
    canvas.scale(properties.scale.value);
  }
}

/// Listenable for SVG properties
class _SvgPropertiesListenable extends ChangeNotifier {
  final SvgAnimationProperties _properties;

  _SvgPropertiesListenable(this._properties) {
    _setupListeners();
  }

  void _setupListeners() {
    // Production code would use effects here
  }

  void _notifyChange() {
    notifyListeners();
  }
}

/// SVG path renderer with morph and dash animations
class SvgPathShape extends KitoSvgShape {
  final ui.Path path;
  final ui.Path? targetPath;

  SvgPathShape(
    super.properties,
    this.path, {
    this.targetPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    applyTransform(canvas);

    ui.Path drawPath = path;

    // Path morphing (if target path is provided)
    if (targetPath != null && properties.morphProgress.value < 1.0) {
      // Simple path interpolation (production would use proper path morphing)
      drawPath = _interpolatePaths(
        path,
        targetPath!,
        properties.morphProgress.value,
      );
    }

    // Apply dash effect
    if (properties.dashLength.value > 0) {
      final dashedPaint = strokePaint;
      // Note: Flutter doesn't have built-in dash support,
      // you'd need to use path_drawing package or implement manually
      canvas.drawPath(drawPath, dashedPaint);
    } else {
      canvas.drawPath(drawPath, fillPaint);
      canvas.drawPath(drawPath, strokePaint);
    }

    canvas.restore();
  }

  /// Simple path interpolation (placeholder for proper implementation)
  ui.Path _interpolatePaths(ui.Path start, ui.Path end, double t) {
    // This is a simplified version
    // Production code would use proper path morphing algorithms
    return t < 0.5 ? start : end;
  }
}

/// SVG circle shape
class SvgCircleShape extends KitoSvgShape {
  final Offset center;
  final double radius;

  SvgCircleShape(
    super.properties,
    this.center,
    this.radius,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    applyTransform(canvas);

    canvas.drawCircle(center, radius * properties.scale.value, fillPaint);
    canvas.drawCircle(center, radius * properties.scale.value, strokePaint);

    canvas.restore();
  }
}

/// SVG rectangle shape
class SvgRectShape extends KitoSvgShape {
  final Rect rect;
  final double borderRadius;

  SvgRectShape(
    super.properties,
    this.rect, {
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    applyTransform(canvas);

    if (borderRadius > 0) {
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, strokePaint);
    } else {
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }

    canvas.restore();
  }
}

/// Widget wrapper for SVG shapes
class KitoSvg extends StatelessWidget {
  final KitoSvgShape shape;
  final Size? size;

  const KitoSvg({
    super.key,
    required this.shape,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: shape,
      size: size ?? Size.infinite,
      willChange: true,
    );
  }
}

/// Helper functions for creating SVG animations

/// Create an SVG path animation
KitoSvg svgPath({
  required ui.Path path,
  required SvgAnimationProperties properties,
  ui.Path? targetPath,
  Size? size,
}) {
  return KitoSvg(
    shape: SvgPathShape(properties, path, targetPath: targetPath),
    size: size,
  );
}

/// Create an SVG circle animation
KitoSvg svgCircle({
  required Offset center,
  required double radius,
  required SvgAnimationProperties properties,
  Size? size,
}) {
  return KitoSvg(
    shape: SvgCircleShape(properties, center, radius),
    size: size,
  );
}

/// Create an SVG rectangle animation
KitoSvg svgRect({
  required Rect rect,
  required SvgAnimationProperties properties,
  double borderRadius = 0.0,
  Size? size,
}) {
  return KitoSvg(
    shape: SvgRectShape(properties, rect, borderRadius: borderRadius),
    size: size,
  );
}

import 'dart:ui' as ui;
import 'dart:math' as math;

/// Represents an SVG path that can be morphed/interpolated
class SvgPath {
  final List<PathCommand> commands;

  const SvgPath(this.commands);

  /// Create an SvgPath from an SVG path string (d attribute)
  factory SvgPath.fromString(String pathData) {
    return SvgPathParser.parse(pathData);
  }

  /// Convert to a Flutter Path
  ui.Path toPath() {
    final path = ui.Path();
    for (final command in commands) {
      command.applyTo(path);
    }
    return path;
  }

  /// Normalize this path to cubic bezier curves for interpolation
  SvgPath normalize() {
    return SvgPathNormalizer.normalize(this);
  }

  /// Get the number of commands
  int get length => commands.length;

  @override
  String toString() {
    return 'SvgPath(${commands.length} commands)';
  }
}

/// Base class for all path commands
abstract class PathCommand {
  const PathCommand();

  /// Apply this command to a Flutter Path
  void applyTo(ui.Path path);

  /// Convert this command to cubic bezier representation
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint);

  /// Get the end point of this command
  ui.Offset getEndPoint(ui.Offset currentPoint);
}

/// Move command (M/m)
class MoveCommand extends PathCommand {
  final ui.Offset point;
  final bool relative;

  const MoveCommand(this.point, {this.relative = false});

  @override
  void applyTo(ui.Path path) {
    path.moveTo(point.dx, point.dy);
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) => [];

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => point;
}

/// Line command (L/l)
class LineCommand extends PathCommand {
  final ui.Offset point;
  final bool relative;

  const LineCommand(this.point, {this.relative = false});

  @override
  void applyTo(ui.Path path) {
    path.lineTo(point.dx, point.dy);
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) {
    // Convert line to cubic bezier: control points are at 1/3 and 2/3
    final dx = point.dx - currentPoint.dx;
    final dy = point.dy - currentPoint.dy;
    return [
      CubicBezierCommand(
        ui.Offset(currentPoint.dx + dx / 3, currentPoint.dy + dy / 3),
        ui.Offset(currentPoint.dx + 2 * dx / 3, currentPoint.dy + 2 * dy / 3),
        point,
      ),
    ];
  }

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => point;
}

/// Horizontal line command (H/h)
class HorizontalLineCommand extends PathCommand {
  final double x;
  final bool relative;

  const HorizontalLineCommand(this.x, {this.relative = false});

  @override
  void applyTo(ui.Path path) {
    // Get current position (this is a simplification)
    path.lineTo(x, 0); // Y should be preserved from current position
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) {
    final point = ui.Offset(x, currentPoint.dy);
    return LineCommand(point).toCubic(currentPoint);
  }

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => ui.Offset(x, currentPoint.dy);
}

/// Vertical line command (V/v)
class VerticalLineCommand extends PathCommand {
  final double y;
  final bool relative;

  const VerticalLineCommand(this.y, {this.relative = false});

  @override
  void applyTo(ui.Path path) {
    path.lineTo(0, y); // X should be preserved from current position
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) {
    final point = ui.Offset(currentPoint.dx, y);
    return LineCommand(point).toCubic(currentPoint);
  }

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => ui.Offset(currentPoint.dx, y);
}

/// Cubic bezier curve command (C/c)
class CubicBezierCommand extends PathCommand {
  final ui.Offset control1;
  final ui.Offset control2;
  final ui.Offset point;
  final bool relative;

  const CubicBezierCommand(
    this.control1,
    this.control2,
    this.point, {
    this.relative = false,
  });

  @override
  void applyTo(ui.Path path) {
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      point.dx,
      point.dy,
    );
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) => [this];

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => point;

  /// Interpolate between two cubic bezier commands
  CubicBezierCommand lerp(CubicBezierCommand other, double t) {
    return CubicBezierCommand(
      ui.Offset.lerp(control1, other.control1, t)!,
      ui.Offset.lerp(control2, other.control2, t)!,
      ui.Offset.lerp(point, other.point, t)!,
    );
  }
}

/// Quadratic bezier curve command (Q/q)
class QuadraticBezierCommand extends PathCommand {
  final ui.Offset control;
  final ui.Offset point;
  final bool relative;

  const QuadraticBezierCommand(
    this.control,
    this.point, {
    this.relative = false,
  });

  @override
  void applyTo(ui.Path path) {
    path.quadraticBezierTo(
      control.dx,
      control.dy,
      point.dx,
      point.dy,
    );
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) {
    // Convert quadratic to cubic bezier
    // CP0 = QP0
    // CP1 = QP0 + 2/3 * (QP1 - QP0)
    // CP2 = QP2 + 2/3 * (QP1 - QP2)
    final cp1 = ui.Offset(
      currentPoint.dx + 2.0 / 3.0 * (control.dx - currentPoint.dx),
      currentPoint.dy + 2.0 / 3.0 * (control.dy - currentPoint.dy),
    );
    final cp2 = ui.Offset(
      point.dx + 2.0 / 3.0 * (control.dx - point.dx),
      point.dy + 2.0 / 3.0 * (control.dy - point.dy),
    );
    return [CubicBezierCommand(cp1, cp2, point)];
  }

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => point;
}

/// Arc command (A/a) - simplified
class ArcCommand extends PathCommand {
  final double rx, ry;
  final double rotation;
  final bool largeArc;
  final bool sweep;
  final ui.Offset point;
  final bool relative;

  const ArcCommand(
    this.rx,
    this.ry,
    this.rotation,
    this.largeArc,
    this.sweep,
    this.point, {
    this.relative = false,
  });

  @override
  void applyTo(ui.Path path) {
    // Flutter doesn't have direct arc support with all parameters
    // This is a simplified version - production code would convert to beziers
    path.lineTo(point.dx, point.dy);
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) {
    // Arc to cubic bezier conversion is complex
    // For now, approximate with a line
    return LineCommand(point).toCubic(currentPoint);
  }

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => point;
}

/// Close path command (Z/z)
class ClosePathCommand extends PathCommand {
  const ClosePathCommand();

  @override
  void applyTo(ui.Path path) {
    path.close();
  }

  @override
  List<CubicBezierCommand> toCubic(ui.Offset currentPoint) => [];

  @override
  ui.Offset getEndPoint(ui.Offset currentPoint) => currentPoint;
}

/// Parses SVG path data strings
class SvgPathParser {
  static final _commandPattern = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]');
  static final _numberPattern = RegExp(r'-?\d*\.?\d+(?:[eE][-+]?\d+)?');

  /// Parse an SVG path data string
  static SvgPath parse(String pathData) {
    final commands = <PathCommand>[];
    final matches = _commandPattern.allMatches(pathData);

    if (matches.isEmpty) {
      return SvgPath(commands);
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final command = pathData[match.start];

      // Get the parameters for this command
      final startIndex = match.end;
      final endIndex = i < matches.length - 1
          ? matches.elementAt(i + 1).start
          : pathData.length;
      final paramString = pathData.substring(startIndex, endIndex);
      final params = _extractNumbers(paramString);

      commands.addAll(_parseCommand(command, params));
    }

    return SvgPath(commands);
  }

  static List<double> _extractNumbers(String str) {
    return _numberPattern
        .allMatches(str)
        .map((m) => double.parse(m.group(0)!))
        .toList();
  }

  static List<PathCommand> _parseCommand(String command, List<double> params) {
    final commands = <PathCommand>[];
    final isRelative = command.toLowerCase() == command;

    switch (command.toUpperCase()) {
      case 'M':
        for (int i = 0; i < params.length; i += 2) {
          commands.add(MoveCommand(
            ui.Offset(params[i], params[i + 1]),
            relative: isRelative,
          ));
        }
        break;

      case 'L':
        for (int i = 0; i < params.length; i += 2) {
          commands.add(LineCommand(
            ui.Offset(params[i], params[i + 1]),
            relative: isRelative,
          ));
        }
        break;

      case 'H':
        for (final x in params) {
          commands.add(HorizontalLineCommand(x, relative: isRelative));
        }
        break;

      case 'V':
        for (final y in params) {
          commands.add(VerticalLineCommand(y, relative: isRelative));
        }
        break;

      case 'C':
        for (int i = 0; i < params.length; i += 6) {
          commands.add(CubicBezierCommand(
            ui.Offset(params[i], params[i + 1]),
            ui.Offset(params[i + 2], params[i + 3]),
            ui.Offset(params[i + 4], params[i + 5]),
            relative: isRelative,
          ));
        }
        break;

      case 'Q':
        for (int i = 0; i < params.length; i += 4) {
          commands.add(QuadraticBezierCommand(
            ui.Offset(params[i], params[i + 1]),
            ui.Offset(params[i + 2], params[i + 3]),
            relative: isRelative,
          ));
        }
        break;

      case 'A':
        for (int i = 0; i < params.length; i += 7) {
          commands.add(ArcCommand(
            params[i],
            params[i + 1],
            params[i + 2],
            params[i + 3] != 0,
            params[i + 4] != 0,
            ui.Offset(params[i + 5], params[i + 6]),
            relative: isRelative,
          ));
        }
        break;

      case 'Z':
        commands.add(const ClosePathCommand());
        break;
    }

    return commands;
  }
}

/// Normalizes SVG paths for interpolation
class SvgPathNormalizer {
  /// Normalize a path to use only cubic bezier curves
  static SvgPath normalize(SvgPath path) {
    final normalized = <PathCommand>[];
    var currentPoint = ui.Offset.zero;

    for (final command in path.commands) {
      if (command is MoveCommand) {
        normalized.add(command);
        currentPoint = command.point;
      } else if (command is ClosePathCommand) {
        normalized.add(command);
      } else {
        // Convert to cubic bezier
        final cubics = command.toCubic(currentPoint);
        normalized.addAll(cubics);
        currentPoint = command.getEndPoint(currentPoint);
      }
    }

    return SvgPath(normalized);
  }

  /// Make two paths compatible for interpolation
  /// This ensures they have the same number and type of commands
  static (SvgPath, SvgPath) makeCompatible(SvgPath path1, SvgPath path2) {
    // Normalize both paths first
    final norm1 = normalize(path1);
    final norm2 = normalize(path2);

    final commands1 = norm1.commands;
    final commands2 = norm2.commands;

    // If they're already the same length, we're done
    if (commands1.length == commands2.length) {
      return (norm1, norm2);
    }

    // Otherwise, we need to subdivide the shorter path
    // This is a simplified version - production code would be more sophisticated
    final maxLength = math.max(commands1.length, commands2.length);

    return (
      _padPath(norm1, maxLength),
      _padPath(norm2, maxLength),
    );
  }

  static SvgPath _padPath(SvgPath path, int targetLength) {
    if (path.commands.length >= targetLength) {
      return path;
    }

    // For now, just duplicate the last command
    // Production code would subdivide curves intelligently
    final padded = List<PathCommand>.from(path.commands);
    while (padded.length < targetLength) {
      final lastCommand = padded.last;
      if (lastCommand is CubicBezierCommand) {
        // Duplicate the last cubic command
        padded.add(lastCommand);
      } else {
        break;
      }
    }

    return SvgPath(padded);
  }
}

/// Interpolate between two SVG paths
class SvgPathInterpolator {
  /// Interpolate between two paths at progress t (0.0 to 1.0)
  static SvgPath interpolate(SvgPath from, SvgPath to, double t) {
    // Make paths compatible
    final (compatFrom, compatTo) = SvgPathNormalizer.makeCompatible(from, to);

    final interpolated = <PathCommand>[];

    for (int i = 0; i < compatFrom.commands.length; i++) {
      final cmd1 = compatFrom.commands[i];
      final cmd2 = i < compatTo.commands.length
          ? compatTo.commands[i]
          : cmd1;

      if (cmd1 is MoveCommand && cmd2 is MoveCommand) {
        interpolated.add(MoveCommand(
          ui.Offset.lerp(cmd1.point, cmd2.point, t)!,
        ));
      } else if (cmd1 is CubicBezierCommand && cmd2 is CubicBezierCommand) {
        interpolated.add(cmd1.lerp(cmd2, t));
      } else if (cmd1 is ClosePathCommand) {
        interpolated.add(cmd1);
      } else {
        // Fallback: use first command
        interpolated.add(cmd1);
      }
    }

    return SvgPath(interpolated);
  }
}

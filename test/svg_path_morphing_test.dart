import 'package:flutter_test/flutter_test.dart';
import 'package:kito/kito.dart';
import 'dart:ui' as ui;

void main() {
  group('SvgPath Parsing', () {
    test('parses simple move command', () {
      final path = SvgPath.fromString('M 10 20');
      expect(path.commands.length, 1);
      expect(path.commands[0], isA<MoveCommand>());
      final move = path.commands[0] as MoveCommand;
      expect(move.point.dx, 10.0);
      expect(move.point.dy, 20.0);
    });

    test('parses line command', () {
      final path = SvgPath.fromString('M 0 0 L 10 20');
      expect(path.commands.length, 2);
      expect(path.commands[1], isA<LineCommand>());
      final line = path.commands[1] as LineCommand;
      expect(line.point.dx, 10.0);
      expect(line.point.dy, 20.0);
    });

    test('parses cubic bezier command', () {
      final path = SvgPath.fromString('M 0 0 C 10 10 20 20 30 30');
      expect(path.commands.length, 2);
      expect(path.commands[1], isA<CubicBezierCommand>());
      final cubic = path.commands[1] as CubicBezierCommand;
      expect(cubic.control1.dx, 10.0);
      expect(cubic.control2.dx, 20.0);
      expect(cubic.point.dx, 30.0);
    });

    test('parses quadratic bezier command', () {
      final path = SvgPath.fromString('M 0 0 Q 10 10 20 20');
      expect(path.commands.length, 2);
      expect(path.commands[1], isA<QuadraticBezierCommand>());
      final quad = path.commands[1] as QuadraticBezierCommand;
      expect(quad.control.dx, 10.0);
      expect(quad.point.dx, 20.0);
    });

    test('parses horizontal line command', () {
      final path = SvgPath.fromString('M 0 0 H 50');
      expect(path.commands.length, 2);
      expect(path.commands[1], isA<HorizontalLineCommand>());
      final hline = path.commands[1] as HorizontalLineCommand;
      expect(hline.x, 50.0);
    });

    test('parses vertical line command', () {
      final path = SvgPath.fromString('M 0 0 V 50');
      expect(path.commands.length, 2);
      expect(path.commands[1], isA<VerticalLineCommand>());
      final vline = path.commands[1] as VerticalLineCommand;
      expect(vline.y, 50.0);
    });

    test('parses close path command', () {
      final path = SvgPath.fromString('M 0 0 L 10 10 Z');
      expect(path.commands.length, 3);
      expect(path.commands[2], isA<ClosePathCommand>());
    });

    test('parses complex path with multiple commands', () {
      final pathData = 'M 10,10 L 90,10 L 90,90 L 10,90 Z';
      final path = SvgPath.fromString(pathData);
      expect(path.commands.length, 5); // M + 3L + Z
    });

    test('handles negative numbers', () {
      final path = SvgPath.fromString('M -10 -20 L -30 -40');
      final move = path.commands[0] as MoveCommand;
      final line = path.commands[1] as LineCommand;
      expect(move.point.dx, -10.0);
      expect(move.point.dy, -20.0);
      expect(line.point.dx, -30.0);
      expect(line.point.dy, -40.0);
    });

    test('handles decimal numbers', () {
      final path = SvgPath.fromString('M 10.5 20.7 L 30.123 40.987');
      final move = path.commands[0] as MoveCommand;
      final line = path.commands[1] as LineCommand;
      expect(move.point.dx, closeTo(10.5, 0.01));
      expect(move.point.dy, closeTo(20.7, 0.01));
      expect(line.point.dx, closeTo(30.123, 0.001));
      expect(line.point.dy, closeTo(40.987, 0.001));
    });
  });

  group('Path Normalization', () {
    test('converts line to cubic bezier', () {
      final path = SvgPath.fromString('M 0 0 L 30 30');
      final normalized = path.normalize();

      // Should have M and C (cubic)
      expect(normalized.commands.length, 2);
      expect(normalized.commands[0], isA<MoveCommand>());
      expect(normalized.commands[1], isA<CubicBezierCommand>());
    });

    test('converts quadratic to cubic bezier', () {
      final path = SvgPath.fromString('M 0 0 Q 10 10 20 20');
      final normalized = path.normalize();

      expect(normalized.commands.length, 2);
      expect(normalized.commands[1], isA<CubicBezierCommand>());
    });

    test('preserves move and close commands', () {
      final path = SvgPath.fromString('M 0 0 L 10 10 Z');
      final normalized = path.normalize();

      expect(normalized.commands[0], isA<MoveCommand>());
      expect(normalized.commands[2], isA<ClosePathCommand>());
    });
  });

  group('Path Interpolation', () {
    test('interpolates between two simple paths at t=0', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 20 20');

      final interpolated = SvgPathInterpolator.interpolate(path1, path2, 0.0);

      // At t=0, should be close to path1
      final endPoint = interpolated.commands.last as CubicBezierCommand;
      expect(endPoint.point.dx, closeTo(10.0, 1.0));
    });

    test('interpolates between two simple paths at t=1', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 20 20');

      final interpolated = SvgPathInterpolator.interpolate(path1, path2, 1.0);

      // At t=1, should be close to path2
      final endPoint = interpolated.commands.last as CubicBezierCommand;
      expect(endPoint.point.dx, closeTo(20.0, 1.0));
    });

    test('interpolates between two simple paths at t=0.5', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 20 20');

      final interpolated = SvgPathInterpolator.interpolate(path1, path2, 0.5);

      // At t=0.5, should be halfway between
      final endPoint = interpolated.commands.last as CubicBezierCommand;
      expect(endPoint.point.dx, closeTo(15.0, 1.0));
      expect(endPoint.point.dy, closeTo(15.0, 1.0));
    });

    test('handles paths with different number of commands', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 10 10 L 20 20 L 30 30');

      // Should not throw
      expect(
        () => SvgPathInterpolator.interpolate(path1, path2, 0.5),
        returnsNormally,
      );
    });
  });

  group('Path Compatibility', () {
    test('makeCompatible makes paths same length', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 10 10 L 20 20');

      final (compat1, compat2) =
          SvgPathNormalizer.makeCompatible(path1, path2);

      // Should have same number of commands
      expect(compat1.commands.length, compat2.commands.length);
    });
  });

  group('Path to Flutter Path conversion', () {
    test('converts simple path to Flutter Path', () {
      final svgPath = SvgPath.fromString('M 10 10 L 90 90');
      final flutterPath = svgPath.toPath();

      expect(flutterPath, isA<ui.Path>());
    });

    test('converts complex path to Flutter Path', () {
      final svgPath = SvgPath.fromString(
        'M 10,10 L 90,10 L 90,90 L 10,90 Z',
      );
      final flutterPath = svgPath.toPath();

      expect(flutterPath, isA<ui.Path>());
    });
  });

  group('AnimatableSvgPath', () {
    test('creates animatable from SvgPath', () {
      final path = SvgPath.fromString('M 0 0 L 10 10');
      final animatable = AnimatableSvgPath(path);

      expect(animatable.value, path);
    });

    test('creates animatable from path string', () {
      final animatable = animatableSvgPathString('M 0 0 L 10 10');

      expect(animatable.value, isA<SvgPath>());
      expect(animatable.value.commands.length, 2);
    });

    test('interpolates between two paths', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 20 20');
      final animatable = AnimatableSvgPath(path1);

      final midPath = animatable.interpolate(path1, path2, 0.5);

      expect(midPath, isA<SvgPath>());
    });

    test('can be animated', () {
      final path1 = SvgPath.fromString('M 0 0 L 10 10');
      final path2 = SvgPath.fromString('M 0 0 L 20 20');
      final animatable = AnimatableSvgPath(path1);

      final animation = animate()
          .to(animatable, path2)
          .withDuration(100)
          .build();

      expect(animation, isA<KitoAnimation>());

      animation.dispose();
    });
  });

  group('CubicBezierCommand interpolation', () {
    test('lerps control points correctly', () {
      final cmd1 = CubicBezierCommand(
        const ui.Offset(0, 0),
        const ui.Offset(10, 10),
        const ui.Offset(20, 20),
      );

      final cmd2 = CubicBezierCommand(
        const ui.Offset(0, 0),
        const ui.Offset(20, 20),
        const ui.Offset(40, 40),
      );

      final lerped = cmd1.lerp(cmd2, 0.5);

      expect(lerped.control1.dx, closeTo(0, 0.01));
      expect(lerped.control2.dx, closeTo(15, 0.01));
      expect(lerped.point.dx, closeTo(30, 0.01));
    });

    test('lerps at t=0 returns first command', () {
      final cmd1 = CubicBezierCommand(
        const ui.Offset(0, 0),
        const ui.Offset(10, 10),
        const ui.Offset(20, 20),
      );

      final cmd2 = CubicBezierCommand(
        const ui.Offset(100, 100),
        const ui.Offset(200, 200),
        const ui.Offset(300, 300),
      );

      final lerped = cmd1.lerp(cmd2, 0.0);

      expect(lerped.control1.dx, closeTo(0, 0.01));
      expect(lerped.control2.dx, closeTo(10, 0.01));
      expect(lerped.point.dx, closeTo(20, 0.01));
    });

    test('lerps at t=1 returns second command', () {
      final cmd1 = CubicBezierCommand(
        const ui.Offset(0, 0),
        const ui.Offset(10, 10),
        const ui.Offset(20, 20),
      );

      final cmd2 = CubicBezierCommand(
        const ui.Offset(100, 100),
        const ui.Offset(200, 200),
        const ui.Offset(300, 300),
      );

      final lerped = cmd1.lerp(cmd2, 1.0);

      expect(lerped.control1.dx, closeTo(100, 0.01));
      expect(lerped.control2.dx, closeTo(200, 0.01));
      expect(lerped.point.dx, closeTo(300, 0.01));
    });
  });

  group('Edge cases', () {
    test('handles empty path string', () {
      final path = SvgPath.fromString('');
      expect(path.commands, isEmpty);
    });

    test('handles path with only move command', () {
      final path = SvgPath.fromString('M 10 10');
      expect(path.commands.length, 1);
    });

    test('handles path with whitespace variations', () {
      final path1 = SvgPath.fromString('M10,10L20,20');
      final path2 = SvgPath.fromString('M 10 10 L 20 20');
      final path3 = SvgPath.fromString('M  10  10  L  20  20');

      expect(path1.commands.length, path2.commands.length);
      expect(path2.commands.length, path3.commands.length);
    });
  });

  group('Real-world SVG paths', () {
    test('parses circle path', () {
      // Approximation of a circle using arcs
      final circlePath = 'M 50,10 A 40,40 0 1,1 50,90 A 40,40 0 1,1 50,10 Z';
      final path = SvgPath.fromString(circlePath);

      expect(path.commands.length, greaterThan(0));
      expect(path.commands[0], isA<MoveCommand>());
      expect(path.commands.last, isA<ClosePathCommand>());
    });

    test('parses star path', () {
      final starPath =
          'M 50,10 L 61,35 L 88,35 L 67,52 L 76,79 L 50,62 L 24,79 L 33,52 L 12,35 L 39,35 Z';
      final path = SvgPath.fromString(starPath);

      expect(path.commands.length, 11); // M + 9L + Z
    });

    test('morphs between circle and square', () {
      final circle = 'M 50,10 A 40,40 0 1,1 50,90 A 40,40 0 1,1 50,10 Z';
      final square = 'M 10,10 L 90,10 L 90,90 L 10,90 Z';

      final circlePath = SvgPath.fromString(circle);
      final squarePath = SvgPath.fromString(square);

      final morphed =
          SvgPathInterpolator.interpolate(circlePath, squarePath, 0.5);

      expect(morphed.commands, isNotEmpty);
    });
  });
}

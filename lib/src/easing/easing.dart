import 'dart:math' as math;

/// Easing functions for animations
///
/// All easing functions take a value from 0.0 to 1.0 and return
/// an eased value, also typically between 0.0 and 1.0 (though some
/// easing functions may overshoot).
class Easing {
  // Linear
  static double linear(double t) => t;

  // Quadratic
  static double easeInQuad(double t) => t * t;
  static double easeOutQuad(double t) => t * (2 - t);
  static double easeInOutQuad(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  // Cubic
  static double easeInCubic(double t) => t * t * t;
  static double easeOutCubic(double t) {
    final t1 = t - 1;
    return t1 * t1 * t1 + 1;
  }

  static double easeInOutCubic(double t) {
    return t < 0.5
        ? 4 * t * t * t
        : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;
  }

  // Quartic
  static double easeInQuart(double t) => t * t * t * t;
  static double easeOutQuart(double t) {
    final t1 = t - 1;
    return 1 - t1 * t1 * t1 * t1;
  }

  static double easeInOutQuart(double t) {
    final t1 = t - 1;
    return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * t1 * t1 * t1 * t1;
  }

  // Quintic
  static double easeInQuint(double t) => t * t * t * t * t;
  static double easeOutQuint(double t) {
    final t1 = t - 1;
    return 1 + t1 * t1 * t1 * t1 * t1;
  }

  static double easeInOutQuint(double t) {
    final t1 = t - 1;
    return t < 0.5 ? 16 * t * t * t * t * t : 1 + 16 * t1 * t1 * t1 * t1 * t1;
  }

  // Sinusoidal
  static double easeInSine(double t) {
    return 1 - math.cos(t * math.pi / 2);
  }

  static double easeOutSine(double t) {
    return math.sin(t * math.pi / 2);
  }

  static double easeInOutSine(double t) {
    return -(math.cos(math.pi * t) - 1) / 2;
  }

  // Exponential
  static double easeInExpo(double t) {
    return t == 0 ? 0 : math.pow(2, 10 * (t - 1)).toDouble();
  }

  static double easeOutExpo(double t) {
    return t == 1 ? 1 : 1 - math.pow(2, -10 * t).toDouble();
  }

  static double easeInOutExpo(double t) {
    if (t == 0 || t == 1) return t;
    if (t < 0.5) {
      return math.pow(2, 20 * t - 10).toDouble() / 2;
    }
    return (2 - math.pow(2, -20 * t + 10).toDouble()) / 2;
  }

  // Circular
  static double easeInCirc(double t) {
    return 1 - math.sqrt(1 - t * t);
  }

  static double easeOutCirc(double t) {
    final t1 = t - 1;
    return math.sqrt(1 - t1 * t1);
  }

  static double easeInOutCirc(double t) {
    if (t < 0.5) {
      return (1 - math.sqrt(1 - 4 * t * t)) / 2;
    }
    final t1 = -2 * t + 2;
    return (math.sqrt(1 - t1 * t1) + 1) / 2;
  }

  // Back
  static double easeInBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return c3 * t * t * t - c1 * t * t;
  }

  static double easeOutBack(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final t1 = t - 1;
    return 1 + c3 * t1 * t1 * t1 + c1 * t1 * t1;
  }

  static double easeInOutBack(double t) {
    const c1 = 1.70158;
    const c2 = c1 * 1.525;
    if (t < 0.5) {
      final t2 = 2 * t;
      return (t2 * t2 * ((c2 + 1) * 2 * t - c2)) / 2;
    }
    final t2 = 2 * t - 2;
    return (t2 * t2 * ((c2 + 1) * (t2) + c2) + 2) / 2;
  }

  // Elastic
  static double easeInElastic(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0 || t == 1) return t;
    return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4);
  }

  static double easeOutElastic(double t) {
    const c4 = (2 * math.pi) / 3;
    if (t == 0 || t == 1) return t;
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1;
  }

  static double easeInOutElastic(double t) {
    const c5 = (2 * math.pi) / 4.5;
    if (t == 0 || t == 1) return t;
    if (t < 0.5) {
      return -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2;
    }
    return (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 +
        1;
  }

  // Bounce
  static double easeInBounce(double t) {
    return 1 - easeOutBounce(1 - t);
  }

  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;

    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      final t1 = t - 1.5 / d1;
      return n1 * t1 * t1 + 0.75;
    } else if (t < 2.5 / d1) {
      final t1 = t - 2.25 / d1;
      return n1 * t1 * t1 + 0.9375;
    } else {
      final t1 = t - 2.625 / d1;
      return n1 * t1 * t1 + 0.984375;
    }
  }

  static double easeInOutBounce(double t) {
    return t < 0.5
        ? (1 - easeOutBounce(1 - 2 * t)) / 2
        : (1 + easeOutBounce(2 * t - 1)) / 2;
  }

  // Steps (for sprite animations, etc)
  static double Function(double) steps(int count, {bool jumpStart = false}) {
    return (double t) {
      final step = (t * count).floor();
      if (jumpStart) {
        return (step + 1) / count;
      } else {
        return step / count;
      }
    };
  }

  // Custom cubic bezier
  static double Function(double) cubicBezier(
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    return (double t) => _cubicBezierImpl(t, x1, y1, x2, y2);
  }

  static double _cubicBezierImpl(
    double t,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    // Simple approximation - for production, you'd want a more accurate solver
    final cx = 3 * x1;
    final bx = 3 * (x2 - x1) - cx;
    final ax = 1 - cx - bx;

    final cy = 3 * y1;
    final by = 3 * (y2 - y1) - cy;
    final ay = 1 - cy - by;

    return ((ay * t + by) * t + cy) * t;
  }
}

/// Predefined easing presets matching anime.js
class EasingPresets {
  static const linear = Easing.linear;

  // Quad
  static const easeInQuad = Easing.easeInQuad;
  static const easeOutQuad = Easing.easeOutQuad;
  static const easeInOutQuad = Easing.easeInOutQuad;

  // Cubic
  static const easeInCubic = Easing.easeInCubic;
  static const easeOutCubic = Easing.easeOutCubic;
  static const easeInOutCubic = Easing.easeInOutCubic;

  // Quart
  static const easeInQuart = Easing.easeInQuart;
  static const easeOutQuart = Easing.easeOutQuart;
  static const easeInOutQuart = Easing.easeInOutQuart;

  // Quint
  static const easeInQuint = Easing.easeInQuint;
  static const easeOutQuint = Easing.easeOutQuint;
  static const easeInOutQuint = Easing.easeInOutQuint;

  // Sine
  static const easeInSine = Easing.easeInSine;
  static const easeOutSine = Easing.easeOutSine;
  static const easeInOutSine = Easing.easeInOutSine;

  // Expo
  static const easeInExpo = Easing.easeInExpo;
  static const easeOutExpo = Easing.easeOutExpo;
  static const easeInOutExpo = Easing.easeInOutExpo;

  // Circ
  static const easeInCirc = Easing.easeInCirc;
  static const easeOutCirc = Easing.easeOutCirc;
  static const easeInOutCirc = Easing.easeInOutCirc;

  // Back
  static const easeInBack = Easing.easeInBack;
  static const easeOutBack = Easing.easeOutBack;
  static const easeInOutBack = Easing.easeInOutBack;

  // Elastic
  static const easeInElastic = Easing.easeInElastic;
  static const easeOutElastic = Easing.easeOutElastic;
  static const easeInOutElastic = Easing.easeInOutElastic;

  // Bounce
  static const easeInBounce = Easing.easeInBounce;
  static const easeOutBounce = Easing.easeOutBounce;
  static const easeInOutBounce = Easing.easeInOutBounce;
}

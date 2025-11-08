import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';

/// Form states
enum FormState {
  editing,      // User is editing
  validating,   // Validating input
  valid,        // Validation passed
  invalid,      // Validation failed
  submitting,   // Submitting to backend
  success,      // Submission successful
  error,        // Submission failed
}

/// Form events
enum FormEvent {
  input,        // User input
  validate,     // Start validation
  validationPassed,    // Validation successful
  validationFailed,    // Validation failed
  submit,       // Submit form
  submitSuccess,       // Submit successful
  submitError,         // Submit failed
  reset,        // Reset form
  retry,        // Retry after error
}

/// Form animation configuration
class FormAnimationConfig {
  /// Shake duration for errors (ms)
  final int shakeDuration;

  /// Shake intensity (pixels)
  final double shakeIntensity;

  /// Fade duration (ms)
  final int fadeDuration;

  /// Success checkmark animation duration (ms)
  final int successDuration;

  const FormAnimationConfig({
    this.shakeDuration = 400,
    this.shakeIntensity = 8.0,
    this.fadeDuration = 200,
    this.successDuration = 600,
  });
}

/// Form context
class FormContext {
  final FormAnimationConfig config;

  // Animation properties
  final AnimatableProperty<double> offsetX;
  final AnimatableProperty<double> opacity;
  final AnimatableProperty<double> borderColor; // 0.0 = normal, 1.0 = error
  final AnimatableProperty<double> successScale;

  KitoAnimation? currentAnimation;
  Map<String, dynamic> formData = {};
  String? errorMessage;
  VoidCallback? onSubmit;

  FormContext({
    required this.config,
    this.onSubmit,
  })  : offsetX = animatableDouble(0.0),
        opacity = animatableDouble(1.0),
        borderColor = animatableDouble(0.0),
        successScale = animatableDouble(0.0);
}

/// Form state machine
class FormStateMachine extends KitoStateMachine<FormState, FormEvent, FormContext> {
  FormStateMachine(FormContext context)
      : super(
          initial: FormState.editing,
          config: StateMachineConfig(
            states: _buildStates(),
          ),
          context: context,
        );

  static Map<FormState, StateConfig<FormState, FormEvent, FormContext>> _buildStates() {
    return {
      FormState.editing: StateConfig(
        state: FormState.editing,
        transitions: {
          FormEvent.validate: TransitionConfig(
            target: FormState.validating,
          ),
        },
      ),

      FormState.validating: StateConfig(
        state: FormState.validating,
        transitions: {
          FormEvent.validationPassed: TransitionConfig(
            target: FormState.valid,
          ),
          FormEvent.validationFailed: TransitionConfig(
            target: FormState.invalid,
            action: (ctx) {
              _animateError(ctx);
              return ctx;
            },
          ),
        },
      ),

      FormState.valid: StateConfig(
        state: FormState.valid,
        transitions: {
          FormEvent.input: TransitionConfig(
            target: FormState.editing,
          ),
          FormEvent.submit: TransitionConfig(
            target: FormState.submitting,
            action: (ctx) {
              _animateSubmitting(ctx);
              ctx.onSubmit?.call();
              return ctx;
            },
          ),
        },
      ),

      FormState.invalid: StateConfig(
        state: FormState.invalid,
        transitions: {
          FormEvent.input: TransitionConfig(
            target: FormState.editing,
            action: (ctx) {
              _animateNormal(ctx);
              return ctx;
            },
          ),
        },
      ),

      FormState.submitting: StateConfig(
        state: FormState.submitting,
        transitions: {
          FormEvent.submitSuccess: TransitionConfig(
            target: FormState.success,
            action: (ctx) {
              _animateSuccess(ctx);
              return ctx;
            },
          ),
          FormEvent.submitError: TransitionConfig(
            target: FormState.error,
            action: (ctx) {
              _animateError(ctx);
              return ctx;
            },
          ),
        },
      ),

      FormState.success: StateConfig(
        state: FormState.success,
        transitions: {
          FormEvent.reset: TransitionConfig(
            target: FormState.editing,
            action: (ctx) {
              _animateReset(ctx);
              return ctx;
            },
          ),
        },
      ),

      FormState.error: StateConfig(
        state: FormState.error,
        transitions: {
          FormEvent.retry: TransitionConfig(
            target: FormState.editing,
            action: (ctx) {
              _animateReset(ctx);
              return ctx;
            },
          ),
          FormEvent.reset: TransitionConfig(
            target: FormState.editing,
            action: (ctx) {
              _animateReset(ctx);
              return ctx;
            },
          ),
        },
      ),
    };
  }

  static void _animateError(FormContext ctx) {
    ctx.currentAnimation?.stop();

    // Shake animation using keyframes
    ctx.currentAnimation = animate()
        .withKeyframes(ctx.offsetX, [
          Keyframe(value: 0.0, offset: 0.0),
          Keyframe(value: ctx.config.shakeIntensity, offset: 0.25),
          Keyframe(value: -ctx.config.shakeIntensity, offset: 0.5),
          Keyframe(value: ctx.config.shakeIntensity / 2, offset: 0.75),
          Keyframe(value: 0.0, offset: 1.0),
        ])
        .to(ctx.borderColor, 1.0)
        .withDuration(ctx.config.shakeDuration)
        .withEasing(Easing.easeOutCubic)
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateNormal(FormContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.borderColor, 0.0)
        .to(ctx.opacity, 1.0)
        .withDuration(ctx.config.fadeDuration)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateSubmitting(FormContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.opacity, 0.7)
        .withDuration(ctx.config.fadeDuration)
        .build();
    ctx.currentAnimation!.play();
  }

  static void _animateSuccess(FormContext ctx) {
    ctx.currentAnimation?.stop();

    // Checkmark pop animation
    ctx.currentAnimation = animate()
        .to(ctx.successScale, 1.0)
        .to(ctx.opacity, 1.0)
        .withDuration(ctx.config.successDuration)
        .withEasing(Easing.easeOutBack)
        .build();

    ctx.currentAnimation!.play();
  }

  static void _animateReset(FormContext ctx) {
    ctx.currentAnimation?.stop();
    ctx.currentAnimation = animate()
        .to(ctx.successScale, 0.0)
        .to(ctx.borderColor, 0.0)
        .to(ctx.opacity, 1.0)
        .to(ctx.offsetX, 0.0)
        .withDuration(ctx.config.fadeDuration)
        .build();
    ctx.currentAnimation!.play();
  }
}

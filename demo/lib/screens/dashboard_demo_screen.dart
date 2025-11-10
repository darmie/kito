import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Easing;
import 'package:kito/kito.dart';
import 'package:kito_fsm/kito_fsm.dart';
import '../widgets/demo_card.dart';
import '../widgets/heatmap_demo_widget.dart';

class DashboardDemoScreen extends StatelessWidget {
  const DashboardDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Dashboard'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 800,
              child: _AdvancedDashboardDemo(),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 500,
              child: HeatMapDemo(),
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard state enums
enum DashboardDataState { idle, loading, refreshing, loaded, error }

enum DashboardAnimState { idle, animating, paused }

enum DashboardInteractionState { idle, interacting }

enum DashboardEvent {
  load,
  refresh,
  loadComplete,
  loadError,
  startAnimation,
  pauseAnimation,
  resumeAnimation,
  animationComplete,
  interact,
  interactionEnd,
}

class DashboardContext {}

// Dashboard Data FSM
class DashboardDataFSM extends KitoStateMachine<DashboardDataState,
    DashboardEvent, DashboardContext> {
  final Future<void> Function() onLoadData;

  DashboardDataFSM({
    required DashboardContext context,
    required this.onLoadData,
  }) : super(
          initial: DashboardDataState.idle,
          context: context,
          config: StateMachineConfig(
            states: {
              DashboardDataState.idle: StateConfig(
                state: DashboardDataState.idle,
                transitions: {
                  DashboardEvent.load: TransitionConfig(
                    target: DashboardDataState.loading,
                  ),
                },
              ),
              DashboardDataState.loading: StateConfig(
                state: DashboardDataState.loading,
                onEntry: (context, from, to) => onLoadData(),
                transitions: {
                  DashboardEvent.loadComplete: TransitionConfig(
                    target: DashboardDataState.loaded,
                  ),
                  DashboardEvent.loadError: TransitionConfig(
                    target: DashboardDataState.error,
                  ),
                },
              ),
              DashboardDataState.loaded: StateConfig(
                state: DashboardDataState.loaded,
                transitions: {
                  DashboardEvent.refresh: TransitionConfig(
                    target: DashboardDataState.refreshing,
                  ),
                },
              ),
              DashboardDataState.refreshing: StateConfig(
                state: DashboardDataState.refreshing,
                onEntry: (context, from, to) => onLoadData(),
                transitions: {
                  DashboardEvent.loadComplete: TransitionConfig(
                    target: DashboardDataState.loaded,
                  ),
                },
              ),
              DashboardDataState.error: StateConfig(
                state: DashboardDataState.error,
                transitions: {
                  DashboardEvent.refresh: TransitionConfig(
                    target: DashboardDataState.loading,
                  ),
                },
              ),
            },
          ),
        );
}

// Dashboard Animation FSM
class DashboardAnimFSM extends KitoStateMachine<DashboardAnimState,
    DashboardEvent, DashboardContext> {
  final void Function() onPlayAnimations;

  DashboardAnimFSM({
    required DashboardContext context,
    required this.onPlayAnimations,
  }) : super(
          initial: DashboardAnimState.idle,
          context: context,
          config: StateMachineConfig(
            states: {
              DashboardAnimState.idle: StateConfig(
                state: DashboardAnimState.idle,
                transitions: {
                  DashboardEvent.startAnimation: TransitionConfig(
                    target: DashboardAnimState.animating,
                  ),
                },
              ),
              DashboardAnimState.animating: StateConfig(
                state: DashboardAnimState.animating,
                onEntry: (context, from, to) => onPlayAnimations(),
                transitions: {
                  DashboardEvent.pauseAnimation: TransitionConfig(
                    target: DashboardAnimState.paused,
                  ),
                  DashboardEvent.animationComplete: TransitionConfig(
                    target: DashboardAnimState.idle,
                  ),
                },
              ),
              DashboardAnimState.paused: StateConfig(
                state: DashboardAnimState.paused,
                transitions: {
                  DashboardEvent.resumeAnimation: TransitionConfig(
                    target: DashboardAnimState.animating,
                  ),
                },
              ),
            },
          ),
        );
}

// Dashboard Interaction FSM
class DashboardInteractionFSM extends KitoStateMachine<
    DashboardInteractionState, DashboardEvent, DashboardContext> {
  DashboardInteractionFSM({
    required DashboardContext context,
  }) : super(
          initial: DashboardInteractionState.idle,
          context: context,
          config: StateMachineConfig(
            states: {
              DashboardInteractionState.idle: StateConfig(
                state: DashboardInteractionState.idle,
                transitions: {
                  DashboardEvent.interact: TransitionConfig(
                    target: DashboardInteractionState.interacting,
                  ),
                },
              ),
              DashboardInteractionState.interacting: StateConfig(
                state: DashboardInteractionState.interacting,
                transitions: {
                  DashboardEvent.interactionEnd: TransitionConfig(
                    target: DashboardInteractionState.idle,
                  ),
                },
              ),
            },
          ),
        );
}

// Advanced Dashboard Demo with Parallel FSM
class _AdvancedDashboardDemo extends StatefulWidget {
  const _AdvancedDashboardDemo();

  @override
  State<_AdvancedDashboardDemo> createState() => _AdvancedDashboardDemoState();
}

class _AdvancedDashboardDemoState extends State<_AdvancedDashboardDemo> {
  // Parallel FSM for dashboard state
  late final ParallelStateMachine<dynamic, DashboardEvent, DashboardContext>
      parallelFsm;

  // Reactive signals for data
  late final Signal<List<double>> revenueData;
  late final Signal<List<double>> userGrowthData;
  late final Signal<double> performanceScore;
  late final Signal<int> totalUsers;
  late final Signal<double> totalRevenue;

  // Canvas animation properties for charts
  late final CanvasAnimationProperties lineChartProps;
  late final CanvasAnimationProperties barChartProps;
  late final CanvasAnimationProperties gaugeProps;

  // Animatable properties for metric counters
  late final AnimatableProperty<double> animatedUsers;
  late final AnimatableProperty<double> animatedRevenue;
  late final AnimatableProperty<double> animatedPerformance;

  // Animatable properties for metric scale (pulse effect)
  late final AnimatableProperty<double> usersScale;
  late final AnimatableProperty<double> revenueScale;
  late final AnimatableProperty<double> performanceScale;

  // Timeline for coordinated animations
  Timeline? timeline;

  final random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize reactive signals
    revenueData = signal<List<double>>([]);
    userGrowthData = signal<List<double>>([]);
    performanceScore = signal<double>(0.0);
    totalUsers = signal<int>(0);
    totalRevenue = signal<double>(0.0);

    // Initialize canvas properties
    lineChartProps = CanvasAnimationProperties(
      color: const Color(0xFF3498DB),
      strokeWidth: 3.0,
      pathProgress: 0.0,
    );

    barChartProps = CanvasAnimationProperties(
      color: const Color(0xFF2ECC71),
      scale: 0.0,
    );

    gaugeProps = CanvasAnimationProperties(
      color: const Color(0xFFE74C3C),
      pathProgress: 0.0,
    );

    // Initialize animatable properties for metric counters
    animatedUsers = AnimatableProperty<double>(
      0.0,
      (start, end, progress) => start + (end - start) * progress,
    );
    animatedRevenue = AnimatableProperty<double>(
      0.0,
      (start, end, progress) => start + (end - start) * progress,
    );
    animatedPerformance = AnimatableProperty<double>(
      0.0,
      (start, end, progress) => start + (end - start) * progress,
    );

    // Initialize scale properties for pulse effect
    usersScale = AnimatableProperty<double>(
      1.0,
      (start, end, progress) => start + (end - start) * progress,
    );
    revenueScale = AnimatableProperty<double>(
      1.0,
      (start, end, progress) => start + (end - start) * progress,
    );
    performanceScale = AnimatableProperty<double>(
      1.0,
      (start, end, progress) => start + (end - start) * progress,
    );

    // Add effect to trigger rebuilds when animated values change
    effect(() {
      // Access the signals to establish reactive dependencies
      animatedUsers.signal.value;
      animatedRevenue.signal.value;
      animatedPerformance.signal.value;
      usersScale.signal.value;
      revenueScale.signal.value;
      performanceScale.signal.value;
      // Trigger rebuild
      if (mounted) setState(() {});
    });

    // Create parallel FSM with three regions
    parallelFsm = _createParallelFSM();

    // Auto-load data on init
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        parallelFsm.broadcast(DashboardEvent.load);
      }
    });
  }

  ParallelStateMachine<dynamic, DashboardEvent, DashboardContext>
      _createParallelFSM() {
    // Data region FSM
    final dataFsm = DashboardDataFSM(
      context: DashboardContext(),
      onLoadData: _loadData,
    );

    // Animation region FSM
    final animFsm = DashboardAnimFSM(
      context: DashboardContext(),
      onPlayAnimations: _playAnimations,
    );

    // Interaction region FSM
    final interactionFsm = DashboardInteractionFSM(
      context: DashboardContext(),
    );

    // Create parallel FSM
    return ParallelStateMachine(
      regions: [
        ParallelRegion(
          id: 'data',
          stateMachine: dataFsm,
        ),
        ParallelRegion(
          id: 'animation',
          stateMachine: animFsm,
        ),
        ParallelRegion(
          id: 'interaction',
          stateMachine: interactionFsm,
        ),
      ],
      config: ParallelConfig.broadcast,
    );
  }

  Future<void> _loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Generate random data
    final newRevenueData = List.generate(12, (i) {
      return 20.0 + random.nextDouble() * 80.0;
    });

    final newUserGrowthData = List.generate(7, (i) {
      return 10.0 + random.nextDouble() * 90.0;
    });

    final newPerformanceScore = 60.0 + random.nextDouble() * 35.0;
    final newTotalUsers = 10000 + random.nextInt(50000);
    final newTotalRevenue = 50000.0 + random.nextDouble() * 200000.0;

    // Update signals
    revenueData.value = newRevenueData;
    userGrowthData.value = newUserGrowthData;
    performanceScore.value = newPerformanceScore;
    totalUsers.value = newTotalUsers;
    totalRevenue.value = newTotalRevenue;

    // Notify load complete
    parallelFsm.broadcast(DashboardEvent.loadComplete);

    // Auto-start animations
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      parallelFsm.sendToRegion('animation', DashboardEvent.startAnimation);
    }
  }

  void _playAnimations() {
    timeline?.dispose();
    timeline = Timeline();

    // Reset all properties
    lineChartProps.pathProgress.value = 0.0;
    barChartProps.scale.value = 0.0;
    gaugeProps.pathProgress.value = 0.0;
    animatedUsers.value = 0.0;
    animatedRevenue.value = 0.0;
    animatedPerformance.value = 0.0;
    usersScale.value = 1.0;
    revenueScale.value = 1.0;
    performanceScale.value = 1.0;

    // Counter animations - count up to target values
    final usersAnim = animate()
        .to(animatedUsers, totalUsers.value.toDouble())
        .withDuration(1500)
        .withEasing(Easing.easeOutExpo)
        .build();

    final revenueAnim = animate()
        .to(animatedRevenue, totalRevenue.value)
        .withDuration(1500)
        .withEasing(Easing.easeOutExpo)
        .build();

    final performanceAnim = animate()
        .to(animatedPerformance, performanceScore.value)
        .withDuration(1500)
        .withEasing(Easing.easeOutExpo)
        .build();

    // Pulse/scale animations for metric cards - gives a "pop" effect
    // Each card pulses up to 1.15 then back to 1.0 during counting animation
    final usersScalePulse = animate()
        .to(usersScale, 1.15)
        .withDuration(700)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final revenueScalePulse = animate()
        .to(revenueScale, 1.15)
        .withDuration(700)
        .withDelay(100)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final performanceScalePulse = animate()
        .to(performanceScale, 1.15)
        .withDuration(700)
        .withDelay(200)
        .withEasing(Easing.easeInOutCubic)
        .build();

    // Animate back to 1.0 after pulse
    final usersScaleBack = animate()
        .to(usersScale, 1.0)
        .withDuration(700)
        .withDelay(700)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final revenueScaleBack = animate()
        .to(revenueScale, 1.0)
        .withDuration(700)
        .withDelay(800)
        .withEasing(Easing.easeInOutCubic)
        .build();

    final performanceScaleBack = animate()
        .to(performanceScale, 1.0)
        .withDuration(700)
        .withDelay(900)
        .withEasing(Easing.easeInOutCubic)
        .build();

    // Line chart animation (draws path)
    final lineAnim = animate()
        .to(lineChartProps.pathProgress, 1.0)
        .withDuration(1200)
        .withEasing(Easing.easeInOutCubic)
        .build();

    // Bar chart animations (staggered)
    final barAnims = <KitoAnimation>[];
    for (var i = 0; i < userGrowthData.value.length; i++) {
      final anim = animate()
          .to(barChartProps.scale, 1.0)
          .withDuration(400)
          .withDelay(i * 80)
          .withEasing(Easing.easeOutBack)
          .build();
      barAnims.add(anim);
    }

    // Gauge animation
    final gaugeAnim = animate()
        .to(gaugeProps.pathProgress, 1.0)
        .withDuration(1500)
        .withEasing(Easing.easeInOutCubic)
        .build();

    // Add counter animations first (concurrent)
    timeline!.add(usersAnim);
    timeline!.add(revenueAnim, position: TimelinePosition.concurrent);
    timeline!.add(performanceAnim, position: TimelinePosition.concurrent);

    // Add pulse animations for visual emphasis during counting
    timeline!.add(usersScalePulse, position: TimelinePosition.concurrent);
    timeline!.add(usersScaleBack, position: TimelinePosition.concurrent);
    timeline!.add(revenueScalePulse, position: TimelinePosition.concurrent);
    timeline!.add(revenueScaleBack, position: TimelinePosition.concurrent);
    timeline!.add(performanceScalePulse, position: TimelinePosition.concurrent);
    timeline!.add(performanceScaleBack, position: TimelinePosition.concurrent);

    // Add chart animations
    timeline!.add(lineAnim, position: TimelinePosition.concurrent);

    // Add bar animations concurrently but internally staggered via delay
    if (barAnims.isNotEmpty) {
      timeline!.add(barAnims.first, position: TimelinePosition.concurrent);
    }

    timeline!.add(gaugeAnim, position: TimelinePosition.concurrent);

    timeline!.play();

    // Mark animation as complete after timeline duration
    Future.delayed(Duration(milliseconds: timeline!.duration + 100), () {
      if (mounted) {
        parallelFsm.sendToRegion(
            'animation', DashboardEvent.animationComplete);
      }
    });
  }

  void _refresh() {
    parallelFsm.broadcast(DashboardEvent.refresh);
  }

  @override
  void dispose() {
    timeline?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      title: 'Advanced Analytics Dashboard',
      description: 'Parallel FSM + Canvas + Timeline + Reactive Signals',
      codeSnippet: '''// Parallel FSM with 3 regions:
final parallelFsm = ParallelStateMachine(
  regions: [
    ParallelRegion(id: 'data',
      stateMachine: dataFsm),      // idle → loading → loaded
    ParallelRegion(id: 'animation',
      stateMachine: animFsm),      // idle → animating → idle
    ParallelRegion(id: 'interaction',
      stateMachine: interactionFsm), // idle → interacting
  ],
  config: ParallelConfig.broadcast,
);

// Canvas painters with reactive properties:
class LineChartPainter extends KitoPainter {
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createPath(data, size);
    // Animate drawing using pathProgress
    final metrics = path.computeMetrics();
    final extractedPath = ui.Path();
    for (final metric in metrics) {
      final length = metric.length *
        properties.pathProgress.value;
      extractedPath.addPath(
        metric.extractPath(0, length),
        Offset.zero
      );
    }
    canvas.drawPath(extractedPath, strokePaint);
  }
}

// Timeline orchestration:
timeline.add(lineChartAnim);
timeline.add(barChartAnim,
  position: TimelinePosition.concurrent);
timeline.add(gaugeAnim,
  position: TimelinePosition.concurrent);
timeline.play();

// Reactive signals auto-update UI:
ReactiveBuilder(
  builder: (_) => Text(
    '\\\$\${totalRevenue.value.toStringAsFixed(0)}'
  ),
);''',
      child: Builder(
        builder: (context) => ReactiveBuilder(
          builder: (_) {
            final dataRegion = parallelFsm.getRegion('data');
            final animRegion = parallelFsm.getRegion('animation');
            final dataState = dataRegion?.currentState.value;
            final animState = animRegion?.currentState.value;

            final isLoading = dataState == DashboardDataState.loading ||
                dataState == DashboardDataState.refreshing;
            final hasData = dataState == DashboardDataState.loaded;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with refresh button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business Metrics',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStateDescription(dataState, animState),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: isLoading ? null : _refresh,
                        icon: Icon(
                          Icons.refresh,
                          color: isLoading
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Summary cards
              if (hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Total Users',
                          value: _formatNumber(animatedUsers.value.toInt()),
                          icon: Icons.people,
                          color: const Color(0xFF3498DB),
                          scale: usersScale.value,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricCard(
                          title: 'Revenue',
                          value: '\$${_formatNumber(animatedRevenue.value.toInt())}',
                          icon: Icons.attach_money,
                          color: const Color(0xFF2ECC71),
                          scale: revenueScale.value,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _MetricCard(
                          title: 'Performance',
                          value: '${animatedPerformance.value.toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: const Color(0xFFE74C3C),
                          scale: performanceScale.value,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Charts
              if (isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading dashboard data...'),
                      ],
                    ),
                  ),
                )
              else if (hasData)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Revenue Line Chart
                        Expanded(
                          flex: 2,
                          child: _ChartCard(
                            title: 'Revenue Trend',
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: KitoCanvas(
                                painter: LineChartPainter(
                                  lineChartProps,
                                  revenueData.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // User Growth Bar Chart
                        Expanded(
                          flex: 2,
                          child: _ChartCard(
                            title: 'User Growth',
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: KitoCanvas(
                                painter: BarChartPainter(
                                  barChartProps,
                                  userGrowthData.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Performance Gauge
                        Expanded(
                          child: _ChartCard(
                            title: 'Score',
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: KitoCanvas(
                                painter: GaugePainter(
                                  gaugeProps,
                                  performanceScore.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        ),
      ),
    );
  }

  String _getStateDescription(dynamic dataState, dynamic animState) {
    if (dataState == DashboardDataState.loading) {
      return 'Data: Loading... | Animation: Idle';
    } else if (dataState == DashboardDataState.refreshing) {
      return 'Data: Refreshing... | Animation: Idle';
    } else if (dataState == DashboardDataState.loaded) {
      if (animState == DashboardAnimState.animating) {
        return 'Data: Loaded | Animation: Playing';
      } else if (animState == DashboardAnimState.paused) {
        return 'Data: Loaded | Animation: Paused';
      }
      return 'Data: Loaded | Animation: Complete';
    }
    return 'Initializing...';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// Metric Card Widget
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double scale;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Transform.scale(
            scale: scale,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// Chart Card Widget
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// Line Chart Painter
class LineChartPainter extends KitoPainter {
  final List<double> data;

  LineChartPainter(super.properties, this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = properties.color.value
      ..strokeWidth = properties.strokeWidth.value
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create path for line chart
    final path = ui.Path();
    final stepX = size.width / (data.length - 1);
    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Animate path drawing using pathProgress
    final metrics = path.computeMetrics();
    final extractedPath = ui.Path();

    for (final metric in metrics) {
      final length = metric.length * properties.pathProgress.value;
      final extracted = metric.extractPath(0, length);
      extractedPath.addPath(extracted, Offset.zero);
    }

    canvas.drawPath(extractedPath, paint);

    // Draw data points
    if (properties.pathProgress.value > 0.8) {
      final pointPaint = Paint()
        ..color = properties.color.value
        ..style = PaintingStyle.fill;

      for (var i = 0; i < data.length; i++) {
        final x = i * stepX;
        final normalizedValue = (data[i] - minValue) / range;
        final y = size.height - (normalizedValue * size.height * 0.8 + size.height * 0.1);

        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
    }
  }
}

// Bar Chart Painter
class BarChartPainter extends KitoPainter {
  final List<double> data;

  BarChartPainter(super.properties, this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce(math.max);
    final barWidth = (size.width / data.length) * 0.7;
    final gap = (size.width / data.length) * 0.3;

    for (var i = 0; i < data.length; i++) {
      final normalizedValue = data[i] / maxValue;
      final barHeight = normalizedValue * size.height * 0.9;
      final x = i * (barWidth + gap) + gap / 2;
      final y = size.height - barHeight * properties.scale.value;

      final paint = Paint()
        ..color = properties.color.value.withOpacity(0.7 + i * 0.04)
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(
        x,
        y,
        barWidth,
        barHeight * properties.scale.value,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }
}

// Gauge Painter
class GaugePainter extends KitoPainter {
  final double percentage;

  GaugePainter(super.properties, this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;

    // Background arc
    final bgPaint = Paint()
      ..color = properties.color.value.withOpacity(0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Foreground arc (animated)
    final fgPaint = Paint()
      ..color = properties.color.value
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percentage / 100) * math.pi * 1.5 * properties.pathProgress.value;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      fgPaint,
    );

    // Draw percentage text
    if (properties.pathProgress.value > 0.5) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${(percentage * properties.pathProgress.value).toStringAsFixed(0)}%',
          style: TextStyle(
            color: properties.color.value,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }
}

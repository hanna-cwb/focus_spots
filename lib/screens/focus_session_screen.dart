import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/models.dart';
import '../sensors/pickup_detector.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'session_end_screen.dart';

/// Figma: "02 · Fokus-Session".
class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({
    super.key,
    required this.spotName,
    this.goal = const Duration(minutes: 30),
  });

  final String spotName;

  /// One full turn of the progress ring.
  final Duration goal;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  final _detector = PickupDetector();
  final List<StreamSubscription<dynamic>> _subs = [];
  late final DateTime _start;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = DateTime.now().difference(_start));
    });
    _listenToSensors();
  }

  void _listenToSensors() {
    const interval = SensorInterval.gameInterval;
    try {
      _subs.add(accelerometerEventStream(samplingPeriod: interval).listen(
        (e) {
          final before = _detector.pickups;
          _detector.onAccel([e.x, e.y, e.z]);
          if (_detector.pickups != before && mounted) setState(() {});
        },
        onError: (_) {},
        cancelOnError: true,
      ));
      _subs.add(gyroscopeEventStream(samplingPeriod: interval).listen(
        (e) => _detector.onGyro([e.x, e.y, e.z]),
        onError: (_) {},
        cancelOnError: true,
      ));
    } catch (_) {
      // No motion sensors (e.g. simulator) – the session still works.
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _end() {
    final end = DateTime.now();
    // Tapping "End" means picking the phone up – don't count that one.
    var pickups = _detector.pickups;
    final last = _detector.lastPickup;
    if (last != null && end.difference(last) < const Duration(seconds: 5)) {
      pickups = math.max(0, pickups - 1);
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SessionEndScreen(
        result: FocusSessionResult(
          spotName: widget.spotName,
          start: _start,
          end: end,
          pickups: pickups,
        ),
      ),
    ));
  }

  String get _clock {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  double get _progress {
    final goal = widget.goal.inSeconds;
    if (goal <= 0) return 0;
    return (_elapsed.inSeconds / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false, // Leave only via "End".
        child: Scaffold(
          backgroundColor: AppColors.sessionBg,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 38),
                Text('FOCUS MODE',
                    style: inter(11, weight: w600, color: AppColors.sessionEyebrow)),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _TimerRing(progress: _progress, clock: _clock),
                          const SizedBox(height: 29),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FigmaSvg('assets/figma/session/pin.svg'),
                              const SizedBox(width: 8),
                              Text(widget.spotName,
                                  style: inter(17,
                                      weight: w500, color: AppColors.sessionSpot)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _PickupPill(count: _detector.pickups),
                          const SizedBox(height: 43),
                          Text(
                            'Put your phone down\nwith the screen facing up.',
                            textAlign: TextAlign.center,
                            style: inter(14,
                                color: AppColors.sessionMuted, height: 20 / 14),
                          ),
                          const SizedBox(height: 23),
                          _EndButton(onTap: _end),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({required this.progress, required this.clock});

  final double progress;
  final String clock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 289,
      height: 289,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FigmaSvg('assets/figma/session/timer_base.svg'),
          const FigmaSvg('assets/figma/session/timer_inner.svg'),
          // The Figma file shows a static 81 % arc; here it follows the timer.
          CustomPaint(
            size: const Size(289, 289),
            painter: _ProgressArcPainter(progress),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clock,
                  style: inter(64, weight: w300, color: AppColors.sessionTime)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                const SizedBox(height: 4),
                Text('IN FOCUS',
                    style: inter(11, weight: w500, color: AppColors.sessionMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  _ProgressArcPainter(this.progress);

  final double progress;

  // Matches the Figma arc: 4 px wide along the outer edge of the ring.
  static const _stroke = 4.05;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );
    final paint = Paint()
      ..color = AppColors.sessionProgress
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_ProgressArcPainter old) => old.progress != progress;
}

class _PickupPill extends StatelessWidget {
  const _PickupPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37,
      padding: const EdgeInsets.only(left: 13, right: 20),
      decoration: BoxDecoration(
        color: AppColors.sessionPill,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FigmaSvg('assets/figma/session/hand.svg'),
          const SizedBox(width: 10),
          Text(pickupsLabel(count),
              style: inter(14, color: AppColors.sessionPillText)),
        ],
      ),
    );
  }
}

class _EndButton extends StatelessWidget {
  const _EndButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      height: 43,
      child: Material(
        color: AppColors.sessionButton,
        borderRadius: BorderRadius.circular(23),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text('End',
                style: inter(15, weight: w500, color: AppColors.sessionButtonText)),
          ),
        ),
      ),
    );
  }
}

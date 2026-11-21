import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

enum StatsRange { week, month, year }

/// Figma: "08 · Statistik".
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsRange _range = StatsRange.week;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _weekTitle() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    if (monday.month == sunday.month) {
      return '${_months[monday.month - 1]} ${monday.day}–${sunday.day}';
    }
    return '${_months[monday.month - 1].substring(0, 3)} ${monday.day} – '
        '${_months[sunday.month - 1].substring(0, 3)} ${sunday.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final minutes = state.weekMinutes;
    final total = state.weekTotalMinutes;
    var best = 0;
    for (var i = 1; i < minutes.length; i++) {
      if (minutes[i] > minutes[best]) best = i;
    }
    final favorite = state.spots.isEmpty ? '–' : state.spots.first.name;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              eyebrow: 'YOUR PROGRESS',
              title: 'Every minute counts.',
              titleSize: 29,
              subtitle: 'Small steps. Noticeably more focus.',
              subtitleSize: 14,
            ),
            const SizedBox(height: 22),
            _RangeSwitch(
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 17, 21, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_weekTitle(), style: inter(13, weight: w600)),
                      ),
                      // TODO: navigate between weeks once history is stored.
                      const FigmaSvg('assets/figma/stats/chevron_left.svg'),
                      const SizedBox(width: 16),
                      const FigmaSvg('assets/figma/stats/chevron_right.svg'),
                    ],
                  ),
                  const SizedBox(height: 19),
                  const Eyebrow('FOCUS MINUTES', size: 9, color: AppColors.muted),
                  const SizedBox(height: 20),
                  _WeekChart(minutes: minutes, highlight: best, labels: _days),
                  const SizedBox(height: 17),
                  Text(
                    total == 0
                        ? 'No focus time yet this week.'
                        : '${_dayNames[best]} was your strongest day.',
                    style: inter(10, weight: w500, color: AppColors.petrol),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total time',
                    value: formatMinutesShort(total),
                    unit: 'min',
                    unitSize: 12,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    label: 'Pickups / hour',
                    value: formatOneDecimal(state.weekPickupsPerHour),
                    unit: '${state.weekPickups} total',
                    unitSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              height: 68,
              padding: const EdgeInsets.only(left: 14, right: 28),
              child: Row(
                children: [
                  const IconTile(asset: 'assets/figma/stats/library.svg'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Favorite spot', style: inter(11, color: AppColors.muted)),
                        const SizedBox(height: 7),
                        Text(favorite,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(17, weight: w600)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(formatMinutesLong(state.favoriteSpotMinutes),
                        style: inter(12, weight: w500, color: AppColors.petrol)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const FigmaSvg('assets/figma/stats/leaf.svg'),
                  const SizedBox(width: 9),
                  Text(
                    '${state.sharedSpotMinutes ~/ 60} h studied at shared spots',
                    style: inter(11, weight: w500, color: AppColors.petrol),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.value, required this.onChanged});

  final StatsRange value;
  final ValueChanged<StatsRange> onChanged;

  static const _labels = {
    StatsRange.week: 'Week',
    StatsRange.month: 'Month',
    StatsRange.year: 'Year',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final r in StatsRange.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: r == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    _labels[r]!,
                    style: inter(
                      12,
                      weight: r == value ? w600 : w500,
                      color: r == value ? AppColors.petrol : AppColors.muted,
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

/// Bar chart Mon–Sun with grid lines at 0 / 60 / 120 minutes.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.minutes, required this.highlight, required this.labels});

  final List<int> minutes;
  final int highlight;
  final List<String> labels;

  static const _plotHeight = 114.0; // 120 min in the design
  static const _top = 6.0; // offset of the top grid line
  static const _labelWidth = 27.0; // y-axis labels, chart starts 43 px into the card
  static const _barWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final maxValue = minutes.fold<int>(0, (a, b) => a > b ? a : b);
    // Keep the design's 120-minute scale unless a day exceeds it.
    final scaleMax = ((maxValue / 60).ceil() * 60).clamp(120, 24 * 60).toDouble();
    final gridValues = [scaleMax.round(), (scaleMax / 2).round(), 0];

    return SizedBox(
      height: 147,
      child: LayoutBuilder(builder: (context, c) {
        final plotWidth = c.maxWidth - _labelWidth;
        final column = plotWidth / minutes.length;
        final baseline = _top + _plotHeight;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var g = 0; g < 3; g++) ...[
              Positioned(
                left: _labelWidth,
                right: 0,
                top: _top + g * _plotHeight / 2,
                child: const Divider(height: 1, thickness: 1, color: AppColors.chartGrid),
              ),
              Positioned(
                left: -4,
                top: _top + g * _plotHeight / 2 - 6,
                child: Text('${gridValues[g]}',
                    style: inter(9, color: AppColors.muted)),
              ),
            ],
            for (var i = 0; i < minutes.length; i++) ...[
              Positioned(
                left: _labelWidth + column * i + (column - _barWidth) / 2,
                top: baseline - _barHeight(minutes[i], scaleMax),
                width: _barWidth,
                height: _barHeight(minutes[i], scaleMax),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == highlight && minutes[i] > 0
                        ? AppColors.petrol
                        : AppColors.chartBar,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: _labelWidth + column * i,
                width: column,
                top: 135,
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: inter(10, weight: w500, color: AppColors.muted),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  double _barHeight(int value, double scaleMax) {
    final h = value / scaleMax * _plotHeight;
    return h < 4 ? 4 : h; // empty days show a small stub
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.unitSize,
  });

  final String label;
  final String value;
  final String unit;
  final double unitSize;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      height: 106,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: inter(12, color: AppColors.muted)),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: inter(30, weight: w600)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(unitSize, color: AppColors.muted)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

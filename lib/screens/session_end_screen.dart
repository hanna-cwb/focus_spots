import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Figma: "03 · Session-Ende".
class SessionEndScreen extends StatelessWidget {
  const SessionEndScreen({super.key, required this.result});

  final FocusSessionResult result;

  String get _feedback {
    final pph = result.pickupsPerHour;
    final value = formatOneDecimal(pph);
    if (result.pickups == 0) return 'Perfect – not a single pickup.';
    if (pph <= 2) return 'Great – only $value pickups per hour.';
    if (pph <= 5) return 'Solid – $value pickups per hour.';
    return '$value pickups per hour. Next time it will be fewer.';
  }

  String get _timeRange {
    final now = DateTime.now();
    final sameDay = now.year == result.start.year &&
        now.month == result.start.month &&
        now.day == result.start.day;
    final day = sameDay ? 'Today' : '${result.start.day}.${result.start.month}.';
    return '$day, ${formatClock(result.start)} – ${formatClock(result.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = result.duration.inMinutes;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 35),
              const Eyebrow('SESSION COMPLETE'),
              const SizedBox(height: 38),
              const SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FigmaSvg('assets/figma/end/success.svg'),
                    FigmaSvg('assets/figma/end/check.svg'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("Time that's yours.", style: inter(28, weight: w600)),
              const SizedBox(height: 7),
              Text('One step closer to your goal.',
                  style: inter(15, color: AppColors.muted)),
              const SizedBox(height: 38),
              AppCard(
                padding: const EdgeInsets.fromLTRB(20, 21, 20, 21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('YOUR SESSION', size: 10, color: AppColors.muted),
                    const SizedBox(height: 17),
                    Text(
                      minutes < 1 ? '< 1 min' : formatMinutesLong(minutes),
                      style: inter(38, weight: w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Focus time', style: inter(13, color: AppColors.muted)),
                    const SizedBox(height: 20),
                    const Divider(height: 1, thickness: 1, color: AppColors.cardDivider),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _Fact(
                            icon: 'assets/figma/end/hand.svg',
                            text: pickupsLabel(result.pickups),
                          ),
                        ),
                        Expanded(
                          child: _Fact(
                            icon: 'assets/figma/end/pin.svg',
                            text: result.spotName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text(_timeRange, style: inter(12, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 49,
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _feedback,
                  textAlign: TextAlign.center,
                  style: inter(14, weight: w500, color: AppColors.petrol),
                ),
              ),
              const SizedBox(height: 34),
              PrimaryButton(
                label: 'Save',
                fontSize: 17,
                onPressed: () {
                  AppScope.read(context).addSession(result);
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  minimumSize: const Size(120, 44),
                ),
                child: Text('Discard',
                    style: inter(15, weight: w500, color: AppColors.muted)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FigmaSvg(icon),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: inter(15, weight: w500),
          ),
        ),
      ],
    );
  }
}

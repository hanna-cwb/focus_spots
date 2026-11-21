import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Figma: "01 · Home" (in a spot) and "12 · Home – kein Spot".
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onStartFocus,
    required this.onOpenSpots,
    required this.onOpenFriends,
  });

  final VoidCallback onStartFocus;
  final VoidCallback onOpenSpots;
  final VoidCallback onOpenFriends;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spot = state.currentSpot;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              eyebrow: 'YOUR MOMENT. YOUR FOCUS.',
              title: 'Good to see you.',
              subtitle: 'A good place to make progress.',
            ),
            const SizedBox(height: 26),
            _CurrentSpotCard(spot: spot, onTap: onOpenSpots),
            const SizedBox(height: 38),
            Center(child: _StartFocusButton(onTap: onStartFocus)),
            const SizedBox(height: 21),
            Center(
              child: Eyebrow('THIS WEEK', size: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '${formatMinutesLong(state.weekTotalMinutes)}  ·  '
                '${pickupsLabel(state.weekPickups)}',
                style: inter(18, weight: w500),
              ),
            ),
            const SizedBox(height: 35),
            Text('Focused together', style: inter(15, weight: w600)),
            const SizedBox(height: 20),
            _FriendsInFocus(friends: state.studyingFriends, onTap: onOpenFriends),
            const SizedBox(height: 20),
            Text('Your next small step is waiting.',
                style: inter(13, color: AppColors.muted)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CurrentSpotCard extends StatelessWidget {
  const _CurrentSpotCard({required this.spot, required this.onTap});

  final Spot? spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inSpot = spot != null;
    return AppCard(
      height: 86,
      onTap: onTap,
      padding: const EdgeInsets.only(left: 16, right: 25),
      child: Row(
        children: [
          const IconTile(asset: 'assets/figma/home/pin.svg', size: 48, radius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inSpot ? "You're in a spot" : 'YOUR LOCATION',
                  style: inter(13, color: AppColors.muted),
                ),
                SizedBox(height: inSpot ? 6 : 9),
                Text(
                  inSpot ? spot!.name : 'No spot nearby',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(inSpot ? 20 : 16, weight: w600),
                ),
              ],
            ),
          ),
          FigmaSvg(inSpot
              ? 'assets/figma/home/live_status.svg'
              : 'assets/figma/home/live_status_off.svg'),
        ],
      ),
    );
  }
}

class _StartFocusButton extends StatelessWidget {
  const _StartFocusButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 239,
      height: 239,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const FigmaSvg('assets/figma/home/focus_aura.svg'),
          const FigmaSvg('assets/figma/home/focus_start.svg'),
          Positioned(
            top: 51,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FigmaSvg('assets/figma/home/play.svg'),
                const SizedBox(height: 20),
                Text('Start focus',
                    style: inter(21, weight: w600, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Time for what matters',
                    style: inter(12, color: Colors.white)),
              ],
            ),
          ),
          // Tap target over the inner circle.
          SizedBox(
            width: 211,
            height: 211,
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Semantics(button: true, label: 'Start focus'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsInFocus extends StatelessWidget {
  const _FriendsInFocus({required this.friends, required this.onTap});

  final List<Friend> friends;
  final VoidCallback onTap;

  String get _names {
    final names = friends.map((f) => f.name).toList();
    if (names.length <= 1) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Text('None of your friends is studying right now.',
          style: inter(12, color: AppColors.muted));
    }
    final shown = friends.take(3).toList();
    final stackWidth = 36.0 + 29 * (shown.length - 1) + 4;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // The avatars start 4 px left of the content edge in the design.
          Transform.translate(
            offset: const Offset(-4, 0),
            child: SizedBox(
              width: stackWidth,
              height: 36,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: 29.0 * i,
                      child: FriendAvatar(friend: shown[i], size: 36),
                    ),
                  Positioned(
                    left: stackWidth - 8,
                    top: 25,
                    child: const FigmaSvg('assets/figma/home/online.svg'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_names ${friends.length == 1 ? 'is' : 'are'} studying right now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(12, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  friends.length == 1
                      ? '1 friend is in focus'
                      : '${friends.length} friends are in focus',
                  style: inter(14, weight: w500, color: AppColors.petrol),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

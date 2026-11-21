import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Figma: "06 · Freunde".
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  String _weekLabel() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final m1 = months[monday.month - 1];
    final m2 = months[sunday.month - 1];
    return m1 == m2
        ? '$m1 ${monday.day}–${sunday.day}'
        : '$m1 ${monday.day} – $m2 ${sunday.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final studying = state.studyingFriends.length;
    final ranking = state.ranking;
    final maxMinutes = ranking.isEmpty
        ? 1
        : ranking.map((r) => r.minutes).reduce((a, b) => a > b ? a : b);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              eyebrow: 'STAY ON TRACK TOGETHER',
              title: 'Your study circle',
              subtitle: 'Each on your own. Never alone.',
              subtitleSize: 13,
              trailing: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showAppSheet<void>(context, (_) => const AddFriendSheet()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Add friend',
                          style: inter(12, weight: w600, color: AppColors.petrol)),
                      const SizedBox(width: 18),
                      const FigmaSvg('assets/figma/friends/plus.svg'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 41,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Dot(
                    size: 7,
                    color: studying > 0 ? AppColors.petrol : AppColors.offline,
                  ),
                  const SizedBox(width: 11),
                  Text(
                    studying == 1
                        ? '1 friend studying now'
                        : '$studying friends studying now',
                    style: inter(13, weight: w500, color: AppColors.petrol),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final friend in state.friends) ...[
              _FriendTile(friend: friend),
              const SizedBox(height: 7),
            ],
            const SizedBox(height: 23),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('This week', style: inter(19, weight: w600))),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 24),
                  child: Text(_weekLabel(),
                      style: inter(10, weight: w500, color: AppColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 19),
              child: Column(
                children: [
                  for (var i = 0; i < ranking.length; i++) ...[
                    if (i > 0) const SizedBox(height: 18),
                    _RankingRow(
                      rank: i + 1,
                      entry: ranking[i],
                      fraction: ranking[i].minutes / maxMinutes,
                    ),
                  ],
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

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final status = friend.isStudying
        ? 'studying at ${friend.studyingAt} for ${friend.studyingFor?.inMinutes ?? 0} min'
        : 'offline';

    return AppCard(
      height: 67,
      radius: 14,
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FriendAvatar(friend: friend, size: 44),
                Positioned(
                  left: 33,
                  top: 32,
                  child: Dot(
                    size: 9,
                    color: friend.isStudying ? AppColors.petrol : AppColors.offline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: inter(16, weight: w600)),
                const SizedBox(height: 7),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: inter(11,
                      color: friend.isStudying ? AppColors.petrol : AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.rank, required this.entry, required this.fraction});

  final int rank;
  final RankingEntry entry;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(rank.toString().padLeft(2, '0'),
                style: inter(11, weight: w500, color: AppColors.muted)),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name, style: inter(13, weight: w600)),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                          child: ColoredBox(color: AppColors.barTrack)),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: entry.isMe ? AppColors.petrol : AppColors.barOther,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 50,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(formatMinutesShort(entry.minutes),
                style: inter(12, weight: w500, color: AppColors.petrol)),
          ),
        ),
      ],
    );
  }
}

/// Figma: "07 · Freund hinzufügen" (bottom sheet).
class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    // TODO: send the request via Firestore.
    messenger.showSnackBar(
      SnackBar(content: Text('Friend request sent to code ${_code.text}.')),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final myCode = AppScope.of(context).myFriendCode;
    final digits = _code.text;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 28),
          Text('Better together.', style: inter(26, weight: w600)),
          const SizedBox(height: 9),
          Text('Connect with your study circle.',
              style: inter(14, color: AppColors.muted)),
          const SizedBox(height: 33),
          Text('Enter a 6-digit friend code', style: inter(13, weight: w500)),
          const SizedBox(height: 14),
          // Six boxes on top of an invisible text field that takes the input.
          SizedBox(
            height: 58,
            child: Stack(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 6; i++) ...[
                      if (i > 0) const SizedBox(width: 9),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: _focus.hasFocus && i == digits.length
                                ? Border.all(color: AppColors.petrol, width: 1.5)
                                : null,
                          ),
                          child: Text(
                            i < digits.length ? digits[i] : '',
                            style: inter(24, weight: w500),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _code,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Send request',
            onPressed: digits.length == 6 ? _send : null,
          ),
          const SizedBox(height: 30),
          const Divider(height: 1, thickness: 1, color: AppColors.sheetDivider),
          const SizedBox(height: 27),
          const Eyebrow('YOUR FRIEND CODE', size: 10, color: AppColors.muted),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  myCode.split('').join(' '),
                  style: inter(29, weight: w600),
                ),
              ),
              IconButton(
                tooltip: 'Copy code',
                onPressed: () => _copyCode(myCode),
                icon: const FigmaSvg('assets/figma/friends/copy.svg'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _copied ? 'Code copied.' : 'Share your code. Focus connects.',
            style: inter(13, color: _copied ? AppColors.petrol : AppColors.muted),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

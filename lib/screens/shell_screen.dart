import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../widgets/focus_bottom_nav.dart';
import 'focus_session_screen.dart';
import 'friends_screen.dart';
import 'home_screen.dart';
import 'spots_screen.dart';
import 'stats_screen.dart';

/// Main screen with the four tabs Home · Spots · Friends · Stats.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.read(context).startSpotDetection();
  }

  void _startFocus() {
    final spot = AppScope.read(context).currentSpot;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FocusSessionScreen(spotName: spot?.name ?? 'No spot'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              onStartFocus: _startFocus,
              onOpenSpots: () => setState(() => _tab = 1),
              onOpenFriends: () => setState(() => _tab = 2),
            ),
            const SpotsScreen(),
            const FriendsScreen(),
            const StatsScreen(),
          ],
        ),
        bottomNavigationBar: FocusBottomNav(
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

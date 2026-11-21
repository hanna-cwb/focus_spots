import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_spots/main.dart';
import 'package:focus_spots/screens/shell_screen.dart';
import 'package:focus_spots/state/app_state.dart';
import 'package:focus_spots/theme/app_theme.dart';

void main() {
  testWidgets('shows onboarding when location is not granted', (tester) async {
    await tester.pumpWidget(const FocusSpotsApp());
    await tester.pumpAndSettle();

    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('01 / YOUR PLACES'), findsOneWidget);
  });

  testWidgets('tabs switch between Home, Spots, Friends and Stats', (tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppScope(
      state: AppState(),
      child: MaterialApp(theme: buildAppTheme(), home: const ShellScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Good to see you.'), findsOneWidget);

    await tester.tap(find.text('Spots'));
    await tester.pumpAndSettle();
    expect(find.text('Saved spots'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Your study circle'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Every minute counts.'), findsOneWidget);
  });
}

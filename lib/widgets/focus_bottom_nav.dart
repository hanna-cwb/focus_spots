import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;

  /// Base name in assets/figma/nav/, `<icon>.svg` and `<icon>_active.svg`.
  final String icon;
}

const _items = [
  _NavItem('Home', 'home'),
  _NavItem('Spots', 'spots'),
  _NavItem('Friends', 'friends'),
  _NavItem('Stats', 'stats'),
];

/// Tab bar from the design: white, hairline on top, pill behind the active icon.
class FocusBottomNav extends StatelessWidget {
  const FocusBottomNav({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.navDivider)),
      ),
      // The labels reach slightly into the home-indicator area, as in Figma.
      child: Padding(
        padding: EdgeInsets.only(
          bottom: math.max(0.0, MediaQuery.paddingOf(context).bottom - 8),
        ),
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _tab(i, _items[i], i == index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, _NavItem item, bool active) {
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: () => onTap(i),
        highlightShape: BoxShape.rectangle,
        radius: 40,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 54,
              height: 29,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.navActive : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: FigmaSvg(
                'assets/figma/nav/${item.icon}${active ? '_active' : ''}.svg',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: inter(
                11,
                weight: active ? w600 : w500,
                color: active ? AppColors.petrol : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

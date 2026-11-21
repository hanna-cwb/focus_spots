import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// SVG exported from Figma, rendered at its own root width/height.
class FigmaSvg extends StatelessWidget {
  const FigmaSvg(this.asset, {super.key});

  /// Full asset path, e.g. 'assets/figma/home/pin.svg'.
  final String asset;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(asset);
}

/// Small uppercase label above titles ("YOUR STUDY SPOTS").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.petrol, this.size = 11});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: inter(size, weight: w600, color: color));
}

/// Eyebrow + big title + optional subtitle, used at the top of every tab.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleSize = 28,
    this.subtitle,
    this.subtitleSize = 15,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final double titleSize;
  final String? subtitle;
  final double subtitleSize;

  /// Shown at the end of the subtitle row (e.g. "Add friend").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Eyebrow(eyebrow),
        const SizedBox(height: 13),
        Text(title, style: inter(titleSize, weight: w600)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(subtitle!,
                    style: inter(subtitleSize, color: AppColors.muted)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ],
    );
  }
}

/// White rounded surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 16,
    this.height,
    this.color = AppColors.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double? height;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Full-width petrol button ("Save", "Allow", "Save spot" …).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
    this.radius = 16,
    this.fontSize = 16,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final double fontSize;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: enabled ? AppColors.petrol : AppColors.petrol.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 12)],
              Text(label,
                  style: inter(fontSize, weight: w600, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Light petrol square with an icon in the middle (spot icons).
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.asset, this.size = 42, this.radius = 12});

  final String asset;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: FigmaSvg(asset),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key, required this.size, required this.color, this.border});

  final double size;
  final Color color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: border),
      );
}

/// Round friend avatar with a 2 px background-coloured ring. Falls back to the
/// initial when no image is available.
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({super.key, required this.friend, required this.size});

  final Friend friend;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = Container(
      color: AppColors.tint,
      alignment: Alignment.center,
      child: Text(
        friend.name.characters.first.toUpperCase(),
        style: inter(size * 0.4, weight: w600, color: AppColors.petrol),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: ClipOval(
        child: friend.avatarAsset == null
            ? initial
            : Image.asset(
                friend.avatarAsset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => initial,
              ),
      ),
    );
  }
}

/// Grab handle at the top of the bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          width: 41,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.sheetHandle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// Opens one of the app's bottom sheets with the design's scrim and corners.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    barrierColor: AppColors.scrim.withValues(alpha: 0.27),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

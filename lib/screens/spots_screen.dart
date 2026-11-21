import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Figma: "04 · Spots".
class SpotsScreen extends StatelessWidget {
  const SpotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final spots = state.spots;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              eyebrow: 'YOUR STUDY SPOTS',
              title: 'Good places. Good focus.',
              titleSize: 27,
              subtitle: 'Staying on track is easier here.',
              subtitleSize: 14,
            ),
            const SizedBox(height: 25),
            _SpotsMap(highlight: state.currentSpot?.name ?? spots.first.name),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text('Saved spots', style: inter(18, weight: w600))),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    spots.length == 1 ? '1 place' : '${spots.length} places',
                    style: inter(12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final spot in spots) ...[
              _SpotTile(spot: spot, isHere: spot == state.currentSpot),
              const SizedBox(height: 11),
            ],
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Save this spot',
              height: 50,
              radius: 25,
              fontSize: 15,
              icon: const FigmaSvg('assets/figma/spots/plus.svg'),
              onPressed: () => showAppSheet<void>(
                context,
                (_) => const SaveSpotSheet(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SpotTile extends StatelessWidget {
  const _SpotTile({required this.spot, required this.isHere});

  final Spot spot;
  final bool isHere;

  @override
  Widget build(BuildContext context) {
    final radius = '${spot.radiusM.round()} m';
    final detail = isHere
        ? "You're here"
        : (spot.shared ? 'Shared spot' : 'Only you');

    return AppCard(
      height: 66,
      padding: const EdgeInsets.only(left: 12, right: 18),
      child: Row(
        children: [
          IconTile(asset: spot.iconAsset),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spot.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: inter(15, weight: w600)),
                const SizedBox(height: 7),
                Text(
                  '$radius · $detail',
                  style: inter(11, color: isHere ? AppColors.petrol : AppColors.muted),
                ),
              ],
            ),
          ),
          FigmaSvg(spot.shared
              ? 'assets/figma/spots/shared.svg'
              : 'assets/figma/spots/lock.svg'),
        ],
      ),
    );
  }
}

/// Stylised map from the design. Drawn at 345 × 216 and scaled to the width.
class _SpotsMap extends StatelessWidget {
  const _SpotsMap({required this.highlight});

  final String highlight;

  static const _w = 345.0;
  static const _h = 216.0;

  Widget _box(double l, double t, double w, double h, Color c, [double r = 0]) =>
      Positioned(
        left: l,
        top: t,
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
        ),
      );

  Widget _marker(double l, double t) => Positioned(
        left: l,
        top: t,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.petrol, shape: BoxShape.circle),
          child: const FigmaSvg('assets/figma/spots/marker_pin.svg'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _w / _h,
        child: FittedBox(
          child: SizedBox(
            width: _w,
            height: _h,
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: AppColors.mapBg)),
                _box(217, 13, 110, 89, AppColors.mapPark, 27),
                _box(91, 140, 107, 80, AppColors.mapCampus, 12),
                _box(0, 65, _w, 13, AppColors.mapStreet),
                _box(0, 129, _w, 11, AppColors.mapStreet),
                _box(64, 0, 12, _h, AppColors.mapStreet),
                _box(198, 0, 15, _h, AppColors.mapStreet),
                _box(280, 0, 9, _h, AppColors.mapStreet),
                Positioned(
                  left: 91,
                  top: 88,
                  child: Text('CAMPUS',
                      style: inter(9, weight: w500, color: AppColors.mapLabel)),
                ),
                Positioned(
                  left: 240,
                  top: 31,
                  child: Text('CITY PARK',
                      style: inter(8, weight: w500, color: AppColors.mapLabel)),
                ),
                _marker(139, 46),
                _marker(245, 144),
                _marker(29, 141),
                // Your position
                _box(166, 111, 34, 34, AppColors.mapRadius, 17),
                _box(178, 123, 10, 10, AppColors.petrol, 5),
                // Label of the highlighted spot
                Positioned(
                  left: 104,
                  top: 12,
                  child: Container(
                    height: 26,
                    constraints: const BoxConstraints(minWidth: 112, maxWidth: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      highlight,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(10, weight: w600),
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

/// Figma: "05 · Spot speichern" (bottom sheet).
class SaveSpotSheet extends StatefulWidget {
  const SaveSpotSheet({super.key});

  @override
  State<SaveSpotSheet> createState() => _SaveSpotSheetState();
}

class _SaveSpotSheetState extends State<SaveSpotSheet> {
  final _name = TextEditingController();
  double _radius = 100;
  bool _shared = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<Position?> _currentPosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = AppScope.read(context);
    final position = await _currentPosition();
    if (!mounted) return;
    state.addSpot(Spot(
      name: _name.text.trim(),
      kind: SpotKind.other,
      radiusM: _radius,
      shared: _shared,
      latitude: position?.latitude,
      longitude: position?.longitude,
    ));
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (position == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Spot saved without location – GPS not available.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 27),
          Text('New study spot', style: inter(24, weight: w600)),
          const SizedBox(height: 9),
          Text('Your current location will be saved.',
              style: inter(13, color: AppColors.muted)),
          const SizedBox(height: 27),
          Text('Spot name', style: inter(13, weight: w500)),
          const SizedBox(height: 9),
          Container(
            height: 54,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _name,
              autofocus: false,
              textCapitalization: TextCapitalization.sentences,
              style: inter(16),
              cursorColor: AppColors.petrol,
              decoration: InputDecoration.collapsed(
                hintText: 'e.g. Library',
                hintStyle: inter(16, color: AppColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: Text('Detection radius', style: inter(14, weight: w500))),
              Text('${_radius.round()} m',
                  style: inter(14, weight: w600, color: AppColors.petrol)),
            ],
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.petrol,
              inactiveTrackColor: AppColors.sliderTrack,
              thumbColor: AppColors.petrol,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 0,
                pressedElevation: 0,
              ),
              trackShape: const RoundedRectSliderTrackShape(),
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              min: 25,
              max: 500,
              divisions: 19, // 25 m steps
              value: _radius,
              onChanged: (v) => setState(() => _radius = v),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('25 m', style: inter(11, color: AppColors.muted)),
              Text('500 m', style: inter(11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 33),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shared spot', style: inter(16, weight: w500)),
                    const SizedBox(height: 7),
                    Text('Visible to your friends too',
                        style: inter(12, color: AppColors.muted)),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _shared,
                activeTrackColor: AppColors.petrol,
                onChanged: (v) => setState(() => _shared = v),
              ),
            ],
          ),
          const SizedBox(height: 44),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save spot',
            onPressed: _name.text.trim().isEmpty || _saving ? null : _save,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

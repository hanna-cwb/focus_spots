import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class _Step {
  const _Step({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.image,
    required this.fallbackIcon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String image;
  final IconData fallbackIcon;
}

const _steps = [
  _Step(
    eyebrow: '01 / YOUR PLACES',
    title: 'Your focus has\na place.',
    body: 'We need your location to recognise your study spots.',
    image: 'assets/figma/onboarding/location.png',
    fallbackIcon: Icons.location_on_outlined,
  ),
  _Step(
    eyebrow: '02 / YOUR FOCUS',
    title: 'Reach less.\nAchieve more.',
    body: 'Allow Motion & Fitness so we can tell how often you pick up your phone.',
    image: 'assets/figma/onboarding/phone.png',
    fallbackIcon: Icons.smartphone_outlined,
  ),
  _Step(
    eyebrow: '03 / YOUR RHYTHM',
    title: 'A small nudge.\nYour moment.',
    body: 'Allow notifications so we can remind you of your focus time.',
    image: 'assets/figma/onboarding/notification.png',
    fallbackIcon: Icons.notifications_none_outlined,
  ),
];

/// Figma: "09–11 · Onboarding" (location, motion, notifications).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_index == _steps.length - 1) {
      widget.onFinished();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _allow() async {
    setState(() => _busy = true);
    try {
      switch (_index) {
        case 0:
          if (await Geolocator.isLocationServiceEnabled()) {
            final perm = await Geolocator.checkPermission();
            if (perm == LocationPermission.denied) {
              await Geolocator.requestPermission();
            }
          }
        case 1:
          // Accelerometer and gyroscope need no runtime permission on iOS.
          break;
        case 2:
          // TODO: request notification permission (e.g. firebase_messaging).
          break;
      }
    } catch (_) {
      // Ignore – the user can still grant permissions in Settings later.
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: Text('focus',
                        style: inter(25, weight: w600, color: AppColors.petrol)),
                  ),
                  TextButton(
                    onPressed: _next,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Later',
                        style: inter(12, weight: w500, color: AppColors.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  for (var i = 0; i < _steps.length; i++) ...[
                    if (i > 0) const SizedBox(width: 9),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= _index ? AppColors.petrol : AppColors.onboardingStep,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _StepPage(step: _steps[i]),
                ),
              ),
              PrimaryButton(label: 'Allow', onPressed: _busy ? null : _allow),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFECEFEA),
      alignment: Alignment.center,
      child: Icon(step.fallbackIcon, size: 72, color: AppColors.petrol),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 37),
        Flexible(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AspectRatio(
                aspectRatio: 321 / 290,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    step.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => placeholder,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 27),
        Eyebrow(step.eyebrow, size: 10),
        const SizedBox(height: 14),
        Text(step.title, style: inter(32, weight: w600, height: 38 / 32)),
        const SizedBox(height: 21),
        Text(step.body, style: inter(15, color: AppColors.muted, height: 23 / 15)),
        const SizedBox(height: 40),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Colours taken from the Figma file "FocusSpots" (V2 · Petrol).
class AppColors {
  AppColors._();

  // Light screens
  static const background = Color(0xFFF6F8F4);
  static const card = Colors.white;
  static const ink = Color(0xFF18363C);
  static const muted = Color(0xFF727F81);
  static const petrol = Color(0xFF1D6E7C);
  static const tint = Color(0xFFE6EFF1);
  static const navActive = Color(0xFFE8F0F2);
  static const navDivider = Color(0xFFE2E8E9);
  static const cardDivider = Color(0xFFE5EBEC);
  static const sheetDivider = Color(0xFFDEE5E7);
  static const sheetHandle = Color(0xFFC8D0D2);
  static const scrim = Color(0xFF102529);
  static const offline = Color(0xFFBDC5C7);

  // Bars & tracks
  static const barTrack = Color(0xFFE9F0F1);
  static const barOther = Color(0xFFABC8CE);
  static const chartBar = Color(0xFFBED6DB);
  static const chartGrid = Color(0xFFEBF0F1);
  static const sliderTrack = Color(0xFFDCE4E6);
  static const segmentBg = Color(0xFFE3EBED);
  static const onboardingStep = Color(0xFFDAE5E7);

  // Map illustration
  static const mapBg = Color(0xFFDDE9EC);
  static const mapPark = Color(0xFFBCD9DF);
  static const mapCampus = Color(0xFFC8DDE1);
  static const mapStreet = Color(0xFFF9FBF5);
  static const mapLabel = Color(0xFF7B8E92);
  static const mapRadius = Color(0xFFC3D4D7);

  // Focus session (dark)
  static const sessionBg = Color(0xFF0E191B);
  static const sessionEyebrow = Color(0xFF9CB1B5);
  static const sessionTime = Color(0xFFE8F1F3);
  static const sessionMuted = Color(0xFF91A6AA);
  static const sessionSpot = Color(0xFFD5E0E2);
  static const sessionPill = Color(0xFF1B2D30);
  static const sessionPillText = Color(0xFFADBDC0);
  static const sessionButton = Color(0xFF203337);
  static const sessionButtonText = Color(0xFFC1CDD0);
  static const sessionProgress = Color(0xFF97C1C9);
}

/// Inter in the weights used by the design (bundled in assets/fonts).
TextStyle inter(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

const w300 = FontWeight.w300;
const w400 = FontWeight.w400;
const w500 = FontWeight.w500;
const w600 = FontWeight.w600;

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.petrol,
    primary: AppColors.petrol,
    surface: AppColors.background,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: inter(14, color: Colors.white),
    ),
  );
}

import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing & Padding
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(spaceMD);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: spaceMD);
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: spaceMD);

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusPill = 999.0;

  static final BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Icon Sizes
  static const double iconSM = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Avatar Sizes
  static const double avatarSM = 36.0;
  static const double avatarMD = 48.0;
  static const double avatarLG = 64.0;
  static const double avatarXL = 96.0;

  // Button Heights
  static const double buttonHeight = 52.0;
  static const double inputHeight = 56.0;
}

import 'package:flutter/material.dart';

/// Shared animation timing/easing constants for iOS-style transitions,
/// so every widget in the app animates with the same feel.
class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve curveOut = Curves.easeOutCubic;
  static const Curve curveIn = Curves.easeInCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
}

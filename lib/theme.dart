// lib/theme.dart
//
// Every color and text style in one place, taken from the v2 Figma design.
// If you want to change the look, change it here and the whole app follows.

import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const moss = Color(0xFFD9DFC8); // page background (sage green)
  static const mossDeep = Color(0xFFC9D2B3); // background blob
  static const sand = Color(0xFFE7D9BE); // background blob
  static const linen = Color(0xFFF8F1E4); // cards and tokens
  static const parchment = Color(0xFFF1E4CC); // clue message

  // Text
  static const bark = Color(0xFF3A2C24); // main text
  static const barkMuted = Color(0xFF6E5A4B); // secondary text
  static const faded = Color(0xFF9A8B7B); // "In use" labels

  // Accents
  static const pine = Color(0xFF3E5D49); // primary buttons
  static const ember = Color(0xFFE8913A); // highlights, right-spot clue
  static const emberLight = Color(0xFFFFD08A);

  // Wooden board
  static const woodLight = Color(0xFFBE8A5D);
  static const wood = Color(0xFFA6744A);
  static const woodDark = Color(0xFF8C6040);
  static const woodRow = Color(0xFFD7A877); // the row being played
  static const rowNumber = Color(0xFF6B4A30);
  static const socket = Color(0xFF6E4A30);
  static const socketDeep = Color(0xFF4F3322);
  static const ash = Color(0xFF4A3122); // "not in the lock" clue

  // Disabled button
  static const disabledBg = Color(0xFFD3C6B0);
  static const disabledFg = Color(0xFF8A7A6A);
}

// The fonts are bundled inside the app (assets/fonts, listed in
// pubspec.yaml), so the game works completely offline.

/// Headings use Grandstander: rounded and a little hand-made.
TextStyle heading(
  double size, {
  FontWeight weight = FontWeight.w800,
  Color color = AppColors.bark,
}) {
  return TextStyle(
    fontFamily: 'Grandstander',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.1,
  );
}

/// Body text uses Nunito: soft and very readable.
TextStyle body(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color color = AppColors.bark,
  double height = 1.45,
}) {
  return TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

/// The soft shadow under tokens, cards and the board.
List<BoxShadow> softShadow({double blur = 6, double y = 3, double opacity = 0.28}) {
  return [
    BoxShadow(
      color: const Color(0xFF3A2210).withAlpha(alpha(opacity)),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];
}

/// Turns an opacity like 0.55 into the 0-255 alpha value Flutter wants.
int alpha(double opacity) => (opacity * 255).round();

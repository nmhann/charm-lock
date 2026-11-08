// lib/widgets/cabin_door.dart
//
// The cabin door picture on the start screen, built only from Flutter
// widgets (no image files). It's drawn at a fixed 460 x 660 size and
// FittedBox scales it to whatever height we ask for.

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../theme.dart';
import 'charm_art.dart';

class CabinDoor extends StatelessWidget {
  final double height;
  const CabinDoor({super.key, this.height = 660});

  static const double _w = 460;
  static const double _h = 660;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: height * _w / _h,
        child: FittedBox(child: SizedBox(width: _w, height: _h, child: _door())),
      ),
    );
  }

  Widget _door() {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(230),
      topRight: Radius.circular(230),
      bottomLeft: Radius.circular(18),
      bottomRight: Radius.circular(18),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC48F62), Color(0xFFA87449)],
        ),
        boxShadow: softShadow(blur: 48, y: 24, opacity: 0.3),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // vertical plank seams
            for (var i = 1; i < 5; i++)
              Positioned(
                left: i * 92 - 1.5,
                top: 0,
                bottom: 0,
                child: Container(width: 3, color: AppColors.woodDark.withAlpha(alpha(0.55))),
              ),
            // horizontal braces
            for (final y in const [150.0, 500.0])
              Positioned(
                left: 0,
                right: 0,
                top: y,
                child: Container(height: 26, color: AppColors.woodDark.withAlpha(alpha(0.7))),
              ),
            // glowing window
            Positioned(left: 155, top: 60, child: _window()),
            // the lock plate with two charms found and two still hidden
            Positioned(
              left: 0,
              right: 0,
              top: 330,
              child: Center(child: _lockPlate()),
            ),
            // door knob
            Positioned(
              left: 390,
              top: 440,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD9B36A),
                  border: Border.all(color: const Color(0xFF9C7A3C), width: 3),
                  boxShadow: softShadow(y: 3, blur: 6, opacity: 0.35),
                ),
              ),
            ),
            // the 8 candles at the bottom
            Positioned(
              left: 0,
              right: 0,
              top: 580,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 8; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3),
                      child: CandleIcon(lit: true, size: 30),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _window() {
    return Container(
      width: 150,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(75),
          topRight: Radius.circular(75),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD48A), Color(0xFFF0A04B)],
        ),
        border: Border.all(color: AppColors.woodDark, width: 8),
        boxShadow: [BoxShadow(color: const Color(0xFFFFB453).withAlpha(alpha(0.6)), blurRadius: 30)],
      ),
      child: Center(child: Container(width: 6, color: AppColors.woodDark)),
    );
  }

  Widget _lockPlate() {
    Widget hidden() => Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.socketDeep, AppColors.socket],
            ),
          ),
          child: Text('?', style: heading(27, weight: FontWeight.w700, color: const Color(0xFFA57B58))),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE9D7B4),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: const Color(0xFFC6A773), width: 3),
        boxShadow: softShadow(y: 6, blur: 12, opacity: 0.35),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CharmToken(Charm.moon, size: 70),
          const SizedBox(width: 14),
          const CharmToken(Charm.acorn, size: 70),
          const SizedBox(width: 14),
          hidden(),
          const SizedBox(width: 14),
          hidden(),
        ],
      ),
    );
  }
}

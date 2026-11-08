// lib/widgets/motion.dart
//
// Small animation helpers. All of them use Flutter's "implicit"
// animations: you describe the end result and Flutter animates there by
// itself. No AnimationController is needed.
//
// If the player has asked their device to reduce motion, everything
// appears instantly instead.

import 'package:flutter/material.dart';

/// true when the system setting "reduce motion / remove animations" is on.
bool reduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// A normal duration, or zero when motion is reduced.
Duration motion(BuildContext context, int milliseconds) =>
    reduceMotion(context) ? Duration.zero : Duration(milliseconds: milliseconds);

/// Makes its child grow in from small and fade in, once, when it first
/// appears. Give it a [key] that changes when you want it to play again.
///
/// [delay] waits before starting (used to reveal clue pegs one by one).
class PopIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;

    final total = delay + duration;
    // The animation runs for the whole time, but nothing moves until the
    // delay has passed (that's what Interval does).
    final start = delay.inMilliseconds / total.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack), // a tiny bounce
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
      ),
    );
  }
}

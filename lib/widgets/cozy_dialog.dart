// lib/widgets/cozy_dialog.dart
//
// The three pop-ups: "Start over?", the win dialog and the lose dialog.
// Each function shows a dialog and returns what the player chose.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../theme.dart';
import 'charm_art.dart';
import 'cozy_widgets.dart';
import 'motion.dart';

/// What the player picked in the win / lose dialog.
enum EndChoice { playAgain, backToStart }

/// Asks before wiping the game. Returns true if the player confirmed.
Future<bool> showRestartDialog(BuildContext context, {required int triesUsed}) async {
  final tries = triesUsed == 1 ? '1 try' : '$triesUsed tries';
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xFF2A1E17).withAlpha(alpha(0.5)),
    builder: (context) => _CozyDialog(
      badge: _Badge(color: const Color(0xFFE9D7B4), child: const Icon(Icons.restart_alt_rounded, size: 44, color: AppColors.bark)),
      title: 'Start over?',
      message: triesUsed == 0
          ? 'The lock gets four new charms.'
          : 'Your $tries will be cleared and the lock gets four new charms.',
      actions: [
        CozyButton(
          label: 'Keep playing',
          style: CozyButtonStyle.outline,
          height: 58,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        CozyButton(
          label: 'Start over',
          icon: Icons.restart_alt_rounded,
          height: 58,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false; // tapping outside counts as "Keep playing"
}

/// The end-of-game dialog. The player must pick an option to close it.
/// [newBest] and [best] come from BestScores, [gemsTotal] from GemBank
/// (only used when the player won).
Future<EndChoice> showEndDialog(
  BuildContext context,
  CharmLockGame game, {
  bool newBest = false,
  int? best,
  int gemsTotal = 0,
}) async {
  final won = game.status == GameStatus.won;
  final used = game.candlesUsed;
  String? note;
  if (won && newBest) {
    note = 'New best score!';
  } else if (won && best != null) {
    note = 'Your best: $best ${best == 1 ? 'try' : 'tries'}';
  }
  final result = await showDialog<EndChoice>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFF2A1E17).withAlpha(alpha(0.5)),
    builder: (context) => _CozyDialog(
      badge: won
          ? _Badge(
              color: const Color(0xFFF6D6A8),
              glow: true,
              child: const CandleIcon(lit: true, size: 64),
            )
          : _Badge(color: const Color(0xFFE2D8C8), child: const CandleIcon(lit: false, size: 64)),
      title: won ? 'The door creaks open' : 'The last candle went out',
      message: won
          ? 'You found all four charms in $used ${used == 1 ? 'try' : 'tries'}. The fire is warm inside.'
          : 'The lock stays shut this time. These were the four charms:',
      code: game.revealedCode,
      note: note,
      noteHighlight: newBest,
      reward: won
          ? _GemReward(
              earned: game.gemsEarned,
              fromCandles: game.triesLeft,
              bonus: game.hintUsed ? 0 : CharmLockGame.noLanternBonus,
              total: gemsTotal,
            )
          : null,
      actions: [
        CozyButton(
          label: 'Back to start',
          icon: Icons.home_outlined,
          style: CozyButtonStyle.outline,
          height: 58,
          onPressed: () => Navigator.of(context).pop(EndChoice.backToStart),
        ),
        CozyButton(
          label: won ? 'Play again' : 'Try again',
          icon: Icons.restart_alt_rounded,
          height: 58,
          onPressed: () => Navigator.of(context).pop(EndChoice.playAgain),
        ),
      ],
    ),
  );
  return result ?? EndChoice.playAgain;
}

// ------------------------------------------------------------ layout

class _CozyDialog extends StatelessWidget {
  final Widget badge;
  final String title;
  final String message;
  final List<Charm>? code;
  final List<Widget> actions;
  final String? note;
  final bool noteHighlight;
  final Widget? reward;

  const _CozyDialog({
    required this.badge,
    required this.title,
    required this.message,
    required this.actions,
    this.code,
    this.note,
    this.noteHighlight = false,
    this.reward,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // Small or short screens (phones, phones held sideways) get smaller sizes.
    final narrow = screen.width < 600 || screen.height < 700;
    // The dialog's width: the screen minus a 20px margin each side, max 560.
    final width = math.min(560.0, screen.width - 40);
    final maxHeight = screen.height - 40;

    final content = SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 20 : 44, vertical: narrow ? 22 : 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopIn(duration: const Duration(milliseconds: 420), child: _sized(badge, narrow ? 68 : 96)),
              SizedBox(height: narrow ? 12 : 18),
              Text(title, textAlign: TextAlign.center, style: heading(narrow ? 26 : 40)),
              SizedBox(height: narrow ? 8 : 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: body(narrow ? 15 : 18, color: AppColors.barkMuted, height: 1.45),
              ),
              if (reward != null) ...[
                SizedBox(height: narrow ? 12 : 18),
                reward!,
              ],
              if (note != null) ...[
                SizedBox(height: narrow ? 10 : 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: noteHighlight ? AppColors.ember : const Color(0xFFE9D7B4),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        noteHighlight ? Icons.star_rounded : Icons.emoji_events_outlined,
                        size: 20,
                        color: noteHighlight ? Colors.white : AppColors.bark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note!,
                        style: body(15, weight: FontWeight.w800, color: noteHighlight ? Colors.white : AppColors.bark),
                      ),
                    ],
                  ),
                ),
              ],
              if (code != null) ...[
                SizedBox(height: narrow ? 14 : 20),
                _SecretCode(code!, narrow: narrow),
              ],
              SizedBox(height: narrow ? 18 : 26),
              Row(
                children: [
                  Expanded(child: actions[0]),
                  SizedBox(width: narrow ? 10 : 14),
                  Expanded(child: actions[1]),
                ],
              ),
            ],
          ),
      ),
    );

    return Dialog(
      backgroundColor: AppColors.linen,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(narrow ? 28 : 40)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        // If the content is still taller than the screen (very small or
        // sideways phones), FittedBox shrinks it to fit: no scrolling ever.
        child: FittedBox(fit: BoxFit.scaleDown, child: content),
      ),
    );
  }

  /// Draws [child] (the badge) at [size] x [size], scaling its picture.
  static Widget _sized(Widget child, double size) =>
      SizedBox(width: size, height: size, child: FittedBox(child: child));
}

/// The revealed code on its wooden-ish plate, with names underneath.
class _SecretCode extends StatelessWidget {
  final List<Charm> code;
  final bool narrow;
  const _SecretCode(this.code, {required this.narrow});

  @override
  Widget build(BuildContext context) {
    final size = narrow ? 46.0 : 66.0;
    return Semantics(
      label: 'The secret code was ${code.map(charmName).join(', ')}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 16, vertical: narrow ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9D7B4),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: const Color(0xFFC6A773), width: 3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animation: the secret charms are revealed one at a time.
                for (var i = 0; i < code.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  PopIn(
                    delay: Duration(milliseconds: 250 + i * 180),
                    duration: const Duration(milliseconds: 320),
                    child: CharmToken(code[i], size: size),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < code.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                SizedBox(
                  width: size,
                  // one line always: shrinks a long name like "Mushroom"
                  // instead of breaking it onto two lines
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      charmName(code[i]),
                      maxLines: 1,
                      softWrap: false,
                      style: body(13, weight: FontWeight.w700, color: AppColors.barkMuted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;
  final bool glow;
  const _Badge({required this.color, required this.child, this.glow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: glow ? [BoxShadow(color: const Color(0xFFFFB453).withAlpha(alpha(0.7)), blurRadius: 30)] : null,
      ),
      child: child,
    );
  }
}

/// The reward box in the win dialog: "+7 gems" counting up from 0,
/// how they were earned, and the new total.
class _GemReward extends StatelessWidget {
  final int earned;
  final int fromCandles;
  final int bonus;
  final int total;

  const _GemReward({
    required this.earned,
    required this.fromCandles,
    required this.bonus,
    required this.total,
  });

  static const _purple = Color(0xFF7B4FB5);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final narrow = screen.width < 600 || screen.height < 700;
    final parts = <String>[
      if (fromCandles > 0) '$fromCandles candle${fromCandles == 1 ? '' : 's'} still lit',
      if (bonus > 0) '+$bonus for no lantern',
    ];
    return Semantics(
      label: 'You earned $earned gems. You now have $total gems.',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: narrow ? 10 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EAF8), // soft lavender
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _purple.withAlpha(alpha(0.45)), width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GemIcon(size: narrow ? 30 : 38),
                const SizedBox(width: 8),
                // Animation: the number counts up from 0 to what you earned.
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: earned),
                  duration: motion(context, 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    '+$value',
                    style: heading(narrow ? 32 : 40, color: _purple),
                  ),
                ),
                const SizedBox(width: 8),
                Text(earned == 1 ? 'gem' : 'gems', style: heading(narrow ? 20 : 24, weight: FontWeight.w700)),
              ],
            ),
            if (parts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                parts.join('  ·  '),
                textAlign: TextAlign.center,
                style: body(14, color: AppColors.barkMuted),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'You now have $total gems',
              textAlign: TextAlign.center,
              style: body(15, weight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

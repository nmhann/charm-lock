// lib/widgets/game_panels.dart
//
// The panels next to the board: status (tries + candles), the clue
// message, the clue key and the charm picker. Like the board, they only
// READ the game; taps are passed up to the game screen.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../theme.dart';
import 'charm_art.dart';
import 'cozy_widgets.dart';
import 'motion.dart';

// ------------------------------------------------------------ status

/// "Try 4 of 8" plus a row of candles. Tries left is shown twice:
/// as text and as candles, so it never depends on a picture alone.
class StatusPanel extends StatelessWidget {
  final CharmLockGame game;
  final bool compact;

  const StatusPanel({super.key, required this.game, this.compact = false});

  String get _title {
    switch (game.status) {
      case GameStatus.won:
        return 'Solved in ${game.candlesUsed} ${game.candlesUsed == 1 ? 'try' : 'tries'}';
      case GameStatus.lost:
        return 'No tries left';
      case GameStatus.playing:
        return 'Try ${game.currentTry} of ${game.totalTries}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = game.triesLeft;
    final candles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < game.maxTries; i++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            // Animation: a candle cross-fades from lit to burnt out.
            child: AnimatedSwitcher(
              duration: motion(context, 500),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(anim), child: child),
              ),
              child: CandleIcon(
                key: ValueKey(i < left), // a new key = a new picture to switch to
                lit: i < left,
                size: compact ? 20 : 30,
              ),
            ),
          ),
      ],
    );
    final candlesText = left == 0
        ? 'The last candle is out'
        : '$left candle${left == 1 ? '' : 's'} left';

    if (compact) {
      return CozyCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
        // Both sides shrink to fit (FittedBox) instead of wrapping or
        // overflowing on very narrow phones.
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_title, maxLines: 1, style: heading(20)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 5,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Semantics(label: candlesText, child: candles),
              ),
            ),
          ],
        ),
      );
    }

    return CozyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_title, style: heading(34)),
          const SizedBox(height: 12),
          Row(
            children: [
              candles,
              const Spacer(),
              Text(candlesText, style: body(16, weight: FontWeight.w700, color: AppColors.barkMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ clue message

/// The sentence that explains what just happened.
class ClueMessage extends StatelessWidget {
  final String message;
  final bool compact;

  const ClueMessage({super.key, required this.message, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      color: AppColors.parchment,
      radius: compact ? 18 : 24,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 10, 14, 10)
          : const EdgeInsets.fromLTRB(20, 18, 22, 18),
      border: Border.all(color: AppColors.ember.withAlpha(alpha(0.5)), width: compact ? 1.5 : 2),
      child: Row(
        children: [
          EmberIcon(size: compact ? 22 : 28),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            // liveRegion: screen readers announce the new message
            child: Semantics(
              liveRegion: true,
              // Animation: the new message fades in over the old one.
              child: AnimatedSwitcher(
                duration: motion(context, 250),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: Text(message, key: ValueKey(message), style: body(compact ? 14 : 17)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ clue key

/// Always-visible legend: what each peg means.
class ClueKey extends StatelessWidget {
  final bool compact;
  const ClueKey({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Widget item(PegKind kind, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CluePeg(kind, size: compact ? 13 : 16),
            const SizedBox(width: 8),
            Text(label, style: body(compact ? 12 : 14, weight: FontWeight.w700, color: AppColors.linen)),
          ],
        );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF8F6240),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 6,
        children: [
          item(PegKind.ember, 'Right spot'),
          item(PegKind.ring, 'Wrong spot'),
          item(PegKind.ash, 'Not in the lock'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ charm picker

/// The 6 charm buttons. A charm is disabled when it's already in the
/// row, when the row is full, or when the game is over.
class CharmPicker extends StatelessWidget {
  final CharmLockGame game;
  final ValueChanged<Charm> onPick;
  final bool compact;
  final bool showHeader;

  const CharmPicker({
    super.key,
    required this.game,
    required this.onPick,
    this.compact = false,
    this.showHeader = true,
  });

  // The rules decide; the picker just asks.
  bool _enabled(Charm c) => game.canPlace(c);

  bool _inUse(Charm c) => game.isInUse(c);

  @override
  Widget build(BuildContext context) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('Pick a charm', style: heading(compact ? 18 : 24, weight: FontWeight.w700)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            compact ? 'Tap a placed charm to remove it' : 'Tap a placed charm to take it back',
            textAlign: TextAlign.end,
            style: body(compact ? 11 : 13, color: AppColors.barkMuted),
          ),
        ),
      ],
    );

    if (compact) {
      // Phone: one row of 6 round buttons with names underneath.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[header, const SizedBox(height: 12)],
          Row(
            children: [
              for (final c in Charm.values) Expanded(child: _compactButton(c)),
            ],
          ),
        ],
      );
    }

    // Laptop: two rows of three pill buttons.
    final charms = Charm.values;
    return CozyCard(
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 16),
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: _pillButton(charms[r * 3 + i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pillButton(Charm c) {
    final enabled = _enabled(c);
    final inUse = _inUse(c);
    return Semantics(
      button: true,
      enabled: enabled,
      label: inUse ? '${charmName(c)}, already in this row' : 'Place ${charmName(c)}',
      excludeSemantics: true,
      child: Material(
        color: inUse ? const Color(0xFFE6DCC9) : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: inUse ? const Color(0xFFD3C6B0) : const Color(0xFFE4D6BD), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onPick(c) : null,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
            child: Row(
              children: [
                CharmToken(c, size: 40, faded: inUse),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        charmName(c),
                        overflow: TextOverflow.ellipsis,
                        style: body(14, weight: FontWeight.w800, color: inUse ? AppColors.faded : AppColors.bark),
                      ),
                      if (inUse) Text('In use', style: body(12, weight: FontWeight.w700, color: AppColors.faded)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _compactButton(Charm c) {
    final enabled = _enabled(c);
    final inUse = _inUse(c);
    return Semantics(
      button: true,
      enabled: enabled,
      label: inUse ? '${charmName(c)}, already in this row' : 'Place ${charmName(c)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => onPick(c) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          // LayoutBuilder: how wide is this button's slot? On tiny phones the
          // token gets smaller, and the name shrinks to one line instead of
          // wrapping ("Mushroom" never breaks onto two lines).
          child: LayoutBuilder(
            builder: (context, slot) {
              final tokenSize = math.min(44.0, slot.maxWidth - 6);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CharmToken(c, size: tokenSize, faded: inUse),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: slot.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        inUse ? 'In use' : charmName(c),
                        maxLines: 1,
                        softWrap: false,
                        style: body(11, weight: FontWeight.w700, color: inUse ? AppColors.faded : AppColors.bark),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ try button

/// "Try the lock" plus a hint saying why it's locked, if it is.
class TryLockAction extends StatelessWidget {
  final CharmLockGame game;
  final VoidCallback onSubmit;
  final bool compact;

  const TryLockAction({super.key, required this.game, required this.onSubmit, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final missing = CharmLockGame.codeLength - game.filledSockets;
    final hint = game.status != GameStatus.playing
        ? 'The game is over'
        : missing == 0
            ? 'Ready! Try the lock.'
            : 'Place $missing more charm${missing == 1 ? '' : 's'} to try the lock';

    final button = CozyButton(
      label: 'Try the lock',
      icon: game.canSubmit ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
      onPressed: game.canSubmit ? onSubmit : null,
      height: compact ? 54 : 62,
      expand: compact,
    );
    final hintText = Text(
      hint,
      textAlign: compact ? TextAlign.center : TextAlign.start,
      style: body(compact ? 12 : 15, weight: FontWeight.w700, color: AppColors.barkMuted, height: 1.35),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [button, const SizedBox(height: 8), hintText],
      );
    }
    return Row(
      children: [button, const SizedBox(width: 16), Expanded(child: hintText)],
    );
  }
}

// ------------------------------------------------------------ lantern hint

/// The one-time hint. Before use it explains the cost; after use it
/// keeps showing what it revealed.
class LanternCard extends StatelessWidget {
  final CharmLockGame game;
  final VoidCallback onUse;
  final bool compact;

  const LanternCard({super.key, required this.game, required this.onUse, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final hint = game.hint;
    final String title;
    final String detail;
    if (hint != null) {
      title = 'The lantern is lit';
      detail = '${charmName(hint.charm)} belongs in socket ${hint.position + 1}.';
    } else if (game.status != GameStatus.playing) {
      title = 'Lantern';
      detail = 'Not used this game.';
    } else if (!game.canUseHint) {
      title = 'Lantern';
      detail = 'Not enough candles left to light it.';
    } else {
      title = 'Stuck? Light the lantern';
      detail = 'Shows one charm in its spot. Costs 1 candle.';
    }

    final Widget trailing = hint != null
        ? CharmToken(hint.charm, size: compact ? 36 : 44)
        : CozyButton(
            label: 'Light it',
            style: CozyButtonStyle.outline,
            height: compact ? 40 : 46,
            onPressed: game.canUseHint ? onUse : null,
          );

    return CozyCard(
      radius: compact ? 18 : 24,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 8, 10, 8)
          : const EdgeInsets.fromLTRB(18, 12, 14, 12),
      child: Row(
        children: [
          LanternIcon(size: compact ? 30 : 38, lit: hint != null || game.canUseHint),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: heading(compact ? 16 : 20, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: body(compact ? 12 : 14, color: AppColors.barkMuted, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ phone actions

/// Phone bottom row: a small Hint (lantern) button and the Try button.
/// The Try button's label says what's missing, so no extra hint text
/// is needed underneath (saves space on small screens).
class PhoneActions extends StatelessWidget {
  final CharmLockGame game;
  final VoidCallback onSubmit;
  final VoidCallback onHint;

  const PhoneActions({super.key, required this.game, required this.onSubmit, required this.onHint});

  @override
  Widget build(BuildContext context) {
    final missing = CharmLockGame.codeLength - game.filledSockets;
    final String label;
    if (game.status != GameStatus.playing) {
      label = 'Game over';
    } else if (missing == 0) {
      label = 'Try the lock';
    } else {
      label = 'Place $missing more';
    }

    final canHint = game.canUseHint;
    final hintTip = game.hintUsed
        ? 'The lantern is already lit'
        : canHint
            ? 'Light the lantern: shows one charm, costs 1 candle'
            : 'Not enough candles left for the lantern';

    return Row(
      children: [
        Tooltip(
          message: hintTip,
          child: Semantics(
            button: true,
            enabled: canHint,
            label: hintTip,
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(color: canHint ? AppColors.bark : AppColors.disabledBg, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: canHint ? onHint : null,
                child: SizedBox(
                  height: 54,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: canHint ? 1 : 0.45,
                          child: LanternIcon(size: 28, lit: canHint || game.hintUsed),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hint',
                          style: heading(18, weight: FontWeight.w700, color: canHint ? AppColors.bark : AppColors.disabledFg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CozyButton(
            label: label,
            icon: game.canSubmit ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            onPressed: game.canSubmit ? onSubmit : null,
            height: 54,
            expand: true,
          ),
        ),
      ],
    );
  }
}

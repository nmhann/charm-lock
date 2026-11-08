// lib/widgets/lock_board.dart
//
// The wooden board with 8 rows. It does NOT change the game itself:
// it only reads the game and reports taps through [onRemove].
// The screen that owns the game decides what a tap does.

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../theme.dart';
import 'charm_art.dart';
import 'motion.dart';

enum _RowState { done, current, future }

class LockBoard extends StatelessWidget {
  final CharmLockGame game;

  /// Called with a socket index when the player taps a placed charm.
  final ValueChanged<int> onRemove;

  /// Size of one charm token. Smaller on phones.
  final double tokenSize;

  /// Phone mode: finished rows are drawn smaller and empty future rows are
  /// hidden, so the whole board fits on the screen without scrolling.
  final bool phone;

  const LockBoard({
    super.key,
    required this.game,
    required this.onRemove,
    this.tokenSize = 56,
    this.phone = false,
  });

  bool get _compact => tokenSize < 48;

  /// Token size for finished rows (smaller on phones, since you only read them).
  double get _pastSize => phone ? (tokenSize * 0.62).roundToDouble() : tokenSize;

  @override
  Widget build(BuildContext context) {
    final built = <Widget>[];
    final rowCount = game.maxTries;
    for (var i = 0; i < rowCount; i++) {
      // After the lantern is used, the last row is the burnt candle.
      if (game.hintUsed && i == rowCount - 1) {
        built.add(_lanternRow(context, i));
        break;
      }
      final _RowState state;
      if (i < game.history.length) {
        state = _RowState.done;
      } else if (i == game.history.length && game.status == GameStatus.playing) {
        state = _RowState.current;
      } else {
        state = _RowState.future;
      }
      if (phone && state == _RowState.future) continue; // hidden on phones
      final size = state == _RowState.current ? tokenSize : _pastSize;
      built.add(_buildRow(context, i, state, size));
    }

    // put a small gap between rows
    final rows = <Widget>[];
    for (var i = 0; i < built.length; i++) {
      if (i > 0) rows.add(SizedBox(height: _compact ? 4 : 6));
      rows.add(built[i]);
    }

    // On phones rows have different sizes, so stretch them all to the
    // widest one; that keeps every row's clue pegs lined up on the right.
    final column = phone
        ? IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          )
        : Column(mainAxisSize: MainAxisSize.min, children: rows);

    return Container(
      padding: _compact
          ? const EdgeInsets.fromLTRB(10, 10, 12, 10)
          : const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_compact ? 24 : 36),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.woodLight, AppColors.wood],
        ),
        boxShadow: softShadow(blur: _compact ? 20 : 36, y: _compact ? 10 : 18, opacity: 0.3),
      ),
      child: column,
    );
  }

  /// The row given up to light the lantern.
  Widget _lanternRow(BuildContext context, int index) {
    final hint = game.hint!;
    final size = _pastSize;
    // Pops in when the lantern is lit.
    return PopIn(
      key: const ValueKey('lantern-row'),
      duration: const Duration(milliseconds: 380),
      child: Semantics(
      label: 'Try ${index + 1} was spent on the lantern',
      excludeSemantics: true,
      child: Container(
        height: size + (_compact ? 8 : 16),
        padding: EdgeInsets.symmetric(horizontal: _compact ? 12 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size),
          color: AppColors.woodDark.withAlpha(alpha(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanternIcon(size: size * 0.7, lit: false),
            SizedBox(width: _compact ? 8 : 12),
            Flexible(
              child: Text(
                'Spent on the lantern: ${charmName(hint.charm)} is socket ${hint.position + 1}',
                style: body(_compact ? 12 : 15, weight: FontWeight.w700, color: AppColors.linen),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index, _RowState state, double size) {
    final isCurrent = state == _RowState.current;
    final guess = state == _RowState.done ? game.history[index] : null;
    final isWinningRow = guess != null && guess.clue.exact == CharmLockGame.codeLength;

    // ---- the 4 sockets
    final sockets = <Widget>[];
    final nextSlot = isCurrent ? game.current.indexOf(null) : -1;
    for (var s = 0; s < CharmLockGame.codeLength; s++) {
      if (s > 0) sockets.add(SizedBox(width: _compact ? 8 : 12));
      if (guess != null) {
        sockets.add(CharmToken(guess.charms[s], size: size));
      } else if (isCurrent && game.current[s] != null) {
        final charm = game.current[s]!;
        // Placed charms in the current row can be tapped to take them back.
        // Animation: the charm pops into its socket. The key names the
        // socket and the charm, so it plays again only when that changes.
        sockets.add(
          PopIn(
            key: ValueKey('placed-$s-${charm.name}'),
            child: Tooltip(
              message: 'Take back ${charmName(charm)}',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onRemove(s),
                  child: CharmToken(charm, size: size),
                ),
              ),
            ),
          ),
        );
      } else {
        // The lantern's charm shows faintly in its socket on the current row.
        final hint = game.hint;
        final ghost = isCurrent && hint != null && hint.position == s ? hint.charm : null;
        final socket = EmptySocket(size: size, next: s == nextSlot && ghost == null, ghost: ghost);
        sockets.add(ghost == null ? socket : PopIn(key: ValueKey('ghost-$s'), child: socket));
      }
    }

    // ---- the clue pegs (2 x 2)
    final kinds = <PegKind>[];
    if (guess != null) {
      kinds.addAll(List.filled(guess.clue.exact, PegKind.ember));
      kinds.addAll(List.filled(guess.clue.partial, PegKind.ring));
    }
    while (kinds.length < CharmLockGame.codeLength) {
      kinds.add(PegKind.ash);
    }
    final pegSize = _compact ? 12.0 : 16.0;
    final gap = _compact ? 4.0 : 7.0;
    // Animation: after a guess, its clue pegs appear one by one
    // (each waits a little longer than the one before).
    Widget peg(int k) {
      final p = CluePeg(kinds[k], size: pegSize);
      if (guess == null) return p;
      return PopIn(
        key: ValueKey('peg-$k'),
        delay: Duration(milliseconds: 120 + k * 160),
        child: p,
      );
    }

    Widget pegRow(int start) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [peg(start), SizedBox(width: gap), peg(start + 1)],
        );
    final pegs = AnimatedOpacity(
      duration: motion(context, 250),
      opacity: guess == null ? 0.5 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [pegRow(0), SizedBox(height: gap), pegRow(2)],
      ),
    );

    // Screen readers get the clue as words.
    final semanticsLabel = guess == null
        ? 'Try ${index + 1}${isCurrent ? ', in progress' : ', not played yet'}'
        : 'Try ${index + 1}: ${guess.charms.map(charmName).join(', ')}. ${guess.clue.describe()}';

    final highlighted = isCurrent || isWinningRow;
    // Animation: AnimatedContainer fades the glow and border smoothly
    // from the row you just played to the next one.
    final row = AnimatedContainer(
      duration: motion(context, 300),
      curve: Curves.easeOut,
      padding: _compact
          ? const EdgeInsets.fromLTRB(8, 4, 10, 4)
          : const EdgeInsets.fromLTRB(14, 8, 18, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        color: highlighted ? AppColors.woodRow : null,
        border: highlighted
            ? Border.all(color: isWinningRow ? AppColors.ember : AppColors.emberLight, width: _compact ? 2 : 3)
            : null,
        boxShadow: isCurrent
            ? [BoxShadow(color: const Color(0xFFFFB453).withAlpha(alpha(0.45)), blurRadius: 18)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _compact ? 18 : 26,
            child: Text(
              '${index + 1}',
              textAlign: TextAlign.center,
              style: heading(
                _compact ? 15 : 22,
                weight: FontWeight.w700,
                color: isCurrent ? AppColors.bark : AppColors.rowNumber,
              ),
            ),
          ),
          SizedBox(width: _compact ? 10 : 14),
          ...sockets,
          if (phone) const Spacer(),
          SizedBox(width: _compact ? 12 : 14),
          Container(width: 2, height: size * 0.7, color: AppColors.woodDark.withAlpha(alpha(0.5))),
          SizedBox(width: _compact ? 10 : 14),
          pegs,
        ],
      ),
    );

    return Semantics(
      label: semanticsLabel,
      child: Opacity(opacity: state == _RowState.future ? 0.55 : 1, child: row),
    );
  }
}

// lib/screens/game_screen.dart
//
// The only widget that holds game state.
//
// This screen owns one CharmLockGame (the brain) and one message string.
// Every tap follows the same loop:
//
//   1. a widget reports a tap        (e.g. CharmPicker calls onPick)
//   2. we call setState(() { ... })  and ask the brain to change
//   3. Flutter rebuilds, and every widget redraws from the brain
//
// Sounds and saved scores are side effects: they happen after the
// brain has changed, and never decide anything themselves.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../services/best_scores.dart';
import '../services/gem_bank.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import '../widgets/charm_art.dart';
import '../widgets/cozy_dialog.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/game_panels.dart';
import '../widgets/lock_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ---- state
  final CharmLockGame game = CharmLockGame();
  static const String _startMessage = 'Pick four charms, then try the lock.';
  String message = _startMessage;

  final SoundService _sound = SoundService.instance;

  @override
  void initState() {
    super.initState();
    _sound.startMusic(); // soft music while you play
  }

  @override
  void dispose() {
    _sound.stopMusic();
    super.dispose();
  }

  // ---- actions: each one changes the brain inside setState

  void _pick(Charm charm) {
    setState(() {
      if (game.placeCharm(charm)) {
        _sound.play(Sfx.place);
      } else {
        // The picker already disables these, but explain just in case.
        message = game.filledSockets == CharmLockGame.codeLength
            ? 'All four sockets are full. Try the lock, or tap a charm to take it back.'
            : '${charmName(charm)} is already in this row. Each charm can only be used once.';
      }
    });
  }

  void _remove(int slot) {
    setState(() {
      final charm = game.current[slot];
      if (game.removeAt(slot) && charm != null) {
        message = '${charmName(charm)} taken back.';
        _sound.play(Sfx.remove);
      }
    });
  }

  void _useHint() {
    setState(() {
      final hint = game.useHint();
      if (hint != null) {
        message = 'The lantern glows: ${charmName(hint.charm)} belongs in socket '
            '${hint.position + 1}. One candle burned.';
        _sound.play(Sfx.lantern);
      }
    });
  }

  Future<void> _submit() async {
    Clue? clue;
    setState(() {
      clue = game.submitGuess();
      if (clue != null) {
        message = 'Try ${game.triesUsed}: ${clue!.describe()}';
      }
    });
    if (clue == null) return;
    _sound.play(Sfx.latch);
    if (game.status == GameStatus.playing) return;

    // Game over: let the board show the last row, then open the dialog.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final won = game.status == GameStatus.won;
    _sound.play(won ? Sfx.win : Sfx.lose);

    var newBest = false;
    int? best;
    var gemsTotal = GemBank.instance.total.value;
    if (won) {
      newBest = await BestScores.submit(game.candlesUsed);
      best = await BestScores.get();
      // The rules say how many gems were earned; the bank saves them.
      gemsTotal = await GemBank.instance.add(game.gemsEarned);
    }
    if (!mounted) return;

    final choice = await showEndDialog(
      context,
      game,
      newBest: newBest,
      best: best,
      gemsTotal: gemsTotal,
    );
    if (!mounted) return;
    if (choice == EndChoice.playAgain) {
      _newGame();
    } else {
      Navigator.of(context).pop(); // back to the start screen
    }
  }

  Future<void> _askRestart() async {
    final confirmed = await showRestartDialog(context, triesUsed: game.triesUsed);
    if (confirmed && mounted) _newGame();
  }

  void _newGame() {
    setState(() {
      game.newGame();
      message = _startMessage;
    });
  }

  // ---- layout: pick wide (laptop) or narrow (phone) based on width

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CozyBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            // Three layouts, picked from the space we actually have:
            if (w >= 900 && h >= 600) return _wide(); // laptop / desktop window
            if (w > h * 1.15) return _landscape(w); // phone on its side, short window
            return _narrow(w, h); // phone upright, tall narrow window
          },
        ),
      ),
    );
  }

  // Phone on its side (or a short, wide window): board on the left, a
  // compact control panel on the right. Both sides shrink to fit the
  // height, so nothing is ever cut off or needs scrolling.
  Widget _landscape(double width) {
    final panelWidth = math.min(400.0, width * 0.46);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: LockBoard(game: game, onRemove: _remove, tokenSize: 46),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: panelWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: panelWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('Charm Lock', maxLines: 1, style: heading(22)),
                            ),
                          ),
                          const GemCounter(compact: true),
                          const SizedBox(width: 6),
                          const SoundToggle(size: 40),
                          const SizedBox(width: 6),
                          CozyIconButton(
                            icon: Icons.restart_alt_rounded,
                            tooltip: 'Start over',
                            onPressed: _askRestart,
                            size: 40,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StatusPanel(game: game, compact: true),
                      const SizedBox(height: 8),
                      ClueMessage(message: message, compact: true),
                      const SizedBox(height: 6),
                      const ClueKey(compact: true),
                      const SizedBox(height: 8),
                      Material(
                        color: AppColors.linen,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CharmPicker(game: game, onPick: _pick, compact: true, showHeader: false),
                              const SizedBox(height: 8),
                              PhoneActions(game: game, onSubmit: _submit, onHint: _useHint),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Laptop: board on the left, panels on the right.
  Widget _wide() {
    // The board and panels are drawn at a fixed size;
    // FittedBox then shrinks them to fit the window.
    const areaHeight = 740.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(64, 28, 64, 32),
      child: Column(
        children: [
          Row(
            children: [
              Text('Charm Lock', style: heading(36)),
              const Spacer(),
              const GemCounter(),
              const SizedBox(width: 12),
              const SoundToggle(),
              const SizedBox(width: 12),
              CozyButton(
                label: 'Start over',
                icon: Icons.restart_alt_rounded,
                style: CozyButtonStyle.outline,
                height: 48,
                onPressed: _askRestart,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              // Shrinks to fit small laptop windows, and grows on big monitors
              // (BoxFit.contain), but never more than 1.3x so it stays cozy.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040 * 1.3, maxHeight: areaHeight * 1.3),
                child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1040,
                  height: areaHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LockBoard(game: game, onRemove: _remove),
                      const SizedBox(width: 44),
                      SizedBox(
                        width: 520,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StatusPanel(game: game),
                            const SizedBox(height: 14),
                            ClueMessage(message: message),
                            const SizedBox(height: 10),
                            const ClueKey(),
                            const SizedBox(height: 14),
                            LanternCard(game: game, onUse: _useHint),
                            const SizedBox(height: 14),
                            CharmPicker(game: game, onPick: _pick),
                            const SizedBox(height: 16),
                            TryLockAction(game: game, onSubmit: _submit),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Phone / narrow window: everything fits on ONE screen, no scrolling.
  //   top:    title, sound, start over, status
  //   middle: the board takes all the height that's left, and shrinks
  //           (FittedBox) if a very small phone doesn't have enough
  //   bottom: clue message, clue key, then the picker and buttons
  Widget _narrow(double width, double height) {
    // On short screens (like an iPhone SE) drop the picker's heading
    // so the board gets more room.
    final short = height < 700 || width < 360;
    // Fit 4 tokens plus the row number and clue pegs into the board width.
    // (156 = row number, gaps, divider, clue pegs and padding)
    final boardWidth = (width - 32).clamp(200.0, 520.0);
    // Phones max out at 46px tokens; tablets (600px+) can go up to 56px.
    final maxToken = width >= 600 ? 56.0 : 46.0;
    final tokenSize = ((boardWidth - 156) / 4).clamp(20.0, maxToken);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        // shrinks instead of wrapping on very narrow phones
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Charm Lock', maxLines: 1, style: heading(24)),
                        ),
                      ),
                      const GemCounter(compact: true),
                      const SizedBox(width: 8),
                      const SoundToggle(size: 42),
                      const SizedBox(width: 8),
                      CozyIconButton(
                        icon: Icons.restart_alt_rounded,
                        tooltip: 'Start over',
                        onPressed: _askRestart,
                        size: 42,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatusPanel(game: game, compact: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // LayoutBuilder tells us how much height the board really has.
                child: LayoutBuilder(
                  builder: (context, area) {
                    // Biggest token that lets all 8 rows fit in this height:
                    // each row is token + 8 (padding), plus 4px gaps between
                    // rows and 20px of board padding.
                    final rows = CharmLockGame.totalCandles;
                    final byHeight = (area.maxHeight - 20 - (rows - 1) * 4 - 6) / rows - 8;
                    final size = math.min(tokenSize, byHeight).toDouble();

                    // Normal phones: all 8 rows, sized to fit.
                    // Very short phones (rows would be too small to tap):
                    // fall back to big current row + small finished rows.
                    final allRowsFit = size >= 30;
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: LockBoard(
                          game: game,
                          onRemove: _remove,
                          tokenSize: allRowsFit ? size : tokenSize,
                          phone: !allRowsFit,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClueMessage(message: message, compact: true),
                  const SizedBox(height: 6),
                  const ClueKey(compact: true),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // the bottom sheet with the picker and the buttons
            Material(
              color: AppColors.linen,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              elevation: 6,
              shadowColor: const Color(0x553A2210),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CharmPicker(game: game, onPick: _pick, compact: true, showHeader: !short),
                    const SizedBox(height: 10),
                    PhoneActions(game: game, onSubmit: _submit, onHint: _useHint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

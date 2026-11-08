// lib/screens/start_screen.dart
//
// The first screen: title, how to play, the clue key, the best score
// and the Play button.
//
// It's a StatefulWidget because the best score is loaded from saved
// data after the screen appears, and changes after a winning game.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/charm_lock_game.dart';
import '../services/best_scores.dart';
import '../theme.dart';
import '../widgets/cabin_door.dart';
import '../widgets/charm_art.dart';
import '../widgets/cozy_widgets.dart';
import 'game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // ---- state variables
  int? best; // fewest tries to win, or null if never won

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final loaded = await BestScores.get();
    if (mounted) setState(() => best = loaded);
  }

  Future<void> _play() async {
    // Open the game on top; wait until the player comes back,
    // then reload the best score in case they set a new record.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
    _loadBest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CozyBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            // Same three layouts as the game screen:
            if (w >= 900 && h >= 600) {
              // laptop: the sound button floats in the corner
              return Stack(
                children: [
                  Positioned.fill(child: _wideLayout()),
                  const Positioned(top: 16, right: 16, child: SoundToggle()),
                ],
              );
            }
            if (w > h * 1.15) return _landscapeLayout(); // phone on its side
            return _narrowLayout(); // phone upright
          },
        ),
      ),
    );
  }

  // Laptop: door on the left, text on the right. The whole block is drawn
  // at 1200 x 760 and shrinks to fit smaller windows.
  Widget _wideLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        // Shrinks on small laptops, grows on big monitors (max 1.3x).
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200 * 1.3, maxHeight: 760 * 1.3),
          child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1200,
            height: 760,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CabinDoor(height: 660),
                const SizedBox(width: 96),
                SizedBox(width: 520, child: _intro(titleSize: 92)),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  // Phone upright: instructions on top, Play pinned to the bottom.
  // No scrolling: on a short phone the instructions shrink a little to fit
  // (FittedBox) instead of running off the screen.
  Widget _narrowLayout() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, area) {
              final width = math.min(520.0, area.maxWidth - 40);
              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 0, 10),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // small door next to the title, sound button on the right
                          Row(
                            children: [
                              const CabinDoor(height: 92),
                              const SizedBox(width: 14),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Charm Lock',
                                    maxLines: 1,
                                    style: heading(38).copyWith(letterSpacing: -1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const SoundToggle(size: 42),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _intro(titleSize: 0, showPlay: false, compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Material(
          color: AppColors.linen,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          elevation: 6,
          shadowColor: const Color(0x553A2210),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Row(
                  children: [
                    Expanded(child: _playButton()),
                    const SizedBox(width: 14),
                    // gems on top, best score underneath
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const GemCounter(compact: true),
                        const SizedBox(height: 6),
                        _bestBadge(compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Phone on its side: title + Play on the left, how to play on the right.
  // Each side shrinks to fit the height, so there's no scrolling.
  Widget _landscapeLayout() {
    Widget fit(double width, Widget child) => Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: width, child: child),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: fit(
              380,
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CabinDoor(height: 104),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('Charm Lock', maxLines: 1, style: heading(40).copyWith(letterSpacing: -1)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SoundToggle(size: 42),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The cabin door is sealed with four charms. Find the right charms in '
                    'the right order before the last candle burns out.',
                    style: body(16, color: AppColors.barkMuted, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _playButton()),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const GemCounter(compact: true),
                          const SizedBox(height: 6),
                          _bestBadge(compact: true),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: fit(400, _intro(titleSize: 0, showPlay: false, compact: true, showPitch: false)),
          ),
        ],
      ),
    );
  }

  Widget _playButton() => CozyButton(
        label: 'Play',
        icon: Icons.play_arrow_rounded,
        height: 64,
        expand: true,
        onPressed: _play,
      );

  /// [compact] = one short line (phone bottom bar).
  Widget _bestBadge({bool compact = false}) {
    final best = this.best;
    final tries = best == 1 ? 'try' : 'tries';
    final bestText = compact
        ? (best == null ? 'No best yet' : 'Best: $best $tries')
        : (best == null ? 'No best\nscore yet' : 'Best score\n$best $tries');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          best == null ? Icons.emoji_events_outlined : Icons.emoji_events_rounded,
          color: best == null ? AppColors.faded : AppColors.ember,
          size: compact ? 18 : 26,
        ),
        SizedBox(width: compact ? 4 : 8),
        Text(
          bestText,
          style: body(compact ? 13 : 15, weight: FontWeight.w700, color: AppColors.barkMuted, height: 1.35),
        ),
      ],
    );
  }

  /// [compact] = phone version: no big title (it's in the header row),
  /// smaller text and tighter spacing.
  Widget _intro({
    required double titleSize,
    bool showPlay = true,
    bool compact = false,
    bool showPitch = true,
  }) {
    final gap = compact ? 8.0 : 10.0;
    final ruleSize = compact ? 15.0 : 17.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text('Charm Lock', style: heading(titleSize).copyWith(letterSpacing: -2)),
          const SizedBox(height: 8),
        ],
        if (showPitch) ...[
          Text(
            'The cabin door is sealed with four charms. Find the right charms in '
            'the right order before the last candle burns out.',
            style: body(compact ? 16 : 21, color: AppColors.barkMuted, height: 1.45),
          ),
          SizedBox(height: compact ? 14 : 22),
        ],
        Text('How to play', style: heading(compact ? 20 : 24, weight: FontWeight.w700)),
        SizedBox(height: compact ? 8 : 12),
        _Rule(Charm.leaf, 'Tap charms to fill the four sockets, then try the lock.', size: ruleSize),
        SizedBox(height: gap),
        _Rule(Charm.moon, 'Read the clues. Every candle still lit when you win earns a gem.', size: ruleSize),
        SizedBox(height: gap),
        _Rule(Charm.berry, 'Each charm can only be used once in a guess. You have 8 tries.', size: ruleSize),
        SizedBox(height: gap),
        _Rule(Charm.honey, 'Stuck? Light the lantern once to see one charm. It costs a candle.', size: ruleSize),
        SizedBox(height: compact ? 14 : 20),
        _ClueLegend(compact: compact),
        if (showPlay) ...[
          const SizedBox(height: 26),
          Row(
            children: [
              SizedBox(width: 220, child: _playButton()),
              const SizedBox(width: 20),
              _bestBadge(),
              const SizedBox(width: 16),
              const GemCounter(),
            ],
          ),
        ],
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  final Charm charm;
  final String text;
  final double size; // text size
  const _Rule(this.charm, this.text, {this.size = 17});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CharmToken(charm, size: size > 16 ? 40 : 34),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: body(size, height: 1.35))),
      ],
    );
  }
}

/// The brown strip that explains the three clue pegs.
class _ClueLegend extends StatelessWidget {
  final bool compact;
  const _ClueLegend({this.compact = false});

  @override
  Widget build(BuildContext context) {
    Widget item(PegKind kind, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CluePeg(kind, size: compact ? 14 : 18),
            SizedBox(width: compact ? 6 : 10),
            Text(label, style: body(compact ? 13 : 16, weight: FontWeight.w700, color: AppColors.linen)),
          ],
        );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22, vertical: compact ? 10 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0xFF9A6A43), Color(0xFF8A5D3A)]),
      ),
      child: Wrap(
        alignment: compact ? WrapAlignment.spaceBetween : WrapAlignment.start,
        spacing: compact ? 10 : 22,
        runSpacing: 10,
        children: [
          item(PegKind.ember, 'Right spot'),
          item(PegKind.ring, 'Wrong spot'),
          item(PegKind.ash, 'Not in the lock'),
        ],
      ),
    );
  }
}

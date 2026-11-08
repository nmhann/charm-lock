// lib/game/charm_lock_game.dart
//
// The RULES of Charm Lock. This file knows nothing about buttons, colors,
// sounds or screens. The UI asks it questions ("can I submit?") and tells
// it what the player did ("place a moon"). Keeping it separate means:
//   - you can explain the rules without opening any UI code
//   - the "separate game logic from the interface" requirement is met
//   - the UI just redraws whatever this class says the game looks like

import 'dart:math';

/// The 6 charms. An enum is a fixed list of named values.
enum Charm { acorn, leaf, mushroom, moon, berry, honey }

/// Where the game is right now.
enum GameStatus { playing, won, lost }

/// The clue the lock gives back after a guess.
class Clue {
  final int exact; // right charm, right spot  -> ember
  final int partial; // right charm, wrong spot -> ring

  const Clue(this.exact, this.partial);

  /// How many charms in the guess earned nothing.
  int get missing => CharmLockGame.codeLength - exact - partial;

  /// The sentence shown under the board, so clues never rely on dots alone.
  String describe() {
    if (exact == CharmLockGame.codeLength) return 'All four charms are in the right spot!';
    final parts = <String>[];
    if (exact > 0) parts.add('$exact in the right spot');
    if (partial > 0) parts.add('$partial in the wrong spot');
    if (missing > 0) parts.add('$missing not in the lock');
    return '${parts.join(', ')}.';
  }
}

/// One finished row on the board: the 4 charms and the clue they earned.
class Guess {
  final List<Charm> charms;
  final Clue clue;

  const Guess(this.charms, this.clue);
}

/// What the lantern revealed: which charm goes in which socket.
class Hint {
  final int position; // 0 to 3
  final Charm charm;

  const Hint(this.position, this.charm);
}

class CharmLockGame {
  static const int codeLength = 4;
  static const int totalCandles = 8; // 8 tries

  final Random _random;
  final List<Charm>? _fixedSecret; // only used by the tests
  late List<Charm> _secret; // the hidden code (private: starts with _)

  /// Finished guesses, oldest first. This is what the board draws.
  final List<Guess> history = [];

  /// The row being built right now. null = empty socket.
  final List<Charm?> current = List.filled(codeLength, null);

  GameStatus status = GameStatus.playing;

  /// The lantern hint, once used (null before that).
  Hint? hint;

  CharmLockGame({Random? random, List<Charm>? fixedSecret})
      : _random = random ?? Random(),
        _fixedSecret = fixedSecret {
    newGame();
  }

  // ---------------------------------------------------------------- setup

  /// Starts (or restarts) a game. Used by Play, Start over and Play again.
  void newGame() {
    final fixed = _fixedSecret;
    if (fixed != null) {
      _secret = List.of(fixed);
    } else {
      // Shuffle all 6 charms and keep the first 4: random code, no repeats.
      final all = List<Charm>.of(Charm.values)..shuffle(_random);
      _secret = all.take(codeLength).toList();
    }

    history.clear();
    for (var i = 0; i < codeLength; i++) {
      current[i] = null;
    }
    hint = null;
    status = GameStatus.playing;
  }

  // ------------------------------------------------------- questions (getters)
  // The UI reads these to decide what to show. They never change anything.

  int get maxTries => totalCandles;
  bool get hintUsed => hint != null;

  /// The lantern costs one candle, so it takes one try away.
  int get candlesUsed => history.length + (hintUsed ? 1 : 0);
  int get triesLeft => maxTries - candlesUsed;

  /// How many guesses the player gets in total (one fewer after the lantern).
  int get totalTries => maxTries - (hintUsed ? 1 : 0);

  int get triesUsed => history.length;

  /// Which try the player is on, e.g. "Try 4 of 8".
  int get currentTry => history.length + 1;

  int get filledSockets => current.where((c) => c != null).length;

  /// Is this charm already somewhere in the current row?
  bool isInUse(Charm charm) => current.contains(charm);

  /// Can this charm be placed right now? (Used to enable picker buttons.)
  bool canPlace(Charm charm) =>
      status == GameStatus.playing &&
      filledSockets < codeLength &&
      !isInUse(charm); // no repeats in one guess

  /// Enables / disables the "Try the lock" button.
  bool get canSubmit => status == GameStatus.playing && filledSockets == codeLength;

  /// The lantern can be used once, and only if a try would still be left after.
  bool get canUseHint => status == GameStatus.playing && !hintUsed && triesLeft >= 2;

  /// Bonus gems for winning without the lantern.
  static const int noLanternBonus = 2;

  /// Gems earned this game (the reward). Only when you win:
  /// one for every candle still lit, plus a bonus if you didn't use the
  /// lantern. Fewer tries = more candles left = more gems.
  int get gemsEarned =>
      status == GameStatus.won ? triesLeft + (hintUsed ? 0 : noLanternBonus) : 0;

  /// Only reveal the code once the game is over.
  List<Charm>? get revealedCode =>
      status == GameStatus.playing ? null : List.unmodifiable(_secret);

  // ------------------------------------------------- actions (change the game)
  // Each one checks the move is allowed first and returns false/null if not,
  // so an invalid action can never break the game.

  /// Puts a charm in the first empty socket.
  bool placeCharm(Charm charm) {
    if (!canPlace(charm)) return false;
    current[current.indexOf(null)] = charm;
    return true;
  }

  /// Takes a charm back out of a socket (tap a placed charm).
  bool removeAt(int slot) {
    if (status != GameStatus.playing || current[slot] == null) return false;
    current[slot] = null;
    return true;
  }

  /// Takes back the last placed charm (used by the Backspace key).
  bool removeLast() {
    for (var i = codeLength - 1; i >= 0; i--) {
      if (current[i] != null) return removeAt(i);
    }
    return false;
  }

  /// Locks in the current row, scores it, and checks for win / lose.
  /// Returns the clue, or null if the guess wasn't allowed.
  Clue? submitGuess() {
    if (!canSubmit) return null;

    final guess = current.cast<Charm>().toList(); // safe: none are null
    final clue = scoreGuess(guess);
    history.add(Guess(guess, clue));

    for (var i = 0; i < codeLength; i++) {
      current[i] = null; // empty row for the next try
    }

    if (clue.exact == codeLength) {
      status = GameStatus.won;
    } else if (triesLeft == 0) {
      status = GameStatus.lost;
    }
    return clue;
  }

  /// Lights the lantern: reveals one charm in its correct socket.
  /// It prefers a socket the player has never got right yet.
  Hint? useHint() {
    if (!canUseHint) return null;

    final unsolved = [
      for (var i = 0; i < codeLength; i++)
        if (!history.any((g) => g.charms[i] == _secret[i])) i,
    ];
    final choices = unsolved.isEmpty ? List.generate(codeLength, (i) => i) : unsolved;
    final position = choices[_random.nextInt(choices.length)];

    hint = Hint(position, _secret[position]);
    return hint;
  }

  // ------------------------------------------------------------ the core rule

  /// Compares a guess to the secret code. Two passes, so repeated charms
  /// are never counted twice:
  ///   1. count charms in exactly the right spot
  ///   2. for the rest, count charms that are somewhere else in the code
  Clue scoreGuess(List<Charm> guess) {
    var exact = 0;
    final leftoverInCode = <Charm, int>{}; // secret charms not matched exactly
    final leftoverGuess = <Charm>[]; // guessed charms not matched exactly

    for (var i = 0; i < codeLength; i++) {
      if (guess[i] == _secret[i]) {
        exact++;
      } else {
        leftoverInCode[_secret[i]] = (leftoverInCode[_secret[i]] ?? 0) + 1;
        leftoverGuess.add(guess[i]);
      }
    }

    var partial = 0;
    for (final charm in leftoverGuess) {
      final count = leftoverInCode[charm] ?? 0;
      if (count > 0) {
        partial++;
        leftoverInCode[charm] = count - 1; // use it up
      }
    }
    return Clue(exact, partial);
  }
}

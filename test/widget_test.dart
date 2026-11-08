// test/widget_test.dart
//
// Tests for the game RULES only (no screens). Run them with:
//   flutter test
//
// (The file keeps the default name so `flutter create .` doesn't
// replace it with a sample test that doesn't fit this app.)

import 'package:flutter_test/flutter_test.dart';
import 'package:charm_lock/game/charm_lock_game.dart';

void main() {
  const secret = [Charm.moon, Charm.acorn, Charm.berry, Charm.leaf];

  CharmLockGame newGame() => CharmLockGame(fixedSecret: secret);

  void place(CharmLockGame game, List<Charm> charms) {
    for (final c in charms) {
      game.placeCharm(c);
    }
  }

  test('a random code has 4 different charms', () {
    for (var i = 0; i < 50; i++) {
      final game = CharmLockGame();
      // play 8 wrong-or-right guesses until the code is revealed
      while (game.status == GameStatus.playing) {
        place(game, [Charm.acorn, Charm.leaf, Charm.mushroom, Charm.moon]);
        game.submitGuess();
      }
      final code = game.revealedCode!;
      expect(code.length, 4);
      expect(code.toSet().length, 4);
    }
  });

  test('scoring counts right spot and wrong spot', () {
    final game = newGame();
    final clue = game.scoreGuess([Charm.moon, Charm.honey, Charm.berry, Charm.leaf]);
    expect(clue.exact, 3);
    expect(clue.partial, 0);
    expect(clue.missing, 1);

    final mixed = game.scoreGuess([Charm.acorn, Charm.moon, Charm.mushroom, Charm.honey]);
    expect(mixed.exact, 0);
    expect(mixed.partial, 2);
  });

  test('a charm cannot be placed twice in one guess', () {
    final game = newGame();
    expect(game.placeCharm(Charm.moon), isTrue);
    expect(game.placeCharm(Charm.moon), isFalse);
    expect(game.filledSockets, 1);
  });

  test('you cannot submit until all 4 sockets are full', () {
    final game = newGame();
    place(game, [Charm.moon, Charm.acorn, Charm.berry]);
    expect(game.canSubmit, isFalse);
    expect(game.submitGuess(), isNull);
    game.placeCharm(Charm.leaf);
    expect(game.canSubmit, isTrue);
  });

  test('taking a charm back empties that socket', () {
    final game = newGame();
    place(game, [Charm.moon, Charm.acorn]);
    expect(game.removeAt(0), isTrue);
    expect(game.current[0], isNull);
    expect(game.placeCharm(Charm.honey), isTrue);
    expect(game.current[0], Charm.honey); // fills the first empty socket
  });

  test('guessing the code wins the game', () {
    final game = newGame();
    place(game, secret);
    game.submitGuess();
    expect(game.status, GameStatus.won);
    expect(game.triesUsed, 1);
  });

  test('8 wrong guesses loses the game', () {
    final game = newGame();
    for (var i = 0; i < 8; i++) {
      place(game, [Charm.acorn, Charm.moon, Charm.berry, Charm.leaf]);
      game.submitGuess();
    }
    expect(game.status, GameStatus.lost);
    expect(game.triesLeft, 0);
    expect(game.revealedCode, secret);
  });

  test('the game has 8 tries', () {
    expect(newGame().triesLeft, 8);
  });

  test('the lantern shows a correct charm, once, and costs a candle', () {
    final game = newGame();
    final hint = game.useHint()!;
    expect(hint.charm, secret[hint.position]);
    expect(game.triesLeft, 7);
    expect(game.useHint(), isNull); // only once
  });

  test('the lantern is locked when only one try is left', () {
    final game = newGame();
    for (var i = 0; i < 7; i++) {
      place(game, [Charm.acorn, Charm.moon, Charm.berry, Charm.leaf]);
      game.submitGuess();
    }
    expect(game.triesLeft, 1);
    expect(game.canUseHint, isFalse);
  });

  test('winning earns a gem per candle left, plus the no-lantern bonus', () {
    final game = newGame();
    place(game, [Charm.acorn, Charm.moon, Charm.berry, Charm.leaf]); // wrong
    game.submitGuess();
    expect(game.gemsEarned, 0); // nothing until you win
    place(game, secret);
    game.submitGuess();
    expect(game.triesLeft, 6);
    expect(game.gemsEarned, 6 + 2);
  });

  test('using the lantern removes the bonus', () {
    final game = newGame();
    game.useHint(); // costs a candle
    place(game, secret);
    game.submitGuess();
    expect(game.gemsEarned, 6); // 6 candles left, no bonus
  });

  test('losing earns no gems', () {
    final game = newGame();
    for (var i = 0; i < 8; i++) {
      place(game, [Charm.acorn, Charm.moon, Charm.berry, Charm.leaf]);
      game.submitGuess();
    }
    expect(game.gemsEarned, 0);
  });

  test('newGame resets everything', () {
    final game = newGame();
    place(game, [Charm.acorn, Charm.moon, Charm.berry, Charm.leaf]);
    game.submitGuess();
    place(game, [Charm.honey]);
    game.useHint();
    game.newGame();
    expect(game.hint, isNull);
    expect(game.history, isEmpty);
    expect(game.filledSockets, 0);
    expect(game.status, GameStatus.playing);
  });
}

// lib/services/sound_service.dart
//
// Plays the cozy sounds. The rest of the app only calls:
//   SoundService.instance.play(Sfx.place)
//   SoundService.instance.startMusic() / stopMusic()
//   SoundService.instance.toggle()
// If audio fails for any reason, the game keeps working silently.
// Sound never carries information on its own: everything it signals is
// also shown on screen.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The short sound effects, with their file and volume.
enum Sfx {
  place('place.wav', 0.7), // charm pressed into a socket
  remove('remove.wav', 0.6), // charm taken back
  latch('latch.wav', 0.8), // "Try the lock"
  lantern('lantern.wav', 0.6), // hint used
  win('win.wav', 0.8), // door opens
  lose('lose.wav', 0.8); // last candle snuffed

  const Sfx(this.file, this.volume);
  final String file;
  final double volume;
}

class SoundService {
  SoundService._();

  /// One shared instance for the whole app (a "singleton").
  static final SoundService instance = SoundService._();

  static const _prefKey = 'sound_on';

  /// true = sound on. Widgets listen to this to show the right icon.
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  AudioPlayer? _music; // the looping background music
  bool _musicWanted = false; // is the game screen open?

  /// Reads the saved on/off setting. Called once in main().
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefKey) ?? true;
    } catch (e) {
      debugPrint('Sound settings could not be read: $e');
    }
  }

  /// The speaker button calls this.
  Future<void> toggle() async {
    enabled.value = !enabled.value;
    if (enabled.value) {
      if (_musicWanted) await _playMusic();
    } else {
      await _music?.stop();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled.value);
    } catch (e) {
      debugPrint('Sound settings could not be saved: $e');
    }
  }

  /// Soft background music, started when the game screen opens.
  Future<void> startMusic() async {
    _musicWanted = true;
    if (enabled.value) await _playMusic();
  }

  Future<void> stopMusic() async {
    _musicWanted = false;
    try {
      await _music?.stop();
    } catch (_) {}
  }

  Future<void> _playMusic() async {
    try {
      final music = _music ??= AudioPlayer();
      await music.setReleaseMode(ReleaseMode.loop); // plays forever, seamlessly
      await music.play(AssetSource('sounds/music.wav'), volume: 0.35);
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  /// Plays one short effect. A new player each time, so effects can overlap.
  Future<void> play(Sfx sfx) async {
    if (!enabled.value) return;
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.first.then((_) => player.dispose());
      await player.play(AssetSource('sounds/${sfx.file}'), volume: sfx.volume);
    } catch (e) {
      debugPrint('Sound ${sfx.name} failed: $e');
    }
  }
}

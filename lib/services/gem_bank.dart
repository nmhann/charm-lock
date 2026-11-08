// lib/services/gem_bank.dart
//
// Keeps the player's total gems (the reward points) and saves them with
// shared_preferences, so they survive closing the app.
//
// The RULE for how many gems you earn lives in CharmLockGame
// (gemsEarned). This class only stores the running total.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GemBank {
  GemBank._();

  /// One shared instance for the whole app.
  static final GemBank instance = GemBank._();

  static const _key = 'gems';

  /// The total. Widgets listen to this, so the counter updates by itself.
  final ValueNotifier<int> total = ValueNotifier<int>(0);

  /// Reads the saved total. Called once in main().
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      total.value = prefs.getInt(_key) ?? 0;
    } catch (e) {
      debugPrint('Gems could not be read: $e');
    }
  }

  /// Adds gems and saves. Returns the new total.
  Future<int> add(int amount) async {
    if (amount <= 0) return total.value;
    total.value += amount;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, total.value);
    } catch (e) {
      debugPrint('Gems could not be saved: $e');
    }
    return total.value;
  }
}

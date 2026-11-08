// lib/services/best_scores.dart
//
// Remembers the fewest tries needed to win. Saved with
// shared_preferences, so it survives closing the app (in Chrome it's
// stored in the browser).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BestScores {
  static const _key = 'best_score';

  /// The best score, or null if the player has never won.
  static Future<int?> get() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_key);
    } catch (e) {
      debugPrint('Best score could not be read: $e');
      return null;
    }
  }

  /// Saves [tries] if it beats the old best. Returns true for a new record.
  static Future<bool> submit(int tries) async {
    final best = await get();
    if (best != null && tries >= best) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, tries);
    } catch (e) {
      debugPrint('Best score could not be saved: $e');
    }
    return true;
  }
}

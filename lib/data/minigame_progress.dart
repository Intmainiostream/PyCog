import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/minigame.dart';

/// Remembers the student's stars for each MINIGAME challenge, saved on the
/// phone with shared_preferences (so it stays after the app closes).
///
/// The first solve of a challenge (always 1 to 3 stars) is its permanent
/// RECORD: replaying never changes it. Stars saved by earlier versions are
/// records already (same keys).
///
/// It decides which levels are open: Level 1 always is, and each next level
/// opens once at least [challengesToUnlockNext] challenges of the level
/// before it have 1 star or more.
class MinigameProgress extends ChangeNotifier {
  MinigameProgress._(this._prefs);

  static Future<MinigameProgress> load() async {
    return MinigameProgress._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static String _key(String challengeId) => 'minigame.stars.$challengeId';
  static String _hintsKey(String challengeId) => 'minigame.hints.$challengeId';
  static String _wrongKey(String challengeId) => 'minigame.wrong.$challengeId';

  /// Hints opened on this challenge since it was last finished (so leaving
  /// and coming back keeps them open and keeps the star limit).
  int hintsUsed(String challengeId) =>
      _prefs.getInt(_hintsKey(challengeId)) ?? 0;

  /// Saves the hints opened so far. Never goes down until [clearAttempt].
  Future<void> saveHintsUsed(String challengeId, int hints) async {
    if (hints <= hintsUsed(challengeId)) return;
    await _prefs.setInt(_hintsKey(challengeId), hints);
  }

  /// Quiz answers (by their place in the data) already picked wrong on this
  /// challenge since it was last finished.
  Set<int> wrongPicks(String challengeId) => {
    for (final s in _prefs.getStringList(_wrongKey(challengeId)) ?? const [])
      ?int.tryParse(s),
  };

  /// Saves one more wrong quiz pick.
  Future<void> saveWrongPick(String challengeId, int answer) async {
    final picks = wrongPicks(challengeId)..add(answer);
    await _prefs.setStringList(_wrongKey(challengeId), [
      for (final p in picks.toList()..sort()) '$p',
    ]);
  }

  /// Forgets the hints and wrong picks of the last try (called when the
  /// challenge is finished, so a replay starts fresh). The record stays.
  Future<void> clearAttempt(String challengeId) async {
    await _prefs.remove(_hintsKey(challengeId));
    await _prefs.remove(_wrongKey(challengeId));
  }

  /// The permanent record of this challenge (0 = not solved yet).
  int bestStars(String challengeId) => _prefs.getInt(_key(challengeId)) ?? 0;

  /// Saves a solve. Only the first solve with at least 1 star is saved (the
  /// record); later solves change nothing. Returns true if this solve
  /// became the record.
  Future<bool> saveStars(String challengeId, int stars) async {
    if (stars < 1 || bestStars(challengeId) >= 1) return false;
    await _prefs.setInt(_key(challengeId), stars);
    notifyListeners();
    return true;
  }

  /// All recorded stars in a level added up.
  int levelStars(MinigameLevel level) => level.challenges.fold(
    0,
    (sum, challenge) => sum + bestStars(challenge.id),
  );

  /// How many challenges in a level have at least 1 star.
  int solvedCount(MinigameLevel level) =>
      level.challenges.where((c) => bestStars(c.id) >= 1).length;

  /// How many levels, from the start, are open.
  int unlockedCount(List<MinigameLevel> levels) {
    if (levels.isEmpty) return 0;
    var count = 1;
    while (count < levels.length &&
        solvedCount(levels[count - 1]) >= challengesToUnlockNext) {
      count++;
    }
    return count;
  }
}

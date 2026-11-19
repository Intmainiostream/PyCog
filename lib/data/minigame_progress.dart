import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/minigame.dart';

/// Remembers the student's best stars for each MINIGAME challenge, saved on
/// the phone with shared_preferences (so it stays after the app closes).
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
  /// challenge is finished, so a replay starts fresh). Best stars stay.
  Future<void> clearAttempt(String challengeId) async {
    await _prefs.remove(_hintsKey(challengeId));
    await _prefs.remove(_wrongKey(challengeId));
  }

  /// Best stars ever earned on this challenge (0 = not solved yet).
  int bestStars(String challengeId) => _prefs.getInt(_key(challengeId)) ?? 0;

  /// Saves a result. Only replaces the saved value if it's better.
  /// Returns true if this is a new best.
  Future<bool> saveStars(String challengeId, int stars) async {
    if (stars <= bestStars(challengeId)) return false;
    await _prefs.setInt(_key(challengeId), stars);
    notifyListeners();
    return true;
  }

  /// All best stars in a level added up.
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

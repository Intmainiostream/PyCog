import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/minigame.dart';
import 'lessons.dart';
import 'progress_controller.dart';

/// Remembers the student's stars for each MINIGAME challenge, saved on the
/// phone with shared_preferences (so it stays after the app closes).
///
/// The first solve of a challenge (always 1 to 3 stars) is its permanent
/// RECORD: replaying never changes it. Stars saved by earlier versions are
/// records already (same keys).
///
/// It decides which levels are open. A level opens only when BOTH are true:
///  * its Play lesson is finished (Level N goes with Lesson N: the lesson's
///    quiz has at least 1 star, the same rule that opens the next lesson);
///  * for Level 2 and up: the level before it is open and at least
///    [challengesToUnlockNext] of its challenges have 1 star or more.
/// Locking a level again never deletes its saved stars.
class MinigameProgress extends ChangeNotifier {
  MinigameProgress._(this._prefs);

  static Future<MinigameProgress> load() async {
    return MinigameProgress._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static String _key(String challengeId) => 'minigame.stars.$challengeId';
  static String _hintsKey(String challengeId) => 'minigame.hints.$challengeId';
  static String _wrongKey(String challengeId) => 'minigame.wrong.$challengeId';
  static String _bonusKey(MinigameLevel level) =>
      'minigame.levelBonus.L${level.number}';

  /// Star Points for finishing a whole level, given once per level.
  static const levelBonusPoints = 10;

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

  /// Whether every challenge of a full level (10 challenges) has a star.
  bool levelComplete(MinigameLevel level) =>
      level.challenges.length >= challengesPerLevel &&
      solvedCount(level) == level.challenges.length;

  /// Whether the one-time level bonus was already given for [level].
  bool levelBonusGiven(MinigameLevel level) =>
      _prefs.getBool(_bonusKey(level)) ?? false;

  /// Gives the level bonus once: true only the first time [level] is found
  /// complete. Saved, so it can never be given twice.
  Future<bool> claimLevelBonus(MinigameLevel level) async {
    if (!levelComplete(level) || levelBonusGiven(level)) return false;
    await _prefs.setBool(_bonusKey(level), true);
    return true;
  }

  /// How many challenges in a level have at least 1 star.
  int solvedCount(MinigameLevel level) =>
      level.challenges.where((c) => bestStars(c.id) >= 1).length;

  /// The Play lesson that goes with [level] (Level N = Lesson N).
  static String? lessonIdFor(MinigameLevel level) =>
      level.number >= 1 && level.number <= lessons.length
      ? lessons[level.number - 1].id
      : null;

  /// Whether the Play lesson of [level] is finished (its quiz has a star).
  bool lessonFinished(MinigameLevel level) {
    final id = lessonIdFor(level);
    if (id == null) return false;
    return (_prefs.getInt(ProgressController.quizStarsKey(id)) ?? 0) >= 1;
  }

  /// How many levels, from the start, are open.
  int unlockedCount(List<MinigameLevel> levels) {
    var count = 0;
    while (count < levels.length &&
        lessonFinished(levels[count]) &&
        (count == 0 ||
            solvedCount(levels[count - 1]) >= challengesToUnlockNext)) {
      count++;
    }
    return count;
  }

  /// Why the level at [index] is locked: its lesson is not finished, and/or
  /// the level before it is not open with stars on enough challenges.
  ({bool needsLesson, bool needsStars}) whyLocked(
    List<MinigameLevel> levels,
    int index,
  ) {
    final needsLesson = !lessonFinished(levels[index]);
    final needsStars =
        index > 0 &&
        !(index - 1 < unlockedCount(levels) &&
            solvedCount(levels[index - 1]) >= challengesToUnlockNext);
    return (needsLesson: needsLesson, needsStars: needsStars);
  }
}

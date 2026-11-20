import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';

/// Remembers the student's stars for each lesson, saved on the phone with
/// shared_preferences: quiz stars and game bonus stars.
///
/// The first finished run that earns at least 1 star becomes the lesson's
/// permanent RECORD: replaying never raises it, lowers it or overwrites it
/// (so nobody can farm stars). Stars saved by earlier versions of the app
/// are records already (same keys), so nothing is lost.
///
/// It decides which lessons are unlocked: Lesson 1 always is, and each next
/// lesson unlocks once the one before it has at least 1 QUIZ star. Bonus
/// stars only add to the total; they never unlock anything.
class ProgressController extends ChangeNotifier {
  ProgressController._(this._prefs);

  static Future<ProgressController> load() async {
    return ProgressController._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static String _key(String lessonId) => 'progress.stars.$lessonId';
  static String _bonusKey(String lessonId) => 'progress.bonus.$lessonId';

  /// The permanent record of this lesson's quiz (0 = not finished yet).
  int bestStars(String lessonId) => _prefs.getInt(_key(lessonId)) ?? 0;

  /// Saves a finished quiz run. Only the first run with at least 1 star is
  /// saved (the record); later runs change nothing. Returns true if this
  /// run became the record.
  Future<bool> saveStars(String lessonId, int stars) async {
    if (stars < 1 || bestStars(lessonId) >= 1) return false;
    await _prefs.setInt(_key(lessonId), stars);
    notifyListeners();
    return true;
  }

  /// The permanent record of this lesson's game (0 = not finished yet).
  int bestBonusStars(String lessonId) =>
      _prefs.getInt(_bonusKey(lessonId)) ?? 0;

  /// Saves a finished game run, like [saveStars]: only the first run with
  /// at least 1 star counts. Returns true if this run became the record.
  Future<bool> saveBonusStars(String lessonId, int stars) async {
    if (stars < 1 || bestBonusStars(lessonId) >= 1) return false;
    await _prefs.setInt(_bonusKey(lessonId), stars);
    notifyListeners();
    return true;
  }

  /// All recorded quiz stars + bonus stars added up (shown on the home
  /// screen).
  int totalStars(List<Lesson> lessons) => lessons.fold(
    0,
    (sum, lesson) => sum + bestStars(lesson.id) + bestBonusStars(lesson.id),
  );

  /// How many lessons, from the start, are open.
  int unlockedCount(List<Lesson> lessons) {
    if (lessons.isEmpty) return 0;
    var count = 1;
    while (count < lessons.length && bestStars(lessons[count - 1].id) >= 1) {
      count++;
    }
    return count;
  }
}

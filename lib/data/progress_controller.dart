import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';

/// Remembers the student's best quiz stars for each lesson, saved on the
/// phone with shared_preferences.
///
/// It decides which lessons are unlocked: Lesson 1 always is, and each next
/// lesson unlocks once the one before it has at least 1 star.
class ProgressController extends ChangeNotifier {
  ProgressController._(this._prefs);

  static Future<ProgressController> load() async {
    return ProgressController._(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  static String _key(String lessonId) => 'progress.stars.$lessonId';

  /// Best stars ever earned in this lesson's quiz (0 = not passed yet).
  int bestStars(String lessonId) => _prefs.getInt(_key(lessonId)) ?? 0;

  /// Saves a quiz result. Only replaces the saved value if it's better.
  /// Returns true if this is a new best.
  Future<bool> saveStars(String lessonId, int stars) async {
    if (stars <= bestStars(lessonId)) return false;
    await _prefs.setInt(_key(lessonId), stars);
    notifyListeners();
    return true;
  }

  /// All best stars added up (shown on the home screen).
  int totalStars(List<Lesson> lessons) =>
      lessons.fold(0, (sum, lesson) => sum + bestStars(lesson.id));

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

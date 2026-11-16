import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import 'lesson_card.dart';
import 'match_game.dart';
import 'quiz.dart';

/// Describes one Python lesson on the home screen's lesson path.
///
/// The title is not stored as plain text. Instead we store a function that
/// picks the right translated title, so it changes when the language changes.
class Lesson {
  const Lesson({
    required this.id,
    required this.icon,
    required this.title,
    this.cards = const [],
    this.quiz = const [],
    this.game = const [],
    this.perfectQuizMessage,
  });

  /// A stable, language-independent name (useful later for saving progress).
  final String id;

  /// Icon for the lesson (for future use, e.g. a lesson header).
  final IconData icon;

  /// Returns the lesson title in the current language.
  final String Function(AppLocalizations l10n) title;

  /// The explanation cards. Empty = lesson not written yet ("Coming soon").
  final List<LessonCard> cards;

  /// The quiz at the end of the lesson. Empty = no quiz yet.
  final List<QuizQuestion> quiz;

  /// The "Label the Robot Box" game rounds. Empty = no game yet.
  final List<GameRound> game;

  /// Cog's line for a perfect (3-star) quiz, e.g. "You are a data type
  /// master!". Null = the default line (which mentions variables).
  final LocalizedText? perfectQuizMessage;

  bool get hasContent => cards.isNotEmpty;
  bool get hasQuiz => quiz.isNotEmpty;
  bool get hasGame => game.isNotEmpty;
}

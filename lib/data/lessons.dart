import 'package:material_ui/material_ui.dart';

import '../models/lesson.dart';
import 'games/data_types_game.dart';
import 'games/variables_game.dart';
import 'lessons/data_types_lesson.dart';
import 'lessons/if_statements_lesson.dart';
import 'lessons/variables_lesson.dart';
import 'quizzes/data_types_quiz.dart';
import 'quizzes/if_statements_quiz.dart';
import 'quizzes/variables_quiz.dart';

/// The list of lessons, in the order students should take them.
/// To add a lesson: add its title to both .arb files, then add an entry here.
/// To fill in a lesson: write its cards in lib/data/lessons/ (see
/// variables_lesson.dart) and pass them as `cards:`. Its quiz goes in
/// lib/data/quizzes/ (see variables_quiz.dart), passed as `quiz:`, and its
/// game rounds in lib/data/games/ (see variables_game.dart), as `game:`.
final List<Lesson> lessons = [
  Lesson(
    id: 'variables',
    icon: Icons.inventory_2_outlined,
    title: (l10n) => l10n.lessonVariables,
    cards: variablesLessonCards,
    quiz: variablesQuiz,
    game: variablesGame,
  ),
  Lesson(
    id: 'data_types',
    icon: Icons.category_outlined,
    title: (l10n) => l10n.lessonDataTypes,
    cards: dataTypesLessonCards,
    quiz: dataTypesQuiz,
    game: dataTypesGame,
    perfectQuizMessage: (l10n) => l10n.lesson2Perfect,
  ),
  Lesson(
    id: 'if_statements',
    icon: Icons.call_split,
    title: (l10n) => l10n.lessonIfStatements,
    cards: ifStatementsLessonCards,
    quiz: ifStatementsQuiz,
    perfectQuizMessage: (l10n) => l10n.lesson3Perfect,
  ),
  Lesson(id: 'loops', icon: Icons.loop, title: (l10n) => l10n.lessonLoops),
  Lesson(
    id: 'functions',
    icon: Icons.functions,
    title: (l10n) => l10n.lessonFunctions,
  ),
];

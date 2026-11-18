import 'package:material_ui/material_ui.dart';

import '../models/lesson.dart';
import 'games/data_types_game.dart';
import 'games/functions_game.dart';
import 'games/if_statements_game.dart';
import 'games/input_output_game.dart';
import 'games/lists_game.dart';
import 'games/logic_game.dart';
import 'games/loops_game.dart';
import 'games/math_operators_game.dart';
import 'games/strings_game.dart';
import 'games/variables_game.dart';
import 'lessons/data_types_lesson.dart';
import 'lessons/functions_lesson.dart';
import 'lessons/if_statements_lesson.dart';
import 'lessons/input_output_lesson.dart';
import 'lessons/lists_lesson.dart';
import 'lessons/logic_lesson.dart';
import 'lessons/loops_lesson.dart';
import 'lessons/math_operators_lesson.dart';
import 'lessons/strings_lesson.dart';
import 'lessons/variables_lesson.dart';
import 'quizzes/data_types_quiz.dart';
import 'quizzes/functions_quiz.dart';
import 'quizzes/if_statements_quiz.dart';
import 'quizzes/input_output_quiz.dart';
import 'quizzes/lists_quiz.dart';
import 'quizzes/logic_quiz.dart';
import 'quizzes/loops_quiz.dart';
import 'quizzes/math_operators_quiz.dart';
import 'quizzes/strings_quiz.dart';
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
    game: ifStatementsGame,
    perfectQuizMessage: (l10n) => l10n.lesson3Perfect,
  ),
  Lesson(
    id: 'loops',
    icon: Icons.loop,
    title: (l10n) => l10n.lessonLoops,
    cards: loopsLessonCards,
    quiz: loopsQuiz,
    game: loopsGame,
    perfectQuizMessage: (l10n) => l10n.lesson4Perfect,
  ),
  Lesson(
    id: 'functions',
    icon: Icons.functions,
    title: (l10n) => l10n.lessonFunctions,
    cards: functionsLessonCards,
    quiz: functionsQuiz,
    game: functionsGame,
    perfectQuizMessage: (l10n) => l10n.lesson5Perfect,
  ),
  Lesson(
    id: 'math_operators',
    icon: Icons.calculate_outlined,
    title: (l10n) => l10n.lesson6Title,
    cards: mathOperatorsLessonCards,
    quiz: mathOperatorsQuiz,
    game: mathOperatorsGame,
    perfectQuizMessage: (l10n) => l10n.lesson6Perfect,
  ),
  Lesson(
    id: 'strings',
    icon: Icons.text_fields,
    title: (l10n) => l10n.lesson7Title,
    cards: stringsLessonCards,
    quiz: stringsQuiz,
    game: stringsGame,
    perfectQuizMessage: (l10n) => l10n.lesson7Perfect,
  ),
  Lesson(
    id: 'lists',
    icon: Icons.backpack_outlined,
    title: (l10n) => l10n.lesson8Title,
    cards: listsLessonCards,
    quiz: listsQuiz,
    game: listsGame,
    perfectQuizMessage: (l10n) => l10n.lesson8Perfect,
  ),
  Lesson(
    id: 'input_output',
    icon: Icons.keyboard_outlined,
    title: (l10n) => l10n.lesson9Title,
    cards: inputOutputLessonCards,
    quiz: inputOutputQuiz,
    game: inputOutputGame,
    perfectQuizMessage: (l10n) => l10n.lesson9Perfect,
  ),
  Lesson(
    id: 'logic',
    icon: Icons.account_tree_outlined,
    title: (l10n) => l10n.lesson10Title,
    cards: logicLessonCards,
    quiz: logicQuiz,
    game: logicGame,
    perfectQuizMessage: (l10n) => l10n.lesson10Perfect,
  ),
];

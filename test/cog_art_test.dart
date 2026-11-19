import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/screens/game_results_screen.dart';
import 'package:pycog/screens/minigame_map_screen.dart';
import 'package:pycog/screens/quiz_results_screen.dart';
import 'package:pycog/theme/app_theme.dart';
import 'package:pycog/widgets/cog_art.dart';
import 'package:pycog/widgets/cog_feedback_card.dart';
import 'package:pycog/widgets/cog_placeholder.dart';

import 'home_test.dart' show startApp;
import 'minigame_screen_test.dart' as mg;
import 'test_helpers.dart';
import 'wordmark_test.dart' show pngSize;

Finder pose(CogPose p) =>
    find.byWidgetPredicate((w) => w is CogArt && w.pose == p);

Widget app(SettingsController settings, Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: settings.locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: home),
);

Future<SettingsController> pumpApp(WidgetTester tester, Widget home) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await SettingsController.load();
  await tester.pumpWidget(app(settings, home));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  group('The pictures', () {
    test('both files are in the app and their shapes match the code', () {
      for (final (asset, aspect) in [
        (CogArt.wavingAsset, CogArt.wavingAspect),
        (CogArt.cheeringAsset, CogArt.cheeringAspect),
      ]) {
        final (w, h) = pngSize(asset);
        expect(w / h, closeTo(aspect, 0.001), reason: asset);
      }
    });

    test('the new Cog is never taller than the old square Cog', () {
      for (final p in CogPose.values) {
        final art = CogArt(pose: p, size: 100);
        expect(art.height, lessThanOrEqualTo(100), reason: '$p');
        expect(art.width, 100 * CogArt.widthFactor);
      }
    });

    testWidgets('screen readers skip the picture, like the old Cog', (
      tester,
    ) async {
      await pumpApp(tester, const CogArt(pose: CogPose.waving, size: 100));
      expect(
        find.descendant(
          of: find.byType(CogArt),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(
        tester.getSize(find.byType(CogArt)),
        const Size(120, 120 / CogArt.wavingAspect),
      );
    });
  });

  group('Greetings: Cog waves', () {
    testWidgets('home screen', (tester) async {
      await startApp(tester);
      expect(pose(CogPose.waving), findsOneWidget);
      expect(find.byType(CogPlaceholder), findsNothing);
    });

    testWidgets('lesson trail', (tester) async {
      await startApp(tester);
      await openTrail(tester);
      expect(pose(CogPose.waving), findsOneWidget);
      expect(find.byType(CogPlaceholder), findsNothing);
    });

    testWidgets('MINIGAME map: Cog beside the speech bubble', (tester) async {
      await mg.pumpMap(tester);
      expect(
        find.descendant(
          of: find.byType(CogSays),
          matching: pose(CogPose.waving),
        ),
        findsOneWidget,
      );
    });
  });

  group('Celebrations: Cog puts both hands up', () {
    testWidgets('quiz results', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsController.load();
      await tester.pumpWidget(
        app(
          settings,
          QuizResultsScreen(
            lesson: lessons.first,
            lessonNumber: 1,
            stars: 1,
            isNewBest: false,
            unlockedLessonNumber: null,
            settings: settings,
            progress: await ProgressController.load(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(pose(CogPose.cheering), findsOneWidget);
      expect(pose(CogPose.waving), findsNothing);
    });

    testWidgets('game results', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = await SettingsController.load();
      await tester.pumpWidget(
        app(
          settings,
          GameResultsScreen(
            lesson: lessons.first,
            lessonNumber: 1,
            stars: 2,
            isNewBest: false,
            settings: settings,
            progress: await ProgressController.load(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(pose(CogPose.cheering), findsOneWidget);
    });

    testWidgets('a cheer card (right answer, challenge solved)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const CogFeedbackCard(text: 'Yes!', mood: CogMood.happy),
      );
      expect(pose(CogPose.cheering), findsOneWidget);
      expect(find.byType(CogPlaceholder), findsNothing);
    });

    testWidgets('the Level 10 ending card', (tester) async {
      await mg.pumpMap(
        tester,
        size: const Size(800, 2400),
        saved: {
          for (var l = 1; l <= 10; l++)
            for (var c = 1; c <= 10; c++) 'minigame.stars.mgL${l}C$c': 1,
        },
      );
      await mg.tapAndSettle(tester, mg.key('mg-level-10'));
      expect(
        find.descendant(
          of: mg.key('mg-all-done'),
          matching: pose(CogPose.cheering),
        ),
        findsOneWidget,
      );
    });
  });

  group('Hints and explanations keep the drawn Cog', () {
    for (final mood in [CogMood.hint, CogMood.explaining]) {
      testWidgets('$mood', (tester) async {
        await pumpApp(tester, CogFeedbackCard(text: 'Hmm', mood: mood));
        expect(find.byType(CogPlaceholder), findsOneWidget);
        expect(find.byType(CogArt), findsNothing);
      });
    }
  });
}

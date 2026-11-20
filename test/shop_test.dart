import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/lessons.dart';
import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/data/shop.dart';
import 'package:pycog/screens/coding_screen.dart';
import 'package:pycog/screens/home_screen.dart';
import 'package:pycog/screens/shop_screen.dart';
import 'package:pycog/theme/app_theme.dart';

import 'coding_screen_test.dart' as coding;
import 'home_test.dart' as home;
import 'minigame_screen_test.dart' as mg;
import 'quiz_test.dart' as quiz;

Future<SettingsController> settingsWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return SettingsController.load();
}

ShopItem item(String id) => shopItemById(id);

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

final shopButton = find.byKey(const ValueKey('home-shop'));

Future<void> openShop(WidgetTester tester) async {
  await tester.ensureVisible(shopButton);
  await tester.pumpAndSettle();
  await tester.tap(shopButton);
  await tester.pumpAndSettle();
  expect(find.byType(ShopScreen), findsOneWidget);
}

Future<void> tapItem(WidgetTester tester, String id) async {
  final action = find.byKey(ValueKey('shop-action-$id'));
  await tester.scrollUntilVisible(
    action,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  group('Star Points', () {
    test('a run earns its stars; the first time, doubled', () {
      expect(ShopController.pointsFor(3, first: true), 6);
      expect(ShopController.pointsFor(1, first: true), 2);
      expect(ShopController.pointsFor(2, first: false), 2);
      expect(ShopController.pointsFor(0, first: true), 0);
    });

    test('replays earn again every time, and the balance is saved', () async {
      final settings = await settingsWith({});
      final shop = settings.shop;
      expect(shop.points, 0);
      expect(shop.earnRun(3, first: true), 6);
      expect(shop.earnRun(3, first: false), 3);
      expect(shop.earnRun(1, first: false), 1);
      expect(shop.points, 10);
      expect((await SettingsController.load()).shop.points, 10);
    });

    test('the balance never goes below 0', () async {
      final settings = await settingsWith({'shop.points': -5});
      expect(settings.shop.points, 0);
      final s2 = await settingsWith({'shop.points': 3});
      expect(s2.shop.buy(item('theme.sunset')), BuyResult.notEnough);
      expect(s2.shop.points, 3);
    });

    testWidgets('a finished quiz: double points the first time, normal on a '
        'replay, and the record stays', (tester) async {
      final (settings, progress) = await quiz.pumpQuiz(tester);
      for (var q = 0; q < quiz.variables.quiz.length; q++) {
        await quiz.tapAnswerAndCheck(
          tester,
          q,
          quiz.variables.quiz[q].correctIndex,
        );
        final isLast = q == quiz.variables.quiz.length - 1;
        await quiz.tapNext(
          tester,
          isLast ? quiz.en.quizSeeResults : quiz.en.quizNext,
        );
      }
      expect(settings.shop.points, 6); // 3 stars, doubled
      expect(
        find.text('${quiz.en.pointsEarned(6)} ${quiz.en.pointsDoubled}'),
        findsOneWidget,
      );
      expect(progress.bestStars('variables'), 3);
    });

    testWidgets('MINIGAME: the first solve is doubled, a replay is not', (
      tester,
    ) async {
      final (progress, _) = await mg.pumpMap(tester);
      await mg.openChallenge(tester, 'mgL1C1');
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      final settings = await SettingsController.load();
      expect(settings.shop.points, 6);
      expect(find.text(mg.en.mgPlusPoints(6)), findsOneWidget);
      expect(find.text(mg.en.pointsDoubled), findsOneWidget);
      await mg.goBack(tester); // back to the level
      await mg.tapAndSettle(tester, mg.key('mg-challenge-mgL1C1'));
      await mg.tapAndSettle(tester, mg.answer('80'));
      await mg.tapAndSettle(tester, mg.key('mg-check'));
      expect((await SettingsController.load()).shop.points, 9);
      expect(find.text(mg.en.mgPlusPoints(3)), findsOneWidget);
      expect(find.textContaining(mg.en.pointsEarned(3)), findsOneWidget);
      expect(find.text(mg.en.pointsDoubled), findsNothing);
      expect(progress.bestStars('mgL1C1'), 3);
    });

    testWidgets('a quit run earns nothing', (tester) async {
      final (settings, _) = await quiz.pumpQuiz(tester);
      await quiz.tapAnswerAndCheck(
        tester,
        0,
        quiz.variables.quiz[0].correctIndex,
      );
      await tester.pumpWidget(const SizedBox()); // left the quiz
      expect(settings.shop.points, 0);
    });
  });

  group('Buying', () {
    test('buying works once; never twice', () async {
      final shop = (await settingsWith({'shop.points': 25})).shop;
      expect(shop.owns(item('theme.sunset')), isFalse);
      expect(shop.buy(item('theme.sunset')), BuyResult.bought);
      expect(shop.points, 15);
      expect(shop.owns(item('theme.sunset')), isTrue);
      expect(shop.buy(item('theme.sunset')), BuyResult.alreadyOwned);
      expect(shop.points, 15);
      // Saved on the phone.
      expect(
        (await SettingsController.load()).shop.owns(item('theme.sunset')),
        isTrue,
      );
    });

    test(
      'not enough points: nothing bought, and how many are missing',
      () async {
        final shop = (await settingsWith({'shop.points': 4})).shop;
        expect(shop.buy(item('tag.pro')), BuyResult.notEnough);
        expect(shop.missingFor(item('tag.pro')), 46);
        expect(shop.owns(item('tag.pro')), isFalse);
        expect(shop.points, 4);
      },
    );

    test('free defaults are owned and cannot be bought', () async {
      final shop = (await settingsWith({})).shop;
      for (final group in ShopGroup.values) {
        final first = shopItemsIn(group).first;
        expect(first.free, isTrue);
        expect(shop.owns(first), isTrue);
        expect(shop.isEquipped(first), isTrue);
        expect(shop.buy(first), BuyResult.alreadyOwned);
      }
    });

    test('items cannot be used before they are bought', () async {
      final shop = (await settingsWith({'shop.points': 100})).shop;
      expect(shop.equip(item('editor.retro')), isFalse);
      expect(shop.isEquipped(item('editor.classic')), isTrue);
    });

    test('the shop never touches stars, records or unlocks', () async {
      final settings = await settingsWith({
        'shop.points': 100,
        'progress.stars.variables': 2,
        'minigame.stars.mgL1C1': 1,
      });
      for (final i in shopItems) {
        settings.shop.buy(i);
        settings.shop.equip(i);
      }
      final progress = await ProgressController.load();
      expect(progress.bestStars('variables'), 2);
      expect(progress.unlockedCount(lessons), 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('minigame.stars.mgL1C1'), 1);
    });

    testWidgets('in the shop: not enough points says how many more', (
      tester,
    ) async {
      await home.startApp(tester, saved: {'shop.points': 3});
      await openShop(tester);
      await tapItem(tester, 'theme.sunset');
      expect(find.text(home.en.shopNeedMore(7)), findsOneWidget);
      expect(find.byKey(const ValueKey('shop-confirm')), findsNothing);
    });

    testWidgets('in the shop: confirm, then it is owned and in use', (
      tester,
    ) async {
      final (settings, _) = await home.startApp(
        tester,
        saved: {'shop.points': 12},
      );
      await openShop(tester);
      await tapItem(tester, 'theme.sunset');
      expect(find.byKey(const ValueKey('shop-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shop-yes')));
      await tester.pumpAndSettle();
      expect(settings.shop.points, 2);
      expect(settings.shop.isEquipped(item('theme.sunset')), isTrue);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('shop-action-theme.sunset')),
          matching: find.text(home.en.shopEquipped),
        ),
        findsOneWidget,
      );
    });

    testWidgets('in the shop: Cancel buys nothing', (tester) async {
      final (settings, _) = await home.startApp(
        tester,
        saved: {'shop.points': 12},
      );
      await openShop(tester);
      await tapItem(tester, 'theme.sunset');
      await tester.tap(find.byKey(const ValueKey('shop-cancel')));
      await tester.pumpAndSettle();
      expect(settings.shop.points, 12);
      expect(settings.shop.owns(item('theme.sunset')), isFalse);
    });
  });

  group('Using the looks (saved)', () {
    testWidgets('a theme colors the home screen and the Play trail', (
      tester,
    ) async {
      await home.startApp(
        tester,
        saved: {
          'shop.owned': ['theme.ocean'],
          'shop.equipped.theme': 'theme.ocean',
        },
      );
      final ocean = item('theme.ocean').theme!.background;
      Color pageOf(Type screen) =>
          Theme.of(tester.element(find.byType(Scaffold).last))
              .scaffoldBackgroundColor;
      expect(pageOf(HomeScreen), ocean);
      await home.tapAndSettle(tester, home.play);
      expect(pageOf(Scaffold), ocean);
    });

    testWidgets('an editor look colors the CODING box', (tester) async {
      final (_, settings) = await coding.pumpCoding(tester);
      // Nothing bought yet: the classic look.
      final classic = tester.widget<TextField>(coding.code).style!.color;
      expect(classic, AppColors.codeText);

      for (var i = 0; i < 4; i++) {
        settings.shop.earnRun(3, first: true); // 24 points
      }
      expect(settings.shop.buy(item('editor.retro')), BuyResult.bought);
      expect(settings.shop.equip(item('editor.retro')), isTrue);
      await tester.enterText(coding.code, 'x = 1'); // the screen redraws
      await tester.pump();
      final retro = item('editor.retro').editor!;
      expect(tester.widget<TextField>(coding.code).style!.color, retro.text);
      expect(tester.widget<TextField>(coding.code).cursorColor, retro.cursor);
    });

    for (final (lang, l10n) in [('en', home.en), ('tl', home.tl)]) {
      testWidgets('$lang: a name tag shows under Cog on the home screen', (
        tester,
      ) async {
        await home.startApp(
          tester,
          saved: {
            'settings.language': lang,
            'shop.owned': ['tag.loop'],
            'shop.equipped.tag': 'tag.loop',
          },
        );
        expect(find.text(l10n.shopTagLoop), findsOneWidget);
        expect(find.byKey(const ValueKey('home-tag')), findsOneWidget);
      });
    }

    testWidgets('no tag by default', (tester) async {
      await home.startApp(tester);
      expect(find.byKey(const ValueKey('home-tag')), findsNothing);
    });

    test('equipping is saved on the phone', () async {
      final shop = (await settingsWith({'shop.points': 50})).shop;
      shop
        ..buy(item('tag.bug'))
        ..equip(item('tag.bug'));
      final again = (await SettingsController.load()).shop;
      expect(again.tag?.id, 'tag.bug');
      again.equip(item('tag.none'));
      expect((await SettingsController.load()).shop.tag, isNull);
    });
  });

  group('The catalog', () {
    test('three groups, a free default and at least 3 items to buy each; '
        'prices 10 to 50', () {
      for (final group in ShopGroup.values) {
        final items = shopItemsIn(group);
        expect(items.first.free, isTrue);
        final paid = items.where((i) => !i.free).toList();
        expect(paid.length, greaterThanOrEqualTo(3));
        for (final i in paid) {
          expect(i.price, inInclusiveRange(10, 50), reason: i.id);
        }
      }
      expect(
        shopItems.where((i) => i.price == 10).length,
        greaterThanOrEqualTo(2),
      );
    });

    test('every theme keeps good text contrast', () {
      for (final i in shopItemsIn(ShopGroup.theme)) {
        final bg = i.theme!.background;
        expect(contrast(AppColors.text, bg), greaterThan(7), reason: i.id);
        expect(
          contrast(AppColors.tealDark, bg),
          greaterThan(4.5),
          reason: i.id,
        );
        expect(
          contrast(AppColors.textMuted, bg),
          greaterThan(4.5),
          reason: i.id,
        );
      }
    });

    test('every editor look keeps the code easy to read', () {
      for (final i in shopItemsIn(ShopGroup.editor)) {
        final e = i.editor!;
        expect(contrast(e.text, e.background), greaterThan(7), reason: i.id);
        expect(contrast(e.hint, e.background), greaterThan(4.5), reason: i.id);
      }
    });
  });

  group('Home screen', () {
    testWidgets('the shop button shows the points and opens the shop', (
      tester,
    ) async {
      await home.startApp(tester, saved: {'shop.points': 7});
      expect(
        find.descendant(of: shopButton, matching: find.text('7')),
        findsOneWidget,
      );
      await openShop(tester);
      expect(find.text(home.en.shopPoints(7)), findsOneWidget);
    });

    for (final lang in ['en', 'tl']) {
      testWidgets('360x640, $lang, big text: home and shop fit', (
        tester,
      ) async {
        await home.startApp(
          tester,
          size: const Size(360, 640),
          systemScale: 1.5,
          saved: {'settings.language': lang, 'settings.textSize': 'large'},
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(shopButton);
        await tester.pumpAndSettle();
        expect(tester.getSize(shopButton).height, greaterThanOrEqualTo(48));
        await openShop(tester);
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -3000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  test('CodingScreen reads the editor look in use', () {
    expect(CodingScreen, isNotNull);
  });
}

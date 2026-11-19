import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/main.dart';
import 'package:pycog/screens/about_screen.dart';
import 'package:pycog/screens/coding_screen.dart';
import 'package:pycog/screens/home_screen.dart';
import 'package:pycog/screens/lesson_screen.dart';
import 'package:pycog/screens/minigame_map_screen.dart';
import 'package:pycog/screens/onboarding_screen.dart';
import 'package:pycog/screens/trail_screen.dart';
import 'package:pycog/sound/sounds.dart';
import 'package:pycog/widgets/settings_sheet.dart';

import 'fake_sounds.dart';
import 'home_test.dart' as home;
import 'minigame_screen_test.dart' as mg;
import 'music_test.dart' show FakeTracks;
import 'test_helpers.dart';

/// The songs asked for, with repeats of the same song removed (asking for
/// the song that is already playing never restarts it).
List<Song?> changes(FakeMusicPlayer music) {
  final out = <Song?>[];
  for (final s in music.asked) {
    if (out.isEmpty || out.last != s) out.add(s);
  }
  return out;
}

Future<void> goBack(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

Future<void> openLesson(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('lesson-node-variables')));
  await tester.pumpAndSettle();
  expect(find.byType(LessonScreen), findsOneWidget);
}

void main() {
  testWidgets('splash and onboarding are silent; the title song starts on '
      'the home screen', (tester) async {
    final music = useFakeMusic();
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      PyCogApp(settings: settings, progress: await ProgressController.load()),
    );
    await tester.pump(const Duration(seconds: 1)); // splash
    expect(music.asked.whereType<Song>(), isEmpty);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(music.asked.whereType<Song>(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('onb-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(changes(music), [Song.title]);
  });

  testWidgets('home: title; Play and everything in it: game; back home: '
      'title again', (tester) async {
    final music = useFakeMusic();
    await home.startApp(tester);
    expect(changes(music), [Song.title]);

    await openTrail(tester);
    expect(find.byType(TrailScreen), findsOneWidget);
    expect(music.current, Song.game);

    await openLesson(tester);
    await goBack(tester); // lesson -> trail
    expect(changes(music), [Song.title, Song.game]); // never restarted

    await goBack(tester); // trail -> home
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(changes(music), [Song.title, Song.game, Song.title]);
  });

  testWidgets('MINIGAME map and challenges: game', (tester) async {
    final music = useFakeMusic();
    await mg.pumpMap(tester);
    expect(changes(music), [Song.game]);
    await mg.openChallenge(tester, 'mgL1C1');
    await goBack(tester);
    await goBack(tester);
    expect(changes(music), [Song.game]);
  });

  testWidgets('MINIGAME from home: game; back: title', (tester) async {
    final music = useFakeMusic();
    await home.startApp(tester);
    await home.tapAndSettle(tester, home.minigame);
    expect(find.byType(MinigameMapScreen), findsOneWidget);
    expect(changes(music), [Song.title, Song.game]);
    await goBack(tester);
    expect(changes(music), [Song.title, Song.game, Song.title]);
  });

  testWidgets('CODING: game; About keeps it playing', (tester) async {
    final music = useFakeMusic();
    await home.startApp(tester);
    await home.tapAndSettle(tester, home.coding);
    expect(find.byType(CodingScreen), findsOneWidget);
    expect(changes(music), [Song.title, Song.game]);

    final about = find.byKey(const ValueKey('coding-about'));
    await tester.ensureVisible(about);
    await tester.pumpAndSettle();
    await tester.tap(about);
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    await goBack(tester); // About -> CODING
    expect(changes(music), [Song.title, Song.game]);
  });

  testWidgets('Settings keeps the song that is playing', (tester) async {
    final music = useFakeMusic();
    final (settings, _) = await home.startApp(tester);
    await openTrail(tester);
    showSettingsSheet(tester.element(find.byType(TrailScreen)), settings);
    await tester.pumpAndSettle();
    await goBack(tester); // close the sheet
    expect(changes(music), [Song.title, Song.game]);
  });

  testWidgets('turning Music off in Settings stops it; on again plays the '
      'song of the screen', (tester) async {
    final music = useFakeMusic();
    final (settings, _) = await home.startApp(tester);
    await openTrail(tester);
    settings.setMusicOn(false);
    await tester.pumpAndSettle();
    expect(music.current, isNull);
    settings.setMusicOn(true);
    await tester.pumpAndSettle();
    expect(music.current, Song.game);
  });

  testWidgets('with the real fade rules: the game song starts once and keeps '
      'going from the trail into a lesson and back', (tester) async {
    final tracks = FakeTracks();
    Sounds.reset();
    addTearDown(Sounds.reset);
    Sounds.music = FadingMusicPlayer(tracks);
    await home.startApp(tester);
    await openTrail(tester);
    await openLesson(tester);
    await goBack(tester);
    await tester.pump(const Duration(seconds: 2)); // let the fades finish
    expect(tracks.log.where((e) => e == 'play game').length, 1);
    expect(tracks.playing, {Song.game});
    expect(tracks.volume[Song.game], FadingMusicPlayer.volume);

    // Home again: the title song fades back in, the game song pauses.
    await goBack(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(tracks.playing, {Song.title});
    expect(tracks.volume[Song.game], 0);
  });
}

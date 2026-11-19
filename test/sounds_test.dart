import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/l10n/generated/app_localizations.dart';
import 'package:pycog/main.dart';
import 'package:pycog/sound/sounds.dart';
import 'package:pycog/widgets/settings_sheet.dart';
import 'package:pycog/widgets/sticker_switch.dart';

import 'fake_sounds.dart';

final en = lookupAppLocalizations(const Locale('en'));

/// Records clips started by [SequencedSoundPlayer].
class FakeClips implements SoundClips {
  final started = <Sfx>[];
  int stops = 0;

  @override
  Future<void> preload() async {}

  @override
  void start(Sfx sfx) => started.add(sfx);

  @override
  void stop() => stops++;
}

/// A player that breaks on every call.
class BrokenPlayer extends SoundPlayer {
  @override
  void play(Sfx sfx) => throw Exception('no speaker');

  @override
  void playStars(int count, {Sfx? first}) => throw Exception('no speaker');

  @override
  void stop() => throw Exception('no speaker');
}

Future<SettingsController> settingsWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return SettingsController.load();
}

void main() {
  group('Sound files', () {
    test('all 9 sounds are registered in pubspec.yaml', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/sfx/'),
      );
      expect(Sfx.values.map((s) => s.name), [
        'tap',
        'correct',
        'wrong',
        'star',
        'finish',
        'hint',
        'run',
        'output',
        'victory',
      ]);
    });

    test('each sound file loads from the app bundle and is an MP3', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final sfx in Sfx.values) {
        final data = await rootBundle.load(sfx.assetPath);
        final bytes = data.buffer.asUint8List();
        expect(bytes.length, greaterThan(1000), reason: sfx.name);
        final id3 = bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
        final frame = bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
        expect(id3 || frame, isTrue, reason: '${sfx.name} is not an MP3');
      }
    });
  });

  group('The sound switch', () {
    test('without settings, sounds are on; the default player is silent', () {
      Sounds.reset();
      addTearDown(Sounds.reset);
      expect(Sounds.on, isTrue);
      expect(Sounds.player, isA<SilentSoundPlayer>());
      Sounds.play(Sfx.tap); // no speaker needed, no error
    });

    test('"Sound effects" is on by default', () async {
      final settings = await settingsWith({});
      expect(settings.soundOn, isTrue);
    });

    test('on: the sound is asked for; off: nothing plays', () async {
      final fake = useFakeSounds();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      Sounds.play(Sfx.tap);
      Sounds.stars(2);
      expect(fake.played, [Sfx.tap, Sfx.star, Sfx.star]);

      fake.clear();
      settings.setSoundOn(false);
      Sounds.play(Sfx.correct);
      Sounds.stars(3, first: Sfx.finish);
      expect(fake.played, isEmpty);
    });

    test('turning sounds off stops a sound that is playing', () async {
      final fake = useFakeSounds();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      settings.setSoundOn(false);
      expect(fake.stops, 1);
    });

    test('the switch is saved on the phone', () async {
      final settings = await settingsWith({'settings.sound': false});
      expect(settings.soundOn, isFalse);
      settings.setSoundOn(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.sound'), isTrue);
    });

    testWidgets('the app follows the switch in Settings', (tester) async {
      final fake = useFakeSounds();
      final settings = await settingsWith({});
      await tester.pumpWidget(
        PyCogApp(settings: settings, progress: await ProgressController.load()),
      );
      await tester.pumpAndSettle();
      showSettingsSheet(tester.element(find.byType(Scaffold).first), settings);
      await tester.pumpAndSettle();
      final soundSwitch = find.byWidgetPredicate(
        (w) => w is StickerSwitch && w.semanticLabel == en.settingsSound,
      );
      expect(soundSwitch, findsOneWidget);
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();
      expect(settings.soundOn, isFalse);
      fake.clear();
      Sounds.play(Sfx.tap);
      expect(fake.played, isEmpty);
    });

    test('a broken player never stops the app', () async {
      Sounds.reset();
      addTearDown(Sounds.reset);
      Sounds.player = BrokenPlayer();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      Sounds.play(Sfx.tap);
      Sounds.stars(3);
      settings.setSoundOn(false); // stop() throws inside
    });

    test('Sounds.tapThen plays a tap, then does the action', () {
      final fake = useFakeSounds();
      var done = 0;
      Sounds.tapThen(() => done++)!();
      expect(fake.played, [Sfx.tap]);
      expect(done, 1);
      expect(Sounds.tapThen(null), isNull);
    });
  });

  group('One sound at a time', () {
    testWidgets('stars play one after the other, quickly', (tester) async {
      final clips = FakeClips();
      final player = SequencedSoundPlayer(clips);
      player.playStars(3);
      expect(clips.started, [Sfx.star]);
      await tester.pump(SequencedSoundPlayer.starGap);
      expect(clips.started, [Sfx.star, Sfx.star]);
      await tester.pump(SequencedSoundPlayer.starGap);
      expect(clips.started, [Sfx.star, Sfx.star, Sfx.star]);
      await tester.pump(const Duration(seconds: 2));
      expect(clips.started.length, 3);
    });

    testWidgets('a first sound, then the stars', (tester) async {
      final clips = FakeClips();
      SequencedSoundPlayer(clips).playStars(2, first: Sfx.finish);
      expect(clips.started, [Sfx.finish]);
      await tester.pump(SequencedSoundPlayer.gapAfter(Sfx.finish));
      await tester.pump(SequencedSoundPlayer.starGap);
      expect(clips.started, [Sfx.finish, Sfx.star, Sfx.star]);
    });

    testWidgets('a new sound replaces stars that are still waiting', (
      tester,
    ) async {
      final clips = FakeClips();
      final player = SequencedSoundPlayer(clips);
      player.playStars(3);
      player.play(Sfx.tap);
      await tester.pump(const Duration(seconds: 2));
      expect(clips.started, [Sfx.star, Sfx.tap]);
    });

    testWidgets('stop cancels waiting stars', (tester) async {
      final clips = FakeClips();
      final player = SequencedSoundPlayer(clips);
      player.playStars(3);
      player.stop();
      await tester.pump(const Duration(seconds: 2));
      expect(clips.started, [Sfx.star]);
      expect(clips.stops, 1);
    });

    test('0 stars: nothing plays', () {
      final clips = FakeClips();
      SequencedSoundPlayer(clips).playStars(0);
      expect(clips.started, isEmpty);
    });
  });
}

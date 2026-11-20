import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/sound/sounds.dart';

import 'fake_sounds.dart';

/// The one music player, pretend version: remembers what it was told and
/// can make loading a song slow (to test requests that finish late).
class FakeBackend implements MusicBackend {
  final log = <String>[];
  Song? loaded;
  bool playing = false;
  double volume = 0;
  Duration at = Duration.zero;
  int preloads = 0;
  final loads = <Song>[];

  /// When set, load() waits for this before it finishes.
  final slow = <Song, Completer<void>>{};

  /// Songs whose file is missing.
  final missing = <Song>{};

  @override
  Future<void> preload() async => preloads++;

  @override
  Future<void> load(Song song) async {
    log.add('load ${song.name}');
    loads.add(song);
    await slow[song]?.future;
    if (missing.contains(song)) throw Exception('no file');
    loaded = song;
    at = Duration.zero;
  }

  @override
  Future<void> play() async {
    log.add('play ${loaded?.name}');
    playing = true;
  }

  @override
  Future<void> pause() async {
    if (playing) log.add('pause ${loaded?.name}');
    playing = false;
  }

  @override
  Future<void> setVolume(double v) async => volume = v;

  @override
  Future<Duration?> position() async => at;

  @override
  Future<void> seek(Duration position) async {
    log.add('seek ${position.inSeconds}s');
    at = position;
  }
}

/// A ready manager with a fake player.
Future<(MusicManager, FakeBackend)> manager() async {
  final backend = FakeBackend();
  final music = MusicManager(backend);
  await music.preload();
  return (music, backend);
}

/// Lets every fade finish.
Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

class BrokenMusic extends MusicPlayer {
  @override
  void playSong(Song? song) => throw Exception('no speaker');

  @override
  void pause() => throw Exception('no speaker');

  @override
  void resume() => throw Exception('no speaker');
}

Future<SettingsController> settingsWith(Map<String, Object> saved) async {
  SharedPreferences.setMockInitialValues(saved);
  return SettingsController.load();
}

void main() {
  group('Music files', () {
    test('both songs are registered in pubspec.yaml', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/music/'),
      );
      expect(Song.title.assetPath, 'assets/music/TitleSong.mp3');
      expect(Song.game.assetPath, 'assets/music/GameBg.mp3');
    });

    test('each song loads from the app bundle and is an MP3', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final song in Song.values) {
        final data = await rootBundle.load(song.assetPath);
        final bytes = data.buffer.asUint8List();
        expect(bytes.length, greaterThan(100000), reason: song.name);
        final id3 = bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33;
        final frame = bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
        expect(id3 || frame, isTrue, reason: '${song.name} is not an MP3');
      }
    });
  });

  group('The Music switch', () {
    test('"Music" is on by default and saved on the phone', () async {
      final settings = await settingsWith({});
      expect(settings.musicOn, isTrue);
      settings.setMusicOn(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings.music'), isFalse);
      expect((await SettingsController.load()).musicOn, isFalse);
    });

    test(
      'off: no music at all; on again: the right song for the screen',
      () async {
        final music = useFakeMusic();
        final settings = await settingsWith({});
        Sounds.useSettings(settings);
        Sounds.screenSong(Song.game);
        expect(music.current, Song.game);

        settings.setMusicOn(false);
        expect(music.current, isNull);
        Sounds.screenSong(Song.title); // a new screen while music is off
        expect(music.current, isNull);

        settings.setMusicOn(true);
        expect(music.current, Song.title);
      },
    );

    test('music stays off when the switch was saved as off', () async {
      final music = useFakeMusic();
      Sounds.useSettings(await settingsWith({'settings.music': false}));
      Sounds.screenSong(Song.title);
      expect(music.asked.whereType<Song>(), isEmpty);
    });

    test('turning sound effects off does not stop the music', () async {
      final sounds = useFakeSounds();
      final music = useFakeMusic();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      Sounds.screenSong(Song.game);
      settings.setSoundOn(false);
      expect(music.current, Song.game);
      expect(music.asked, isNot(contains(null)));
      expect(sounds.stops, 1); // only the sound effects stop
    });

    test('turning music off does not stop the sound effects', () async {
      final sounds = useFakeSounds();
      final music = useFakeMusic();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      settings.setMusicOn(false);
      expect(sounds.stops, 0);
      Sounds.play(Sfx.tap);
      expect(sounds.played, [Sfx.tap]);
      expect(music.current, isNull);
    });

    test('a broken music player never stops the app', () async {
      Sounds.reset();
      addTearDown(Sounds.reset);
      Sounds.music = BrokenMusic();
      final settings = await settingsWith({});
      Sounds.useSettings(settings);
      Sounds.screenSong(Song.title);
      settings.setMusicOn(false);
      Sounds.appLifecycle(AppLifecycleState.paused);
      Sounds.appLifecycle(AppLifecycleState.resumed);
    });
  });

  group('App in the background', () {
    test('the music pauses when the app is away and continues after', () {
      final music = useFakeMusic();
      Sounds.appLifecycle(AppLifecycleState.paused); // home button / lock
      expect(music.pauses, 1);
      Sounds.appLifecycle(AppLifecycleState.resumed);
      expect(music.resumes, 1);
      Sounds.appLifecycle(AppLifecycleState.hidden);
      expect(music.pauses, 2);
      Sounds.appLifecycle(AppLifecycleState.inactive); // shade pulled down
      expect(music.pauses, 2);
    });
  });

  group('Music manager (one player)', () {
    testWidgets('a song fades in to a quiet volume', (tester) async {
      final (music, backend) = await manager();
      music.playSong(Song.title);
      await tester.pump(const Duration(milliseconds: 10));
      expect(backend.log, ['load title', 'play title']);
      expect(backend.volume, lessThan(0.1));
      await settle(tester);
      expect(backend.volume, MusicManager.volume);
      expect(MusicManager.volume, inInclusiveRange(0.3, 0.4));
      final fade = MusicManager.fadeOut + MusicManager.fadeIn;
      expect(fade.inMilliseconds, inInclusiveRange(500, 1000));
    });

    testWidgets('the same song asked again: nothing happens', (tester) async {
      final (music, backend) = await manager();
      music.playSong(Song.game);
      await settle(tester);
      final before = List.of(backend.log);
      music.playSong(Song.game);
      music.playSong(Song.game);
      await settle(tester);
      expect(backend.log, before); // no load, no restart, no cut
      expect(backend.playing, isTrue);
      expect(backend.volume, MusicManager.volume);
    });

    testWidgets('another song: the old one fades out, then the new one '
        'fades in', (tester) async {
      final (music, backend) = await manager();
      music.playSong(Song.title);
      await settle(tester);
      music.playSong(Song.game);
      await tester.pump(MusicManager.fadeOut ~/ 2);
      expect(backend.loaded, Song.title); // still fading out
      expect(backend.volume, inExclusiveRange(0, MusicManager.volume));
      await settle(tester);
      expect(backend.loaded, Song.game);
      expect(backend.volume, MusicManager.volume);
      expect(backend.log, [
        'load title',
        'play title',
        'pause title',
        'load game',
        'play game',
      ]);
    });

    testWidgets('a song continues where it was when it comes back', (
      tester,
    ) async {
      final (music, backend) = await manager();
      music.playSong(Song.game);
      await settle(tester);
      backend.at = const Duration(seconds: 30);
      music.playSong(Song.title);
      await settle(tester);
      music.playSong(Song.game);
      await settle(tester);
      expect(backend.log.last, 'play game');
      expect(backend.log, contains('seek 30s'));
    });

    testWidgets('a late, older request is ignored: the newest song wins', (
      tester,
    ) async {
      final (music, backend) = await manager();
      // TitleSong is slow to load...
      final slowTitle = backend.slow[Song.title] = Completer<void>();
      music.playSong(Song.title);
      await tester.pump(const Duration(milliseconds: 10));
      // ...and before it is ready, the student is already on a game screen.
      music.playSong(Song.game);
      await tester.pump(const Duration(milliseconds: 10));
      slowTitle.complete(); // the old request finishes late
      await settle(tester);
      expect(backend.log, isNot(contains('play title')));
      expect(backend.loaded, Song.game);
      expect(backend.playing, isTrue);
      expect(music.wanted, Song.game);
    });

    testWidgets('many fast requests: only the newest plays', (tester) async {
      final (music, backend) = await manager();
      music.playSong(Song.title);
      await settle(tester);
      for (var i = 0; i < 5; i++) {
        music.playSong(Song.game);
        await tester.pump(const Duration(milliseconds: 60));
        music.playSong(Song.title);
        await tester.pump(const Duration(milliseconds: 60));
      }
      music.playSong(Song.game);
      await settle(tester);
      expect(backend.loaded, Song.game);
      expect(backend.playing, isTrue);
      expect(backend.volume, MusicManager.volume);
    });

    testWidgets('coming back to the song that was fading out: it fades back '
        'in, no restart', (tester) async {
      final (music, backend) = await manager();
      music.playSong(Song.game);
      await settle(tester);
      music.playSong(Song.title);
      await tester.pump(MusicManager.fadeOut ~/ 2);
      music.playSong(Song.game); // changed their mind quickly
      await settle(tester);
      expect(backend.log, ['load game', 'play game']);
      expect(backend.volume, MusicManager.volume);
    });

    testWidgets('no song wanted: the music fades out and pauses', (
      tester,
    ) async {
      final (music, backend) = await manager();
      music.playSong(Song.title);
      await settle(tester);
      music.playSong(null);
      await settle(tester);
      expect(backend.playing, isFalse);
    });

    testWidgets('app away: pause at once; back: the song continues', (
      tester,
    ) async {
      final (music, backend) = await manager();
      music.playSong(Song.game);
      await settle(tester);
      music.pause();
      await tester.pump();
      expect(backend.playing, isFalse);
      music.playSong(Song.title); // a new screen while away
      await settle(tester);
      expect(backend.playing, isFalse);
      music.resume();
      await settle(tester);
      expect(backend.loaded, Song.title);
      expect(backend.playing, isTrue);
    });

    testWidgets('the app goes away while a song is starting: it ends paused', (
      tester,
    ) async {
      final (music, backend) = await manager();
      final slow = backend.slow[Song.title] = Completer<void>();
      music.playSong(Song.title);
      await tester.pump(const Duration(milliseconds: 10));
      music.pause();
      slow.complete();
      await settle(tester);
      expect(backend.playing, isFalse);
    });

    testWidgets('a missing music file: quiet, no error, the other song still '
        'works', (tester) async {
      final (music, backend) = await manager();
      backend.missing.add(Song.title);
      music.playSong(Song.title);
      await settle(tester);
      expect(backend.playing, isFalse);
      music.playSong(Song.game);
      await settle(tester);
      expect(backend.loaded, Song.game);
      expect(backend.playing, isTrue);
    });

    testWidgets('nothing plays before the songs are ready', (tester) async {
      final backend = FakeBackend();
      final music = MusicManager(backend);
      music.playSong(Song.title);
      await settle(tester);
      expect(backend.log, isEmpty);
      await music.preload();
      await settle(tester);
      expect(backend.log, ['load title', 'play title']);
    });
  });
}

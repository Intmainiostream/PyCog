import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/sound/sounds.dart';

import 'fake_sounds.dart';

/// Records what [FadingMusicPlayer] does with the two songs.
class FakeTracks implements MusicTracks {
  final log = <String>[];
  final volume = {for (final s in Song.values) s: 0.0};
  final playing = <Song>{};

  @override
  Future<void> preload() async {}

  @override
  void play(Song song) {
    log.add('play ${song.name}');
    playing.add(song);
  }

  @override
  void pause(Song song) {
    log.add('pause ${song.name}');
    playing.remove(song);
  }

  @override
  void setVolume(Song song, double v) => volume[song] = v;
}

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

  group('Fading music player', () {
    testWidgets('a song fades in to a quiet volume', (tester) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.title);
      expect(tracks.log, ['play title']);
      expect(tracks.volume[Song.title], 0);
      await tester.pump(FadingMusicPlayer.fade ~/ 2);
      expect(tracks.volume[Song.title], inExclusiveRange(0.05, 0.3));
      await tester.pump(FadingMusicPlayer.fade);
      expect(tracks.volume[Song.title], FadingMusicPlayer.volume);
      expect(FadingMusicPlayer.volume, inInclusiveRange(0.3, 0.4));
      expect(
        FadingMusicPlayer.fade.inMilliseconds,
        inInclusiveRange(500, 1000),
      );
    });

    testWidgets('asking for the same song again does not restart it', (
      tester,
    ) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.game);
      await tester.pump(const Duration(seconds: 1));
      player.playSong(Song.game);
      player.playSong(Song.game);
      await tester.pump(const Duration(seconds: 1));
      expect(tracks.log, ['play game']);
      expect(tracks.volume[Song.game], FadingMusicPlayer.volume);
    });

    testWidgets('another song fades over, then the old one pauses', (
      tester,
    ) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.title);
      await tester.pump(const Duration(seconds: 1));
      player.playSong(Song.game);
      expect(tracks.playing, {Song.title, Song.game}); // both, crossfading
      await tester.pump(FadingMusicPlayer.fade ~/ 2);
      expect(tracks.volume[Song.title], inExclusiveRange(0, 0.35));
      expect(tracks.volume[Song.game], inExclusiveRange(0, 0.35));
      await tester.pump(FadingMusicPlayer.fade);
      expect(tracks.volume[Song.title], 0);
      expect(tracks.volume[Song.game], FadingMusicPlayer.volume);
      expect(tracks.playing, {Song.game});
      expect(tracks.log, ['play title', 'play game', 'pause title']);
    });

    testWidgets('going back continues the old song (paused, not restarted)', (
      tester,
    ) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.game);
      await tester.pump(const Duration(seconds: 1));
      player.playSong(Song.title);
      await tester.pump(const Duration(seconds: 1));
      player.playSong(Song.game);
      await tester.pump(const Duration(seconds: 1));
      // "play" on a paused song continues it from where it was.
      expect(tracks.log, [
        'play game',
        'play title',
        'pause game',
        'play game',
        'pause title',
      ]);
    });

    testWidgets('no song: the music fades out and pauses', (tester) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.title);
      await tester.pump(const Duration(seconds: 1));
      player.playSong(null);
      await tester.pump(const Duration(seconds: 1));
      expect(tracks.playing, isEmpty);
      expect(tracks.volume[Song.title], 0);
    });

    testWidgets('pause (app away) stops at once; resume continues', (
      tester,
    ) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.game);
      await tester.pump(const Duration(seconds: 1));
      player.pause();
      expect(tracks.playing, isEmpty);
      // A new screen while away: nothing plays until the app is back.
      player.playSong(Song.title);
      await tester.pump(const Duration(seconds: 1));
      expect(tracks.playing, isEmpty);
      player.resume();
      expect(tracks.playing, {Song.title});
      await tester.pump(const Duration(seconds: 1));
      expect(tracks.volume[Song.title], FadingMusicPlayer.volume);
    });

    testWidgets('a song asked for while loading starts after loading', (
      tester,
    ) async {
      final tracks = FakeTracks();
      final player = FadingMusicPlayer(tracks);
      player.playSong(Song.title);
      await player.preload();
      expect(tracks.log.where((e) => e == 'play title').length, 2);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

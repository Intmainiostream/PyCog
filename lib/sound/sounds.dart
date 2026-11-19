import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;

import '../data/settings_controller.dart';

/// The app's sound effects (files in assets/sfx/).
enum Sfx {
  tap,
  correct,
  wrong,
  star,
  finish,
  hint,
  run,
  output,
  victory;

  /// Path inside the app's assets.
  String get assetPath => 'assets/sfx/$name.mp3';
}

/// The two background songs (files in assets/music/).
enum Song {
  /// The home screen.
  title('TitleSong.mp3'),

  /// Lessons, quizzes, games, MINIGAME and CODING.
  game('GameBg.mp3');

  const Song(this.file);

  final String file;

  /// Path inside the app's assets.
  String get assetPath => 'assets/music/$file';
}

/// Plays the background music: one song at a time, on a loop, quietly.
abstract class MusicPlayer {
  /// Loads the songs. Never throws.
  Future<void> preload() async {}

  /// Plays [song] (null: no music). Asking for the song that is already
  /// playing changes nothing; another song fades over.
  void playSong(Song? song);

  /// The app went to the background (or the phone locked): pause.
  void pause();

  /// The app is back: continue the song.
  void resume();
}

/// Plays no music. The default, so tests never need a speaker.
class SilentMusicPlayer extends MusicPlayer {
  @override
  void playSong(Song? song) {}

  @override
  void pause() {}

  @override
  void resume() {}
}

/// Plays sound effects, one at a time: a new sound stops the one before.
abstract class SoundPlayer {
  /// Loads every sound so the first play is quick. Never throws.
  Future<void> preload() async {}

  /// Plays [sfx] (stopping any sound that is still playing).
  void play(Sfx sfx);

  /// Plays [first] (if given), then one star sound per star (1 to 3),
  /// quickly one after the other.
  void playStars(int count, {Sfx? first});

  /// Stops whatever is playing.
  void stop();
}

/// Plays nothing. The default, so tests never need a speaker.
class SilentSoundPlayer extends SoundPlayer {
  @override
  void play(Sfx sfx) {}

  @override
  void playStars(int count, {Sfx? first}) {}

  @override
  void stop() {}
}

/// The one place the whole app asks for sounds and music.
///
/// `Sounds.play(Sfx.tap)` plays a sound effect, unless "Sound effects" is
/// off in Settings. `Sounds.screenSong(Song.game)` says which song the
/// screen on top wants; it plays unless "Music" is off. The two switches
/// never affect each other. If anything goes wrong (a missing file, no
/// audio), nothing plays and the app carries on.
class Sounds {
  Sounds._();

  /// Who actually plays the sounds. main() sets the real one; tests can set
  /// a fake one.
  static SoundPlayer player = SilentSoundPlayer();

  /// Who plays the music. main() sets the real one; tests can set a fake.
  static MusicPlayer music = SilentMusicPlayer();

  static Song? _screenSong;

  /// The song the screen on top asked for (null before the home screen,
  /// e.g. on the splash and the onboarding).
  static Song? get currentScreenSong => _screenSong;

  static SettingsController? _settings;

  /// Follows the "Sound effects" and "Music" switches in [settings].
  /// Turning sound effects off stops a sound that is playing; turning music
  /// off stops the music, and turning it on again starts the right song.
  static void useSettings(SettingsController settings) {
    if (identical(settings, _settings)) return;
    _settings?.removeListener(_onSettings);
    _settings = settings;
    settings.addListener(_onSettings);
  }

  static void _onSettings() {
    if (!on) _safely(player.stop);
    _updateMusic();
  }

  /// Whether sounds may play (on when no settings are attached).
  static bool get on => _settings?.soundOn ?? true;

  /// Whether music may play (on when no settings are attached).
  static bool get musicOn => _settings?.musicOn ?? true;

  /// The screen on top wants [song] (null: no music). The same song keeps
  /// playing from where it is; another one fades over.
  static void screenSong(Song? song) {
    _screenSong = song;
    _updateMusic();
  }

  static void _updateMusic() =>
      _safely(() => music.playSong(musicOn ? _screenSong : null));

  static AppLifecycleListener? _lifecycle;

  /// Starts following the app going to the background and coming back
  /// (see [appLifecycle]). Called once by main().
  static void followAppLifecycle() =>
      _lifecycle ??= AppLifecycleListener(onStateChange: appLifecycle);

  /// Pauses the music when the app goes to the background or the phone
  /// locks, and continues it when the student comes back.
  static void appLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _safely(music.resume);
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        _safely(music.pause);
      case AppLifecycleState.inactive:
        break; // e.g. the notification shade: keep playing
    }
  }

  static void play(Sfx sfx) {
    if (on) _safely(() => player.play(sfx));
  }

  /// One star sound per earned star (1 to 3), after [first] if given.
  static void stars(int count, {Sfx? first}) {
    if (on) _safely(() => player.playStars(count.clamp(0, 3), first: first));
  }

  /// Plays a tap, then runs [action]. For buttons that are not ChunkyButtons.
  static VoidCallback? tapThen(VoidCallback? action) {
    if (action == null) return null;
    return () {
      play(Sfx.tap);
      action();
    };
  }

  /// Back to the start (silent player, no settings). For tests.
  @visibleForTesting
  static void reset() {
    _settings?.removeListener(_onSettings);
    _settings = null;
    player = SilentSoundPlayer();
    music = SilentMusicPlayer();
    _screenSong = null;
  }

  static void _safely(void Function() action) {
    try {
      action();
    } catch (error) {
      debugPrint('Sound skipped: $error');
    }
  }
}

/// Something that can start one sound clip (and stop the one before).
abstract class SoundClips {
  Future<void> preload();
  void start(Sfx sfx);
  void stop();
}

/// The sound rules, on top of [SoundClips]: one sound at a time, and the
/// star sounds a short moment apart. Any new sound cancels stars that are
/// still waiting.
class SequencedSoundPlayer extends SoundPlayer {
  SequencedSoundPlayer(this.clips);

  final SoundClips clips;

  /// Time between two star sounds.
  static const starGap = Duration(milliseconds: 380);

  /// How long to wait after the [SoundPlayer.playStars] `first` sound.
  static Duration gapAfter(Sfx sfx) => switch (sfx) {
    Sfx.finish => const Duration(milliseconds: 1100),
    _ => const Duration(milliseconds: 800),
  };

  Timer? _waiting;

  @override
  Future<void> preload() => clips.preload();

  @override
  void play(Sfx sfx) {
    _cancel();
    clips.start(sfx);
  }

  @override
  void playStars(int count, {Sfx? first}) {
    _cancel();
    var left = count;
    void nextStar() {
      if (left <= 0) return;
      left--;
      clips.start(Sfx.star);
      if (left > 0) _waiting = Timer(starGap, nextStar);
    }

    if (first != null) {
      clips.start(first);
      if (left > 0) _waiting = Timer(gapAfter(first), nextStar);
    } else {
      nextStar();
    }
  }

  @override
  void stop() {
    _cancel();
    clips.stop();
  }

  void _cancel() {
    _waiting?.cancel();
    _waiting = null;
  }
}

/// Something that can play the two songs (each keeps its own place).
abstract class MusicTracks {
  Future<void> preload();

  /// Starts [song], or continues it from where it was paused.
  void play(Song song);

  void pause(Song song);

  void setVolume(Song song, double volume);
}

/// The music rules, on top of [MusicTracks]: one song at a time, quiet
/// ([volume]), and a short fade ([fade]) when the song changes, pauses or
/// comes back. A song that was faded out is paused, so it continues from
/// the same place later.
class FadingMusicPlayer extends MusicPlayer {
  FadingMusicPlayer(this.tracks);

  final MusicTracks tracks;

  /// Quiet, so the sound effects are heard clearly above it.
  static const volume = 0.35;

  static const fade = Duration(milliseconds: 700);
  static const _tick = Duration(milliseconds: 50);

  Song? _song;
  bool _paused = false;
  final _volume = {for (final song in Song.values) song: 0.0};
  final _playing = <Song>{};
  Timer? _timer;

  /// The song that is playing (or will, when the app comes back).
  Song? get song => _song;

  /// The current volume of [song] (for tests).
  @visibleForTesting
  double volumeOf(Song song) => _volume[song]!;

  @override
  Future<void> preload() async {
    await tracks.preload();
    // A song asked for while loading starts now.
    final song = _song;
    if (song != null && !_paused) {
      _playing.remove(song);
      _fadeToTargets();
    }
  }

  @override
  void playSong(Song? song) {
    if (song == _song) return; // the same song keeps going
    _song = song;
    _fadeToTargets();
  }

  @override
  void pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
    for (final song in Song.values) {
      if (_playing.remove(song)) tracks.pause(song);
      _volume[song] = 0;
      tracks.setVolume(song, 0);
    }
  }

  @override
  void resume() {
    if (!_paused) return;
    _paused = false;
    _fadeToTargets();
  }

  double _target(Song song) => !_paused && song == _song ? volume : 0;

  void _fadeToTargets() {
    _timer?.cancel();
    final song = _song;
    if (song != null && !_paused && !_playing.contains(song)) {
      tracks.setVolume(song, _volume[song]!);
      tracks.play(song);
      _playing.add(song);
    }
    _timer = Timer.periodic(_tick, (_) => _step());
  }

  void _step() {
    final delta = volume * _tick.inMicroseconds / fade.inMicroseconds;
    var done = true;
    for (final song in Song.values) {
      final target = _target(song);
      final before = _volume[song]!;
      var v = before;
      if (v < target) {
        v = v + delta > target ? target : v + delta;
      } else if (v > target) {
        v = v - delta < target ? target : v - delta;
      }
      if (v != target) done = false;
      if (v != before) {
        _volume[song] = v;
        tracks.setVolume(song, v);
      }
      if (v == 0 && target == 0 && _playing.remove(song)) tracks.pause(song);
    }
    if (done) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

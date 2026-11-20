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

  static Future<void>? _loading;

  /// Loads the sound effects, then the music, one after the other. Runs
  /// only once (later calls wait for the same loading).
  static Future<void> loadAll() => _loading ??= () async {
    await player.preload();
    await music.preload();
  }();

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
    _loading = null;
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

/// The one music player of the app (the real one plays with audioplayers;
/// tests use a fake). Every call may take a moment; the manager waits.
abstract class MusicBackend {
  /// Gets both songs ready once (never throws).
  Future<void> preload();

  /// Puts [song] in the player (from the copy made by [preload]).
  Future<void> load(Song song);

  Future<void> play();

  Future<void> pause();

  Future<void> setVolume(double volume);

  /// Where the song is now (null if unknown).
  Future<Duration?> position();

  Future<void> seek(Duration position);
}

/// The one music manager of the app.
///
/// It keeps the "wanted song" (none, [Song.title] or [Song.game]) and moves
/// the one player towards it, one step at a time:
///  * the wanted song is already playing: nothing happens (no restart);
///  * another song: the old one fades out, the new one fades in
///    ([fadeOut] + [fadeIn], under a second), and a song continues from
///    where it was when it comes back;
///  * requests that come fast: only the newest counts. Every step checks
///    that no newer request came in, so a slow, older step can never make
///    the wrong song play.
/// The music is quiet ([volume]) and pauses at once when the app is away.
class MusicManager extends MusicPlayer {
  MusicManager(this.backend);

  final MusicBackend backend;

  static const volume = 0.35;
  static const fadeOut = Duration(milliseconds: 350);
  static const fadeIn = Duration(milliseconds: 350);

  /// Volume changes per fade (few, so the phone is not kept busy).
  static const fadeSteps = 5;

  Song? _wanted;
  bool _away = false;
  bool _ready = false;

  // What the player really does (changed only after a step finished).
  Song? _loaded;
  bool _playing = false;
  double _volume = 0;
  final _positions = <Song, Duration>{};
  final _broken = <Song>{};

  int _request = 0; // grows with every new request
  bool _working = false;

  /// The song the app wants now (null: none).
  Song? get wanted => _wanted;

  /// The song in the player, and whether it is playing (for tests).
  @visibleForTesting
  (Song?, bool, double) get state => (_loaded, _playing, _volume);

  Song? get _target => _away ? null : _wanted;

  @override
  Future<void> preload() async {
    await backend.preload();
    _ready = true;
    _kick();
  }

  @override
  void playSong(Song? song) {
    if (song == _wanted) return; // the same song keeps going
    _wanted = song;
    _kick();
  }

  @override
  void pause() {
    if (_away) return;
    _away = true;
    _request++; // anything still running is now out of date
    _playing = false;
    _volume = 0;
    // Always sent, after anything already sent, so the player ends up
    // paused even if a song was just starting.
    unawaited(
      _quietly(() async {
        await backend.pause();
        await backend.setVolume(0);
      }),
    );
  }

  @override
  void resume() {
    if (!_away) return;
    _away = false;
    _kick();
  }

  void _kick() {
    _request++;
    if (!_working) unawaited(_work());
  }

  bool _settled() {
    final target = _target;
    if (target == null) return !_playing;
    if (_broken.contains(target)) return !_playing;
    return _loaded == target && _playing && _volume == volume;
  }

  Future<void> _work() async {
    _working = true;
    try {
      while (_ready && !_settled()) {
        await _step(_request, _target);
      }
    } finally {
      _working = false;
    }
  }

  /// Moves the player one way towards [target]. Returns early if a newer
  /// request came in ([request] is out of date); the loop then starts
  /// again from what the player really does, with the newest target.
  Future<void> _step(int request, Song? target) async {
    bool stale() => request != _request;

    // 1. Something else is playing (or nothing is wanted): fade it out.
    if (_playing &&
        (_loaded != target || target == null || _broken.contains(target))) {
      if (!await _fadeTo(0, fadeOut, stale)) return;
      final playing = _loaded;
      if (playing != null) {
        final at = await _quietly(backend.position);
        if (at != null) _positions[playing] = at;
      }
      await _quietly(backend.pause);
      _playing = false;
      if (stale()) return;
    }
    if (target == null || _broken.contains(target)) return;

    // 2. Put the wanted song in the player (it continues where it was).
    if (_loaded != target) {
      final ok = await _quietly(() async {
        await backend.load(target);
        return true;
      });
      if (ok != true) {
        _broken.add(target); // missing or broken file: stay quiet
        return;
      }
      _loaded = target;
      final at = _positions[target];
      if (at != null) await _quietly(() => backend.seek(at));
      if (stale()) return; // a newer request: never start this song
    }

    // 3. Start it quietly and fade in.
    if (!_playing) {
      await _quietly(() => backend.setVolume(_volume));
      if (stale()) return;
      _playing = true; // before the await: a pause now sees it
      await _quietly(backend.play);
      if (stale()) return;
    }
    await _fadeTo(volume, fadeIn, stale);
  }

  /// Changes the volume to [to] in [fadeSteps] steps over [time]. Returns
  /// false if a newer request came in on the way.
  Future<bool> _fadeTo(double to, Duration time, bool Function() stale) async {
    final from = _volume;
    if (from == to) return !stale();
    for (var i = 1; i <= fadeSteps; i++) {
      await Future<void>.delayed(time ~/ fadeSteps);
      if (stale()) return false;
      final v = i == fadeSteps ? to : from + (to - from) * i / fadeSteps;
      await _quietly(() => backend.setVolume(v));
      if (stale()) return false; // a pause may have set the volume to 0
      _volume = v;
    }
    return !stale();
  }

  static Future<T?> _quietly<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      debugPrint('Music skipped: $error');
      return null;
    }
  }
}

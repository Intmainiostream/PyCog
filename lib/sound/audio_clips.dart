import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'sounds.dart';

/// The real sounds, played with the audioplayers package.
///
/// Every sound gets its own player, loaded once at start, so a sound starts
/// quickly. Starting a sound stops the one before (never two at once).
///
/// The sounds mix with other apps: on Android they take no audio focus, and
/// on iOS they use the "ambient" session. So music or videos the student is
/// already playing keep playing.
class AudioplayersClips implements SoundClips {
  final _players = <Sfx, AudioPlayer>{};
  AudioPlayer? _current;

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  @override
  Future<void> preload() async {
    await _try(
      'audio setup',
      () => AudioPlayer.global.setAudioContext(_context),
    );
    for (final sfx in Sfx.values) {
      await _try(sfx.name, () async {
        final player = AudioPlayer(playerId: 'sfx-${sfx.name}');
        await player.setAudioContext(_context);
        await player.setReleaseMode(ReleaseMode.stop);
        // AssetSource adds the "assets/" folder itself.
        await player.setSource(AssetSource('sfx/${sfx.name}.mp3'));
        _players[sfx] = player;
      });
    }
  }

  @override
  void start(Sfx sfx) {
    final player = _players[sfx];
    if (player == null) return; // missing or broken file: stay quiet
    final before = _current;
    _current = player;
    // Only stop what is really still playing: most taps are then a
    // single call to the phone instead of three.
    unawaited(
      _try(sfx.name, () async {
        if (before != null &&
            !identical(before, player) &&
            before.state == PlayerState.playing) {
          await before.stop();
        }
        if (player.state == PlayerState.playing) await player.stop();
        await player.resume();
      }),
    );
  }

  @override
  void stop() {
    final player = _current;
    _current = null;
    if (player != null) unawaited(_try('stop', player.stop));
  }

  static Future<void> _try(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Sound "$what" skipped: $error');
    }
  }
}

/// The real background music: ONE audioplayers player for the whole app,
/// on a loop. The [MusicManager] decides what it does.
///
/// Music uses normal media audio focus on Android: a phone call pauses it
/// and it continues afterwards; if another app takes the audio for good,
/// it continues when the student comes back to PyCog. (Sound effects take
/// no focus at all.) On iOS it uses the same "ambient" session as the
/// sound effects, so it mixes with other apps.
class AudioplayersMusic implements MusicBackend {
  final _player = AudioPlayer(playerId: 'music');

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Sets the player up and copies both songs out of the app once (the
  /// player can only play files), so switching songs later only points the
  /// player at a ready file.
  @override
  Future<void> preload() => AudioplayersClips._try('music setup', () async {
    await _player.setAudioContext(_context);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0);
    for (final song in Song.values) {
      await _player.audioCache.load('music/${song.file}');
    }
  });

  // AssetSource adds the "assets/" folder itself.
  @override
  Future<void> load(Song song) =>
      _player.setSource(AssetSource('music/${song.file}'));

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<Duration?> position() => _player.getCurrentPosition();

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}

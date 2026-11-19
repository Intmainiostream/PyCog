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
    unawaited(
      _try(sfx.name, () async {
        if (before != null && !identical(before, player)) await before.stop();
        await player.stop(); // back to the start if it is still playing
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

/// The real background music, played with the audioplayers package.
///
/// Each song has its own player, on a loop, so it keeps its place while
/// the other one plays. Music uses normal media audio focus on Android:
/// a phone call pauses it and it continues afterwards; if another app
/// takes the audio for good, it continues when the student comes back to
/// PyCog. (Sound effects take no focus at all.) On iOS it uses the same
/// "ambient" session as the sound effects, so it mixes with other apps.
class AudioplayersTracks implements MusicTracks {
  final _players = <Song, AudioPlayer>{};

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

  @override
  Future<void> preload() async {
    for (final song in Song.values) {
      await AudioplayersClips._try(song.name, () async {
        final player = AudioPlayer(playerId: 'music-${song.name}');
        await player.setAudioContext(_context);
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(0);
        await player.setSource(AssetSource('music/${song.file}'));
        _players[song] = player;
      });
    }
  }

  @override
  void play(Song song) => _do(song, (p) => p.resume());

  @override
  void pause(Song song) => _do(song, (p) => p.pause());

  @override
  void setVolume(Song song, double volume) =>
      _do(song, (p) => p.setVolume(volume));

  void _do(Song song, Future<void> Function(AudioPlayer) action) {
    final player = _players[song];
    if (player == null) return; // missing or broken file: stay quiet
    unawaited(AudioplayersClips._try(song.name, () => action(player)));
  }
}

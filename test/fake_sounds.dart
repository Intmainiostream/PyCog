import 'package:flutter_test/flutter_test.dart';

import 'package:pycog/sound/sounds.dart';

/// Remembers which sounds the app asked for, instead of playing them.
class FakeSoundPlayer extends SoundPlayer {
  final played = <Sfx>[];
  int stops = 0;

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void playStars(int count, {Sfx? first}) {
    if (first != null) played.add(first);
    for (var i = 0; i < count; i++) {
      played.add(Sfx.star);
    }
  }

  @override
  void stop() => stops++;

  void clear() => played.clear();
}

/// Puts a [FakeSoundPlayer] in place for this test (undone afterwards).
FakeSoundPlayer useFakeSounds() {
  final fake = FakeSoundPlayer();
  Sounds.reset();
  Sounds.player = fake;
  addTearDown(Sounds.reset);
  return fake;
}

/// Remembers which songs the app asked for, instead of playing them.
class FakeMusicPlayer extends MusicPlayer {
  /// Every playSong call, in order (null = no music).
  final asked = <Song?>[];
  int pauses = 0;
  int resumes = 0;

  /// The last song asked for.
  Song? get current => asked.isEmpty ? null : asked.last;

  @override
  void playSong(Song? song) => asked.add(song);

  @override
  void pause() => pauses++;

  @override
  void resume() => resumes++;
}

/// Puts a [FakeMusicPlayer] in place for this test (undone afterwards).
/// Call it after [useFakeSounds] when a test uses both.
FakeMusicPlayer useFakeMusic() {
  final fake = FakeMusicPlayer();
  Sounds.music = fake;
  addTearDown(Sounds.reset);
  return fake;
}

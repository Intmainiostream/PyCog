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

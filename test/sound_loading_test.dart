import 'package:flutter_test/flutter_test.dart';

import 'package:pycog/sound/sounds.dart';

import 'music_test.dart' show FakeBackend;

/// Notes when it was asked to load.
class LoadingSounds extends SilentSoundPlayer {
  LoadingSounds(this.order);

  final List<String> order;

  @override
  Future<void> preload() async => order.add('sound effects');
}

class LoadingBackend extends FakeBackend {
  LoadingBackend(this.order);

  final List<String> order;

  @override
  Future<void> preload() async {
    order.add('music');
    await super.preload();
  }
}

void main() {
  setUp(Sounds.reset);
  tearDown(Sounds.reset);

  test('loading runs once: sound effects first, then the music', () async {
    final order = <String>[];
    final backend = LoadingBackend(order);
    Sounds.player = LoadingSounds(order);
    Sounds.music = MusicManager(backend);
    await Future.wait([Sounds.loadAll(), Sounds.loadAll()]);
    await Sounds.loadAll();
    expect(order, ['sound effects', 'music']);
    expect(backend.preloads, 1);
  });

  testWidgets('each song is put in the player only when it is needed, and '
      'only once while it stays', (tester) async {
    final backend = FakeBackend();
    final music = MusicManager(backend);
    await music.preload();
    for (var i = 0; i < 4; i++) {
      music.playSong(Song.game); // e.g. Play, MINIGAME, CODING...
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(backend.loads, [Song.game]);
  });

  testWidgets('a fade changes the volume only a few times', (tester) async {
    final backend = _CountingBackend();
    final music = MusicManager(backend);
    await music.preload();
    music.playSong(Song.title);
    await tester.pump(const Duration(seconds: 2));
    backend.volumes = 0;
    music.playSong(Song.game);
    await tester.pump(const Duration(seconds: 2));
    // Fade out + fade in, plus one "start quietly".
    expect(backend.volumes, lessThanOrEqualTo(2 * MusicManager.fadeSteps + 1));
  });
}

class _CountingBackend extends FakeBackend {
  int volumes = 0;

  @override
  Future<void> setVolume(double v) {
    volumes++;
    return super.setVolume(v);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

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

/// The one place the whole app asks for sounds.
///
/// `Sounds.play(Sfx.tap)` plays a sound, unless "Sound effects" is off in
/// Settings. If anything goes wrong (a missing file, no audio), nothing
/// plays and the app carries on.
class Sounds {
  Sounds._();

  /// Who actually plays the sounds. main() sets the real one; tests can set
  /// a fake one.
  static SoundPlayer player = SilentSoundPlayer();

  static SettingsController? _settings;

  /// Follows the "Sound effects" switch in [settings]. Turning it off also
  /// stops a sound that is playing.
  static void useSettings(SettingsController settings) {
    if (identical(settings, _settings)) return;
    _settings?.removeListener(_onSettings);
    _settings = settings;
    settings.addListener(_onSettings);
  }

  static void _onSettings() {
    if (!on) _safely(player.stop);
  }

  /// Whether sounds may play (on when no settings are attached).
  static bool get on => _settings?.soundOn ?? true;

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

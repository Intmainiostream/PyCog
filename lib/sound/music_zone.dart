import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'sounds.dart';

/// The one place that decides which song the app wants.
///
/// It watches the app's navigator. After every screen change it looks at
/// the screen on top and asks for that screen's song (the label a
/// [MusicZone] gave it), at most once per frame, so fast moves between
/// screens make one request, not many. A screen without a label (Settings,
/// About, the licenses page, the splash, the onboarding) changes nothing:
/// what is playing keeps playing, and before the home screen nothing plays.
class MusicRouteObserver extends NavigatorObserver {
  final _stack = <Route<dynamic>>[];
  final _songs = Expando<Song>('song');
  bool _scheduled = false;

  /// [route] (a screen) wants [song]. Called by its [MusicZone].
  void label(Route<dynamic> route, Song song) {
    _songs[route] = song;
    _schedule();
  }

  /// The song of the screen on top, if it has one (for tests).
  @visibleForTesting
  Song? get topSong {
    for (final route in _stack.reversed) {
      // Pop-ups (the settings sheet, dialogs) sit on top of a screen; the
      // screen under them decides.
      if (route is PopupRoute) continue;
      return _songs[route];
    }
    return null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) _stack.clear(); // a fresh navigator
    _stack.add(route);
    _schedule();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _schedule();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _schedule();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (i >= 0) {
        _stack[i] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (i >= 0) {
      _stack.removeAt(i);
    }
    _schedule();
  }

  /// Decide after this frame (a new screen has put up its label by then).
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _scheduled = false;
        _decide();
      })
      ..ensureVisualUpdate();
  }

  void _decide() {
    final song = topSong;
    if (song != null) Sounds.screenSong(song);
  }
}

/// The app's music observer, added to the navigator in main.dart.
final musicRouteObserver = MusicRouteObserver();

/// Labels a screen with its song: [Song.title] for the home screen,
/// [Song.game] for lessons, quizzes, games, MINIGAME and CODING.
///
/// It does not start any music itself; [MusicRouteObserver] decides, in
/// one place. (Without that observer, e.g. a screen shown alone in a test,
/// the label asks for the song directly.)
class MusicZone extends StatefulWidget {
  const MusicZone({super.key, required this.song, required this.child});

  final Song song;
  final Widget child;

  @override
  State<MusicZone> createState() => _MusicZoneState();
}

class _MusicZoneState extends State<MusicZone> {
  Route<dynamic>? _labelled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _labelled)) return;
    _labelled = route;
    if (musicRouteObserver.navigator != null) {
      musicRouteObserver.label(route, widget.song);
    } else {
      Sounds.screenSong(widget.song);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

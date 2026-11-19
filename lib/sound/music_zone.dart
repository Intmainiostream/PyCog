import 'package:material_ui/material_ui.dart';

import 'sounds.dart';

/// Tells [MusicZone]s when their screen is covered or shown again. Added to
/// the app's navigator in main.dart.
final musicRouteObserver = RouteObserver<ModalRoute<Object?>>();

/// Marks a screen with the song it wants: [Song.title] for the home screen,
/// [Song.game] for lessons, quizzes, games, MINIGAME and CODING.
///
/// The song is asked for when the screen opens and when the student comes
/// back to it (e.g. after closing a screen on top). Screens without a zone
/// (Settings, About, the licenses page) keep whatever is playing; the
/// splash and the onboarding come before any zone, so they are silent.
/// Asking for the song that is already playing never restarts it.
class MusicZone extends StatefulWidget {
  const MusicZone({super.key, required this.song, required this.child});

  final Song song;
  final Widget child;

  @override
  State<MusicZone> createState() => _MusicZoneState();
}

class _MusicZoneState extends State<MusicZone> with RouteAware {
  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    if (_route != null) musicRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) {
      musicRouteObserver.subscribe(this, route); // calls didPush now
    } else {
      _claim();
    }
  }

  @override
  void dispose() {
    musicRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _claim() => Sounds.screenSong(widget.song);

  @override
  void didPush() => _claim();

  @override
  void didPopNext() => _claim();

  @override
  Widget build(BuildContext context) => widget.child;
}

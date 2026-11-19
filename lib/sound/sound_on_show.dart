import 'package:material_ui/material_ui.dart';

/// Plays a sound once, when [child] first appears on screen (not again when
/// the screen redraws).
class SoundOnShow extends StatefulWidget {
  const SoundOnShow({super.key, required this.play, required this.child});

  /// Asks for the sound, e.g. `() => Sounds.stars(3)`.
  final VoidCallback play;
  final Widget child;

  @override
  State<SoundOnShow> createState() => _SoundOnShowState();
}

class _SoundOnShowState extends State<SoundOnShow> {
  @override
  void initState() {
    super.initState();
    widget.play();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

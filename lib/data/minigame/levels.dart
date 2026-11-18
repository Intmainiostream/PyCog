import '../../models/minigame.dart';
import 'level1.dart';
import 'level2.dart';
import 'level3.dart';
import 'level4.dart';
import 'level5.dart';
import 'level6.dart';
import 'level7.dart';
import 'level8.dart';
import 'level9.dart';
import 'level10.dart';

/// The MINIGAME map: 10 levels of up to 10 challenges each, one file per
/// level. A level with no challenges yet shows "coming soon" on the map.
final List<MinigameLevel> minigameLevels = [
  level1,
  level2,
  level3,
  level4,
  level5,
  level6,
  level7,
  level8,
  level9,
  level10,
];

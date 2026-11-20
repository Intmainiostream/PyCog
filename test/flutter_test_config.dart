import 'dart:async';

import 'package:pycog/widgets/fog_footer.dart';

/// Runs before every test file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The trail's fog drifts forever, so a screen with it would never
  // "settle". Tests keep it still; the fog tests turn the drifting on.
  FogFooter.drift = false;
  await testMain();
}

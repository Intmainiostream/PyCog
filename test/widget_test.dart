import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pycog/data/progress_controller.dart';
import 'package:pycog/data/settings_controller.dart';
import 'package:pycog/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SettingsController> pumpApp(WidgetTester tester) async {
    final settings = await SettingsController.load();
    await tester.pumpWidget(
      PyCogApp(settings: settings, progress: await ProgressController.load()),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('Home shows Cog, stars and the lesson path', (tester) async {
    await pumpApp(tester);

    expect(
      find.text("Hi! I'm Cog. Let's learn Python together!"),
      findsOneWidget,
    );
    expect(find.text('Variables'), findsOneWidget);
    expect(find.text('Functions'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // lesson 1 is open
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(4)); // rest locked
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('Settings sheet changes and saves language', (tester) async {
    final settings = await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Tagalog'));
    await tester.pumpAndSettle();

    expect(find.text('Mga Setting'), findsOneWidget);
    expect(settings.locale.languageCode, 'tl');

    // Saved to the device: a fresh load remembers it.
    final reloaded = await SettingsController.load();
    expect(reloaded.locale.languageCode, 'tl');

    await tester.tap(find.text('Tapos na'));
    await tester.pumpAndSettle();
    expect(find.text('Mga Variable'), findsOneWidget);
  });

  testWidgets('Sound, music and text size are saved', (tester) async {
    final settings = await pumpApp(tester);
    settings
      ..setSoundOn(false)
      ..setMusicOn(false)
      ..setTextSize(TextSize.large);

    final reloaded = await SettingsController.load();
    expect(reloaded.soundOn, isFalse);
    expect(reloaded.musicOn, isFalse);
    expect(reloaded.textSize, TextSize.large);
  });
}

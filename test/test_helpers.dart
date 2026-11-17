import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:pycog/widgets/output_box.dart';

/// The app now opens on the home screen (PLAY / MINIGAME / CODING). Tests
/// that work with the lesson trail call this right after starting the app:
/// it taps PLAY and waits for the trail to appear.
Future<void> openTrail(WidgetTester tester) async {
  final play = find.byKey(const ValueKey('home-play'));
  await tester.ensureVisible(play);
  await tester.pumpAndSettle();
  await tester.tap(play);
  await tester.pumpAndSettle();
}

/// The rows shown in the output box, as Text widgets, top to bottom.
List<Text> outputRows(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(OutputBox), matching: find.byType(Text)),
    )
    .skip(1) // the "Output" label
    .toList();

/// The printed lines in the output box, with wrapped rows (which start with
/// the wrap indent) joined back onto their line.
List<String> printedLines(WidgetTester tester) {
  final lines = <String>[];
  final indent = ' ' * outputWrapIndent;
  for (final row in outputRows(tester).map((t) => t.data!)) {
    if (row.startsWith(indent) && lines.isNotEmpty) {
      lines.last = '${lines.last} ${row.substring(outputWrapIndent)}';
    } else {
      lines.add(row);
    }
  }
  return lines;
}

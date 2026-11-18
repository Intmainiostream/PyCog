import 'package:material_ui/material_ui.dart';

import 'playground/python_test_screen.dart';
import 'theme/app_theme.dart';

/// Separate entry point for the offline Python feasibility test, so the
/// real app (lib/main.dart) and its home screen stay untouched.
///
/// Run on a phone or emulator with:
///   flutter run -t lib/main_playground.dart
void main() {
  runApp(
    MaterialApp(
      title: 'PyCog Python test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const PythonTestScreen(),
    ),
  );
}

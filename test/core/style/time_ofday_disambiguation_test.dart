import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the one disambiguation idiom for the `TimeOfDay` collision: the app
/// enum in `core/database/enums.dart` and Flutter material's `TimeOfDay`
/// share a name. Every file that imports both must hide material's type on
/// the import line (`import 'package:flutter/material.dart' hide TimeOfDay;`),
/// so a future reference can never be ambiguous.
void main() {
  test('files importing both material and enums hide TimeOfDay', () {
    final lib = Directory('lib');
    final violations = <String>[];
    final enumsImport = RegExp(r"import .*database/enums\.dart';");

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (!source.contains("package:flutter/material.dart")) continue;
      if (!enumsImport.hasMatch(source)) continue;

      final materialImport = source
          .split('\n')
          .firstWhere((line) => line.contains("package:flutter/material.dart"));
      if (!materialImport.contains('hide TimeOfDay')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Files importing both material and enums must hide TimeOfDay: '
          '$violations',
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every `SnackBar` in the app has to name its own background.
///
/// The app sets no `snackBarTheme`, so a bar that omits `backgroundColor`
/// inherits Material's default of `colorScheme.inverseSurface` — near-white in
/// this light scheme. Every bar here paints its icon and label `Colors.white`,
/// so a missing colour renders white-on-white and the message cannot be read.
void main() {
  test('every SnackBar sets an explicit backgroundColor', () {
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();

      var searchFrom = 0;
      while (true) {
        final start = source.indexOf('SnackBar(', searchFrom);
        if (start < 0) break;
        searchFrom = start + 1;

        // Walk to the matching close paren to inspect just this bar.
        var depth = 1;
        var i = start + 'SnackBar('.length;
        while (i < source.length && depth > 0) {
          if (source[i] == '(') {
            depth++;
          } else if (source[i] == ')') {
            depth--;
          }
          i++;
        }
        final block = source.substring(start, i);

        if (!block.contains('backgroundColor')) {
          final line = source.substring(0, start).split('\n').length;
          offenders.add('${file.path}:$line');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'SnackBar without a backgroundColor, unreadable on the light '
            'theme: ${offenders.join(', ')}');
  });
}

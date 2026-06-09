// Tests PickerMode enum — Story 1.13.
//
// Vérifient :
//  1. fromString parse les 5 valeurs Firestore snake_case
//  2. fromString fallback derived pour valeurs inconnues / null (defaults safe v1)
//  3. toFirestoreString sérialise correctement (round-trip)

import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';

void main() {
  group('PickerMode — Story 1.13', () {
    test('fromString parse `derived` -> PickerMode.derived', () {
      expect(PickerMode.fromString('derived'), PickerMode.derived);
    });

    test('fromString parse `opt_out` -> PickerMode.optOut', () {
      expect(PickerMode.fromString('opt_out'), PickerMode.optOut);
    });

    test(
        'fromString parse `free_with_obligatory` -> PickerMode.freeWithObligatory',
        () {
      expect(
        PickerMode.fromString('free_with_obligatory'),
        PickerMode.freeWithObligatory,
      );
    });

    test(
        'fromString parse `series_plus_optional` -> PickerMode.seriesPlusOptional',
        () {
      expect(
        PickerMode.fromString('series_plus_optional'),
        PickerMode.seriesPlusOptional,
      );
    });

    test('fromString parse `tve_picker` -> PickerMode.tvePicker', () {
      expect(PickerMode.fromString('tve_picker'), PickerMode.tvePicker);
    });

    test(
        'fromString fallback derived pour valeur inconnue + null '
        '(defaults safe v1)', () {
      expect(PickerMode.fromString('unknown_mode'), PickerMode.derived);
      expect(PickerMode.fromString(null), PickerMode.derived);
      expect(PickerMode.fromString(''), PickerMode.derived);
    });

    test('toFirestoreString round-trip avec fromString', () {
      for (final mode in PickerMode.values) {
        expect(
          PickerMode.fromString(mode.toFirestoreString()),
          mode,
          reason: 'Round-trip failed for ${mode.name}',
        );
      }
    });
  });
}

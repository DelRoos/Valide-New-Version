// Tests Story E1bis-0 AC7 — helper maskPhone (5 cas obligatoires).

import 'package:flutter_test/flutter_test.dart';
import 'package:valide_school/core/logging/log_safe.dart';

void main() {
  group('maskPhone', () {
    test('numero E164 Cameroun valide (mobile 6) -> reveal 4 derniers', () {
      // Local = "671234567" (9 chiffres). Masque les 5 premiers ("XXXXX"),
      // revele les 4 derniers ("4567"). Groupage 1+2+2+2+2.
      final result = maskPhone('+237671234567');
      expect(result, '+237 X XX XX 45 67');
    });

    test('numero E164 Cameroun valide (fixe 2) -> meme pattern', () {
      final result = maskPhone('+237222234567');
      expect(result, '+237 X XX XX 45 67');
    });

    test('null -> sentinelle <no-phone>', () {
      expect(maskPhone(null), '<no-phone>');
    });

    test('chaine vide -> sentinelle <no-phone>', () {
      expect(maskPhone(''), '<no-phone>');
    });

    test('format invalide (autre pays) -> sentinelle <invalid-phone>', () {
      expect(maskPhone('+33612345678'), '<invalid-phone>');
    });

    test('format invalide (trop court) -> sentinelle <invalid-phone>', () {
      expect(maskPhone('+2376123'), '<invalid-phone>');
    });

    test('format invalide (caracteres non-digit) -> sentinelle <invalid-phone>',
        () {
      expect(maskPhone('+237ABCDEFGHI'), '<invalid-phone>');
    });

    test('format invalide (sans prefixe +) -> sentinelle <invalid-phone>', () {
      expect(maskPhone('237671234567'), '<invalid-phone>');
    });

    test('Cameroun avec 3eme digit different de 2 ou 6 -> invalide', () {
      // Specs Cameroun : mobile commence par 6, fixe par 2. 7 n'existe pas.
      expect(maskPhone('+237771234567'), '<invalid-phone>');
    });

    test('preservation des 4 derniers digits', () {
      // Verification que les 4 derniers chiffres correspondent au numero source.
      final result = maskPhone('+237671234567');
      // "+237 XX XX X3 45 67" -> les derniers " 67" reflechissent "67" du numero.
      expect(result.endsWith('67'), isTrue);
    });
  });
}

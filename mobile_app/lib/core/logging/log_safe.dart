// Helpers de masquage pour les logs (CLAUDE.md regle 4 securite).
//
// Tout code qui logue un numero de telephone, un jeton, un PIN, un mot
// de passe DOIT passer par un helper de ce fichier (ou s'aligner sur le
// meme pattern). JAMAIS de log direct d'une donnee sensible — ni en
// production, ni en debug.
//
// Reference Story E1bis-0 AC7 + step 7 onboarding (PhoneInputWithCountryFlag).

const String _noPhone = '<no-phone>';
const String _invalidPhone = '<invalid-phone>';

/// Masque un numero de telephone au format E.164 Cameroun pour les logs.
///
/// Format de sortie : `+237 X XX XX 78 90` (4 derniers digits visibles,
/// 5 premiers digits du numero local masques par X, espaces selon le
/// groupage standard 1+2+2+2+2 = 9 chiffres locaux).
///
/// Sentinelles :
/// * `null` ou empty -> `'<no-phone>'`
/// * format invalide (non E.164 Cameroun) -> `'<invalid-phone>'`
///
/// Exemples :
/// ```
/// maskPhone('+237671234567') // '+237 X XX XX 45 67'
/// maskPhone(null)             // '<no-phone>'
/// maskPhone('')               // '<no-phone>'
/// maskPhone('+33612345678')   // '<invalid-phone>' (prefixe pays != 237)
/// maskPhone('+2376123')       // '<invalid-phone>' (longueur < 12)
/// ```
///
/// Regex de validation E.164 Cameroun : `^\+237[26][0-9]{8}$`.
/// Mobile camerounais : 9 chiffres apres indicatif, commence par 6 (MTN/Orange)
/// ou 2 (fixe Camtel) — on accepte les deux.
String maskPhone(String? e164) {
  if (e164 == null || e164.isEmpty) return _noPhone;
  final valid = RegExp(r'^\+237[26][0-9]{8}$');
  if (!valid.hasMatch(e164)) return _invalidPhone;

  // e164 = +237 + 9 chiffres (13 caracteres total avec le +).
  final local = e164.substring(4); // 9 chiffres, ex. "671234567"
  // Premiers 5 chiffres locaux masques X, derniers 4 reveles.
  final masked = 'XXXXX${local.substring(5)}'; // ex. "XXXXX4567"

  // Groupage 1+2+2+2+2 (chiffre seul puis 4 paires). Standard pour les
  // numeros camerounais affiches dans l'UI.
  final buffer = StringBuffer('+237 ');
  buffer.write(masked[0]);
  for (var i = 1; i < masked.length; i += 2) {
    buffer.write(' ');
    buffer.write(masked[i]);
    if (i + 1 < masked.length) buffer.write(masked[i + 1]);
  }
  return buffer.toString();
}

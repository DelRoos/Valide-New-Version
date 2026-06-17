// Point d'accès unique aux capacités spécifiques à la plateforme.
// CLAUDE.md règle cross-platform 1 : tout `Platform.isAndroid` / `Platform.isIOS`
// est confiné dans ce dossier. Les couches presentation/ ne doivent jamais
// importer `dart:io` directement pour des checks de plateforme.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True si Apple Sign-In est disponible sur la plateforme courante.
/// Vrai uniquement sur iOS natif ; faux sur Android, web et desktop.
bool get isAppleSignInAvailable => !kIsWeb && Platform.isIOS;

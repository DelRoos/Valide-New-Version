import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/firebase/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/feedback/offline_banner.dart';
import 'features/account/providers.dart';
import 'features/onboarding/providers.dart';
import 'l10n/generated/app_localizations.dart';

/// Design reference : iPhone 14 / Android entry-level phone portrait.
/// `.w` / `.h` / `.sp` dans les widgets sont scalés relativement à ce gabarit.
const Size kDesignSize = Size(375, 812);

/// Notifier qui pilote la locale active.
///
/// Priorité :
///   1. Override manuel sauvegardé en SharedPreferences (clé `locale_override`).
///   2. Locale dérivée du sous-système (ADR-006).
///   3. FR par défaut (PRD § 2.3).
///
/// L'override persiste entre les sessions et peut être changé via [setLocale].
class LocaleNotifier extends Notifier<Locale> {
  static const _kKey = 'locale_override';

  @override
  Locale build() {
    final override =
        ref.read(sharedPreferencesProvider).getString(_kKey);
    if (override != null) return Locale(override);

    final subSystem = ref.watch(subSystemNotifierProvider);
    return subSystem?.locale ?? const Locale('fr');
  }

  Future<void> setLocale(Locale locale) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kKey, locale.languageCode);
    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ValideApp extends ConsumerWidget {
  const ValideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    // Story 1.10 — amorce l'auto-canceller de suppression au boot.
    // Gardé derrière firebaseReadyProvider : au hot restart Firebase prend
    // ~1s à s'initialiser ; accéder à firestoreProvider avant ce délai
    // lance un ProviderException [core/no-app]. Une fois Firebase prêt, le
    // rebuild de ValideApp démarre le canceller normalement.
    final firebaseReady = ref.watch(firebaseReadyProvider);
    if (firebaseReady.value == true) {
      ref.watch(autoAccountDeletionCancellerProvider);
    }
    return ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
        // 2026-06-12 — banner offline global affiche au-dessus du
        // current page (router-aware). Le banner se masque automatiquement
        // quand la connectivite revient.
        builder: (context, child) => Column(
          children: [
            const OfflineBanner(),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

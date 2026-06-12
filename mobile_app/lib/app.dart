import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/feedback/offline_banner.dart';
import 'features/onboarding/providers.dart';
import 'l10n/generated/app_localizations.dart';

/// Design reference : iPhone 14 / Android entry-level phone portrait.
/// `.w` / `.h` / `.sp` dans les widgets sont scalés relativement à ce gabarit.
const Size kDesignSize = Size(375, 812);

/// Notifier qui pilote la locale active. Story 1.2 : la locale est désormais
/// **dérivée** du sous-système choisi (cf. ADR-006 — sous-système figé à
/// l'inscription, la langue en dérive). Tant que le sous-système n'est pas
/// posé (1er lancement), on défaut FR (majorité des élèves cibles, PRD § 2.3).
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final subSystem = ref.watch(subSystemNotifierProvider);
    return subSystem?.locale ?? const Locale('fr');
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class ValideApp extends ConsumerWidget {
  const ValideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/complete_profile_dialog.dart';
import 'widgets/name_edit_sheet.dart';
import 'widgets/profile_authenticated_body.dart';

class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  bool _dialogShown = false;

  @override
  void deactivate() {
    _dialogShown = false;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(currentUserProvider);

    // Déclenche le dialogue une seule fois dès que l'état auth est connu et
    // que l'utilisateur est anonyme. addPostFrameCallback évite d'appeler
    // showDialog pendant build().
    if (!_dialogShown) {
      asyncUser.whenData((user) {
        if (user?.isAnonymous ?? true) {
          _dialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              CompleteProfileDialog.show(
                context,
                onLinked: () {
                  // Apres linkGoogle / signInWithCredential, ne montrer le
                  // sheet que si le compte ne fournit pas de displayName.
                  // Google fournit toujours un nom -> skip si non vide.
                  // Apple ne le fournit qu'au premier sign-in -> sheet si vide.
                  // Le routeur gere la completion de profil si le doc Firestore
                  // est absent (filiereMissing -> /onboarding).
                  final displayName = ref
                          .read(firebaseAuthProvider)
                          .currentUser
                          ?.displayName ??
                      '';
                  if (displayName.isEmpty) {
                    NameEditSheet.show(
                      context,
                      displayName: '',
                    );
                  }
                },
              );
            }
          });
        }
      });
    }

    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ProfileAuthenticatedBody(l10n: l10n, languageCode: languageCode),
    );
  }
}

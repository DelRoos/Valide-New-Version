import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/profile_authenticated_body.dart';

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ProfileAuthenticatedBody(l10n: l10n, languageCode: languageCode),
    );
  }
}

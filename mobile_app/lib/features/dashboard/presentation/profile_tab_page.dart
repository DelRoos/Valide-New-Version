import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'widgets/complete_profile_dialog.dart';
import 'widgets/profile_authenticated_body.dart';

class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  bool _upgradePromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowUpgradeSheet());
  }

  Future<void> _maybeShowUpgradeSheet() async {
    if (_upgradePromptShown || !mounted) return;
    final userState = ref.read(currentUserProvider);
    final isAnonymous = userState.maybeWhen(
      data: (user) => user?.isAnonymous ?? false,
      orElse: () => false,
    );
    AppLogger.d(
      'ProfileTab: _maybeShowUpgradeSheet '
      'isAnonymous=$isAnonymous '
      'authState=${userState.runtimeType}',
    );
    if (!isAnonymous) return;
    _upgradePromptShown = true;
    AppLogger.i('ProfileTab: anonymous user → CompleteProfileDialog');
    await CompleteProfileDialog.showIfAnonymous(context, ref);
    AppLogger.d('ProfileTab: CompleteProfileDialog returned');
  }

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

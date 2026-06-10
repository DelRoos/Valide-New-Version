// Story 1.9 — Dashboard skeleton (FR-10 partiel).
//
// Premier ecran metier post-onboarding. Pure presentation : aucun nouveau
// provider/repo, on consomme :
//   - subSystemNotifierProvider (Story 1.2) -> langKey
//   - firebaseAuthProvider (Story 0.6) -> isAnonymous (lecture sync)
//   - userProfileRepositoryProvider.watchProfile() (Story 1.5) -> displayName
//   - derivedProfileProvider (Story 1.3) -> examTargets pour le bandeau
//   - effectiveDerivedSubjectsProvider (Story 1.4) -> liste filtree des matieres
//
// AC5 fallback : si derivedProfile.Left ou effective.data([]) -> empty state.
// Loading : skeleton shimmer via flutter_animate (Story 0.14 deja au pubspec).
//
// Composants UI extraits dans widgets/ (CLAUDE.md regle 12 max-lines) :
//   - DashboardHero (banniere haut)
//   - DashboardSubjectsArea (grid + skeleton + empty)
//   - DashboardGuestInviteCard (carte invitation creation compte)
//   - DevAuditFab (FAB outil dev, dans core/debug/)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/debug/dev_audit_fab.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../onboarding/providers.dart';
import '_main_bottom_nav.dart';
import 'widgets/dashboard_guest_invite_card.dart';
import 'widgets/dashboard_hero.dart';
import 'widgets/dashboard_subjects_area.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subSystem = ref.watch(subSystemNotifierProvider);
    final langKey = subSystem?.languageCode ?? 'fr';
    final isAnonymous =
        ref.watch(firebaseAuthProvider).currentUser?.isAnonymous ?? true;

    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();
    final derivedAsync = ref.watch(derivedProfileProvider);
    final effectiveAsync = ref.watch(effectiveDerivedSubjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                dashboardCrossAxisCountFor(constraints.maxWidth);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<Map<String, dynamic>?>(
                  stream: profileStream,
                  builder: (context, snap) {
                    final displayName = snap.data?['displayName'] as String?;
                    final firstName =
                        (displayName != null && displayName.isNotEmpty)
                            ? displayName.split(' ').first
                            : null;
                    return DashboardHero(
                      firstName: firstName,
                      examLabel: dashboardExamLabelFor(derivedAsync, langKey),
                      isAnonymous: isAnonymous,
                    );
                  },
                ),
                Expanded(
                  child: DashboardSubjectsArea(
                    derivedAsync: derivedAsync,
                    effectiveAsync: effectiveAsync,
                    crossAxisCount: crossAxisCount,
                    langKey: langKey,
                  ),
                ),
                if (isAnonymous)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s4.w,
                      AppSpacing.s2.h,
                      AppSpacing.s4.w,
                      AppSpacing.s3.h,
                    ),
                    child: const DashboardGuestInviteCard(),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      floatingActionButton: const DevAuditFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

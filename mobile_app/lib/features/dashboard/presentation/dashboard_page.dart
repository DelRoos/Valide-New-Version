// Story 1.9 — Dashboard skeleton (FR-10 partiel).
//
// Premier ecran metier post-onboarding. Pure presentation : on consomme
//   - firebaseAuthProvider.currentUser?.isAnonymous -> banner upgrade
//   - userProfileRepositoryProvider.watchProfile() -> displayName
//   - userSubjectsProvider -> matieres derivees du profil
//
// Composants UI extraits dans widgets/ (CLAUDE.md regle 12 max-lines) :
//   - DashboardHero (banniere haut)
//   - DashboardSubjectsArea (grid + skeleton + empty)
//   - DashboardGuestInviteCard (carte upgrade visiteur -> compte permanent)
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
    // Audit NEW-BUG-17 — watch currentUserProvider (StreamProvider sur
    // authStateChanges) au lieu de firebaseAuthProvider (statique) pour que
    // l'upgrade visiteur -> compte permanent rebuild le dashboard et masque
    // automatiquement DashboardGuestInviteCard.
    final isAnonymous = ref.watch(currentUserProvider).maybeWhen(
          data: (user) => user?.isAnonymous ?? true,
          orElse: () => true,
        );

    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
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
                      examLabel: null,
                      isAnonymous: isAnonymous,
                    );
                  },
                ),
                const Expanded(
                  child: DashboardSubjectsArea(),
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

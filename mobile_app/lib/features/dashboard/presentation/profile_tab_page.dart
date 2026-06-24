import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/catalogue/providers.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/providers.dart';
import 'widgets/profile_edit_sheet.dart';
import 'widgets/school_edit_sheet.dart';

class ProfileTabPage extends ConsumerWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    final isAnonymous = ref.watch(currentUserProvider).maybeWhen(
          data: (user) => user?.isAnonymous ?? true,
          orElse: () => true,
        );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: isAnonymous
          ? _GuestBody(l10n: l10n)
          : _AuthenticatedBody(l10n: l10n, languageCode: languageCode),
    );
  }
}

// ── Authenticated body ────────────────────────────────────────────────────────

class _AuthenticatedBody extends ConsumerWidget {
  const _AuthenticatedBody({
    required this.l10n,
    required this.languageCode,
  });

  final AppLocalizations l10n;
  final String languageCode;

  void _onDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Toutes tes données seront supprimées définitivement.\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final auth = ref.read(firebaseAuthProvider);
      final firestore = ref.read(firestoreProvider);
      final user = auth.currentUser;
      if (user == null) return;
      // 1. Supprimer le document Firestore en ligne
      try {
        await firestore.collection('users').doc(user.uid).delete();
      } catch (_) {}
      // 2. Terminer les listeners puis vider le cache offline du téléphone
      try {
        await firestore.terminate();
        await firestore.clearPersistence();
      } catch (_) {}
      // 3. Supprimer le compte Auth → déclenche le redirect vers onboarding
      await user.delete();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileData = ref
        .watch(userProfileRepositoryProvider)
        .watchProfile()
        .map((snap) => snap);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: profileData,
      builder: (context, snap) {
        final data = snap.data;
        final schoolId = data?['schoolId'] as String?;
        final schoolName = data?['schoolName'] as String?;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                l10n: l10n,
                languageCode: languageCode,
              ),
            ),
            SliverToBoxAdapter(
              child: _StatsRow(l10n: l10n),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.s4.w,
                  AppSpacing.s5.h,
                  AppSpacing.s4.w,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuSection(
                      title: 'Mon parcours',
                      items: [
                        _MenuItemData(
                          icon: LucideIcons.star,
                          label: l10n.profileMenuSubscription,
                          color: const Color(0xFFF59E0B),
                          onTap: () => AppToast.show(
                            context,
                            message: l10n.featureComingSoon,
                            tone: ToastTone.info,
                          ),
                        ),
                        _MenuItemData(
                          icon: LucideIcons.barChart2,
                          label: l10n.profileMenuResults,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => AppToast.show(
                            context,
                            message: l10n.featureComingSoon,
                            tone: ToastTone.info,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                    _MenuSection(
                      title: 'Réglages',
                      items: [
                        _MenuItemData(
                          icon: LucideIcons.languages,
                          label: l10n.profileMenuLanguage,
                          color: const Color(0xFF0EA5E9),
                          onTap: () => AppToast.show(
                            context,
                            message: l10n.featureComingSoon,
                            tone: ToastTone.info,
                          ),
                        ),
                        _MenuItemData(
                          icon: LucideIcons.bell,
                          label: l10n.profileMenuNotifications,
                          color: const Color(0xFF10B981),
                          onTap: () => AppToast.show(
                            context,
                            message: l10n.featureComingSoon,
                            tone: ToastTone.info,
                          ),
                        ),
                        _MenuItemData(
                          icon: LucideIcons.settings,
                          label: l10n.profileMenuAccount,
                          color: AppColors.muted,
                          onTap: () =>
                              GoRouter.of(context).push('/profil/settings'),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s4.h),
                    _MenuSection(
                      title: 'Compte',
                      items: [
                        _MenuItemData(
                          icon: LucideIcons.school,
                          label: l10n.profileMenuSchool,
                          color: const Color(0xFF0EA5E9),
                          onTap: () => SchoolEditSheet.show(
                            context,
                            schoolId: schoolId,
                            schoolName: schoolName,
                          ),
                        ),
                        _MenuItemData(
                          icon: LucideIcons.logOut,
                          label: l10n.profileMenuSignOut,
                          color: AppColors.danger,
                          onTap: () =>
                              ref.read(firebaseAuthProvider).signOut(),
                        ),
                        _MenuItemData(
                          icon: LucideIcons.trash2,
                          label: 'Supprimer le compte',
                          color: AppColors.danger,
                          onTap: () => _onDeleteAccount(context, ref),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.s8.h),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.l10n,
    required this.languageCode,
  });

  final AppLocalizations l10n;
  final String languageCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStream =
        ref.watch(userProfileRepositoryProvider).watchProfile();
    final catalogueAsync = ref.watch(catalogueProvider);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: profileStream,
      builder: (context, snap) {
        final data = snap.data;
        final displayName = data?['displayName'] as String?;
        final levelId = data?['levelId'] as String?;
        final streamId = data?['streamId'] as String?;

        final initial = (displayName != null && displayName.isNotEmpty)
            ? displayName[0].toUpperCase()
            : '?';

        final streamLabel = catalogueAsync.maybeWhen(
          data: (cat) {
            String? levelName;
            String? serieName;
            if (levelId != null) {
              final match =
                  cat.niveaux.where((n) => n.niveauId == levelId);
              if (match.isNotEmpty) {
                levelName =
                    match.first.name[languageCode] ?? match.first.name['fr'];
              }
            }
            if (streamId != null) {
              final match =
                  cat.series.where((s) => s.serieId == streamId);
              if (match.isNotEmpty) {
                serieName =
                    match.first.name[languageCode] ?? match.first.name['fr'];
              }
            }
            if (levelName != null && serieName != null) {
              return '$levelName — $serieName';
            }
            return levelName ?? serieName;
          },
          orElse: () => null,
        );

        final phoneNumber = data?['phoneNumber'] as String?;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s4.w,
                AppSpacing.s4.h,
                AppSpacing.s4.w,
                AppSpacing.s6.h,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.profilePageTitle,
                        style: AppTypography.h2.copyWith(
                          color: Colors.white,
                          fontSize: AppFontSize.h2,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          LucideIcons.settings,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: AppIconSize.md,
                        ),
                        onPressed: () =>
                            GoRouter.of(context).push('/profil/settings'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                  // Avatar
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: AppBorderWidth.bold,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: AppTypography.h1.copyWith(
                          color: Colors.white,
                          fontSize: AppFontSize.h1,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.s3.h),
                  Text(
                    displayName ?? '—',
                    style: AppTypography.h3.copyWith(
                      color: Colors.white,
                      fontSize: AppFontSize.h3,
                    ),
                  ),
                  if (streamLabel != null) ...[
                    SizedBox(height: AppSpacing.s1.h),
                    Text(
                      streamLabel,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: AppFontSize.bodySmall,
                      ),
                    ),
                  ],
                  SizedBox(height: AppSpacing.s3.h),
                  TextButton.icon(
                    onPressed: () => ProfileEditSheet.show(
                      context,
                      displayName: displayName ?? '',
                      phoneNumber: phoneNumber,
                    ),
                    icon: Icon(
                      LucideIcons.pencil,
                      size: AppIconSize.sm,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    label: Text(
                      l10n.profileEditButton,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppFontSize.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.s4.h,
        horizontal: AppSpacing.s4.w,
      ),
      child: Row(
        children: [
          _StatCell(
            value: '7',
            unit: l10n.profileDays,
            label: l10n.profileStreak,
            icon: LucideIcons.flame,
            iconColor: const Color(0xFFEF4444),
          ),
          _Divider(),
          _StatCell(
            value: '24',
            unit: '',
            label: l10n.profileLessons,
            icon: LucideIcons.bookOpen,
            iconColor: AppColors.primary,
          ),
          _Divider(),
          _StatCell(
            value: '68%',
            unit: '',
            label: l10n.profileAvgScore,
            icon: LucideIcons.target,
            iconColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.lg, color: iconColor),
          SizedBox(height: AppSpacing.s1.h),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.ink,
                    fontSize: AppFontSize.h3,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                      fontSize: AppFontSize.caption,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTypography.eyebrow.copyWith(
              color: AppColors.muted,
              fontSize: AppFontSize.eyebrow,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppBorderWidth.hairline,
      height: 48.h,
      color: AppColors.border,
    );
  }
}

// ── Menu section ──────────────────────────────────────────────────────────────

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.eyebrow.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.eyebrow,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: AppSpacing.s2.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppElevation.soft,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: AppBorderWidth.hairline,
                    color: AppColors.border,
                    indent: AppSpacing.s4.w + AppSpacing.s10,
                  ),
                _MenuItem(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});

  final _MenuItemData item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s4.w,
          vertical: AppSpacing.s4.h,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.s10,
              height: AppSpacing.s10,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(item.icon, size: AppIconSize.md, color: item.color),
            ),
            SizedBox(width: AppSpacing.s3.w),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.body.copyWith(
                  color: AppColors.ink,
                  fontSize: AppFontSize.body,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: AppIconSize.sm,
              color: AppColors.mute2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest body ────────────────────────────────────────────────────────────────

class _GuestBody extends StatelessWidget {
  const _GuestBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.s4.w),
        child: Column(
          children: [
            SizedBox(height: AppSpacing.s6.h),
            // Illustration zone
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              child: Icon(
                LucideIcons.userRound,
                size: AppIconSize.xl9,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.s5.h),
            Text(
              l10n.profileGuestTitle,
              style: AppTypography.h2.copyWith(
                color: AppColors.ink,
                fontSize: AppFontSize.h2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s2.h),
            Text(
              l10n.profileGuestSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.muted,
                fontSize: AppFontSize.body,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.s6.h),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => GoRouter.of(context).go('/onboarding/v2'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  'Créer un compte',
                  style: AppTypography.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: AppFontSize.body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

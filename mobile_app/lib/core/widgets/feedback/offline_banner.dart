// Bandeau global "Hors ligne" affiche en haut de l'app tant que la
// connectivite est absente. Cable dans ValideApp via un Overlay au-dessus
// du MaterialApp.router.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../connectivity/connectivity_provider.dart';
import '../../theme/tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = connectivityAsync.maybeWhen(
      data: (status) => status == ConnectivityStatus.offline,
      orElse: () => false,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: isOffline
          ? _Banner(
              key: const ValueKey('offline'),
              message: AppLocalizations.of(context).offlineBannerMessage,
            )
          : const SizedBox.shrink(key: ValueKey('online')),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningInk,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s2.h,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.wifiOff,
                  size: AppIconSize.lg, color: Colors.white),
              SizedBox(width: AppSpacing.s2.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyStrong.copyWith(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

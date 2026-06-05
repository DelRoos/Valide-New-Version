import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app.dart';
import '../../../core/di/providers.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pedagogical_content.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Page Hello Valide — sentinelle E0 (Story 0.21).
///
/// Intègre dans une seule page tous les blocs P0 livrés pendant l'Epic 0 :
///
/// - i18n FR/EN (Story 0.16) avec sélecteur runtime
/// - Tokens design + thème (Stories 0.10/0.11/0.12)
/// - `PedagogicalContent` qui rend Markdown + LaTeX + Mermaid (Stories 0.15
///   / 0.19 / 0.19.2 — pivot gpt_markdown, ADR-014)
/// - Composants atomiques `AppButton` (Stories 0.13/0.14)
/// - Responsive max 600 dp sur tablette (Story 0.12 AC5/AC6)
///
/// La sentinelle reste utile post-MVP comme smoke test régression — si une
/// PR critique casse l'un des blocs ci-dessus, cette page le révèle.
class HelloPage extends ConsumerStatefulWidget {
  const HelloPage({super.key});

  @override
  ConsumerState<HelloPage> createState() => _HelloPageState();
}

class _HelloPageState extends ConsumerState<HelloPage> {
  String? _markdownFr;
  String? _markdownEn;

  @override
  void initState() {
    super.initState();
    _loadMarkdowns();
  }

  Future<void> _loadMarkdowns() async {
    final fr = await rootBundle.loadString('assets/sentinel/hello_sentinel_fr.md');
    final en = await rootBundle.loadString('assets/sentinel/hello_sentinel_en.md');
    if (!mounted) return;
    setState(() {
      _markdownFr = fr;
      _markdownEn = en;
    });
  }

  @override
  Widget build(BuildContext context) {
    final greetingTarget = ref.watch(helloProvider);
    final responsive = Responsive.of(context);
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final markdown = currentLocale.languageCode == 'en'
        ? _markdownEn
        : _markdownFr;

    final titleStyle = AppTypography.h1.copyWith(
      fontSize: responsive.select<double>(
        phone: AppTypography.h1.fontSize!.sp,
        tablet: AppTypography.display.fontSize!.sp,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s6.w,
                vertical: AppSpacing.s6.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.helloValide(greetingTarget),
                    style: titleStyle,
                  ),
                  SizedBox(height: AppSpacing.s2.h),
                  Text(
                    '${responsive.formFactor.name} · ${responsive.width.toStringAsFixed(0)} dp',
                    style: AppTypography.meta.copyWith(color: AppColors.muted),
                  ),
                  SizedBox(height: AppSpacing.s6.h),
                  _LanguageSwitcher(
                    current: currentLocale,
                    onChanged: (loc) =>
                        ref.read(localeProvider.notifier).setLocale(loc),
                    label: l10n.helloLanguageLabel,
                    frLabel: l10n.helloLanguageFr,
                    enLabel: l10n.helloLanguageEn,
                  ),
                  SizedBox(height: AppSpacing.s6.h),
                  if (markdown != null)
                    PedagogicalContent(data: markdown)
                  else
                    const _MarkdownLoading(),
                  SizedBox(height: AppSpacing.s6.h),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: l10n.cancelLabel,
                          onPressed: () {},
                        ),
                      ),
                      SizedBox(width: AppSpacing.s3.w),
                      Expanded(
                        child: AppButton.primary(
                          label: l10n.continueLabel,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.current,
    required this.onChanged,
    required this.label,
    required this.frLabel,
    required this.enLabel,
  });

  final Locale current;
  final ValueChanged<Locale> onChanged;
  final String label;
  final String frLabel;
  final String enLabel;

  static const _fr = Locale('fr');
  static const _en = Locale('en');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.meta.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: AppSpacing.s2.h),
        SegmentedButton<Locale>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _fr, label: Text(frLabel)),
            ButtonSegment(value: _en, label: Text(enLabel)),
          ],
          selected: {current.languageCode == 'en' ? _en : _fr},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }
}

class _MarkdownLoading extends StatelessWidget {
  const _MarkdownLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
      child: SizedBox(
        height: 32.h,
        width: 32.w,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted),
      ),
    );
  }
}

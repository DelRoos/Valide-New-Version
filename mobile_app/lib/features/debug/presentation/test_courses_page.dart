import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/pedagogical_content.dart';

/// Catalogue des cours de test pour Story 0.19 (R2) — validation precoce de
/// `flutter_smooth_markdown` sur du Markdown + LaTeX + Mermaid + code.
/// Cette route disparait a la cloture E0 (Story 0.21).
class TestCoursesPage extends StatelessWidget {
  const TestCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tests cours (R2 debug)')),
      body: ListView.separated(
        padding: EdgeInsets.all(AppSpacing.s4.w),
        itemCount: testCourses.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s3.h),
        itemBuilder: (context, index) {
          final course = testCourses[index];
          return AppCard(
            onTap: () => context.push('/_test_courses/${course.slug}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: AppTypography.h3),
                SizedBox(height: AppSpacing.s2.h),
                Text(course.description, style: AppTypography.body),
                SizedBox(height: AppSpacing.s2.h),
                Text(
                  'Focus rendu : ${course.renderFocus}',
                  style: AppTypography.meta.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Detail d'un cours : charge le `.md` depuis les assets, mesure le temps
/// d'ouverture (cold + warm) via `Stopwatch` et affiche les chiffres en
/// haut de page pour AC3.
class TestCourseDetailPage extends StatefulWidget {
  const TestCourseDetailPage({super.key, required this.slug});

  final String slug;

  @override
  State<TestCourseDetailPage> createState() => _TestCourseDetailPageState();
}

class _TestCourseDetailPageState extends State<TestCourseDetailPage> {
  late final TestCourse course;
  String? _markdown;
  int? _loadMs;
  int? _firstFrameMs;

  @override
  void initState() {
    super.initState();
    course = testCourses.firstWhere(
      (c) => c.slug == widget.slug,
      orElse: () => testCourses.first,
    );
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    final loadWatch = Stopwatch()..start();
    final md = await rootBundle.loadString(course.assetPath);
    loadWatch.stop();
    if (!mounted) return;
    setState(() {
      _markdown = md;
      _loadMs = loadWatch.elapsedMilliseconds;
    });
    // Mesure du premier frame apres rendu : on schedule un callback
    // post-frame et on note delta depuis le `setState`.
    final frameWatch = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      frameWatch.stop();
      if (!mounted) return;
      setState(() => _firstFrameMs = frameWatch.elapsedMilliseconds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final md = _markdown;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(course.title)),
      body: md == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(AppSpacing.s4.w),
              children: [
                _BenchmarkBanner(loadMs: _loadMs, firstFrameMs: _firstFrameMs),
                SizedBox(height: AppSpacing.s4.h),
                PedagogicalContent(data: md),
              ],
            ),
    );
  }
}

class _BenchmarkBanner extends StatelessWidget {
  const _BenchmarkBanner({required this.loadMs, required this.firstFrameMs});

  final int? loadMs;
  final int? firstFrameMs;

  @override
  Widget build(BuildContext context) {
    final total = (loadMs ?? 0) + (firstFrameMs ?? 0);
    final ok = total > 0 && total < 2000;
    return Container(
      padding: EdgeInsets.all(AppSpacing.s3.w),
      decoration: BoxDecoration(
        color: ok ? AppColors.successSoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: ok ? AppColors.successInk : AppColors.warningInk,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benchmark AC3 (cible < 2000 ms)',
            style: AppTypography.bodyStrong.copyWith(
              color: ok ? AppColors.successInk : AppColors.warningInk,
            ),
          ),
          SizedBox(height: AppSpacing.s1.h),
          Text(
            'Asset load : ${loadMs ?? '...'} ms\n'
            'First frame : ${firstFrameMs ?? '...'} ms\n'
            'Total : ${total > 0 ? '$total ms' : '...'}',
            style: AppTypography.meta,
          ),
        ],
      ),
    );
  }
}

@immutable
class TestCourse {
  const TestCourse({
    required this.slug,
    required this.title,
    required this.description,
    required this.renderFocus,
    required this.assetPath,
  });

  final String slug;
  final String title;
  final String description;
  final String renderFocus;
  final String assetPath;
}

const List<TestCourse> testCourses = [
  TestCourse(
    slug: 'maths_derivees',
    title: 'Maths — Dérivées et primitives',
    description: 'Tle D / C, ~3000 mots, 10+ formules LaTeX inline et display.',
    renderFocus: 'LaTeX \$...\$ et \$\$...\$\$ + tableaux',
    assetPath: 'assets/dev/test_courses/maths_derivees.md',
  ),
  TestCourse(
    slug: 'pct_acide_base',
    title: 'PCT — Réactions acide-base',
    description: 'Tle C / D, équations chimiques avec indices et exposants.',
    renderFocus: 'LaTeX subscript / superscript (\$H_3O^+\$, \$CO_3^{2-}\$)',
    assetPath: 'assets/dev/test_courses/pct_acide_base.md',
  ),
  TestCourse(
    slug: 'info_algo_recherche',
    title: 'Info — Algorithmes de recherche',
    description: 'Tle / 1er cycle, blocs de code Python + flowchart Mermaid.',
    renderFocus: 'Code Python fenced + Mermaid flowchart TD / LR',
    assetPath: 'assets/dev/test_courses/info_algo_recherche.md',
  ),
];

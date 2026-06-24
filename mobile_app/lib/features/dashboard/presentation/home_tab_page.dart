import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/tokens.dart';

// ---------------------------------------------------------------------------
// Fake data
// ---------------------------------------------------------------------------

const _kName = 'Fatou';
const _kClass = 'Terminale D';
const _kSchool = 'Lycée Général Leclerc';
const _kIsExamClass = true;
const _kDaysToExam = 47;
const _kExamLabel = 'BAC';
const _kSequenceLabel = 'Séq. 3-4';
const _kGlobalCoverage = 0.52;

const _kLastLessonTitle = 'Dérivation et étude de fonctions';
const _kLastLessonChapter = 'Chapitre 3';
const _kLastLessonSubject = 'Mathématiques';
const _kLastLessonProgress = 0.60;
const _kLastLessonColor = Color(0xFF2563EB);

class _Subject {
  const _Subject(this.name, this.icon, this.coverage, this.color);
  final String name;
  final IconData icon;
  final double coverage;
  final Color color;
}

const _kSubjects = [
  _Subject('Mathématiques', LucideIcons.calculator, 0.72, Color(0xFF2563EB)),
  _Subject('Physique-Chimie', LucideIcons.atom, 0.45, Color(0xFF7C3AED)),
  _Subject('SVT', LucideIcons.leaf, 0.30, Color(0xFF059669)),
  _Subject('Philosophie', LucideIcons.bookMarked, 0.68, Color(0xFFD97706)),
  _Subject('Français', LucideIcons.penLine, 0.55, Color(0xFFDC2626)),
];

class _Classmate {
  const _Classmate(this.initials, this.name, this.activity, this.since, this.color);
  final String initials;
  final String name;
  final String activity;
  final String since;
  final Color color;
}

const _kClassmates = [
  _Classmate('AK', 'Amina K.', 'révise Chimie organique', '30 min', Color(0xFF7C3AED)),
  _Classmate('JN', 'Jean-Paul N.', 'a terminé Fonctions — Ch. 3', '1 h', Color(0xFF059669)),
  _Classmate('MT', 'Mariam T.', 'a fait 5 exercices de Physique', '2 h', Color(0xFFD97706)),
];

// ---------------------------------------------------------------------------

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bonjour';
  if (h < 18) return 'Bon après-midi';
  return 'Bonsoir';
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width >= 840 ? (width - 700) / 2 : AppSpacing.s4;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: const _HomeHeader()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hPad.w, AppSpacing.s4.h, hPad.w, AppSpacing.s12.h,
            ),
            sliver: SliverList.list(children: [
              const _ResumeCard(),
              SizedBox(height: AppSpacing.s6.h),
              const _ProgrammeSection(),
              SizedBox(height: AppSpacing.s6.h),
              const _QuickExerciseCard(),
              SizedBox(height: AppSpacing.s6.h),
              const _ClassmatesSection(),
            ]),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — compact, sans gradient, tout sur 2 lignes
// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final daysColor = _kDaysToExam < 14
        ? AppColors.danger
        : _kDaysToExam < 30
            ? AppColors.warning
            : AppColors.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s5.w,
        top + AppSpacing.s4.h,
        AppSpacing.s4.w,
        AppSpacing.s4.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $_kName 👋',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.h2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: AppSpacing.s1.h),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.bodySmall,
                      color: AppColors.muted,
                    ),
                    children: [
                      TextSpan(text: '$_kClass · '),
                      if (_kIsExamClass)
                        TextSpan(
                          text: '$_kExamLabel dans $_kDaysToExam jours',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: daysColor,
                          ),
                        )
                      else
                        TextSpan(text: _kSchool),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s3.w),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: AppSpacing.s10.w,
              height: AppSpacing.s10.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                boxShadow: AppElevation.soft,
              ),
              child: Icon(
                LucideIcons.bell,
                size: AppIconSize.lg,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card reprendre — gradient couleur matière, dominante
// ---------------------------------------------------------------------------

class _ResumeCard extends StatelessWidget {
  const _ResumeCard();

  @override
  Widget build(BuildContext context) {
    final pct = (_kLastLessonProgress * 100).round();
    final dark = Color.lerp(_kLastLessonColor, Colors.black, 0.35)!;

    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kLastLessonColor, dark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            boxShadow: [
              BoxShadow(
                color: _kLastLessonColor.withValues(alpha: 0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.s5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chip matière + label "continuer"
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2.w,
                      vertical: AppSpacing.s1.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      _kLastLessonSubject.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.tiny,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _kLastLessonChapter,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.caption,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s4.h),
              // Titre
              Text(
                _kLastLessonTitle,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.h2Compact,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.s5.h),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: _kLastLessonProgress,
                  minHeight: 6.h,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(height: AppSpacing.s3.h),
              // Stats + CTA
              Row(
                children: [
                  Text(
                    '$pct% lu',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(LucideIcons.play, size: AppIconSize.md),
                    label: const Text('Continuer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.s4.w,
                        vertical: AppSpacing.s2.h,
                      ),
                      textStyle: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section programme
// ---------------------------------------------------------------------------

class _ProgrammeSection extends StatelessWidget {
  const _ProgrammeSection();

  @override
  Widget build(BuildContext context) {
    final pct = (_kGlobalCoverage * 100).round();
    final isLow = _kGlobalCoverage < 0.40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mon programme · $_kSequenceLabel',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.h3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.h3,
                fontWeight: FontWeight.w800,
                color: isLow ? AppColors.danger : AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s3.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: _kGlobalCoverage,
            minHeight: 8.h,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(
              isLow ? AppColors.danger : AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.s1.h),
        Text(
          isLow
              ? 'Programme peu couvert — intensifie les révisions'
              : 'Tu avances bien sur cette séquence',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.caption,
            color: isLow ? AppColors.danger : AppColors.muted,
          ),
        ),
        SizedBox(height: AppSpacing.s4.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.s4.w,
            vertical: AppSpacing.s2.h,
          ),
          child: Column(
            children: List.generate(_kSubjects.length, (i) => Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s2.h),
              child: _SubjectRow(_kSubjects[i]),
            )),
          ),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow(this.subject);
  final _Subject subject;

  @override
  Widget build(BuildContext context) {
    final pct = (subject.coverage * 100).round();
    final isUrgent = subject.coverage < 0.30;
    final barColor = isUrgent ? AppColors.danger : subject.color;

    return Row(
      children: [
        Container(
          width: AppSpacing.s9.w,
          height: AppSpacing.s9.h,
          decoration: BoxDecoration(
            color: subject.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(subject.icon, size: AppIconSize.lg, color: subject.color),
        ),
        SizedBox(width: AppSpacing.s3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.name,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: FontWeight.w600,
                        color: isUrgent ? AppColors.danger : AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w700,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s1.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: subject.coverage,
                  minHeight: 4.h,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card exercice rapide
// ---------------------------------------------------------------------------

class _QuickExerciseCard extends StatelessWidget {
  const _QuickExerciseCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          padding: EdgeInsets.all(AppSpacing.s4.w),
          child: Row(
            children: [
              Container(
                width: AppSpacing.s12.w,
                height: AppSpacing.s12.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.zap, size: AppIconSize.xl2, color: Colors.white),
              ),
              SizedBox(width: AppSpacing.s4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercice rapide',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.h3,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: AppSpacing.s1.h),
                    Text(
                      '5 questions · ~3 min',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.caption,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: AppIconSize.xl, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section activité classmates
// ---------------------------------------------------------------------------

class _ClassmatesSection extends StatelessWidget {
  const _ClassmatesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppFontSize.h3,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        SizedBox(height: AppSpacing.s3.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppElevation.soft,
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _kClassmates.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1, indent: 68, color: AppColors.border,
            ),
            itemBuilder: (_, i) => _ClassmateRow(_kClassmates[i]),
          ),
        ),
      ],
    );
  }
}

class _ClassmateRow extends StatelessWidget {
  const _ClassmateRow(this.classmate);
  final _Classmate classmate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4.w,
        vertical: AppSpacing.s3.h,
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.s9.w,
            height: AppSpacing.s9.h,
            decoration: BoxDecoration(
              color: classmate.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              classmate.initials,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: AppFontSize.caption,
                fontWeight: FontWeight.w700,
                color: classmate.color,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classmate.name,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  classmate.activity,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.caption,
                    color: AppColors.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s2.w),
          Text(
            classmate.since,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppFontSize.tiny,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

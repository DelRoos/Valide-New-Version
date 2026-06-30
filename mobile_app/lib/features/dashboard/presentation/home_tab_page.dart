import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/tokens.dart';
import 'widgets/classmates_section.dart';
import 'widgets/home_header.dart';
import 'widgets/programme_section.dart';
import 'widgets/quick_exercise_card.dart';
import 'widgets/resume_card.dart';

class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // hPad en logical px dans les deux cas — pas de .w à l'usage.
    // Tablet : calculé depuis width (MediaQuery, déjà en logical px).
    // Phone  : AppSpacing.s4.w applique le scaling ScreenUtil ici.
    final hPad = width >= 840 ? (width - 700) / 2 : AppSpacing.s4.w;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HomeHeader()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hPad, AppSpacing.s4.h, hPad, AppSpacing.s12.h,
            ),
            sliver: SliverList.list(children: [
              const ResumeCard(),
              SizedBox(height: AppSpacing.s6.h),
              const ProgrammeSection(),
              SizedBox(height: AppSpacing.s6.h),
              const QuickExerciseCard(),
              SizedBox(height: AppSpacing.s6.h),
              const ClassmatesSection(),
            ]),
          ),
        ],
      ),
    );
  }
}

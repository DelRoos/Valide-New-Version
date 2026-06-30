import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_skeleton.dart';
import 'subject_header.dart';

class SubjectLoadingBody extends StatelessWidget {
  const SubjectLoadingBody({
    super.key,
    required this.subjectName,
    required this.subjectIcon,
    required this.isFr,
    required this.onBack,
  });

  final String subjectName;
  final IconData subjectIcon;
  final bool isFr;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubjectHeader(
          subjectName: subjectName,
          subjectIcon: subjectIcon,
          eyebrow: '',
          overallProgress: 0,
          rank: 0,
          isFr: isFr,
          onBack: onBack,
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s3,
            ),
            itemCount: 5,
            separatorBuilder: (_, _) => SizedBox(height: AppSpacing.s2),
            itemBuilder: (_, _) => AppSkeleton(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/chapter_entity.dart';
import 'chapter_list.dart';

// ---------------------------------------------------------------------------
// Mock — sera remplacé par un champ `sequenceId` sur ChapterEntity (Story 2.x).
// La séquence courante viendra soit de la date, soit d'un flag `isCurrent`
// dans la config classe, soit du profil user.
// ---------------------------------------------------------------------------

const int kSequencesPerYear = 6;
const int kMockCurrentSequence = 1;

int mockSequenceFor(ChapterEntity c, int totalChapters) {
  if (totalChapters == 0) return 1;
  final perSeq = (totalChapters / kSequencesPerYear).ceil().clamp(1, 9999);
  return ((c.order - 1) / perSeq).floor().clamp(0, kSequencesPerYear - 1) + 1;
}

int trimesterForSequence(int sequence) =>
    ((sequence - 1) ~/ 2).clamp(0, 2) + 1;

int computeTrimesterProgress(
  List<ChapterEntity> chapters,
  int currentSequence,
) {
  final trim = trimesterForSequence(currentSequence);
  final firstSeq = (trim - 1) * 2 + 1;
  final lastSeq = firstSeq + 1;
  final total = chapters.length;
  final inTrim = chapters.where((c) {
    final seq = mockSequenceFor(c, total);
    return seq >= firstSeq && seq <= lastSeq;
  }).toList();
  if (inTrim.isEmpty) return 0;
  final sum = inTrim.fold<int>(0, (s, c) => s + c.progressPercent);
  return (sum / inTrim.length).round();
}

// ---------------------------------------------------------------------------
// SubjectSequencesView — PageView pur (état contrôlé par le parent)
// ---------------------------------------------------------------------------

class SubjectSequencesView extends StatelessWidget {
  const SubjectSequencesView({
    super.key,
    required this.chapters,
    required this.languageCode,
    required this.subjectId,
    required this.pageController,
    required this.onPageChanged,
  });

  final List<ChapterEntity> chapters;
  final String languageCode;
  final String subjectId;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalChapters = chapters.length;
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: kSequencesPerYear,
      itemBuilder: (_, i) {
        final seqNumber = i + 1;
        final filtered = chapters
            .where((c) => mockSequenceFor(c, totalChapters) == seqNumber)
            .toList();
        return ChapterList(
          chapters: filtered,
          languageCode: languageCode,
          subjectId: subjectId,
        );
      },
    );
  }
}

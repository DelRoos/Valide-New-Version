import 'package:equatable/equatable.dart';

class ChapterEntity extends Equatable {
  const ChapterEntity({
    required this.chapterId,
    required this.subjectId,
    required this.order,
    required this.titleFr,
    required this.titleEn,
    this.descriptionFr,
    this.descriptionEn,
    this.lessonCount = 0,
    this.quizCount = 0,
    this.exerciseCount = 0,
    this.progressPercent = 0,
    this.studentCount = 0,
  });

  final String chapterId;
  final String subjectId;
  final int order;
  final String titleFr;
  final String titleEn;
  final String? descriptionFr;
  final String? descriptionEn;
  final int lessonCount;
  final int quizCount;
  final int exerciseCount;
  final int progressPercent;
  final int studentCount;

  String titleFor(String languageCode) =>
      languageCode == 'fr' ? titleFr : titleEn;

  String? descriptionFor(String languageCode) =>
      languageCode == 'fr' ? descriptionFr : descriptionEn;

  @override
  List<Object?> get props => [
        chapterId,
        subjectId,
        order,
        titleFr,
        titleEn,
        descriptionFr,
        descriptionEn,
        lessonCount,
        quizCount,
        exerciseCount,
        progressPercent,
        studentCount,
      ];
}

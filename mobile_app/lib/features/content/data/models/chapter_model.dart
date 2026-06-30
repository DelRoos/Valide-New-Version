import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chapter_entity.dart';

class ChapterModel {
  const ChapterModel({
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

  factory ChapterModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final title = (data['title'] as Map<String, dynamic>?) ?? {};
    final description = data['description'] as Map<String, dynamic>?;

    return ChapterModel(
      chapterId: doc.id,
      subjectId: (data['subjectId'] as String?) ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      titleFr: (title['fr'] as String?) ?? '',
      titleEn: (title['en'] as String?) ?? '',
      descriptionFr: description?['fr'] as String?,
      descriptionEn: description?['en'] as String?,
      lessonCount: (data['lessonCount'] as num?)?.toInt() ?? 0,
      quizCount: (data['quizCount'] as num?)?.toInt() ?? 0,
      exerciseCount: (data['exerciseCount'] as num?)?.toInt() ?? 0,
      progressPercent: (data['progressPercent'] as num?)?.toInt() ?? 0,
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChapterEntity toEntity() => ChapterEntity(
        chapterId: chapterId,
        subjectId: subjectId,
        order: order,
        titleFr: titleFr,
        titleEn: titleEn,
        descriptionFr: descriptionFr,
        descriptionEn: descriptionEn,
        lessonCount: lessonCount,
        quizCount: quizCount,
        exerciseCount: exerciseCount,
        progressPercent: progressPercent,
        studentCount: studentCount,
      );
}

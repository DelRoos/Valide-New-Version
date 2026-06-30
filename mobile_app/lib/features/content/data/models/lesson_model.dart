import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/lesson_entity.dart';

class LessonModel {
  const LessonModel({
    required this.lessonId,
    required this.chapterId,
    required this.order,
    required this.titleFr,
    required this.titleEn,
    this.subtitleFr,
    this.subtitleEn,
    this.durationMinutes = 0,
  });

  final String lessonId;
  final String chapterId;
  final int order;
  final String titleFr;
  final String titleEn;
  final String? subtitleFr;
  final String? subtitleEn;
  final int durationMinutes;

  // Content blobs live in lessons/{id}/content/main — not read here.
  factory LessonModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final title = (data['title'] as Map<String, dynamic>?) ?? {};
    final subtitle = data['subtitle'] as Map<String, dynamic>?;

    return LessonModel(
      lessonId: doc.id,
      chapterId: (data['chapterId'] as String?) ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      titleFr: (title['fr'] as String?) ?? '',
      titleEn: (title['en'] as String?) ?? '',
      subtitleFr: subtitle?['fr'] as String?,
      subtitleEn: subtitle?['en'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  LessonEntity toEntity() => LessonEntity(
        lessonId: lessonId,
        chapterId: chapterId,
        order: order,
        titleFr: titleFr,
        titleEn: titleEn,
        subtitleFr: subtitleFr,
        subtitleEn: subtitleEn,
        durationMinutes: durationMinutes,
      );
}

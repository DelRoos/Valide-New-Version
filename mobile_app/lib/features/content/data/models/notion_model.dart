import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notion_entity.dart';

class NotionModel {
  const NotionModel({
    required this.notionId,
    required this.lessonId,
    required this.order,
    required this.type,
    required this.titleFr,
    required this.titleEn,
    required this.contentFr,
    required this.contentEn,
  });

  final String notionId;
  final String lessonId;
  final int order;
  final String type;
  final String titleFr;
  final String titleEn;
  final String contentFr;
  final String contentEn;

  factory NotionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final title = data['title'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as Map<String, dynamic>? ?? {};
    return NotionModel(
      notionId: doc.id,
      lessonId: data['lessonId'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      type: data['type'] as String? ?? 'fact',
      titleFr: title['fr'] as String? ?? '',
      titleEn: title['en'] as String? ?? '',
      contentFr: content['fr'] as String? ?? '',
      contentEn: content['en'] as String? ?? '',
    );
  }

  NotionEntity toEntity() => NotionEntity(
        notionId: notionId,
        lessonId: lessonId,
        order: order,
        type: type,
        titleFr: titleFr,
        titleEn: titleEn,
        contentFr: contentFr,
        contentEn: contentEn,
      );
}

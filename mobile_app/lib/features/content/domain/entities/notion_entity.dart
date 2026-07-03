import 'package:equatable/equatable.dart';

class NotionEntity extends Equatable {
  const NotionEntity({
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

  /// 'definition' | 'formula' | 'rule' | 'fact'
  final String type;
  final String titleFr;
  final String titleEn;
  final String contentFr;
  final String contentEn;

  String titleFor(String lang) => lang == 'fr' ? titleFr : titleEn;
  String contentFor(String lang) => lang == 'fr' ? contentFr : contentEn;

  @override
  List<Object?> get props => [
        notionId,
        lessonId,
        order,
        type,
        titleFr,
        titleEn,
        contentFr,
        contentEn,
      ];
}

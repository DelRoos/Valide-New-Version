import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  const LessonEntity({
    required this.lessonId,
    required this.chapterId,
    required this.order,
    required this.titleFr,
    required this.titleEn,
    required this.contentFr,
    required this.contentEn,
    this.subtitleFr,
    this.subtitleEn,
    this.durationMinutes = 0,
  });

  final String lessonId;
  final String chapterId;
  final int order;
  final String titleFr;
  final String titleEn;
  final String contentFr;
  final String contentEn;
  final String? subtitleFr;
  final String? subtitleEn;
  final int durationMinutes;

  String titleFor(String languageCode) =>
      languageCode == 'fr' ? titleFr : titleEn;

  String contentFor(String languageCode) =>
      languageCode == 'fr' ? contentFr : contentEn;

  String? subtitleFor(String languageCode) =>
      languageCode == 'fr' ? subtitleFr : subtitleEn;

  @override
  List<Object?> get props => [
        lessonId,
        chapterId,
        order,
        titleFr,
        titleEn,
        contentFr,
        contentEn,
        subtitleFr,
        subtitleEn,
        durationMinutes,
      ];
}

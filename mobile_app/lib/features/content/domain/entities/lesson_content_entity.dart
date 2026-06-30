import 'package:equatable/equatable.dart';

class LessonContentEntity extends Equatable {
  const LessonContentEntity({
    required this.lessonId,
    required this.contentFr,
    required this.contentEn,
  });

  final String lessonId;
  final String contentFr;
  final String contentEn;

  String contentFor(String languageCode) =>
      languageCode == 'fr' ? contentFr : contentEn;

  @override
  List<Object?> get props => [lessonId, contentFr, contentEn];
}

import 'package:equatable/equatable.dart';

class ChapterFicheEntity extends Equatable {
  const ChapterFicheEntity({
    required this.chapterId,
    required this.contentFr,
    required this.contentEn,
  });

  final String chapterId;
  final String contentFr;
  final String contentEn;

  String contentFor(String languageCode) {
    if (languageCode == 'fr') return contentFr.isNotEmpty ? contentFr : contentEn;
    return contentEn.isNotEmpty ? contentEn : contentFr;
  }

  @override
  List<Object?> get props => [chapterId, contentFr, contentEn];
}

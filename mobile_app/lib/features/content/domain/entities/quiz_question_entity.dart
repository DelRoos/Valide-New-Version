import 'package:equatable/equatable.dart';

class QuizQuestionEntity extends Equatable {
  const QuizQuestionEntity({
    required this.id,
    required this.textFr,
    required this.textEn,
    required this.optionsFr,
    required this.optionsEn,
    required this.correctIndex,
    this.notionId,
    this.explanationFr,
    this.explanationEn,
  });

  final String id;
  final String? notionId;
  final String textFr;
  final String textEn;
  final List<String> optionsFr;
  final List<String> optionsEn;
  final int correctIndex;
  final String? explanationFr;
  final String? explanationEn;

  String textFor(String languageCode) =>
      languageCode == 'fr' ? textFr : textEn;

  List<String> optionsFor(String languageCode) =>
      languageCode == 'fr' ? optionsFr : optionsEn;

  String? explanationFor(String languageCode) =>
      languageCode == 'fr' ? explanationFr : explanationEn;

  @override
  List<Object?> get props => [
        id,
        notionId,
        textFr,
        textEn,
        optionsFr,
        optionsEn,
        correctIndex,
        explanationFr,
        explanationEn,
      ];
}

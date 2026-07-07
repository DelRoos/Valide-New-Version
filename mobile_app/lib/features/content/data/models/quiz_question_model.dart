import '../../domain/entities/quiz_question_entity.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
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

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    final text = map['text'] as Map<String, dynamic>? ?? {};
    final options = map['options'] as Map<String, dynamic>? ?? {};
    final explanation = map['explanation'] as Map<String, dynamic>?;
    return QuizQuestionModel(
      id: map['id'] as String? ?? '',
      notionId: map['notionId'] as String?,
      textFr: text['fr'] as String? ?? '',
      textEn: text['en'] as String? ?? '',
      optionsFr: List<String>.from(options['fr'] as List? ?? []),
      optionsEn: List<String>.from(options['en'] as List? ?? []),
      correctIndex: map['correctIndex'] as int? ?? 0,
      explanationFr: explanation?['fr'] as String?,
      explanationEn: explanation?['en'] as String?,
    );
  }

  QuizQuestionEntity toEntity() => QuizQuestionEntity(
        id: id,
        notionId: notionId,
        textFr: textFr,
        textEn: textEn,
        optionsFr: optionsFr,
        optionsEn: optionsEn,
        correctIndex: correctIndex,
        explanationFr: explanationFr,
        explanationEn: explanationEn,
      );
}

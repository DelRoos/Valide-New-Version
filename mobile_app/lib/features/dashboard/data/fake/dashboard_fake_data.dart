// Données de substitution pour l'UI hardcodée (Story 2.3).
// À remplacer par l'intégration Firestore dans une story ultérieure.

class _FakeRecommendation {
  const _FakeRecommendation({
    required this.titleFr,
    required this.titleEn,
  });

  final String titleFr;
  final String titleEn;

  String title(String langKey) => langKey == 'en' ? titleEn : titleFr;
}

const kFakeRecommendation = _FakeRecommendation(
  titleFr: 'Fonctions dérivées et applications',
  titleEn: 'Derivative functions and applications',
);

const List<int> _kFakeProgress = [72, 45, 88, 30, 60, 15, 50, 95];

int fakeProgressAt(int index) => _kFakeProgress[index % _kFakeProgress.length];

// Story 1.4 AC5 — Tests effectiveDerivedSubjectsProvider (StreamProvider).
//
// Combine derivedProfileProvider + userProfileRepository.watchProfile()
// pour exposer la liste filtree des matieres effectivement presentees a
// l'examen (derivedSubjects \ optedOutSubjects).
//
// Meme pattern que profile_completion_provider_test.dart : ProviderContainer
// + override + listen + polling (provider.future + Stream.value est instable
// avec Riverpod 3.x).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/catalogue/domain/catalogue_failure.dart';
import 'package:valide_school/core/catalogue/domain/models.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';
import 'package:valide_school/features/onboarding/providers.dart';

class _FakeRepo implements UserProfileRepository {
  _FakeRepo(this._stream);
  final Stream<Map<String, dynamic>?> _stream;

  @override
  Stream<Map<String, dynamic>?> watchProfile() => _stream;

  @override
  Future<Either<ProfileFailure, void>> createProfile({
    required SubSystem subSystem,
    required String filiereId,
    required String niveauId,
    required String serieId,
    required List<String> derivedSubjects,
    required List<String> examTargets,
  }) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateOptedOutSubjects(
    List<String> optedOutSubjectIds,
  ) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateSchoolId(String? schoolId) async =>
      const Right(null);
}

Subject _subject(String id) => Subject(
      subjectId: id,
      subSystem: 'anglophone',
      name: {'fr': id, 'en': id},
      icon: 'book-open',
      isActive: true,
      sortOrder: 0,
    );

DerivedProfile _profileWith(List<String> ids, {bool canOptOut = true}) =>
    DerivedProfile(
      subjects: ids.map(_subject).toList(),
      examTargets: const [],
      canOptOut: canOptOut,
    );

Future<List<Subject>?> _resolveEffective({
  required Either<CatalogueFailure, DerivedProfile> derived,
  required Stream<Map<String, dynamic>?> profileStream,
}) async {
  final container = ProviderContainer(
    overrides: [
      derivedProfileProvider.overrideWith((ref) async => derived),
      userProfileRepositoryProvider.overrideWithValue(_FakeRepo(profileStream)),
    ],
  );
  addTearDown(container.dispose);

  container.listen<AsyncValue<List<Subject>>>(
    effectiveDerivedSubjectsProvider,
    (_, _) {},
    fireImmediately: true,
  );

  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final async = container.read(effectiveDerivedSubjectsProvider);
    if (async is AsyncData<List<Subject>>) return async.value;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('effectiveDerivedSubjectsProvider — Story 1.4 AC5', () {
    test('(a) optedOutSubjects vide -> retourne toutes les matieres derivees',
        () async {
      final result = await _resolveEffective(
        derived: Right(_profileWith(['math', 'physics', 'chemistry'])),
        profileStream: Stream.value(<String, dynamic>{
          'optedOutSubjects': <String>[],
        }),
      );
      expect(result, isNotNull);
      expect(result!.map((s) => s.subjectId), ['math', 'physics', 'chemistry']);
    });

    test(
        '(b) optedOutSubjects = [biology] sur [math, biology, chemistry] -> filtre biology',
        () async {
      final result = await _resolveEffective(
        derived: Right(_profileWith(['math', 'biology', 'chemistry'])),
        profileStream: Stream.value(<String, dynamic>{
          'optedOutSubjects': ['biology'],
        }),
      );
      expect(result, isNotNull);
      expect(result!.map((s) => s.subjectId), ['math', 'chemistry']);
    });

    test('(c) doc Firestore null (uid absent) -> aucun filtrage', () async {
      final result = await _resolveEffective(
        derived: Right(_profileWith(['math', 'physics'])),
        profileStream: Stream.value(null),
      );
      expect(result, isNotNull);
      expect(result!.map((s) => s.subjectId), ['math', 'physics']);
    });

    test('(d) derivedProfile Left(failure) -> stream vide', () async {
      final result = await _resolveEffective(
        derived: Left(
          CatalogueFailure.noMatchingRule(
            subSystem: 'anglophone',
            filiere: 'generale',
            niveau: 'form_5',
            serie: null,
          ),
        ),
        profileStream: Stream.value(<String, dynamic>{
          'optedOutSubjects': <String>[],
        }),
      );
      // stream vide -> AsyncData jamais emis dans 500ms (polling timeout)
      expect(result, isNull);
    });
  });
}

// Helpers de test partages — fakes FirebaseAuth + UserProfileRepository
// pour overrides Riverpod sans firebase_auth_mocks (absent du pubspec).
//
// Voir Story 1.5 (test profile_completion_provider_test.dart) et Story 1.9
// (DashboardPage qui lit firebaseAuthProvider + watchProfile()).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
import 'package:valide_school/features/onboarding/domain/sub_system.dart';
import 'package:valide_school/features/onboarding/domain/user_profile_repository.dart';

class FakeAuth implements FirebaseAuth {
  FakeAuth({
    this.uid = 'test-uid',
    this.isAnonymous = false,
    this.displayName,
    this.email,
  });

  final String? uid;
  final bool isAnonymous;
  final String? displayName;
  final String? email;

  @override
  User? get currentUser => uid == null
      ? null
      : _FakeUser(
          uid: uid!,
          isAnonymous: isAnonymous,
          displayName: displayName,
          email: email,
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUser implements User {
  _FakeUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
    this.email,
  });

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? displayName;

  @override
  final String? email;

  // Liste vide par defaut (`user.providerData` est consomme par les widgets
  // Story 1.10 pour detecter le provider lie Google/Apple).
  @override
  List<UserInfo> get providerData => const [];

  // Default null sur tous les autres getters (les widgets de test n'y
  // touchent pas — si un nouveau widget en a besoin, ajouter une propriete
  // explicite ci-dessus).
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Audit NEW-BUG-17 — Factory publique pour les tests qui doivent stubber
/// `currentUserProvider` directement (StreamProvider sur authStateChanges).
User fakeUser({
  required String uid,
  required bool isAnonymous,
  String? displayName,
}) {
  return _FakeUser(
    uid: uid,
    isAnonymous: isAnonymous,
    displayName: displayName,
  );
}

class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository({this.profileData});

  final Map<String, dynamic>? profileData;

  @override
  Stream<Map<String, dynamic>?> watchProfile() => Stream.value(profileData);

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
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>?>> fetchProfileOnce() async =>
      Right(profileData);
}

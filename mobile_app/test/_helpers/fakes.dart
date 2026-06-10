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
  FakeAuth({this.uid = 'test-uid', this.isAnonymous = false, this.displayName});

  final String? uid;
  final bool isAnonymous;
  final String? displayName;

  @override
  User? get currentUser => uid == null
      ? null
      : _FakeUser(uid: uid!, isAnonymous: isAnonymous, displayName: displayName);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser({
    required this.uid,
    required this.isAnonymous,
    this.displayName,
  });

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
}

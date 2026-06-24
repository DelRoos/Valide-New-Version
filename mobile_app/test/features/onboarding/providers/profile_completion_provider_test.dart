// Story 1.5 AC1 — Tests profileCompletionProvider (StreamProvider).
//
// 7 cas (a-g) couvrent les 5 etats ProfileCompletionState + fail-safe auth
// + fail-safe stream error.
//
// Pattern utilise : ProviderContainer + override des deps + container.listen
// pour declencher le build + Future delay pour laisser le stream emettre
// le 1er event + lecture synchrone container.read(provider).value.
//
// Pourquoi ce pattern et pas `container.read(provider.future)` : avec
// Stream.value(...) (sync), Riverpod 3.x peut ne pas resoudre .future
// proprement (bug observe en dev). Le pattern listen+delay est robuste
// et expose la valeur via AsyncValue.value une fois le stream emis.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:valide_school/core/firebase/providers.dart';
import 'package:valide_school/features/onboarding/domain/profile_completion_state.dart';
import 'package:valide_school/features/onboarding/domain/profile_failure.dart';
import 'package:valide_school/features/onboarding/domain/school.dart';
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
  Future<Either<ProfileFailure, void>> updatePickedSubjects(
    List<String> pickedSubjectIds,
  ) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateLinkedSchool(School? school) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updateDisplayName(String displayName) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, void>> updatePhoneNumber(String? phoneNumber) async =>
      const Right(null);

  @override
  Future<Either<ProfileFailure, Map<String, dynamic>?>> fetchProfileOnce() async =>
      Right(null);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this._uid);
  final String? _uid;
  @override
  User? get currentUser => _uid == null ? null : _FakeUser(_uid);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser(this._uid);
  final String _uid;
  @override
  String get uid => _uid;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _StubSubSystemNotifier extends SubSystemNotifier {
  _StubSubSystemNotifier(this._initial);
  final SubSystem? _initial;
  @override
  SubSystem? build() => _initial;
}

Future<ProfileCompletionState> _resolveCompletion({
  required SubSystem? initialSubSystem,
  required String? uid,
  required Stream<Map<String, dynamic>?> profileStream,
}) async {
  // Audit NEW-BUG-17 — profileCompletionProvider watch maintenant
  // currentUserProvider (StreamProvider). On override pour emettre un User
  // factice avec l'uid demande (ou null).
  final container = ProviderContainer(
    overrides: [
      subSystemNotifierProvider
          .overrideWith(() => _StubSubSystemNotifier(initialSubSystem)),
      firebaseAuthProvider.overrideWithValue(_FakeAuth(uid)),
      currentUserProvider.overrideWith(
        (ref) => Stream.value(uid == null ? null : _FakeUser(uid)),
      ),
      userProfileRepositoryProvider
          .overrideWithValue(_FakeRepo(profileStream)),
    ],
  );
  addTearDown(container.dispose);

  // Declenche le build (subscribe le stream).
  container.listen<AsyncValue<ProfileCompletionState>>(
    profileCompletionProvider,
    (_, _) {},
    fireImmediately: true,
  );

  // Laisse le stream emettre son 1er event.
  for (var i = 0; i < 50; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final async = container.read(profileCompletionProvider);
    if (async is AsyncData<ProfileCompletionState>) return async.value;
  }
  throw StateError(
    'profileCompletionProvider did not emit in 500ms '
    '(state: ${container.read(profileCompletionProvider)})',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('profileCompletionProvider — Story 1.5 AC1', () {
    test('(a) subSystem == null -> subsystemMissing', () async {
      final state = await _resolveCompletion(
        initialSubSystem: null,
        uid: 'alice',
        profileStream: const Stream.empty(),
      );
      expect(state, ProfileCompletionState.subsystemMissing);
    });

    test('(b) subSystem present + users/{uid} absent -> filiereMissing',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(null),
      );
      expect(state, ProfileCompletionState.filiereMissing);
    });

    test('(c) doc avec filiere vide -> filiereMissing', () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'filiere': '',
          'niveau': 'francophone_terminale',
          'serie': 'francophone_terminale_d',
        }),
      );
      expect(state, ProfileCompletionState.filiereMissing);
    });

    test('(d) doc avec filiere mais niveau null -> niveauMissing', () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'filiere': 'generale',
          'niveau': null,
          'serie': null,
        }),
      );
      expect(state, ProfileCompletionState.niveauMissing);
    });

    test('(e) doc avec filiere+niveau mais serie vide -> serieMissing',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'filiere': 'generale',
          'niveau': 'francophone_terminale',
          'serie': '',
        }),
      );
      expect(state, ProfileCompletionState.serieMissing);
    });

    test(
        '(f) doc avec tous champs non vides (serie sentinelle "-" OK) -> complete',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'filiere': 'generale',
          'niveau': 'francophone_6e',
          'serie': '-',
        }),
      );
      expect(state, ProfileCompletionState.complete);
    });

    test('(g) auth.currentUser == null -> filiereMissing (fail-safe)',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: null,
        profileStream: const Stream.empty(),
      );
      expect(state, ProfileCompletionState.filiereMissing);
    });

    test('bonus : serie nominale "francophone_terminale_d" -> complete',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'filiere': 'generale',
          'niveau': 'francophone_terminale',
          'serie': 'francophone_terminale_d',
        }),
      );
      expect(state, ProfileCompletionState.complete);
    });

    // =====================================================================
    // Audit 2026-06-13 (PR1) — Schema E1bis (trackId / levelId / pickedSubjects)
    // =====================================================================
    test(
        'E1bis : trackId + levelId + pickedSubjects non-vide -> complete',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'trackId': 'general',
          'levelId': 'francophone_terminale',
          'streamId': 'francophone_terminale_d',
          'pickedSubjects': ['math', 'physics'],
        }),
      );
      expect(state, ProfileCompletionState.complete);
    });

    test(
        'E1bis PR1 : trackId + levelId mais pickedSubjects vide -> serieMissing '
        '(fix flush partiel — evite redirect dashboard vide)',
        () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'trackId': 'general',
          'levelId': 'francophone_terminale',
          'streamId': 'francophone_terminale_d',
          'pickedSubjects': <String>[],
        }),
      );
      expect(state, ProfileCompletionState.serieMissing);
    });

    test('E1bis : trackId pose mais levelId vide -> niveauMissing', () async {
      final state = await _resolveCompletion(
        initialSubSystem: SubSystem.francophone,
        uid: 'alice',
        profileStream: Stream.value(<String, dynamic>{
          'trackId': 'general',
          'levelId': '',
        }),
      );
      expect(state, ProfileCompletionState.niveauMissing);
    });
  });
}

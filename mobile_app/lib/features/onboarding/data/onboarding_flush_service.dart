// Story E1bis-7 — Service qui ecrit le profil onboarding dans Firestore
// post-completion du flow (step 9). WriteBatch :
//   1. users/{uid} : set(merge: true) avec tous les champs E1bis schema
//      (trackId, levelId, streamId, pickedSubjects, phoneNumber, schoolId,
//      displayName, authProvider, isAnonymous, createdAt, updatedAt).
//   2. Pas de write school_requests ici : la demande d'ajout (si tapee)
//      est creee LIVE par SchoolSearchWithAdd via SchoolRepository au tap.
//
// Pattern fail-safe : si write echoue, retourne Left(OnboardingFlushFailure)
// — la SuccessCelebrationStepBody affiche un toast + retry.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/catalogue/domain/catalogue_repository.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_safe.dart';
import '../../../core/logging/perf_logger.dart';
import '../presentation/state/onboarding_state.dart';
import 'onboarding_draft_prefs.dart';

class OnboardingFlushFailure {
  const OnboardingFlushFailure(this.message, {this.code});
  final String message;
  final String? code;
}

class OnboardingFlushService {
  OnboardingFlushService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required OnboardingDraftPrefs draftPrefs,
    required CatalogueRepository catalogueRepository,
  })  : _auth = auth,
        _firestore = firestore,
        _draftPrefs = draftPrefs,
        _catalogueRepository = catalogueRepository;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final OnboardingDraftPrefs _draftPrefs;
  final CatalogueRepository _catalogueRepository;

  /// Flush l'etat onboarding dans Firestore. Idempotent grace au
  /// `set(merge: true)` (peut etre rejoue si echec partiel).
  ///
  /// Logs : avant ecriture, on dump la cle de chaque champ du payload pour
  /// diagnostiquer permission-denied (regle Firestore qui rejette un champ
  /// requis manquant). Le numero de telephone passe par `maskPhone()`
  /// (CLAUDE.md regle 4 securite).
  Future<Either<OnboardingFlushFailure, void>> flush(
      OnboardingState state) async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('flush: no current user (auth required)');
      return const Left(OnboardingFlushFailure('not-authenticated'));
    }
    final uid = user.uid;
    final uidShort = uid.length >= 6 ? '${uid.substring(0, 6)}...' : uid;

    // Audit BUG-02 2026-06-13 : en mode derive (levelRequiresPicker=false),
    // le user saute step 4 -> state.pickedSubjects reste []. Le flush ecrirait
    // pickedSubjects=[] -> profileCompletionProvider retournerait serieMissing
    // -> redirect /onboarding/v2 -> boucle. Fix : auto-populer pickedSubjects
    // via derive() AVANT le flush si mode derive + liste vide.
    final effectiveState = await _autoPopulateDerivedSubjects(state);

    try {
      final docRef = _firestore.collection('users').doc(uid);

      // Fix runtime 2026-06-13 : verifier l'existence AVANT d'inclure
      // `createdAt` dans le payload. La regle UPDATE exige `createdAt`
      // immuable — un set(merge: true) qui ecrit serverTimestamp() a chaque
      // flush ferait toujours echouer la regle (nouvelle timestamp != stockee).
      var existing = await docRef.get();
      var isCreate = !existing.exists;

      // Audit 2026-06-13 (cursus mismatch) — Si le doc existe DEJA et que
      // l'utilisateur a change un champ immutable (subSystem/trackId/levelId/
      // streamId) entre l'ancien doc et le nouveau state, la rule UPDATE
      // refuse (immutabilite). Pour un visiteur (isAnonymous=true), c'est
      // legitime : il refait son onboarding avec un autre cursus. On supprime
      // l'ancien doc puis on cree fresh.
      //
      // Pour un compte permanent, on garde la rule stricte : l'utilisateur
      // ne doit pas pouvoir changer son cursus en silence (necessite UX
      // explicite "modifier mon profil" future).
      if (existing.exists && user.isAnonymous) {
        final existingData = existing.data() ?? <String, dynamic>{};
        final mismatch = _hasCursusMismatch(existingData, effectiveState);
        if (mismatch) {
          AppLogger.i(
            'flush cursus mismatch detected (visitor) — delete + recreate '
            'old=(subSystem=${existingData['subSystem']}, '
            'trackId=${existingData['trackId']}, '
            'levelId=${existingData['levelId']}) '
            'new=(subSystem=${effectiveState.subSystem?.id}, '
            'trackId=${effectiveState.trackId}, '
            'levelId=${effectiveState.levelId})',
          );
          await docRef.delete();
          existing = await docRef.get();
          isCreate = true;
        }
      }

      final payload = <String, dynamic>{
        'uid': uid,
        ...effectiveState.toFirestorePayload(isCreate: isCreate),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      // language derive du subSystem — inclus seulement si subSystem connu.
      // Si null (upgrade depuis dashboard apres restart), on ne l'ecrase pas
      // (le doc Firestore a deja la bonne valeur depuis le flush guest).
      if (effectiveState.subSystem != null) {
        payload['language'] = effectiveState.subSystem!.languageCode;
      }
      if (isCreate) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      AppLogger.i(
        'flush START uid=$uidShort '
        'isAuthUser=${!user.isAnonymous} firebaseAnonymous=${user.isAnonymous} '
        'docExists=${!isCreate} -> ${isCreate ? "CREATE" : "UPDATE"}',
      );
      AppLogger.i(
        'flush PAYLOAD '
        'subSystem=${payload['subSystem']} '
        'language=${payload['language']} '
        'trackId=${payload['trackId']} '
        'levelId=${payload['levelId']} '
        'streamId=${payload['streamId'] ?? "<null>"} '
        'pickedSubjects=${(payload['pickedSubjects'] as List).length} items '
        'displayName=${maskName(payload['displayName'] as String?)} '
        'phoneNumber=${maskPhone(payload['phoneNumber'] as String?)} '
        'schoolId=${payload['schoolId'] ?? "<null>"} '
        'schoolName=${payload['schoolName'] ?? "<null>"} '
        'pendingSchoolRequestId=${payload['pendingSchoolRequestId'] ?? "<null>"} '
        'authProvider=${payload['authProvider'] ?? "<null>"} '
        'isAnonymous=${payload['isAnonymous']}',
      );
      AppLogger.i(
        'flush MISSING_FIELDS_CHECK '
        'subSystem=${payload.containsKey('subSystem')} '
        'language=${payload.containsKey('language')} '
        'trackId=${payload.containsKey('trackId')} '
        'levelId=${payload.containsKey('levelId')} '
        'pickedSubjects=${payload.containsKey('pickedSubjects')} '
        'displayName=${payload.containsKey('displayName')} '
        'authProvider=${payload.containsKey('authProvider')} '
        'isAnonymous=${payload.containsKey('isAnonymous')}',
      );

      await logPerf(
        'onboarding.flush.users',
        () => _firestore
            .collection('users')
            .doc(uid)
            .set(payload, SetOptions(merge: true)),
      );

      AppLogger.i(
        'flush OK uid=$uidShort '
        'authProvider=${effectiveState.authProvider?.id} '
        'isAnonymous=${effectiveState.isVisitor} '
        'trackId=${effectiveState.trackId} levelId=${effectiveState.levelId} '
        'streamId=${effectiveState.streamId ?? "-"} '
        'subjects=${effectiveState.pickedSubjects.length} '
        'phone=${maskPhone(effectiveState.phoneNumber)} '
        'schoolSet=${effectiveState.schoolId != null || effectiveState.pendingSchoolRequestId != null}',
      );
      // Audit 2026-06-13 (PR1) — Apres flush success, le doc users/{uid}
      // est source de verite : on clear le draft persiste pour eviter
      // que loadFromPersistence le restaure au prochain boot.
      try {
        await _draftPrefs.clear();
      } catch (e) {
        AppLogger.w('flush draft clear failed (non-blocking): $e');
      }
      return const Right(null);
    } on FirebaseException catch (e, st) {
      AppLogger.w(
        'flush Firebase error code=${e.code} '
        'message="${e.message}" plugin=${e.plugin} uid=$uidShort',
        error: e,
      );
      AppLogger.w('flush stack: $st');
      return Left(
        OnboardingFlushFailure(e.message ?? 'firebase-error', code: e.code),
      );
    } catch (e, st) {
      AppLogger.w('flush unexpected: $e uid=$uidShort', error: e);
      AppLogger.w('flush stack: $st');
      return Left(OnboardingFlushFailure(e.toString()));
    }
  }

  /// Audit BUG-02 — Si l'utilisateur a choisi un niveau en mode `derived`
  /// (ex. 6e francophone, Form 2 anglophone), `state.pickedSubjects` reste
  /// `[]` car step 4 est skippe et aucun picker ne collecte les matieres.
  /// Avant ce fix, le doc users/{uid} etait ecrit avec pickedSubjects=[] et
  /// profileCompletionProvider retournait serieMissing -> redirect onboarding
  /// boucle.
  ///
  /// Ici on appelle `derive()` pour resoudre les matieres dynamiquement et
  /// les inclure dans le payload. Si derive() echoue (catalogue desync,
  /// reseau coupe), on flush quand meme avec la liste vide — le user pourra
  /// completer plus tard et le router renverra eventuellement vers
  /// onboarding (comportement "soft", pas de blocage du flush).
  Future<OnboardingState> _autoPopulateDerivedSubjects(
    OnboardingState state,
  ) async {
    final shouldAutoPopulate = !state.levelRequiresPicker &&
        state.pickedSubjects.isEmpty &&
        state.subSystem != null &&
        state.trackId != null &&
        state.levelId != null;
    if (!shouldAutoPopulate) return state;

    AppLogger.i(
      'flush auto-populate derived subjects '
      'trackId=${state.trackId} levelId=${state.levelId}',
    );
    try {
      final result = await _catalogueRepository.derive(
        subSystem: state.subSystem!.id,
        filiere: state.trackId!,
        niveau: state.levelId!,
        serie: state.streamId,
      );
      return result.fold(
        (failure) {
          AppLogger.w(
            'flush auto-populate failed: ${failure.runtimeType} '
            '-> proceed with empty pickedSubjects',
          );
          return state;
        },
        (profile) {
          final ids = profile.subjects
              .map((s) => s.subjectId)
              .toList(growable: false);
          AppLogger.i(
            'flush auto-populate OK ${ids.length} subjects',
          );
          return state.copyWith(pickedSubjects: ids);
        },
      );
    } catch (e) {
      AppLogger.w('flush auto-populate threw: $e -> proceed empty');
      return state;
    }
  }

  /// Audit 2026-06-13 — Detecte un mismatch entre l'ancien doc Firestore et
  /// le nouveau state E1bis sur les champs immutables (subSystem / trackId /
  /// levelId / streamId). Utilise par [flush] pour decider si un delete +
  /// recreate est necessaire (visiteur uniquement).
  ///
  /// Compare les valeurs en gerant le schema legacy (filiere/niveau/serie)
  /// comme equivalentes aux nouveaux champs.
  bool _hasCursusMismatch(
    Map<String, dynamic> existingData,
    OnboardingState state,
  ) {
    final existingSubSystem = existingData['subSystem'] as String?;
    if (existingSubSystem != null &&
        state.subSystem != null &&
        existingSubSystem != state.subSystem!.id) {
      return true;
    }
    final existingTrack =
        (existingData['trackId'] ?? existingData['filiere']) as String?;
    if (existingTrack != null &&
        state.trackId != null &&
        existingTrack != state.trackId) {
      return true;
    }
    final existingLevel =
        (existingData['levelId'] ?? existingData['niveau']) as String?;
    if (existingLevel != null &&
        state.levelId != null &&
        existingLevel != state.levelId) {
      return true;
    }
    final existingStream =
        (existingData['streamId'] ?? existingData['serie']) as String?;
    if (existingStream != null &&
        state.streamId != null &&
        existingStream != state.streamId) {
      return true;
    }
    return false;
  }
}

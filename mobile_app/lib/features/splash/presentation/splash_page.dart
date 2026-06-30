// Story 0.22 — SplashPage Flutter animee post-natif.
//
// Sequence au lancement de l'app :
//   1. Splash natif (instantane, fond AppColors.primary, logo centre statique)
//      -> declenche par flutter_native_splash via main.dart preserve().
//         Limitation Android < 12 + iOS : aucune animation possible avant
//         que Flutter charge — c'est juste un drawable XML statique.
//   2. SplashPage Flutter (ce fichier, ~2100 ms)
//      -> declenche le FlutterNativeSplash.remove() au 1er postFrame
//      -> animation "mot VALIDE qui se dessine au trait" :
//         * un trait blanc se trace de gauche a droite sous le mot
//         * chaque lettre apparait progressivement quand la pointe du
//           trait passe au-dessous d'elle
//         * un point "stylo" suit la pointe pour la sensation d'ecriture
//      -> apres le trace + 300 ms de hold, navigate vers /hello
//   3. /hello (sentinelle Story 0.21, deviendra /onboarding apres Story 1.5)
//
// Choix design (verdict 2026-06-05, Story 0.22 AC4-AC5) :
//   - L'animation N'EST PAS liee au logo (le logo image n'est pas affiche
//     dans cette SplashPage — il est deja vu sur le splash natif).
//   - L'animation est natif Flutter pur (CustomPainter + AnimationController).
//     Zero asset .riv/.json, zero package supplementaire. Coherent contrainte
//     data-light Cameroun.
//   - Re-evaluer Rive/Lottie en story polish future si un motion designer
//     rejoint l'equipe.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/catalogue/providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/firebase/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../onboarding/domain/profile_completion_state.dart';
import '../../onboarding/domain/sub_system.dart';
import '../../onboarding/providers.dart';

const Duration _kStrokeDuration = Duration(milliseconds: 1800);
const Duration _kHoldAfterStroke = Duration(milliseconds: 300);
const String _kWord = 'VALIDE';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _strokeProgress;
  Timer? _navigationTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kStrokeDuration);
    _strokeProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _controller.forward();
      // Audit 2026-06-13 — Precharger le catalogue scolaire en arriere-plan
      // pendant l'animation splash (~2,1s). Sur connexion correcte le fetch
      // est termine avant l'arrivee step 2/3/4 -> les loaders sont
      // invisibles. Si reseau lent, le loader sera affiche normalement.
      // `ref.read(provider.future)` declenche le build sans bloquer la nav.
      unawaited(_warmUpCatalogue());
    });

    _navigationTimer = Timer(_kStrokeDuration + _kHoldAfterStroke, _goNext);
  }

  Future<void> _warmUpCatalogue() async {
    // Audit 2026-06-14 — Capturer le ProviderContainer AVANT les awaits :
    // le splash navigue apres 2.1s (kStrokeDuration + kHoldAfterStroke) mais
    // Firebase init prend ~2.9s sur device entree de gamme. L'await sur
    // `firebaseReadyProvider.future` resout donc APRES que le splash soit
    // unmounted -> `ref.read(...)` post-unmount throw
    // `Using "ref" when a widget is about to or has been unmounted is unsafe`.
    // Le container vit pour toute la duree de l'app -> safe a utiliser
    // depuis n'importe quelle Future, meme post-unmount.
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      // Attendre que Firebase soit initialise AVANT de toucher au catalogue.
      // Sans ce gate, `firestoreProvider` throw `[core/no-app]` car
      // `_bootstrap()` tourne en parallele de runApp (~2.9s) et n'a pas fini
      // quand SplashPage mount. Le warm-up echouait donc systematiquement,
      // perdant tout l'interet UX du precharge (PR #138).
      final firebaseReady = await container.read(firebaseReadyProvider.future);
      if (!firebaseReady) {
        AppLogger.w('splash warm-up skipped: Firebase unavailable');
        return;
      }
      // Catalogue + synchro subSystem en parallele pour rester dans la fenetre
      // d'animation (~2.1s). Sur connexion correcte les deux terminent avant
      // que _goNext() soit appele -> pas de flash.
      await Future.wait([
        container.read(catalogueProvider.future),
        _syncSubSystemFromFirestore(container),
      ]);
      AppLogger.i('splash warm-up OK');
    } catch (e) {
      AppLogger.w('splash warm-up failed (non-blocking): $e');
    }
  }

  /// Synchro boot du sous-système depuis Firestore.
  ///
  /// Firestore est la source de vérité pour les utilisateurs existants :
  /// sur un nouveau téléphone ou si SharedPreferences est stale (backup
  /// cloud Android/iOS), la valeur locale peut être incorrecte.
  /// Cette méthode corrige le subSystem AVANT la navigation du splash
  /// -> profileCompletionProvider émet le bon état -> router va direct
  /// au dashboard sans passer par l'onboarding.
  ///
  /// Ne lance jamais d'exception (non-bloquant par design).
  Future<void> _syncSubSystemFromFirestore(ProviderContainer container) async {
    try {
      final uid = container.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return; // Pas de session active.
      final result = await container
          .read(userProfileRepositoryProvider)
          .fetchProfileOnce();
      result.fold(
        (f) => AppLogger.w('bootSync subSystem: ${f.kind.name}'),
        (data) async {
          final sub = SubSystem.fromString(data?['subSystem'] as String?);
          if (sub == null) return; // Champ absent (doc ancien ou profil vide).
          final current = container.read(subSystemNotifierProvider);
          if (current == sub) return; // Déjà correct, pas d'écriture inutile.
          AppLogger.i(
            'bootSync: subSystem Firestore=${sub.id} '
            'override local=${current?.id ?? "<null>"}',
          );
          await container.read(subSystemNotifierProvider.notifier).set(sub);
        },
      );
    } catch (e) {
      AppLogger.w('bootSync subSystem error (non-blocking): $e');
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    // Audit PR4 2026-06-13 — Direct redirect : avant ce PR, le splash
    // tapait toujours /dashboard puis le router redirigeait /onboarding
    // si profil incomplet -> 3 frames de transition (splash -> dashboard
    // -> onboarding) avec flicker visible. Maintenant on lit l'etat de
    // completion ICI pour viser direct la bonne route.
    final completion = ref.read(profileCompletionProvider);
    final isComplete = completion.maybeWhen(
      data: (s) => s == ProfileCompletionState.complete,
      orElse: () => false,
    );
    context.go(isComplete ? AppRoutes.dashboard : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _strokeProgress,
        builder: (context, child) {
          return CustomPaint(
            painter: _StrokeWordPainter(
              progress: _strokeProgress.value,
              word: _kWord,
              color: Colors.white,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Painter du mot qui se dessine au trait.
///
/// Trace un trait horizontal blanc qui avance de gauche a droite sous le
/// mot. Chaque lettre du mot devient progressivement opaque quand la pointe
/// du trait depasse son centre horizontal. Un point ("pointe du stylo") suit
/// la pointe pour renforcer la sensation d'ecriture.
class _StrokeWordPainter extends CustomPainter {
  _StrokeWordPainter({
    required this.progress,
    required this.word,
    required this.color,
  });

  final double progress;
  final String word;
  final Color color;

  static const double _letterRevealWindow = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = size.shortestSide * 0.18;
    final centerY = size.height / 2;

    // Pre-mesurer chaque lettre pour layout precis (les glyphes Nunito Sans
    // ont des largeurs differentes — V plus large que I, etc).
    final letterPainters = <TextPainter>[];
    for (final ch in word.characters) {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      letterPainters.add(tp);
    }

    const letterGap = 12.0;
    final wordWidth = letterPainters.fold<double>(
          0,
          (acc, tp) => acc + tp.width,
        ) +
        letterGap * (letterPainters.length - 1);
    final wordStartX = (size.width - wordWidth) / 2;
    final wordEndX = wordStartX + wordWidth;

    final penY = centerY + fontSize * 0.6;
    final penX = wordStartX + (wordEndX - wordStartX) * progress;

    // Pre-trait : ligne discrete (faible opacite) du debut a la fin du mot,
    // visualise le "papier reglee" pour orienter l'oeil.
    final guidePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(wordStartX, penY),
      Offset(wordEndX, penY),
      guidePaint,
    );

    // Trait dessine en cours : du debut a la pointe du stylo, opacite forte.
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    if (progress > 0) {
      canvas.drawLine(
        Offset(wordStartX, penY),
        Offset(penX, penY),
        strokePaint,
      );
    }

    // Dessiner chaque lettre avec opacite progressive : la lettre commence a
    // apparaitre quand la pointe atteint son bord gauche, devient totalement
    // opaque sur une fenetre de 18% du trace global.
    double cursorX = wordStartX;
    for (var i = 0; i < letterPainters.length; i++) {
      final tp = letterPainters[i];
      final letterCenterX = cursorX + tp.width / 2;
      final letterCenterProgress = (letterCenterX - wordStartX) / wordWidth;

      final delta = progress - letterCenterProgress;
      final letterOpacity =
          (delta / _letterRevealWindow).clamp(0.0, 1.0).toDouble();

      if (letterOpacity > 0) {
        final letterTp = TextPainter(
          text: TextSpan(
            text: tp.text!.toPlainText(),
            style: TextStyle(
              color: color.withValues(alpha: letterOpacity),
              fontSize: fontSize,
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        letterTp.paint(
          canvas,
          Offset(cursorX, centerY - letterTp.height / 2),
        );
      }

      cursorX += tp.width + letterGap;
    }

    // Pointe du stylo : petit cercle plein qui suit la pointe pendant le
    // trace, disparait une fois le mot complet.
    if (progress > 0 && progress < 1) {
      final tipPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(penX, penY), 5.0, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokeWordPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.word != word ||
        oldDelegate.color != color;
  }
}

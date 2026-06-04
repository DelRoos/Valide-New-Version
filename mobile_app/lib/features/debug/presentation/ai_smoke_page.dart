import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/firebase/providers.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_inline_alert.dart';
import '../../../core/widgets/app_spinner.dart';

/// Route debug `/_ai_smoke` — Story 0.6 AC6 (Firebase AI Logic smoke).
/// 2 smoke tests : sync `generateContent` + streaming `generateContentStream`.
/// Cette route disparaît à la clôture E0 (Story 0.21, conservée comme
/// sentinelle de régression possible).
class AISmokePage extends ConsumerStatefulWidget {
  const AISmokePage({super.key});

  @override
  ConsumerState<AISmokePage> createState() => _AISmokePageState();
}

class _AISmokePageState extends ConsumerState<AISmokePage> {
  String _syncOutput = '';
  String _streamOutput = '';
  bool _syncLoading = false;
  bool _streamLoading = false;
  String? _error;

  Future<void> _runSync() async {
    setState(() {
      _syncLoading = true;
      _error = null;
      _syncOutput = '';
    });
    final sw = Stopwatch()..start();
    try {
      final model = ref.read(firebaseAIProvider);
      final response = await model.generateContent([Content.text('Bonjour')]);
      sw.stop();
      setState(() {
        _syncOutput = response.text ?? '(réponse vide)';
        _syncLoading = false;
      });
      AppLogger.i('AI Logic sync smoke: latency=${sw.elapsedMilliseconds}ms');
    } catch (e, st) {
      sw.stop();
      setState(() {
        _error = e.toString();
        _syncLoading = false;
      });
      AppLogger.e('AI Logic sync smoke failed', error: e, stackTrace: st);
    }
  }

  Future<void> _runStream() async {
    setState(() {
      _streamLoading = true;
      _error = null;
      _streamOutput = '';
    });
    final sw = Stopwatch()..start();
    try {
      final model = ref.read(firebaseAIProvider);
      final stream =
          model.generateContentStream([Content.text('Compte de 1 à 5.')]);
      await for (final chunk in stream) {
        setState(() {
          _streamOutput += chunk.text ?? '';
        });
      }
      sw.stop();
      setState(() => _streamLoading = false);
      AppLogger.i(
        'AI Logic stream smoke: latency=${sw.elapsedMilliseconds}ms '
        'chunks_total_len=${_streamOutput.length}',
      );
    } catch (e, st) {
      sw.stop();
      setState(() {
        _error = e.toString();
        _streamLoading = false;
      });
      AppLogger.e('AI Logic stream smoke failed', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('AI Logic smoke (debug)')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.s5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Story 0.6 AC6 — Firebase AI Logic (Gemini Developer API).',
                style: AppTypography.h3),
            SizedBox(height: AppSpacing.s4.h),
            if (_error != null) ...[
              AppInlineAlert(
                tone: AlertTone.error,
                title: 'Erreur',
                message: _error!,
              ),
              SizedBox(height: AppSpacing.s4.h),
            ],
            Text('Test 1 : `generateContent` (sync)',
                style: AppTypography.bodyStrong),
            SizedBox(height: AppSpacing.s2.h),
            AppButton.primary(
              label: 'Lancer le test sync',
              onPressed: _syncLoading ? null : _runSync,
              loading: _syncLoading,
            ),
            if (_syncOutput.isNotEmpty) ...[
              SizedBox(height: AppSpacing.s3.h),
              Container(
                padding: EdgeInsets.all(AppSpacing.s4.w),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child:
                    Text(_syncOutput, style: AppTypography.body),
              ),
            ],
            SizedBox(height: AppSpacing.s6.h),
            Text('Test 2 : `generateContentStream`',
                style: AppTypography.bodyStrong),
            SizedBox(height: AppSpacing.s2.h),
            AppButton.secondary(
              label: 'Lancer le test stream',
              onPressed: _streamLoading ? null : _runStream,
            ),
            if (_streamLoading)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.s3.h),
                child: const Center(child: AppSpinner()),
              ),
            if (_streamOutput.isNotEmpty) ...[
              SizedBox(height: AppSpacing.s3.h),
              Container(
                padding: EdgeInsets.all(AppSpacing.s4.w),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child:
                    Text(_streamOutput, style: AppTypography.body),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

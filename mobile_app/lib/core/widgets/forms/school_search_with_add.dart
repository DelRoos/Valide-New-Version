import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/tokens.dart';
import '../app_inline_alert.dart';
import '../cards/selection_card.dart';
import '../pressable.dart';
import 'school_entry.dart';

/// Etat asynchrone des suggestions d'ecoles.
///
/// Sealed-like via factories nommees. Equivalent simplifie de
/// `AsyncValue<List<SchoolEntry>>` sans dependance Riverpod (le composant
/// reste neutre — caller fournit la source de donnees).
sealed class SchoolSearchAsync {
  const SchoolSearchAsync();

  factory SchoolSearchAsync.idle() = SchoolSearchIdle;
  factory SchoolSearchAsync.loading() = SchoolSearchLoading;
  factory SchoolSearchAsync.data(List<SchoolEntry> results) = SchoolSearchData;
  factory SchoolSearchAsync.error({required bool isNetwork}) =
      SchoolSearchError;
}

class SchoolSearchIdle extends SchoolSearchAsync {
  const SchoolSearchIdle();
}

class SchoolSearchLoading extends SchoolSearchAsync {
  const SchoolSearchLoading();
}

class SchoolSearchData extends SchoolSearchAsync {
  const SchoolSearchData(this.results);
  final List<SchoolEntry> results;
}

class SchoolSearchError extends SchoolSearchAsync {
  const SchoolSearchError({required this.isNetwork});
  final bool isNetwork;
}

/// Recherche d'ecole avec ajout custom — pattern reutilise par step 8
/// onboarding (E1bis-6) et profil edition future.
///
/// API :
/// * [selectedSchool] : ecole actuellement choisie (peut etre null ou pending).
/// * [onSelect] : appele quand l'utilisateur tape un resultat.
/// * [onAddRequest] : appele quand l'utilisateur valide « + Ajouter ... ».
///   Doit retourner un `Future<String>` qui resout sur l'ID de la demande
///   pending (`school_requests/{autoId}`).
/// * [searchProvider] : source des suggestions. Recoit le terme courant et
///   retourne un [SchoolSearchAsync] (data/loading/error/idle).
/// * [placeholder] : texte d'aide du champ recherche (localisable par caller).
/// * [emptyAddTemplate] : template du libelle `+ Ajouter "saisie"`.
///   Le composant remplace `{name}` par la saisie courante.
/// * [warningOfflineMessage] : texte du bandeau erreur reseau (localisable).
///
/// Comportement :
/// * Debounce 250 ms sur la saisie avant declenchement [searchProvider].
/// * Si zero resultat + saisie non-vide -> carte « + Ajouter ... » (dashed).
/// * Si error reseau -> bandeau warning + bouton « + Ajouter ... » dispo.
class SchoolSearchWithAdd extends StatefulWidget {
  const SchoolSearchWithAdd({
    super.key,
    required this.selectedSchool,
    required this.onSelect,
    required this.onAddRequest,
    required this.searchProvider,
    required this.placeholder,
    required this.emptyAddTemplate,
    required this.warningOfflineMessage,
  });

  final SchoolEntry? selectedSchool;
  final void Function(SchoolEntry school) onSelect;
  final Future<String> Function(String name) onAddRequest;
  final SchoolSearchAsync Function(String query) searchProvider;
  final String placeholder;

  /// Template `« + Ajouter "{name}" »`. `{name}` est remplace par la saisie.
  final String emptyAddTemplate;
  final String warningOfflineMessage;

  @override
  State<SchoolSearchWithAdd> createState() => _SchoolSearchWithAddState();
}

class _SchoolSearchWithAddState extends State<SchoolSearchWithAdd> {
  late final TextEditingController _controller;
  String _query = '';
  Timer? _debounce;
  bool _addInProgress = false;

  static const Duration _debounceDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedSchool?.name ?? '');
    _query = _controller.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) return;
      setState(() => _query = text);
    });
  }

  Future<void> _onAddTap() async {
    if (_addInProgress || _query.trim().isEmpty) return;
    setState(() => _addInProgress = true);
    try {
      final id = await widget.onAddRequest(_query.trim());
      widget.onSelect(
        SchoolEntry(id: id, name: _query.trim(), isPending: true),
      );
    } finally {
      if (mounted) setState(() => _addInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncResult = _query.trim().isEmpty
        ? const SchoolSearchIdle()
        : widget.searchProvider(_query.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchField(
          controller: _controller,
          placeholder: widget.placeholder,
          onChanged: _onInputChanged,
        ),
        SizedBox(height: AppSpacing.s4.h),
        _Results(
          query: _query.trim(),
          asyncResult: asyncResult,
          selected: widget.selectedSchool,
          onSelect: widget.onSelect,
          emptyAddTemplate: widget.emptyAddTemplate,
          warningOfflineMessage: widget.warningOfflineMessage,
          addInProgress: _addInProgress,
          onAddTap: _onAddTap,
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.s4.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: AppElevation.soft,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, color: AppColors.mute2, size: 22.sp),
          SizedBox(width: AppSpacing.s3.w),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              inputFormatters: [
                LengthLimitingTextInputFormatter(80),
              ],
              style: AppTypography.body.copyWith(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.mute2,
                  fontSize: 16.sp,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isCollapsed: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            _ClearButton(controller: controller, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        controller.clear();
        onChanged('');
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      hapticPreset: HapticPreset.selection,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s2.w),
        child: Icon(
          LucideIcons.circleX,
          color: AppColors.mute2,
          size: 22.sp,
        ),
      ),
    );
  }
}

/// Bloc resultats : 4 etats (idle / loading / data / error).
class _Results extends StatelessWidget {
  const _Results({
    required this.query,
    required this.asyncResult,
    required this.selected,
    required this.onSelect,
    required this.emptyAddTemplate,
    required this.warningOfflineMessage,
    required this.addInProgress,
    required this.onAddTap,
  });

  final String query;
  final SchoolSearchAsync asyncResult;
  final SchoolEntry? selected;
  final void Function(SchoolEntry school) onSelect;
  final String emptyAddTemplate;
  final String warningOfflineMessage;
  final bool addInProgress;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return switch (asyncResult) {
      SchoolSearchIdle() => const SizedBox.shrink(),
      SchoolSearchLoading() => Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.s4.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      SchoolSearchData(:final results) => results.isEmpty
          ? _AddCard(
              query: query,
              template: emptyAddTemplate,
              isLoading: addInProgress,
              onTap: onAddTap,
            )
          : _ResultsList(
              results: results,
              selected: selected,
              onSelect: onSelect,
            ),
      SchoolSearchError(:final isNetwork) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInlineAlert(
              tone: AlertTone.warning,
              message: isNetwork
                  ? warningOfflineMessage
                  : warningOfflineMessage,
            ),
            SizedBox(height: AppSpacing.s4.h),
            _AddCard(
              query: query,
              template: emptyAddTemplate,
              isLoading: addInProgress,
              onTap: onAddTap,
            ),
          ],
        ),
    };
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.selected,
    required this.onSelect,
  });

  final List<SchoolEntry> results;
  final SchoolEntry? selected;
  final void Function(SchoolEntry school) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in results) ...[
          SelectionCard(
            title: entry.name,
            selected: selected?.id == entry.id,
            onTap: () => onSelect(entry),
            icon: const Icon(LucideIcons.school),
            variant: SelectionCardVariant.standard,
          ),
          SizedBox(height: AppSpacing.s2.h),
        ],
      ],
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.query,
    required this.template,
    required this.isLoading,
    required this.onTap,
  });

  final String query;
  final String template;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = template.replaceFirst('{name}', query);
    final radius = BorderRadius.circular(AppRadius.xl2);
    return Pressable(
      onTap: isLoading ? null : onTap,
      borderRadius: radius,
      hapticPreset: HapticPreset.light,
      child: DottedBorderBox(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.s5.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.primary,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 22.sp,
                  height: 22.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              else
                Icon(LucideIcons.plus, color: AppColors.primary, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}

/// Container avec bordure en pointilles dessinee via CustomPaint.
/// Flutter n'a pas de `Border.dashed` natif.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    // Dash pattern : 6 px on / 4 px off via Path metrics.
    final path = Path()..addRRect(rrect);
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

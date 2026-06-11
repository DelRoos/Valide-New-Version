// Modale "Ajouter mon ecole" (Story 1.5.c — flow demande d'ajout d'ecole).
//
// 4 champs : nom (obligatoire), ville (obligatoire), region (optionnel),
// subSystem (radio Francophone / Anglophone / Both / Je ne sais pas).
// Returns AddSchoolFormData via Navigator.pop ou null si annule.
//
// Extrait de school_picker_page.dart en juin 2026 (CLAUDE.md regle 12).

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Donnees retournees par AddSchoolDialog quand l'utilisateur soumet.
class AddSchoolFormData {
  const AddSchoolFormData({
    required this.name,
    required this.city,
    this.region,
    this.subSystem,
  });
  final String name;
  final String city;
  final String? region;

  /// Story 1.5.c — `francophone` | `anglophone` | `both` | `null` (utilisateur
  /// a choisi « Je ne sais pas »).
  final String? subSystem;
}

/// Story 1.5.c — 4 choix UI pour le champ subSystem. `null` = « Je ne sais
/// pas » (defaut). Les 3 autres valeurs matchent le schema Firestore.
enum _SubSystemChoice { unknown, francophone, anglophone, both }

class AddSchoolDialog extends StatefulWidget {
  const AddSchoolDialog({super.key});

  @override
  State<AddSchoolDialog> createState() => _AddSchoolDialogState();
}

class _AddSchoolDialogState extends State<AddSchoolDialog> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  _SubSystemChoice _subSystem = _SubSystemChoice.unknown;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty && _cityCtrl.text.trim().isNotEmpty;

  String? _subSystemValue() {
    switch (_subSystem) {
      case _SubSystemChoice.unknown:
        return null;
      case _SubSystemChoice.francophone:
        return 'francophone';
      case _SubSystemChoice.anglophone:
        return 'anglophone';
      case _SubSystemChoice.both:
        return 'both';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.onboardingSchoolAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.onboardingSchoolAddDialogNameLabel,
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _cityCtrl,
              decoration: InputDecoration(
                labelText: l10n.onboardingSchoolAddDialogCityLabel,
              ),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _regionCtrl,
              decoration: InputDecoration(
                labelText: l10n.onboardingSchoolAddDialogRegionLabel,
              ),
            ),
            SizedBox(height: AppSpacing.s3.h),
            Text(
              l10n.onboardingSchoolAddDialogSubSystemLabel,
              style: AppTypography.bodyStrong,
            ),
            RadioGroup<_SubSystemChoice>(
              groupValue: _subSystem,
              onChanged: (v) => setState(() => _subSystem = v!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<_SubSystemChoice>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.onboardingSchoolAddDialogSubSystemFrancophone,
                    ),
                    value: _SubSystemChoice.francophone,
                  ),
                  RadioListTile<_SubSystemChoice>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.onboardingSchoolAddDialogSubSystemAnglophone,
                    ),
                    value: _SubSystemChoice.anglophone,
                  ),
                  RadioListTile<_SubSystemChoice>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.onboardingSchoolAddDialogSubSystemBoth,
                    ),
                    value: _SubSystemChoice.both,
                  ),
                  RadioListTile<_SubSystemChoice>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.onboardingSchoolAddDialogSubSystemUnknown,
                    ),
                    value: _SubSystemChoice.unknown,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.back),
        ),
        ElevatedButton(
          onPressed: _canSubmit
              ? () {
                  final regionInput = _regionCtrl.text.trim();
                  Navigator.of(context).pop(
                    AddSchoolFormData(
                      name: _nameCtrl.text.trim(),
                      city: _cityCtrl.text.trim(),
                      region: regionInput.isEmpty ? null : regionInput,
                      subSystem: _subSystemValue(),
                    ),
                  );
                }
              : null,
          child: Text(l10n.onboardingSchoolAddDialogSubmitCta),
        ),
      ],
    );
  }
}

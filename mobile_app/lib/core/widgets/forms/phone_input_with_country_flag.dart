import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../logging/log_safe.dart';
import '../../theme/tokens.dart';

/// Champ de saisie telephone +237 (Cameroun) avec drapeau CM dessine.
///
/// API (Story E1bis-0 AC3) :
/// * [value] : valeur courante au format E.164 (`+237XXXXXXXXX`) ou vide.
/// * [onChanged] : callback emis a chaque modification, valeur au format E.164.
/// * [errorText] : message d'erreur affiche sous le champ (gere par caller).
/// * [enabled] : desactivation (opacity 0.5 + clavier non focus).
/// * [autofocus] : focus automatique au render.
///
/// Comportement non negociable (CLAUDE.md regle 4 securite) :
/// * Le composant **n'expose AUCUN log AppLogger** — il n'a aucune dependance
///   sur `package:logger`. Tout caller qui veut logguer le numero passe par
///   [maskPhone] (helper public dans `log_safe.dart`) OU via la methode
///   statique [PhoneInputWithCountryFlag.maskedForLogs] qui delegue au meme
///   helper (zero duplication d'algorithme).
/// * Validation regex `^\+237[26][0-9]{8}$` (mobile 6, fixe 2, 9 chiffres).
///
/// Le composant n'effectue PAS la validation lui-meme (responsabilite du
/// caller) — il accepte des saisies partielles et propage la valeur en E.164
/// au callback. Le caller decide quand afficher `errorText`.
class PhoneInputWithCountryFlag extends StatefulWidget {
  const PhoneInputWithCountryFlag({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  /// Helper statique pour formater un numero E.164 pour les logs.
  /// Delegue a [maskPhone] (helper canonical) — pas de duplication.
  static String maskedForLogs(String? e164) => maskPhone(e164);

  @override
  State<PhoneInputWithCountryFlag> createState() =>
      _PhoneInputWithCountryFlagState();
}

class _PhoneInputWithCountryFlagState extends State<PhoneInputWithCountryFlag> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _localFromE164(widget.value));
  }

  @override
  void didUpdateWidget(PhoneInputWithCountryFlag oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLocal = _localFromE164(widget.value);
    if (_controller.text != newLocal) _controller.text = newLocal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Convertit la valeur E.164 vers la partie locale visible (sans `+237`).
  String _localFromE164(String e164) {
    if (e164.startsWith('+237')) return e164.substring(4);
    return e164;
  }

  void _onLocalChanged(String local) {
    // On propage en E.164 (prefixe figure dans le champ inerte).
    final digits = local.replaceAll(RegExp(r'\D'), '');
    widget.onChanged(digits.isEmpty ? '' : '+237$digits');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final radius = BorderRadius.circular(AppRadius.xl2);
    final borderColor = hasError ? AppColors.danger : AppColors.border;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: radius,
              border: Border.all(color: borderColor),
              boxShadow: AppElevation.soft,
            ),
            child: Row(
              children: [
                SizedBox(width: AppSpacing.s4.w),
                const _CameroonFlag(),
                SizedBox(width: AppSpacing.s2.w),
                Text(
                  '+237',
                  style: AppTypography.bodyStrong.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(width: AppSpacing.s2.w),
                Container(
                  width: 1,
                  height: 24.h,
                  color: AppColors.border,
                ),
                SizedBox(width: AppSpacing.s3.w),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    onChanged: _onLocalChanged,
                    style: AppTypography.bodyStrong.copyWith(
                      fontSize: 17.sp,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: '6 -- -- -- --',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.mute2,
                        fontSize: 17.sp,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.s4.w),
              ],
            ),
          ),
          if (hasError) ...[
            SizedBox(height: AppSpacing.s2.h),
            Text(
              widget.errorText!,
              style: AppTypography.meta.copyWith(
                color: AppColors.danger,
                fontSize: 13.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Drapeau Cameroun 20x14 px dessine avec CustomPaint (3 bandes verticales
/// vert / rouge / jaune + etoile jaune centrale dans la bande rouge).
///
/// Implementation native (pas de SVG) pour eviter une dependance asset et
/// garantir le rendu identique sur tous les form factors.
class _CameroonFlag extends StatelessWidget {
  const _CameroonFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 22.w,
        height: 16.h,
        child: CustomPaint(painter: _CameroonFlagPainter()),
      ),
    );
  }
}

class _CameroonFlagPainter extends CustomPainter {
  static const Color _green = Color(0xFF007A5E);
  static const Color _red = Color(0xFFCE1126);
  static const Color _yellow = Color(0xFFFCD116);

  @override
  void paint(Canvas canvas, Size size) {
    final bandWidth = size.width / 3;
    final paint = Paint();

    paint.color = _green;
    canvas.drawRect(Rect.fromLTWH(0, 0, bandWidth, size.height), paint);

    paint.color = _red;
    canvas.drawRect(
      Rect.fromLTWH(bandWidth, 0, bandWidth, size.height),
      paint,
    );

    paint.color = _yellow;
    canvas.drawRect(
      Rect.fromLTWH(2 * bandWidth, 0, bandWidth, size.height),
      paint,
    );

    // Etoile 5-branches simplifiee : point central + 5 traits radiaux.
    // Pour une vraie etoile cf. story future avec asset SVG ; ici un point
    // suffit visuellement au format 20x14.
    paint.color = _yellow;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.height * 0.18, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

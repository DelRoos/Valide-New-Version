part of '../pedagogical_content.dart';

/// Bloc audio pédagogique — rendu depuis `:::audio\nurl=...\nlabel=...\n:::`.
///
/// Utilise `audioplayers` (déjà dans pubspec) pour lire des URL réseau.
/// Syntaxe callout :
/// ```
/// :::audio
/// url=https://example.com/audio.mp3
/// label=Prononciation : nǐ hǎo
/// :::
/// ```
class _AudioBlock extends StatefulWidget {
  const _AudioBlock({
    required this.url,
    required this.label,
  });

  final String url;
  final String label;

  static _AudioBlock? fromBody(String body) {
    String? url;
    String? label;
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('url=')) {
        url = trimmed.substring(4).trim();
      } else if (trimmed.startsWith('label=')) {
        label = trimmed.substring(6).trim();
      }
    }
    if (url == null || url.isEmpty) return null;
    return _AudioBlock(
      url: url,
      label: label ?? '',
    );
  }

  @override
  State<_AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends State<_AudioBlock> {
  // Un seul lecteur audio actif à la fois dans toute l'app.
  static _AudioBlockState? _activePlaying;

  // Taille du bouton play/pause circulaire (dp, pas responsive — zone de touch stable).
  static const double _kPlayButtonSize = 40;

  late final AudioPlayer _player;
  // Subscriptions stockées pour annulation dans dispose().
  final _subs = <StreamSubscription<dynamic>>[];
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // true pendant que _preload() est en cours
  bool _preloading = true;
  // true quand la source a été préchargée avec succès (évite de re-set à chaque play)
  bool _sourceReady = false;
  // true si le codec/réseau a rendu l'audio indisponible
  bool _hasError = false;
  // true dès que dispose() est appelé — stoppe _preload() si encore en vol.
  bool _disposed = false;
  // Chemin local du fichier audio préchargé — null tant que _sourceReady == false.
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _subs
      ..add(_player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _state = s);
      }))
      ..add(_player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      }))
      ..add(_player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      }))
      ..add(_player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _state = PlayerState.stopped;
            _position = Duration.zero;
          });
          if (_activePlaying == this) _activePlaying = null;
        }
      }));
    // Pré-charge la source en arrière-plan dès l'ouverture de la leçon.
    // Téléchargement via http.get (headers custom) + lecture depuis fichier local —
    // Android MediaPlayer ne supporte pas les headers sur HTTPS, ce qui provoque
    // MEDIA_ERROR_SYSTEM sur les URLs Wikimedia et assimilés.
    _preload();
  }

  Future<void> _preload() async {
    AppLogger.d('[AudioBlock] preload url=${widget.url}');
    try {
      final tmpDir = await getTemporaryDirectory();
      final urlHash = widget.url.hashCode.abs();
      final ext = Uri.parse(widget.url).path.split('.').last;
      final file = File('${tmpDir.path}/valide_audio_$urlHash.$ext');

      // Réutilise le fichier en cache si déjà téléchargé (évite les 429 Wikimedia).
      if (await file.exists()) {
        AppLogger.d('[AudioBlock] cache hit url=${widget.url}');
        _localFilePath = file.path;
        if (_disposed) return;
        await _player.setSourceDeviceFile(file.path);
        if (mounted) setState(() { _preloading = false; _sourceReady = true; });
        return;
      }

      const audioHeaders = {
        'User-Agent': 'ValideSchool/1.0 (Flutter; educational app)',
        'Accept': 'audio/ogg,audio/mpeg,audio/*;q=0.9,*/*;q=0.8',
      };
      var response = await http.get(Uri.parse(widget.url), headers: audioHeaders);
      if (response.statusCode == 429) {
        AppLogger.d('[AudioBlock] 429 rate-limited, retrying in 3s url=${widget.url}');
        await Future.delayed(const Duration(seconds: 3));
        response = await http.get(Uri.parse(widget.url), headers: audioHeaders);
      }
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      _localFilePath = file.path;
      if (_disposed) return;
      await _player.setSourceDeviceFile(file.path);
      AppLogger.i('[AudioBlock] ready url=${widget.url} size=${response.bodyBytes.length}B');
      if (mounted) setState(() { _preloading = false; _sourceReady = true; });
    } catch (e) {
      AppLogger.w('[AudioBlock] preload failed url=${widget.url}', error: e);
      if (mounted) setState(() { _preloading = false; _hasError = true; });
    }
  }

  Future<void> _retry() async {
    if (_preloading) return;
    setState(() { _preloading = true; _hasError = false; _sourceReady = false; });
    // Supprime le fichier en cache éventuellement corrompu avant de retenter.
    try {
      final tmpDir = await getTemporaryDirectory();
      final urlHash = widget.url.hashCode.abs();
      final ext = Uri.parse(widget.url).path.split('.').last;
      final file = File('${tmpDir.path}/valide_audio_$urlHash.$ext');
      if (await file.exists()) await file.delete();
    } catch (_) {}
    await _preload();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    if (_activePlaying == this) _activePlaying = null;
    _player.dispose();
    super.dispose();
  }

  void _pauseFromExternal() {
    _player.pause(); // onPlayerStateChanged met à jour _state
  }

  Future<void> _toggle() async {
    if (_hasError) return;

    if (_state == PlayerState.playing) {
      await _player.pause();
      if (_activePlaying == this) _activePlaying = null;
    } else {
      // Mettre en pause tout autre lecteur actif
      if (_activePlaying != null && _activePlaying != this) {
        if (_activePlaying!.mounted) _activePlaying!._pauseFromExternal();
        _activePlaying = null;
      }
      _activePlaying = this;
      try {
        if (_state == PlayerState.paused) {
          await _player.resume();
        } else if (_sourceReady && _localFilePath != null) {
          // resume() ne fonctionne que sur état paused — état stopped après fin :
          // relancer depuis le fichier local préchargé.
          await _player.play(DeviceFileSource(_localFilePath!));
        } else {
          // Pas encore préchargé (réseau lent) : play classique avec source
          await _player.play(UrlSource(widget.url));
        }
      } catch (_) {
        if (mounted) setState(() => _hasError = true);
        if (_activePlaying == this) _activePlaying = null;
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    // Spinner : pré-chargement initial OU lecture démarrée mais durée inconnue
    final isLoading = _preloading || (isPlaying && _duration == Duration.zero);
    final progress =
        (_duration.inMilliseconds > 0 && _position.inMilliseconds > 0)
            ? (_position.inMilliseconds / _duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s3.h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hasError
                ? AppColors.dangerInk.withValues(alpha: 0.3)
                : AppColors.sky.withValues(alpha: 0.4),
            width: AppBorderWidth.normal,
          ),
          color: _hasError ? AppColors.dangerSoft : AppColors.skySoft,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s3.w,
          vertical: AppSpacing.s3.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.s1.w),
                  decoration: BoxDecoration(
                    color: _hasError
                        ? AppColors.dangerInk.withValues(alpha: 0.1)
                        : AppColors.sky.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(
                    _hasError
                        ? Icons.volume_off_outlined
                        : Icons.headphones_outlined,
                    size: AppIconSize.sm,
                    color: _hasError ? AppColors.dangerInk : AppColors.skyInk,
                  ),
                ),
                SizedBox(width: AppSpacing.s2.w),
                Text(
                  'AUDIO',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppFontSize.eyebrow,
                    fontWeight: FontWeight.w800,
                    color: _hasError ? AppColors.dangerInk : AppColors.skyInk,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            if (widget.label.isNotEmpty) ...[
              SizedBox(height: AppSpacing.s2.h),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppFontSize.body,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],

            SizedBox(height: AppSpacing.s3.h),

            if (_hasError) ...[
              // État d'erreur : format audio non supporté ou réseau indisponible
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppIconSize.sm,
                    color: AppColors.dangerInk,
                  ),
                  SizedBox(width: AppSpacing.s2.w),
                  Expanded(
                    child: Text(
                      'Audio indisponible',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppFontSize.meta,
                        color: AppColors.dangerInk,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _retry,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.s2.w,
                        vertical: AppSpacing.s1.h,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.dangerInk.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: AppIconSize.xs,
                            color: AppColors.dangerInk,
                          ),
                          SizedBox(width: AppSpacing.s1.w),
                          Text(
                            'Réessayer',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: AppFontSize.meta,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dangerInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Contrôles normaux
              Row(
                children: [
                  GestureDetector(
                    onTap: (_preloading || _hasError) ? null : _toggle,
                    child: Container(
                      width: _kPlayButtonSize,
                      height: _kPlayButtonSize,
                      decoration: BoxDecoration(
                        color: AppColors.sky,
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: AppIconSize.xl,
                            ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor:
                                AppColors.sky.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.sky),
                          ),
                        ),
                        SizedBox(height: AppSpacing.s1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _fmt(_position),
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: AppFontSize.meta,
                                color: AppColors.muted,
                              ),
                            ),
                            if (_duration > Duration.zero)
                              Text(
                                _fmt(_duration),
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: AppFontSize.meta,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

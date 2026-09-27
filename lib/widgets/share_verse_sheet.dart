// lib/widgets/share_verse_sheet.dart
// ✅ bilingue FR/EN — partage d'un verset ou d'un passage en image (statut / story / carré)
// ou en texte, avec la signature MemorizBible pour la provenance.
//
// Utilisation, depuis n'importe quel écran :
//   showShareVerseSheet(context, reference: 'Jean 14:27', text: 'Je vous laisse la paix…');

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import 'package:memoriz_bible/models/language_provider.dart';

import '../prayer/prayer_translations.dart';

/// ⚠️ Mets ici le chemin de ton icône (déclarée dans pubspec.yaml)
const kLogoAsset = 'assets/images/logo.png';
const kAppLink = 'https://memorizbible.web.app';
const _teal = Color(0xFF1F5C57);

Future<void> showShareVerseSheet(
    BuildContext context, {
      required String reference,
      required String text,
      String? language, // ✅ 'fr' ou 'en' ; sinon on lit le LanguageProvider
    }) {
  final lang = language ?? Provider.of<LanguageProvider>(context, listen: false).language;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFFF3F5F2),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ShareVerseSheet(reference: reference, text: text, language: lang),
  );
}

enum _Format { story, carre }

class _CardTheme {
  final List<Color> fond;
  final Color texte;
  final Color accent;
  const _CardTheme(this.fond, this.texte, this.accent);

  String nom(PrayerTranslations t, int index) =>
      [t.themeTeal, t.themeNight, t.themeLight][index];
}

const _themes = [
  _CardTheme([Color(0xFF1F5C57), Color(0xFF14403C)], Colors.white, Color(0xFF8FC7BF)),
  _CardTheme([Color(0xFF1C2230), Color(0xFF2E3A52)], Colors.white, Color(0xFFE0B96A)),
  _CardTheme([Color(0xFFFFFFFF), Color(0xFFE6EEEB)], Color(0xFF1C2622), _teal),
];

class ShareVerseSheet extends StatefulWidget {
  final String reference;
  final String text;
  final String language;

  const ShareVerseSheet({
    Key? key,
    required this.reference,
    required this.text,
    this.language = 'fr',
  }) : super(key: key);

  @override
  State<ShareVerseSheet> createState() => _ShareVerseSheetState();
}

class _ShareVerseSheetState extends State<ShareVerseSheet> {
  final _cardKey = GlobalKey();
  _Format _format = _Format.story;
  int _theme = 0;
  bool _busy = false;

  // Taille de l'aperçu à l'écran ; l'image exportée fait 1080 px de large
  double get _previewWidth => _format == _Format.story ? 200 : 280;
  double get _previewHeight => _format == _Format.story ? 200 * 16 / 9 : 280;

  PrayerTranslations get _t =>
      PrayerTranslations.of(widget.language == 'en' ? 'en' : 'fr');

  String get _texteComplet => _t.locale == 'en'
      ? '"${widget.text}"\n— ${widget.reference}\n\n${_t.sharedFromApp}\n$kAppLink'
      : '« ${widget.text} »\n— ${widget.reference}\n\n${_t.sharedFromApp}\n$kAppLink';

  Rect? _origine() {
    // Nécessaire sur iPad pour positionner la feuille de partage
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _partagerImage() async {
    setState(() => _busy = true);
    try {
      final boundary =
      _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1080 / _previewWidth);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();

      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'image/png', name: 'memorizbible_verset.png'),
        ],
        text: '${widget.reference} — ${_t.viaApp}\n$kAppLink',
        sharePositionOrigin: _origine(),
      ));
    } catch (e) {
      debugPrint('❌ Partage image impossible : $e');
      await _copierAvecMessage(_t.imageShareUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _partagerTexte() async {
    try {
      await SharePlus.instance.share(ShareParams(
        text: _texteComplet,
        sharePositionOrigin: _origine(),
      ));
    } catch (e) {
      debugPrint('❌ Partage texte impossible : $e');
      await _copierAvecMessage(_t.textCopied);
    }
  }

  Future<void> _copierAvecMessage(String message) async {
    await Clipboard.setData(ClipboardData(text: _texteComplet));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFC9D2CD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.share,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          // Aperçu : c'est exactement ce widget qui est capturé en image
          RepaintBoundary(
            key: _cardKey,
            child: _VerseCard(
              width: _previewWidth,
              height: _previewHeight,
              reference: widget.reference,
              text: widget.text,
              theme: _themes[_theme],
              story: _format == _Format.story,
            ),
          ),

          const SizedBox(height: 16),

          // Format
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(t.storyFormat),
                selected: _format == _Format.story,
                onSelected: (_) => setState(() => _format = _Format.story),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(t.squareFormat),
                selected: _format == _Format.carre,
                onSelected: (_) => setState(() => _format = _Format.carre),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Couleurs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_themes.length, (i) {
              final th = _themes[i];
              final actif = i == _theme;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Tooltip(
                  message: _themes[i].nom(t, i),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _theme = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: th.fond),
                        border: Border.all(
                          color: actif ? _teal : const Color(0xFFC9D2CD),
                          width: actif ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _busy ? null : _partagerImage,
            icon: _busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.image_outlined),
            label: Text(t.shareImage),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: const StadiumBorder(),
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _partagerTexte,
                  icon: const Icon(Icons.short_text),
                  label: Text(t.textLabel),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                    foregroundColor: const Color(0xFF1C2622),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copierAvecMessage(t.copied),
                  icon: const Icon(Icons.copy),
                  label: Text(t.copy),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: const StadiumBorder(),
                    foregroundColor: const Color(0xFF1C2622),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.whatsappStatusHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF5B6661)),
          ),
        ],
      ),
    );
  }
}

/// La carte exportée en image. Toutes les tailles sont proportionnelles
/// à la largeur, donc l'aperçu et l'image finale sont identiques.
class _VerseCard extends StatelessWidget {
  final double width;
  final double height;
  final String reference;
  final String text;
  final _CardTheme theme;
  final bool story;

  const _VerseCard({
    required this.width,
    required this.height,
    required this.reference,
    required this.text,
    required this.theme,
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    final w = width;
    final pad = w * 0.09;
    final innerWidth = w - pad * 2;
    final texte = text.length > 600 ? '${text.substring(0, 600)}…' : text;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.fond,
        ),
      ),
      child: Column(
        children: [
          // Le verset, réduit automatiquement s'il est long
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: innerWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“',
                        style: TextStyle(
                          fontSize: w * 0.2,
                          height: 0.9,
                          color: theme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        texte,
                        style: TextStyle(
                          fontSize: w * (story ? 0.072 : 0.062),
                          height: 1.45,
                          color: theme.texte,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: w * 0.05),
                      Text(
                        reference,
                        style: TextStyle(
                          fontSize: w * 0.05,
                          fontWeight: FontWeight.w700,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Signature MemorizBible
          SizedBox(height: w * 0.04),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(w * 0.025),
                child: Image.asset(
                  kLogoAsset,
                  width: w * 0.1,
                  height: w * 0.1,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: w * 0.1,
                    height: w * 0.1,
                    color: theme.accent,
                    child: Icon(Icons.menu_book, size: w * 0.06, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MemorizBible',
                    style: TextStyle(
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      color: theme.texte,
                    ),
                  ),
                  Text(
                    'memorizbible.web.app',
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: theme.texte.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
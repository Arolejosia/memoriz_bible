// lib/prayer/screens/note_read_screen.dart
// Vue de lecture d'une note ou d'une méditation — ✅ bilingue FR/EN
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memoriz_bible/services/bible_service.dart';

import '../prayer_translations.dart';
import '../providers/prayer_notes_provider.dart';
import '../models/prayer_note.dart';
import '../widgets/note_editor_widget.dart';
import 'package:memoriz_bible/widgets/share_verse_sheet.dart';
import 'guided_meditation_screen.dart' show appLang;

const _teal = Color(0xFF1F5C57);

class NoteReadScreen extends StatefulWidget {
  final String noteId;

  const NoteReadScreen({Key? key, required this.noteId}) : super(key: key);

  @override
  State<NoteReadScreen> createState() => _NoteReadScreenState();
}

class _NoteReadScreenState extends State<NoteReadScreen> {
  Future<List<VerseData>>? _passage;
  String? _refChargee;

  void _chargerPassageSiBesoin(String? ref) {
    if (ref == null || ref.isEmpty || ref == _refChargee) return;
    _refChargee = ref;
    _passage = BibleService().getPassageText(
      ref,
      language: appLang(context),
    );
  }

  bool _ouvrePartage = false;

  // ✅ NOUVEAU : ouvre la feuille de partage avec le texte du passage
  Future<void> _partager(String reference) async {
    if (_passage == null || _ouvrePartage) return;
    setState(() => _ouvrePartage = true);
    final versets = await _passage!;
    if (!mounted) return;
    setState(() => _ouvrePartage = false);
    final texte = versets.map((v) => v.text).join(' ');
    await showShareVerseSheet(context, reference: reference, text: texte);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerNotesProvider>(
      builder: (context, notesProvider, child) {
        final t = PrayerTranslations.of(appLang(context));
        // On relit la note depuis le provider pour voir les modifications
        PrayerNote? note;
        for (final n in notesProvider.notes) {
          if (n.id == widget.noteId) {
            note = n;
            break;
          }
        }

        if (note == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(t.noteNotFound)),
          );
        }

        final n = note;
        _chargerPassageSiBesoin(n.verseReference);

        final typeLabel = n.type == NoteType.autre && n.customTypeLabel != null
            ? n.customTypeLabel!
            : (t.locale == 'en' ? n.type.displayNameEn : n.type.displayNameFr);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5F2),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F5F2),
            foregroundColor: const Color(0xFF1C2622),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: t.edit,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NoteEditorWidget(note: n)),
                  );
                },
              ),
            ],
          ),
          // ✅ NOUVEAU : bouton Partager en bas de la lecture
          bottomNavigationBar: n.verseReference == null
              ? null
              : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton.icon(
                onPressed: _ouvrePartage ? null : () => _partager(n.verseReference!),
                icon: _ouvrePartage
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.ios_share),
                label: Text(t.shareVerse),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: const StadiumBorder(),
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text(
                typeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _teal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                n.verseReference ?? t.noteLabel,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                t.dateAt(n.createdAt),
                style: const TextStyle(fontSize: 14, color: Color(0xFF5B6661)),
              ),

              // Le passage médité
              if (_passage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _teal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: FutureBuilder<List<VerseData>>(
                    future: _passage,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        );
                      }
                      final texte = (snapshot.data ?? []).map((v) => v.text).join(' ');
                      return Text(
                        texte,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _ContenuNote(texte: n.content),

              if (n.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: n.tags
                      .map((t) => Chip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

}

/// Affiche le contenu. Les blocs d'une méditation guidée
/// ("Observer — question" + réponse) sont mis en forme par étape.
class _ContenuNote extends StatelessWidget {
  final String texte;
  const _ContenuNote({required this.texte});

  // Titres d'étapes FR et EN, pour relire une méditation dans n'importe quelle langue
  static const _etapes = PrayerTranslations.allStepTitles;

  @override
  Widget build(BuildContext context) {
    final blocs = texte.split('\n\n');
    final estGuidee = blocs.isNotEmpty &&
        blocs.every((b) => _etapes.any((e) => b.startsWith('$e — ')));

    if (!estGuidee) {
      return SelectableText(
        texte,
        style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF2A3530)),
      );
    }

    final widgets = <Widget>[];
    for (var i = 0; i < blocs.length; i++) {
      final lignes = blocs[i].split('\n');
      final entete = lignes.first;
      final sep = entete.indexOf(' — ');
      final etape = entete.substring(0, sep);
      final question = entete.substring(sep + 3);
      final reponse = lignes.skip(1).join('\n');

      if (i > 0) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(height: 1, color: Color(0xFFD5DBD6)),
        ));
      }
      widgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etape,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _teal),
          ),
          const SizedBox(height: 4),
          Text(
            question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          SelectableText(
            reponse,
            style: const TextStyle(fontSize: 16, height: 1.55, color: Color(0xFF2A3530)),
          ),
        ],
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
// lib/prayer/screens/guided_meditation_screen.dart
// Méditation guidée étape par étape — ✅ bilingue FR/EN
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memoriz_bible/services/bible_service.dart';

import 'package:memoriz_bible/models/language_provider.dart';
import '../prayer_translations.dart';
import '../providers/prayer_notes_provider.dart';
import '../models/prayer_note.dart';
import 'note_read_screen.dart';

const _teal = Color(0xFF1F5C57);

/// Langue courante ('fr' ou 'en'), lue dans le LanguageProvider de l'app
/// ✅ CORRIGÉ : même source que le lecteur de Bible
String appLang(BuildContext context) =>
    // listen: false → utilisable aussi dans les callbacks (boutons, async)
Provider.of<LanguageProvider>(context, listen: false).language == 'en'
    ? 'en'
    : 'fr';

/// Les trois façons de méditer proposées sur l'accueil
enum MeditationMode { guidee, rapide, libre }

extension MeditationModeX on MeditationMode {
  String label(PrayerTranslations t) {
    switch (this) {
      case MeditationMode.guidee:
        return t.modeGuided;
      case MeditationMode.rapide:
        return t.modeQuick;
      case MeditationMode.libre:
        return t.modeFree;
    }
  }

  String duree(PrayerTranslations t) {
    switch (this) {
      case MeditationMode.guidee:
        return '10 min';
      case MeditationMode.rapide:
        return '5 min';
      case MeditationMode.libre:
        return t.modeNoQuestions;
    }
  }

  String tag(PrayerTranslations t) {
    switch (this) {
      case MeditationMode.guidee:
        return t.tagGuided;
      case MeditationMode.rapide:
        return t.tagQuick;
      case MeditationMode.libre:
        return t.tagFree;
    }
  }
}

/// Une étape du parcours : un titre, une consigne et une banque de questions
class _Etape {
  final String titre;
  final String consigne;
  final List<String> questions;
  const _Etape(this.titre, this.consigne, this.questions);
}

List<_Etape> _etapesPour(MeditationMode mode, PrayerTranslations t) {
  final lire = _Etape(t.stepRead, t.readInstruction, const []);
  final observer = _Etape(t.stepObserve, t.observeInstruction, t.observeQuestions);
  final reflechir = _Etape(t.stepReflect, t.reflectInstruction, t.reflectQuestions);
  final appliquer = _Etape(t.stepApply, t.applyInstruction, t.applyQuestions);
  final prier = _Etape(t.stepPray, t.prayInstruction, t.prayQuestions);
  final ecrire = _Etape(t.stepMeditate, t.meditateInstruction, t.meditateQuestions);

  switch (mode) {
    case MeditationMode.guidee:
      return [lire, observer, reflechir, appliquer, prier];
    case MeditationMode.rapide:
      return [lire, reflechir, prier];
    case MeditationMode.libre:
      return [lire, ecrire];
  }
}

class GuidedMeditationScreen extends StatefulWidget {
  final String reference;
  final MeditationMode mode;

  const GuidedMeditationScreen({
    Key? key,
    required this.reference,
    this.mode = MeditationMode.guidee,
  }) : super(key: key);

  @override
  State<GuidedMeditationScreen> createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  final _random = Random();

  // Initialisés une seule fois, dans didChangeDependencies (on a besoin de la langue)
  late PrayerTranslations _t;
  List<_Etape> _etapes = [];
  List<TextEditingController> _reponses = [];
  List<int> _questionIndex = [];
  Future<List<VerseData>>? _passage;

  int _index = 0;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = appLang(context);
    _t = PrayerTranslations.of(lang);

    if (_etapes.isEmpty) {
      _etapes = _etapesPour(widget.mode, _t);
      _reponses = List.generate(_etapes.length, (_) => TextEditingController());
      _questionIndex = _etapes
          .map((e) => e.questions.isEmpty ? 0 : _random.nextInt(e.questions.length))
          .toList();
      _passage = BibleService().getPassageText(widget.reference, language: lang);
    }
  }

  @override
  void dispose() {
    for (final c in _reponses) {
      c.dispose();
    }
    super.dispose();
  }

  _Etape get _etape => _etapes[_index];
  bool get _derniere => _index == _etapes.length - 1;

  String? get _questionCourante =>
      _etape.questions.isEmpty ? null : _etape.questions[_questionIndex[_index]];

  void _autreQuestion() {
    final n = _etape.questions.length;
    if (n < 2) return;
    setState(() {
      _questionIndex[_index] = (_questionIndex[_index] + 1) % n;
    });
  }

  void _suivant() {
    FocusScope.of(context).unfocus();
    if (_derniere) {
      _terminer();
    } else {
      setState(() => _index++);
    }
  }

  void _precedent() {
    FocusScope.of(context).unfocus();
    if (_index > 0) setState(() => _index--);
  }

  /// Assemble les réponses en un seul texte lisible
  String _construireContenu() {
    final blocs = <String>[];
    for (var i = 0; i < _etapes.length; i++) {
      final e = _etapes[i];
      final reponse = _reponses[i].text.trim();
      if (e.questions.isEmpty || reponse.isEmpty) continue;
      final question = e.questions[_questionIndex[i]];
      blocs.add('${e.titre} — $question\n$reponse');
    }
    return blocs.join('\n\n');
  }

  Future<void> _terminer() async {
    final contenu = _construireContenu();
    if (contenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.writeAtLeastOne)),
      );
      return;
    }

    setState(() => _saving = true);
    final notesProvider = context.read<PrayerNotesProvider>();
    final id = await notesProvider.createNote(
      type: NoteType.meditation,
      content: contenu,
      verseReference: widget.reference,
      tags: [widget.mode.tag(_t)],
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.meditationSaveError)),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => NoteReadScreen(noteId: id)),
    );
  }

  Future<bool> _confirmerSortie() async {
    final aEcrit = _reponses.any((c) => c.text.trim().isNotEmpty);
    if (!aEcrit) return true;
    final quitter = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t.quitMeditationTitle),
        content: Text(_t.quitMeditationBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t.continueLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t.quit),
          ),
        ],
      ),
    );
    return quitter ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;

    return WillPopScope(
      onWillPop: _confirmerSortie,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F5F2),
          foregroundColor: const Color(0xFF1C2622),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: t.quit,
            onPressed: () async {
              if (await _confirmerSortie() && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            widget.reference,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / _etapes.length,
              backgroundColor: const Color(0xFFC9D2CD),
              color: _teal,
              minHeight: 4,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Text(
              t.stepOf(_index + 1, _etapes.length, _etape.titre),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _teal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _etape.consigne,
              style: const TextStyle(fontSize: 14, color: Color(0xFF5B6661)),
            ),
            const SizedBox(height: 16),

            // Le passage reste toujours visible
            _PassageCard(passage: _passage, indisponible: t.passageUnavailable),

            if (_questionCourante != null) ...[
              const SizedBox(height: 24),
              Text(
                _questionCourante!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Color(0xFF1C2622),
                ),
              ),
              if (_etape.questions.length > 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _autreQuestion,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(t.anotherQuestion),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF3F4A45)),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey('reponse_$_index'),
                controller: _reponses[_index],
                minLines: 5,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: t.yourAnswerPrivate,
                  hintText: t.answerHint,
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                if (_index > 0) ...[
                  OutlinedButton(
                    onPressed: _saving ? null : _precedent,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: const StadiumBorder(),
                      foregroundColor: const Color(0xFF1C2622),
                    ),
                    child: Text(t.previous),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _suivant,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      shape: const StadiumBorder(),
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(
                      _derniere ? t.finish : t.nextStep(_etapes[_index + 1].titre),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PassageCard extends StatelessWidget {
  final Future<List<VerseData>>? passage;
  final String indisponible;
  const _PassageCard({required this.passage, required this.indisponible});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5DBD6)),
      ),
      child: FutureBuilder<List<VerseData>>(
        future: passage,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final texte = (snapshot.data ?? []).map((v) => v.text).join(' ');
          return Text(
            texte.isEmpty ? indisponible : texte,
            style: const TextStyle(
              fontSize: 17,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: Color(0xFF2A3530),
            ),
          );
        },
      ),
    );
  }
}
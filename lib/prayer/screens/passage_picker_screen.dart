// lib/prayer/screens/passage_picker_screen.dart
// La personne choisit elle-même le passage à méditer — ✅ bilingue FR/EN
import 'package:flutter/material.dart';
import 'package:memoriz_bible/services/bible_service.dart';

import '../prayer_translations.dart';
import 'guided_meditation_screen.dart';

const _teal = Color(0xFF1F5C57);

class PassagePickerScreen extends StatefulWidget {
  final MeditationMode mode;

  const PassagePickerScreen({Key? key, this.mode = MeditationMode.guidee})
      : super(key: key);

  @override
  State<PassagePickerScreen> createState() => _PassagePickerScreenState();
}

class _PassagePickerScreenState extends State<PassagePickerScreen> {
  final _bible = BibleService();
  final _searchCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  List<BibleBookInfo> _livres = [];
  bool _loadingLivres = true;
  String _testament = 'NT';
  BibleBookInfo? _livre;
  int? _chapitre;

  List<VerseData>? _apercu;
  bool _loadingApercu = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _chargerLivres());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  String get _lang => appLang(context);

  Future<void> _chargerLivres() async {
    final livres = await _bible.getLivres(language: _lang);
    if (!mounted) return;
    setState(() {
      _livres = livres;
      _loadingLivres = false;
    });
  }

  /// La référence finale : recherche directe en priorité, sinon la navigation
  String? get _reference {
    final saisie = _searchCtrl.text.trim();
    if (saisie.isNotEmpty) return saisie;
    if (_livre == null || _chapitre == null) return null;
    final debut = int.tryParse(_fromCtrl.text.trim());
    if (debut == null || debut < 1) return null;
    final fin = int.tryParse(_toCtrl.text.trim());
    if (fin != null && fin > debut) {
      return '${_livre!.nom} $_chapitre:$debut-$fin';
    }
    return '${_livre!.nom} $_chapitre:$debut';
  }

  void _referenceChangee() {
    setState(() => _apercu = null);
  }

  Future<void> _voirApercu() async {
    final ref = _reference;
    if (ref == null) return;
    FocusScope.of(context).unfocus();
    setState(() => _loadingApercu = true);
    final versets = await _bible.getPassageText(ref, language: _lang);
    if (!mounted) return;
    setState(() {
      _apercu = versets;
      _loadingApercu = false;
    });
  }

  void _commencer() {
    final ref = _reference;
    if (ref == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedMeditationScreen(reference: ref, mode: widget.mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(_lang);
    final ref = _reference;
    final livresFiltres = _livres.where((l) => l.testament == _testament).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F2),
        foregroundColor: const Color(0xFF1C2622),
        elevation: 0,
        title: Text(t.choosePassage),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // Recherche directe
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => _referenceChangee(),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _voirApercu(),
            decoration: InputDecoration(
              labelText: t.directSearch,
              hintText: t.directSearchHint,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),

          const SizedBox(height: 20),
          _SectionLabel(t.orBrowseBible),
          const SizedBox(height: 10),

          // Ancien / Nouveau Testament
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text(t.oldTestament)),
                  selected: _testament == 'AT',
                  onSelected: (_) => setState(() {
                    _testament = 'AT';
                    _livre = null;
                    _chapitre = null;
                    _apercu = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text(t.newTestament)),
                  selected: _testament == 'NT',
                  onSelected: (_) => setState(() {
                    _testament = 'NT';
                    _livre = null;
                    _chapitre = null;
                    _apercu = null;
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _SectionLabel(t.book),
          const SizedBox(height: 8),
          if (_loadingLivres)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_livres.isEmpty)
            Row(
              children: [
                Expanded(child: Text(t.booksLoadError)),
                TextButton(
                  onPressed: () {
                    setState(() => _loadingLivres = true);
                    _chargerLivres();
                  },
                  child: Text(t.retry),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: livresFiltres.map((livre) {
                return ChoiceChip(
                  label: Text(livre.nom),
                  selected: _livre?.nom == livre.nom,
                  selectedColor: _teal.withOpacity(0.18),
                  onSelected: (_) => setState(() {
                    _searchCtrl.clear();
                    _livre = livre;
                    _chapitre = null;
                    _apercu = null;
                  }),
                );
              }).toList(),
            ),

          // Chapitres
          if (_livre != null) ...[
            const SizedBox(height: 20),
            _SectionLabel(t.chapterOf(_livre!.nom)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_livre!.nbChapitres, (i) {
                final n = i + 1;
                return SizedBox(
                  width: 44,
                  child: ChoiceChip(
                    label: Center(child: Text('$n')),
                    labelPadding: EdgeInsets.zero,
                    selected: _chapitre == n,
                    selectedColor: _teal.withOpacity(0.18),
                    onSelected: (_) => setState(() {
                      _chapitre = n;
                      _apercu = null;
                      if (_fromCtrl.text.isEmpty) _fromCtrl.text = '1';
                    }),
                  ),
                );
              }),
            ),
          ],

          // Versets
          if (_livre != null && _chapitre != null) ...[
            const SizedBox(height: 20),
            _SectionLabel(t.verses),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _referenceChangee(),
                    decoration: InputDecoration(
                      labelText: t.fromVerse,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _toCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _referenceChangee(),
                    decoration: InputDecoration(
                      labelText: t.toVerseOptional,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Aperçu
          if (ref != null) ...[
            const SizedBox(height: 20),
            if (_apercu == null)
              OutlinedButton.icon(
                onPressed: _loadingApercu ? null : _voirApercu,
                icon: _loadingApercu
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.menu_book),
                label: Text(t.viewPassage(ref)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder(),
                  foregroundColor: _teal,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD5DBD6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: _teal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _apercu!.map((v) => v.text).join(' '),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: ref == null ? null : _commencer,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: const StadiumBorder(),
              backgroundColor: _teal,
              foregroundColor: Colors.white,
            ),
            child: Text(
              ref == null ? t.choosePassage : t.meditateOn(ref),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3F4A45),
      ),
    );
  }
}
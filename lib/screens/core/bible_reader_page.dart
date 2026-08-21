// Fichier: screens/core/bible_reader_page.dart
// 📖 Écran de lecture de la Bible : livre → chapitre → versets
//
// ⚠️ NOTE : structure Material standard, à ajuster une fois qu'on aura
// vu un écran existant de l'app pour matcher le thème (couleurs, AppBar, etc.)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bible_service.dart';
import '../../Bibliotheque.dart';
import '../../models/language_provider.dart';
import '../../prayer/providers/prayer_notes_provider.dart';
import '../../prayer/models/prayer_note.dart';
// bible_reader_page.dart est placé dans lib/screens/core/, comme pageDeConfiguration.dart
import 'pageDeConfiguration.dart';
// ⚠️ Chemins à confirmer : modèle Verse et écran de détail/progression réelle
import '../../models/verse_model.dart';
// ⚠️ Chemin à confirmer si erreur : écran de détail/progression réelle
import '../verse/verse_detail_page.dart';

class BibleReaderPage extends StatefulWidget {
  const BibleReaderPage({super.key});

  @override
  State<BibleReaderPage> createState() => _BibleReaderPageState();
}

class _BibleReaderPageState extends State<BibleReaderPage> {
  final BibleService _bibleService = BibleService();

  // Langue courante — synchronisée avec le LanguageProvider global de l'app.
  // '' au départ pour forcer le premier chargement dans didChangeDependencies.
  String _language = '';

  // État de la liste des livres
  List<BibleBookInfo> _livres = [];
  bool _loadingLivres = true;
  String? _errorLivres;

  // Sélection courante
  BibleBookInfo? _livreSelectionne;
  int? _chapitreSelectionne;

  // État du passage affiché
  List<VerseData> _versets = [];
  bool _loadingVersets = false;
  String? _errorVersets;

  // Sélection de versets (tap pour démarrer, tap pour terminer une plage)
  int? _indexDebutSelection;
  int? _indexFinSelection;

  bool get _aUneSelection => _indexDebutSelection != null;

  bool _estSelectionne(int index) {
    if (_indexDebutSelection == null) return false;
    if (_indexFinSelection == null) return index == _indexDebutSelection;
    final min = _indexDebutSelection! < _indexFinSelection!
        ? _indexDebutSelection!
        : _indexFinSelection!;
    final max = _indexDebutSelection! > _indexFinSelection!
        ? _indexDebutSelection!
        : _indexFinSelection!;
    return index >= min && index <= max;
  }

  void _onTapVerset(int index) {
    setState(() {
      if (_indexDebutSelection == null) {
        // Aucune sélection en cours → on démarre
        _indexDebutSelection = index;
        _indexFinSelection = null;
      } else if (_indexFinSelection == null) {
        if (index == _indexDebutSelection) {
          // Tap sur le même verset → désélectionne tout
          _indexDebutSelection = null;
        } else {
          // Deuxième tap → termine la plage
          _indexFinSelection = index;
        }
      } else {
        // Une plage était déjà complète → on recommence une nouvelle sélection
        _indexDebutSelection = index;
        _indexFinSelection = null;
      }
    });
  }

  void _effacerSelection() {
    setState(() {
      _indexDebutSelection = null;
      _indexFinSelection = null;
    });
  }

  List<VerseData> _versetsSelectionnes() {
    if (_indexDebutSelection == null) return [];
    if (_indexFinSelection == null) {
      // Un seul verset sélectionné (pas encore de plage)
      return [_versets[_indexDebutSelection!]];
    }
    final min = _indexDebutSelection! < _indexFinSelection!
        ? _indexDebutSelection!
        : _indexFinSelection!;
    final max = _indexDebutSelection! > _indexFinSelection!
        ? _indexDebutSelection!
        : _indexFinSelection!;
    return _versets.sublist(min, max + 1);
  }

  @override
  void initState() {
    super.initState();
    // Le chargement initial se fait dans didChangeDependencies, une fois
    // que le LanguageProvider est accessible via le context.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final nouvelleLangue = languageProvider.language;

    if (nouvelleLangue != _language) {
      setState(() {
        _language = nouvelleLangue;
        // Le nom du livre changeant selon la langue (Jean ↔ John), on
        // revient à la liste des livres plutôt que de deviner l'équivalent.
        _livreSelectionne = null;
        _chapitreSelectionne = null;
        _versets = [];
        _indexDebutSelection = null;
        _indexFinSelection = null;
      });

      _chargerLivres();
    }
  }

  Future<void> _chargerLivres() async {
    setState(() {
      _loadingLivres = true;
      _errorLivres = null;
    });

    try {
      final livres = await _bibleService.getLivres(language: _language);
      setState(() {
        _livres = livres;
        _loadingLivres = false;
        if (livres.isEmpty) {
          _errorLivres = _language == 'fr'
              ? "Impossible de charger la liste des livres."
              : "Unable to load the list of books.";
        }
      });
    } catch (e) {
      print("❌ ERREUR dans _chargerLivres : $e");
      setState(() {
        _loadingLivres = false;
        _errorLivres = _language == 'fr'
            ? "Erreur de connexion."
            : "Connection error.";
      });
    }
  }

  Future<void> _ouvrirChapitre(BibleBookInfo livre, int chapitre) async {
    setState(() {
      _livreSelectionne = livre;
      _chapitreSelectionne = chapitre;
      _loadingVersets = true;
      _errorVersets = null;
      _versets = [];
      _indexDebutSelection = null;
      _indexFinSelection = null;
    });

    final reference = '${livre.nom} $chapitre';

    try {
      final versets = await _bibleService.getPassageText(
        reference,
        language: _language,
      );
      setState(() {
        _versets = versets;
        _loadingVersets = false;
      });
    } catch (e) {
      print("❌ ERREUR dans _ouvrirChapitre : $e");
      setState(() {
        _loadingVersets = false;
        _errorVersets = _language == 'fr'
            ? "Erreur lors du chargement du chapitre."
            : "Error loading the chapter.";
      });
    }
  }

  void _retourListeLivres() {
    setState(() {
      _livreSelectionne = null;
      _chapitreSelectionne = null;
      _versets = [];
    });
  }

  void _retourListeChapitres() {
    setState(() {
      _chapitreSelectionne = null;
      _versets = [];
      _indexDebutSelection = null;
      _indexFinSelection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titreAppBar()),
        leading: _leadingAppBar(),
      ),
      body: _buildBody(),
    );
  }

  String _titreAppBar() {
    if (_livreSelectionne == null) {
      return _language == 'fr' ? 'La Bible' : 'The Bible';
    } else if (_chapitreSelectionne == null) {
      return _livreSelectionne!.nom;
    } else {
      return '${_livreSelectionne!.nom} $_chapitreSelectionne';
    }
  }

  Widget? _leadingAppBar() {
    if (_livreSelectionne == null) return null;
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _chapitreSelectionne == null
          ? _retourListeLivres
          : _retourListeChapitres,
    );
  }

  Widget _buildBody() {
    if (_livreSelectionne == null) {
      return _buildListeLivres();
    } else if (_chapitreSelectionne == null) {
      return _buildGrilleChapitres();
    } else {
      return _buildLectureChapitre();
    }
  }

  // ===================================================
  // ÉTAPE 1 : Liste des livres, groupés par testament
  // ===================================================
  Widget _buildListeLivres() {
    if (_loadingLivres) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLivres != null) {
      return _buildErreur(_errorLivres!, _chargerLivres);
    }

    final livresAT = _livres.where((l) => l.testament == 'AT').toList();
    final livresNT = _livres.where((l) => l.testament == 'NT').toList();

    return ListView(
      children: [
        _buildEnteteTestament(
          _language == 'fr' ? 'Ancien Testament' : 'Old Testament',
        ),
        ...livresAT.map(_buildLigneLivre),
        _buildEnteteTestament(
          _language == 'fr' ? 'Nouveau Testament' : 'New Testament',
        ),
        ...livresNT.map(_buildLigneLivre),
      ],
    );
  }

  Widget _buildEnteteTestament(String titre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildLigneLivre(BibleBookInfo livre) {
    return ListTile(
      title: Text(livre.nom),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        setState(() {
          _livreSelectionne = livre;
        });
      },
    );
  }

  // ===================================================
  // ÉTAPE 2 : Grille des chapitres pour le livre choisi
  // ===================================================
  Widget _buildGrilleChapitres() {
    final livre = _livreSelectionne!;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: livre.nbChapitres,
      itemBuilder: (context, index) {
        final chapitre = index + 1;
        return InkWell(
          onTap: () => _ouvrirChapitre(livre, chapitre),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '$chapitre',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  // ===================================================
  // ÉTAPE 3 : Lecture du chapitre (liste des versets)
  // ===================================================
  Widget _buildLectureChapitre() {
    if (_loadingVersets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorVersets != null) {
      return _buildErreur(
        _errorVersets!,
            () => _ouvrirChapitre(_livreSelectionne!, _chapitreSelectionne!),
      );
    }

    if (_versets.isEmpty) {
      return Center(
        child: Text(
          _language == 'fr' ? 'Aucun verset trouvé.' : 'No verses found.',
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            _aUneSelection ? 180 : 16,
          ),
          itemCount: _versets.length,
          itemBuilder: (context, index) {
            final verset = _versets[index];
            final numeroVerset = verset.reference.split(':').last;
            final selectionne = _estSelectionne(index);

            return InkWell(
              onTap: () => _onTapVerset(index),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: selectionne
                      ? Colors.brown.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(
                      fontSize: 17,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: '$numeroVerset  ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectionne
                              ? Colors.brown.shade700
                              : Colors.grey,
                        ),
                      ),
                      TextSpan(text: verset.text),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_aUneSelection) _buildBarreActionsSelection(),
      ],
    );
  }

  // ===================================================
  // Barre d'actions flottante quand des versets sont sélectionnés
  // ===================================================
  Widget _buildBarreActionsSelection() {
    final versetsChoisis = _versetsSelectionnes();
    final nb = versetsChoisis.length;

    final referenceComplete = versetsChoisis.isNotEmpty
        ? _construireReferenceComplete(versetsChoisis)
        : '';

    final library = Provider.of<VerseLibrary>(context, listen: true);

    final verseExistant = versetsChoisis.isNotEmpty
        ? _trouverVerseParReference(library, referenceComplete)
        : null;

    final estDejaEnregistre = verseExistant != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Nombre de versets sélectionnés + fermeture
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nb == 1
                          ? (_language == 'fr'
                          ? '1 verset sélectionné'
                          : '1 verse selected')
                          : (_language == 'fr'
                          ? '$nb versets sélectionnés'
                          : '$nb verses selected'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip: _language == 'fr' ? 'Annuler' : 'Cancel',
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _effacerSelection,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ─────────────────────────────────────────
              // Ligne 1 : Note + Enregistrer
              // ─────────────────────────────────────────

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _prendreNoteSurVerset(versetsChoisis),
                      icon: const Icon(
                        Icons.edit_note,
                        size: 19,
                      ),
                      label: Text(
                        _language == 'fr' ? 'Note' : 'Note',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: estDejaEnregistre
                          ? null
                          : () => _enregistrerPassage(
                        versetsChoisis,
                      ),
                      icon: Icon(
                        estDejaEnregistre
                            ? Icons.check_circle
                            : Icons.bookmark_border,
                        size: 19,
                      ),
                      label: Text(
                        estDejaEnregistre
                            ? (_language == 'fr'
                            ? 'Enregistré'
                            : 'Saved')
                            : (_language == 'fr'
                            ? 'Enregistrer'
                            : 'Save'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ─────────────────────────────────────────
              // Ligne 2 : S'entraîner + Mémoriser
              // ─────────────────────────────────────────

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _lancerEntrainement(versetsChoisis),
                      icon: const Icon(
                        Icons.gamepad_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _language == 'fr'
                            ? "S'entraîner"
                            : 'Practice',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _handleMemoriser(versetsChoisis),
                      icon: const Icon(
                        Icons.school,
                        size: 18,
                      ),
                      label: Text(
                        _language == 'fr'
                            ? 'Mémoriser'
                            : 'Memorize',
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // Actions déclenchées depuis la sélection
  // (branchements réels à faire selon tes écrans de jeu / bibliothèque)
  // ===================================================
  String _construireReferenceComplete(List<VerseData> versets) {
    final livre = _livreSelectionne!.nom;
    final chapitre = _chapitreSelectionne;
    final premierNumero = versets.first.reference.split(':').last;
    final dernierNumero = versets.last.reference.split(':').last;
    return premierNumero == dernierNumero
        ? '$livre $chapitre:$premierNumero'
        : '$livre $chapitre:$premierNumero-$dernierNumero';
  }

  // Note importante : on utilise volontairement le mode sandbox ici.
  // "S'entraîner" ne touche jamais à VerseLibrary — c'est le rôle de
  // "Mémoriser" (_handleMemoriser) qui, lui, passe par le vrai Verse et
  // VerseDetailPage pour respecter progressLevel/srsLevel et la séquence
  // officielle qcm → texte_a_trous → ordre → dictee → recitation.
  void _lancerEntrainement(List<VerseData> versets) {
    if (versets.isEmpty) return;
    final referenceComplete = _construireReferenceComplete(versets);

    print("🎮 Lancer entraînement (sandbox) sur : $referenceComplete");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PageDeJeuPrincipale(initialReference: referenceComplete),
      ),
    );
  }

  Future<void> _enregistrerPassage(
      List<VerseData> versets,
      ) async {
    if (versets.isEmpty) return;

    final referenceComplete =
    _construireReferenceComplete(versets);

    final livre = _livreSelectionne!.nom;

    final library =
    Provider.of<VerseLibrary>(
      context,
      listen: false,
    );

    // Vérifier s'il existe déjà
    final existant =
    _trouverVerseParReference(
      library,
      referenceComplete,
    );

    if (existant != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? '$referenceComplete est déjà enregistré.'
                : '$referenceComplete is already saved.',
          ),
        ),
      );

      return;
    }

    try {
      // Catégorie vide :
      // le passage sera regroupé par livre
      // et aucun parcours de mémorisation ne démarre.
      await library.addVerse(
        referenceComplete,
        livre,
        '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? '$referenceComplete enregistré dans votre bibliothèque.'
                : '$referenceComplete saved to your library.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _effacerSelection();
    } catch (e) {
      debugPrint(
        '❌ Erreur enregistrement passage : $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? "Impossible d'enregistrer le passage."
                : 'Unable to save the passage.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _prendreNoteSurVerset(
      List<VerseData> versets,
      ) async {
    if (versets.isEmpty) return;

    final referenceComplete =
    _construireReferenceComplete(versets);

    final controller = TextEditingController();

    final contenu = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                _language == 'fr'
                    ? 'Ma note'
                    : 'My note',
              ),
              const SizedBox(height: 4),
              Text(
                referenceComplete,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),

          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 7,
            minLines: 4,
            decoration: InputDecoration(
              hintText: _language == 'fr'
                  ? 'Écrivez ce que ce passage vous inspire...'
                  : 'Write what this passage means to you...',
              border: const OutlineInputBorder(),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                    null,
                  ),
              child: Text(
                _language == 'fr'
                    ? 'Annuler'
                    : 'Cancel',
              ),
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () {
                final texte =
                controller.text.trim();

                if (texte.isEmpty) return;

                Navigator.pop(
                  dialogContext,
                  texte,
                );
              },
              label: Text(
                _language == 'fr'
                    ? 'Enregistrer'
                    : 'Save',
              ),
            ),
          ],
        );
      },
    );

    if (contenu == null ||
        contenu.trim().isEmpty ||
        !mounted) {
      return;
    }

    // Dans main.dart, ton PrayerNotesProvider
    // peut être nullable lorsque l'utilisateur
    // n'est pas connecté.
    final notesProvider =
    Provider.of<PrayerNotesProvider>(
      context,
      listen: false,
    );


    final noteId =
    await notesProvider.createNote(
      type: NoteType.meditation,
      content: contenu.trim(),
      verseReference: referenceComplete,
      tags: const ['Bible'],
    );

    if (!mounted) return;

    if (noteId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? 'Note enregistrée pour $referenceComplete.'
                : 'Note saved for $referenceComplete.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _effacerSelection();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? "Erreur lors de l'enregistrement de la note."
                : 'Error saving the note.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Bouton "Mémoriser" — le vrai parcours de progression.
  // - Si le passage est déjà dans VerseLibrary → on ouvre directement
  //   VerseDetailPage, qui décide lui-même (neutral/learning/mastered).
  // - Sinon → on l'ajoute via addVerse(), on récupère le Verse créé, puis
  //   on ouvre VerseDetailPage, qui démarre alors _startLearning() lui-même.
  // Aucune logique de progressLevel/srsLevel n'est dupliquée ici.
  Future<void> _handleMemoriser(List<VerseData> versets) async {
    if (versets.isEmpty) return;

    final livre = _livreSelectionne!.nom;
    final referenceComplete = _construireReferenceComplete(versets);

    // On récupère VerseLibrary juste avant chaque utilisation, plutôt que
    // de garder une seule référence à travers l'await du dialog : si le
    // Provider est recréé entre-temps (ex: rebuild de HomePage déclenché
    // par _listenToInvitations), l'ancienne référence serait "disposed".
    var library = Provider.of<VerseLibrary>(context, listen: false);
    final verseExistant = _trouverVerseParReference(library, referenceComplete);

    if (verseExistant != null) {
      print("📖 Déjà dans la bibliothèque, ouverture directe : $referenceComplete");
      _ouvrirVerseDetail(verseExistant);
      return;
    }

    // Pas encore enregistré : demander la catégorie puis créer le Verse
    final categorie = await _demanderCategorie();
    if (categorie == null) return; // Annulé par l'utilisateur

    if (!mounted) return;
    // Re-récupère la référence après l'attente du dialog, au cas où le
    // Provider aurait été recréé pendant ce délai.
    library = Provider.of<VerseLibrary>(context, listen: false);

    try {
      await library.addVerse(referenceComplete, livre, categorie);
      final verseCree = _trouverVerseParReference(library, referenceComplete);

      if (verseCree == null) {
        print("❌ Verse introuvable juste après addVerse : $referenceComplete");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _language == 'fr'
                  ? "Erreur : verset introuvable après l'ajout."
                  : "Error: verse not found after adding.",
            ),
          ),
        );
        return;
      }

      print("✅ Ajouté et parcours démarré : $referenceComplete ($categorie)");
      _ouvrirVerseDetail(verseCree);
    } catch (e) {
      print("❌ ERREUR dans _handleMemoriser : $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _language == 'fr'
                ? "Erreur lors de l'ajout à la bibliothèque."
                : "Error adding to library.",
          ),
        ),
      );
    }
  }

  Verse? _trouverVerseParReference(VerseLibrary library, String reference) {
    final tousLesVersets =
    library.myVerseCategories.expand((cat) => cat.verses).toList();
    for (final v in tousLesVersets) {
      if (v.reference == reference) return v;
    }
    return null;
  }

  void _ouvrirVerseDetail(Verse verse) {
    _effacerSelection();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerseDetailPage(verse: verse)),
    );
  }

  Future<String?> _demanderCategorie() async {
    final library = Provider.of<VerseLibrary>(context, listen: false);

    // Catégories recommandées
    final recommendedCategories =
    library.recommendedCategories.map((c) => c.name);

    // Catégories déjà utilisées par l'utilisateur
    final userCategories = library.myVerseCategories
        .expand((category) => category.verses)
        .map((verse) => verse.category)
        .whereType<String>()
        .where((category) => category.trim().isNotEmpty);

    // Fusion sans doublons
    final categories = {
      ...recommendedCategories,
      ...userCategories,
    }.toList()
      ..sort();

    final controller = TextEditingController();
    String? selectedCategory;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                _language == 'fr'
                    ? 'Choisir une catégorie'
                    : 'Choose a category',
              ),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText:
                      _language == 'fr' ? 'Catégorie' : 'Category',
                      border: const OutlineInputBorder(),
                    ),

                    hint: Text(
                      _language == 'fr'
                          ? 'Sélectionner une catégorie'
                          : 'Select a category',
                    ),

                    items: [
                      ...categories.map(
                            (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      DropdownMenuItem<String>(
                        value: '__new__',
                        child: Text(
                          _language == 'fr'
                              ? '+ Nouvelle catégorie'
                              : '+ New category',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ),
                    ],

                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value;

                        if (value == '__new__') {
                          controller.clear();
                        }
                      });
                    },
                  ),

                  if (selectedCategory == '__new__') ...[
                    const SizedBox(height: 16),

                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: _language == 'fr'
                            ? 'Nouvelle catégorie'
                            : 'New category',
                        hintText: _language == 'fr'
                            ? 'Ex: Promesses de Dieu'
                            : 'E.g: God\'s promises',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(
                    _language == 'fr' ? 'Annuler' : 'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: selectedCategory == null
                      ? null
                      : () {
                    if (selectedCategory == '__new__') {
                      final nouvelleCategorie =
                      controller.text.trim();

                      if (nouvelleCategorie.isEmpty) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        nouvelleCategorie,
                      );
                    } else {
                      Navigator.pop(
                        dialogContext,
                        selectedCategory,
                      );
                    }
                  },
                  child: Text(
                    _language == 'fr' ? 'Continuer' : 'Continue',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===================================================
  // Widget d'erreur réutilisable
  // ===================================================
  Widget _buildErreur(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(_language == 'fr' ? 'Réessayer' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
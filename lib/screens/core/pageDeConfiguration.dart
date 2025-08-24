import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../services/Bible_service.dart';
import '../games/dictee_page.dart';
import '../../widgets/main_drawer.dart';
import '../games/remettre_ordre_page.dart';
import '../games/recitation_page.dart';
import '../../models/verse_model.dart';

// ✅ MODIFIÉ : Assurez-vous que ces imports pointent vers vos fichiers de jeu réels
import '../../Bibliotheque.dart';

import '../games/jeu_trous.dart';
import '../games/QcmPage.dart';
import '../games/QcmAleatoirePage.dart';
 // Assurez-vous que le chemin est correct


// = an====================================================================
// PAGE DE CONFIGURATION
// Cette page gère maintenant uniquement la configuration et la navigation vers les jeux.
// =======================================================================

enum GameMode { texteATrous, qcm,remettreEnOrdre ,dictee,recitation}

class PageDeJeuPrincipale extends StatefulWidget {
  final String? initialReference;
  const PageDeJeuPrincipale({Key? key, this.initialReference}) : super(key: key);
  @override
  _PageDeJeuPrincipaleState createState() => _PageDeJeuPrincipaleState();
}

class _PageDeJeuPrincipaleState extends State<PageDeJeuPrincipale> {
  // --- État de Configuration ---
  List<String> books = [
    "Genèse",
    "Exode",
    "Lévitique",
    "Nombres",
    "Deutéronome",
    "Josué",
    "Juges",
    "Ruth",
    "1 Samuel",
    "2 Samuel",
    "1 Rois",
    "2 Rois",
    "1 Chroniques",
    "2 Chroniques",
    "Esdras",
    "Néhémie",
    "Esther",
    "Job",
    "Psaume",
    "Proverbes",
    "Ecclésiaste",
    "Cantique des Cantiques",
    "Ésaïe",
    "Jérémie",
    "Lamentations",
    "Ézéchiel",
    "Daniel",
    "Osée",
    "Joël",
    "Amos",
    "Abdias",
    "Jonas",
    "Michée",
    "Nahum",
    "Habacuc",
    "Sophonie",
    "Aggée",
    "Zacharie",
    "Malachie",
    "Matthieu",
    "Marc",
    "Luc",
    "Jean",
    "Actes",
    "Romains",
    "1 Corinthiens",
    "2 Corinthiens",
    "Galates",
    "Éphésiens",
    "Philippiens",
    "Colossiens",
    "1 Thessaloniciens",
    "2 Thessaloniciens",
    "1 Timothée",
    "2 Timothée",
    "Tite",
    "Philémon",
    "Hébreux",
    "Jacques",
    "1 Pierre",
    "2 Pierre",
    "1 Jean",
    "2 Jean",
    "3 Jean",
    "Jude",
    "Apocalypse",
  ];
  String? selectedBook;
  final TextEditingController chapitreController = TextEditingController();
  final TextEditingController versetController = TextEditingController();
// ✅ On restaure la variable pour le verset de fin
  int versetFin = 0;
  GameMode selectedGameMode = GameMode.texteATrous;
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    // On charge les livres, puis on traite la référence initiale si elle existe.
    _chargerLivresDepuisJson().then((_) {
      if (widget.initialReference != null) {
        _parseAndSetInitialReference(widget.initialReference!);
      }
    });
  }
  /// ✅ NOUVEAU : Analyse la référence reçue et pré-remplit les champs.
  void _parseAndSetInitialReference(String reference) {
    // Regex pour extraire : 1. le livre, 2. le chapitre, 3. le verset
    final regExp = RegExp(r"^(\d?\s?[a-zA-Z\s]+)\s(\d+):(\d+)");
    final match = regExp.firstMatch(reference.trim());

    if (match != null) {
      final bookName = match.group(1)!.trim();
      final chapter = match.group(2)!;
      final verse = match.group(3)!;

      setState(() {
        if (books.contains(bookName)) {
          selectedBook = bookName;
        }
        chapitreController.text = chapter;
        versetController.text = verse;

      });
    }
  }

  Future<void> _chargerLivresDepuisJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);
      final Set<String> livresUniques = data.map((item) => item['book_name'] as String).toSet();

      if (mounted) {
        setState(() {
          books = ["Tous les livres", ...livresUniques.toList()..sort()];
          selectedBook = "Jean";
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBooks = false);
        // _afficherMessageErreur("Impossible de charger la liste des livres.");
      }
    }
  }

  // ✅ MODIFIÉ : La logique de lancement est maintenant plus simple et plus directe.
  // Elle envoie toujours la référence complète à la page de jeu.
  // Dans _PageDeJeuPrincipaleState

// ✅ VERSION FINALE POUR LE JEU LIBRE UNIQUEMENT
  void _lancerPartie() async {
    // --- 1. On construit la référence comme avant ---
    // (La logique pour le jeu "Référence" et les cas spéciaux reste la même)
    int? chapitre = int.tryParse(chapitreController.text.trim());
    if (selectedBook == null || selectedBook == "Tous les livres" || chapitre == null) {
      _afficherMessageErreur("Pour ce jeu, le livre et le chapitre sont requis.");
      return;
    }
    int? versetDebut = int.tryParse(versetController.text.trim());
    String referenceActuelle;

    if (versetDebut == null) {
      referenceActuelle = "$selectedBook $chapitre";
    } else {
      // ✅ On utilise directement la variable d'état 'versetFin'
      int versetFinFinal = versetFin > 0 ? versetFin : versetDebut;

      if (versetDebut != versetFinFinal) {
        referenceActuelle = "$selectedBook $chapitre:$versetDebut-$versetFinFinal";
      } else {
        referenceActuelle = "$selectedBook $chapitre:$versetDebut";
      }
    }

    // --- 2. On crée un objet Verse TEMPORAIRE ---
    // Cet objet n'est pas sauvegardé, il sert juste à passer les infos à la page de jeu.
    final temporaryVerse = Verse(
      id: referenceActuelle,
      reference: referenceActuelle,
      book: selectedBook!,
      status: VerseStatus.neutral, // Le statut n'a pas d'importance ici
      progressLevel: 0,
      scores: {},
      isUserAdded: false,
      updatedAt: null,
      failedAttempts: {},
      srsLevel: 0,
      reviewDate: null,
    );

    // --- 3. On lance le jeu en mode SANDBOX ---
    // On passe le Verse temporaire et on met isSandbox à TRUE.
    switch (selectedGameMode) {
      case GameMode.qcm:
        Navigator.push(context, MaterialPageRoute(builder: (context) => QcmGamePage(verse: temporaryVerse, isSandbox: true)));
        break;
      case GameMode.texteATrous:
        Navigator.push(context, MaterialPageRoute(builder: (context) => TexteATrousPage(verse: temporaryVerse, isSandbox: true)));
      break;
      case GameMode.remettreEnOrdre:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RemettreOrdrePage(verse: temporaryVerse, isSandbox: true)));
        break;
      case GameMode.dictee:
        Navigator.push(context, MaterialPageRoute(builder: (context) => DicteePage(verse: temporaryVerse, isSandbox: true)));
        break;
      case GameMode.recitation:
        Navigator.push(context, MaterialPageRoute(builder: (context) => RecitationPage(verse: temporaryVerse, isSandbox: true)));
        break;

    // ... faites de même pour toutes vos autres pages de jeu

    // Le cas "Référence" reste un cas spécial

      default:
        _afficherMessageErreur("Ce mode de jeu n'est pas encore connecté.");
    }
  }


  // void _ouvrirBibliotheque() {
  //   Navigator.push(context, MaterialPageRoute(builder: (context) => VerseLibraryPage()));
  // }



  void _afficherMessageErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent)
    );
  }

  @override
  void dispose() {
    chapitreController.dispose();
    versetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Jeu Libre "),
        // Gardons une couleur de marque
        elevation: 0,
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildVueConfiguration(),
        ),
      ),
    );
  }
  Widget _buildVueConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Étape 1 : Choix du mode de jeu ---
        Text("1. Choisissez un mode de jeu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo),),
        const SizedBox(height: 16),
        Wrap(
          // Espacement horizontal entre les boutons
          spacing: 12.0,
          // Espacement vertical entre les lignes
          runSpacing: 12.0,

          children: GameMode.values.map((gameMode) {
            return ChoiceChip(
              // L'icône du jeu
              avatar: Icon(
                gameMode == GameMode.texteATrous ? Icons.edit :
                gameMode == GameMode.qcm ? Icons.check_circle_outline:
                gameMode == GameMode.remettreEnOrdre ? Icons.swap_horiz:
                gameMode == GameMode.dictee ? Icons.hearing :
                Icons.mic,
                color: selectedGameMode == gameMode ? Colors.white : Colors.black54,

              ),
              // Le nom du jeu
              label: Text(
                gameMode == GameMode.texteATrous ? 'Texte à trous' :
                gameMode == GameMode.qcm ? 'QCM' :
                gameMode == GameMode.remettreEnOrdre ? 'Ordre' :
                gameMode == GameMode.dictee ? 'Dictée' :
                'Récitation',
                style: TextStyle(
                  color: selectedGameMode == gameMode ? Colors.white : Colors.black,
                ),
              ),

              // Apparence du chip
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

              // Logique de sélection
              selected: selectedGameMode == gameMode,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (isSelected) {
                if (isSelected) {
                  setState(() {
                    selectedGameMode = gameMode;
                  });
                }
              },
            );
          }).toList(),
        ),
        const Divider(height: 32),

        // --- Étape 2 : Configuration (s'adapte au mode de jeu) ---
        Text(
          '2. Choisissez votre passage',
          // --- TITRE MODIFIÉ ---
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo),
        ),

        const SizedBox(height: 16),

        // Le Dropdown pour le livre est toujours visible

        if (_isLoadingBooks)
          const Center(child: CircularProgressIndicator())
        else
    DropdownButtonFormField<String>(
    decoration: _inputDecoration('Livre'),
              value: selectedBook,
              isExpanded: true,
              items: books.map((book) => DropdownMenuItem(value: book, child: Text(book))).toList(),
              onChanged: (value) { if (value != null) setState(() => selectedBook = value); }
          ),
        const SizedBox(height: 16),

        // ✅ Ces champs ne s'affichent que pour les jeux à référence

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TextField(
              controller: chapitreController,
              decoration: _inputDecoration('Chapitre', hint: 'Ex: 23'),
            keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      // On utilise le contrôleur unique
                      controller: versetController,
                      decoration: _inputDecoration('Verset de début'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      // ✅ ON N'UTILISE PAS DE CONTRÔLEUR ICI
                      decoration: _inputDecoration('Fin (facultatif)'),
                      keyboardType: TextInputType.number,
                      // ✅ on utilise onChanged pour mettre à jour la variable
                      onChanged: (value) {
                        setState(() {
                          // On convertit le texte en nombre et on le stocke dans versetFin
                          versetFin = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),



        const SizedBox(height: 32),

        // --- Étape 3 : Lancer la partie ---
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text("JOUER"),
            onPressed: _lancerPartie,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600], // Un vert plus sobre

              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),

            ),
          ),
        ),
        const SizedBox(height: 20), // Espace entre les boutons
        // Center(
        //   child: ElevatedButton.icon(
        //     icon: const Icon(Icons.library_books),
        //     label: const Text("Bibliothèque"),
        //     onPressed: _ouvrirBibliotheque,
        //     style: ElevatedButton.styleFrom(
        //         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
        //   ),
        // ),
      ],
    );
  }
  // --- CHAMPS DE SAISIE MODIFIÉS ---
  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}


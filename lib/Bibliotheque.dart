// Fichier : lib/bibliotheque_page.dart

import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/screens/verse/verse_detail_page.dart';
import 'package:memoriz_bible/widgets/main_drawer.dart';
import '../../widgets/stats_card_widget.dart';
import '../../models/verse_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// =======================================================================
// Les anciens modèles de données (Verse, VerseStatus, VerseCategory) sont SUPPRIMÉS de ce fichier.
// La classe VerseCategory est conservée car elle est utile pour l'organisation UI.
// =======================================================================

class VerseCategory {
  final String name;
  final List<Verse> verses; // Utilise maintenant le modèle Verse centralisé
  VerseCategory({required this.name, required this.verses});
}

class RecommendedCategory {
  final String name;
  final List<String> verses; // Les recommandations sont de simples chaînes de caractères
  RecommendedCategory({required this.name, required this.verses});
}

// =======================================================================
// 2. LE "STORE" (GESTION DE L'ÉTAT) CONNECTÉ À FIRESTORE
// =======================================================================

class VerseLibrary extends ChangeNotifier {
  // "Ma Bibliothèque" - Les versets personnels de l'utilisateur
  List<VerseCategory> myVerseCategories = [];

  // "Recommandés" - Le catalogue public de l'application
  List<RecommendedCategory> recommendedCategories = [];

  bool isLoading = true;
  final String? userId;


  // ✅ NOUVEAU : Getter pour le nombre total de versets maîtrisés
  int get totalMasteredCount {
    if (isLoading) return 0;
    // On parcourt toutes les catégories et on additionne les versets maîtrisés
    return myVerseCategories
        .expand((category) => category.verses)
        .where((verse) => verse.status == VerseStatus.mastered)
        .length;
  }

  // ✅ NOUVEAU : Getter pour le nombre total de versets en cours
  int get totalInProgressCount {
    if (isLoading) return 0;
    return myVerseCategories
        .expand((category) => category.verses)
        .where((verse) => verse.status == VerseStatus.learning)
        .length;
  }
  VerseLibrary(this.userId) {
    // On ne charge les données que si un utilisateur est connecté
    if (userId != null && userId!.isNotEmpty) {
      _loadAllData();
    } else {
      isLoading = false;
      myVerseCategories = [];
      recommendedCategories = []; // Assurez-vous d'initialiser toutes les listes
    }
  }

  Future<void> _loadAllData() async {
    isLoading = true;
    notifyListeners();

    // Charge les deux listes en parallèle pour plus d'efficacité
    await Future.wait([
      _loadMyVersesFromFirestore(),
      _loadRecommendedCategories(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> handleVerseReview(Verse verse, {required bool wasSuccessful}) async {
    // 1. Définir les intervalles de révision en jours.
    // Vous pouvez ajuster ces valeurs pour rendre la mémorisation plus ou moins intensive.
    final List<int> srsIntervals = [1, 3, 7, 16, 35, 75, 180];

    int newSrsLevel = verse.srsLevel;
    DateTime nextReviewDate;

    if (wasSuccessful) {
      // --- CAS SUCCÈS ---
      // L'utilisateur s'en souvenait : on augmente le niveau et l'intervalle.
      newSrsLevel++;

      // On s'assure de ne pas dépasser la taille de notre liste d'intervalles.
      if (newSrsLevel >= srsIntervals.length) {
        newSrsLevel = srsIntervals.length - 1;
      }

      final int daysToAdd = srsIntervals[newSrsLevel];
      nextReviewDate = DateTime.now().add(Duration(days: daysToAdd));

    } else {
      // --- CAS ÉCHEC ---
      // L'utilisateur avait oublié : on réinitialise le niveau pour une révision rapide.
      newSrsLevel = 0; // On repart du début
      nextReviewDate = DateTime.now().add(const Duration(days: 1)); // Révision demain
    }

    // 2. Mettre à jour les données dans Firestore
    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(verse.id);
    await docRef.update({
      'srsLevel': newSrsLevel,
      'reviewDate': Timestamp.fromDate(nextReviewDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Rafraîchir les données locales pour que l'UI se mette à jour
    await _loadMyVersesFromFirestore();
    notifyListeners();
    print("Révision traitée pour ${verse.reference}. Prochaine révision le: $nextReviewDate");
  }


  Future<void> _loadMyVersesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users/$userId/verses')
        .get();

    final userVerses = snapshot.docs.map((doc) => Verse.fromFirestore(doc)).toList();

    // Organiser les versets par livre/catégorie
    final Map<String, List<Verse>> versesByBook = {};
    for (var verse in userVerses) {
      (versesByBook[verse.book] ??= []).add(verse);
    }
    myVerseCategories = versesByBook.entries.map((entry) {
      return VerseCategory(name: entry.key, verses: entry.value);
    }).toList();
  }

  Future<void> _loadRecommendedCategories() async {
    // Cette méthode charge la liste "en dur" pour l'onglet des recommandations
    final List<Map<String, dynamic>> data = [
      {
        "category": "Les Fondamentaux de la Foi",
        "verses": [
          "Jean 3:16",
          "Romains 3:23",
          "Romains 6:23",
          "Éphésiens 2:8-9",
          "Jean 14:6"
        ]
      },
      {
        "category": "Réconfort et Paix",
        "verses": [
          "Psaumes 23:1-4",
          "Philippiens 4:6-7",
          "Matthieu 11:28",
          "Jean 14:27",
          "Ésaïe 41:10"
        ]
      },
      {
        "category": "Confiance en Dieu",
        "verses": [
          "Proverbes 3:5-6",
          "Jérémie 29:11",
          "Josué 1:9",
          "Psaumes 37:5",
          "Hébreux 13:5"
        ]
      },
      {
        "category": "Amour et Relations",
        "verses": [
          "1 Corinthiens 13:4-7",
          "Jean 13:34-35",
          "1 Jean 4:7-8",
          "Éphésiens 4:2-3",
          "Colossiens 3:13-14"
        ]
      },
      {
        "category": "Espoir et Encouragement",
        "verses": [
          "Romains 8:28",
          "Ésaïe 40:31",
          "2 Corinthiens 12:9",
          "Psaumes 121:1-2",
          "Hébreux 11:1"
        ]
      },
      {
        "category": "Force dans l'Épreuve",
        "verses": [
          "Philippiens 4:13",
          "Ésaïe 40:29-31",
          "2 Timothée 1:7",
          "Psaumes 46:1",
          "1 Pierre 5:7"
        ]
      },
      {
        "category": "La Prière",
        "verses": [
          "Matthieu 6:9-13", // Notre Père
          "1 Thessaloniciens 5:16-18",
          "Marc 11:24",
          "Jérémie 33:3",
          "Philippiens 4:6"
        ]
      },
      {
        "category": "La Sagesse",
        "verses": [
          "Jacques 1:5",
          "Proverbes 1:7",
          "Proverbes 9:10",
          "Psaumes 119:105",
          "Colossiens 3:16"
        ]
      },
      {
        "category": "La Vie Chrétienne",
        "verses": [
          "Galates 2:20",
          "Matthieu 5:14-16",
          "Romains 12:1-2",
          "2 Corinthiens 5:17",
          "Colossiens 3:23"
        ]
      },
      {
        "category": "Promesses de Dieu",
        "verses": [
          "Deutéronome 31:6",
          "Psaumes 91:1-2",
          "Jean 10:28-29",
          "2 Corinthiens 1:20",
          "Apocalypse 21:4"
        ]
      }
    ];

    recommendedCategories = data.map((d) => RecommendedCategory(
        name: d['category'],
        verses: List<String>.from(d['verses'])
    )).toList();
  }

  Future<void> addVerse(String reference, String categoryName) async {
    final newVerseId = reference; // Utilise la référence comme ID
    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(newVerseId);

    final newVerse = Verse(
      id: newVerseId,
      reference: reference,
      status: VerseStatus.neutral, // Le statut par défaut est bien 'neutral'
      progressLevel: 0,
      scores: {},
      isUserAdded: true,
      book: categoryName, // ou extraire le livre depuis la référence
      updatedAt: null,
      failedAttempts: {},
      srsLevel: 0,
      reviewDate: null,
    );

    await docRef.set(newVerse.toFirestore());
    await _loadMyVersesFromFirestore(); // Recharge les données pour mettre à jour l'UI
    notifyListeners();
  }
  // Dans la classe VerseLibrary de bibliotheque_page.dart

  Future<void> onGameFinished({
    required Verse verse,
    required String gameMode,
    required int score,
  }) async {
    final int minScoreToPass = 70;
    final gameSequence = ["qcm", "texte_a_trous", "ordre", "dictee", "recitation"];

    final updatedScores = Map<String, int>.from(verse.scores);
    final updatedFailedAttempts = Map<String, int>.from(verse.failedAttempts);

    updatedScores[gameMode] = score;

    int newProgressLevel = verse.progressLevel;
    VerseStatus newStatus = verse.status;

    // --- LOGIQUE DE RÉTROGRADATION ---
    if (gameMode == "recitation" && score < minScoreToPass) {
      int currentFails = (updatedFailedAttempts['recitation'] ?? 0) + 1;
      updatedFailedAttempts['recitation'] = currentFails;

      if (currentFails >= 3) {
        // RÉTROGRADATION !
        newProgressLevel = 2; // Index du jeu "ordre"
        updatedFailedAttempts['recitation'] = 0;
        updatedScores.remove('dictee');
        updatedScores.remove('recitation');
      }
    }
    // --- LOGIQUE DE PROGRESSION NORMALE ---
    else if (score >= minScoreToPass) {
      updatedFailedAttempts[gameMode] = 0;

      int currentLevel = 0;
      for (final game in gameSequence) {
        if ((updatedScores[game] ?? 0) >= minScoreToPass) {
          currentLevel++;
        } else {
          break;
        }
      }
      newProgressLevel = currentLevel;
      if (newProgressLevel == gameSequence.length) {
        newStatus = VerseStatus.mastered;
      }
    }

    // Mise à jour de la base de données
    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(verse.id);
    await docRef.update({
      'scores': updatedScores,
      'failedAttempts': updatedFailedAttempts,
      'progressLevel': newProgressLevel,
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _loadMyVersesFromFirestore();
    notifyListeners();
  }

  Future<void> removeVerse(String verseId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users/$userId/verses')
        .doc(verseId)   // ✅ c’est bien l’ID du verset à supprimer
        .delete();

    // Recharge la bibliothèque pour mettre à jour l'UI
    await _loadMyVersesFromFirestore();
    notifyListeners();
  }
}

// =======================================================================
// 3. L'INTERFACE UTILISATEUR (LA PAGE) AVEC ONGLETS
// =======================================================================

class VerseLibraryPage extends StatefulWidget {
  final VerseStatus? initialFilter;
  const VerseLibraryPage({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<VerseLibraryPage> createState() => _VerseLibraryPageState();
}

class _VerseLibraryPageState extends State<VerseLibraryPage> {
  late VerseStatus? _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Bibliothèque"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Ma Bibliothèque", icon: Icon(Icons.person)),
              Tab(text: "Recommandés", icon: Icon(Icons.star)),
            ],
          ),
        ),
        drawer: const MainDrawer(),
        body: Consumer<VerseLibrary>(
          builder: (context, library, child) {
            if (library.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _buildMaBibliothequeTab(library),
                _buildRecommandesTab(library),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddVerseDialog(context),
          child: const Icon(Icons.add),
          tooltip: 'Ajouter un verset personnel',
        ),
      ),
    );
  }

  Widget _buildMaBibliothequeTab(VerseLibrary library) {
    // --- 1. Préparation des données ---
    // On récupère tous les versets une seule fois pour les calculs
    final allVerses = library.myVerseCategories
        .expand((cat) => cat.verses)
        .toList();

    // On calcule les totaux pour les cartes de statistiques
    final learningCount = allVerses
        .where((v) => v.status == VerseStatus.learning)
        .length;
    final masteredCount = allVerses
        .where((v) => v.status == VerseStatus.mastered)
        .length;

    // On filtre la liste complète en fonction du filtre actuel
    final filteredVerses = allVerses.where((verse) {
      if (_currentFilter == null)
        return true; // Si aucun filtre, on montre tout
      return verse.status == _currentFilter;
    }).toList();

    // On regroupe les versets filtrés par catégorie (livre) pour les ExpansionTiles
    final groupedFilteredVerses = <String, List<Verse>>{};
    for (var verse in filteredVerses) {
      (groupedFilteredVerses[verse.book] ??= []).add(verse);
    }

    // --- 2. Construction de l'interface ---
    // La racine est un ListView pour que tout soit scrollable ensemble
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Section des statistiques ---
        Text("Mes Statistiques", style: Theme
            .of(context)
            .textTheme
            .headlineSmall),
        const SizedBox(height: 16),
        // ✅ Affichez simplement le widget ici aussi
        const StatsCardWidget(),

        const SizedBox(height: 24),
        const Divider(),

        const SizedBox(height: 16),

        // --- Section de la liste des versets ---
        Text("Mes Versets", style: Theme
            .of(context)
            .textTheme
            .headlineSmall),
        const SizedBox(height: 16),

        // --- Filtres ---
        SegmentedButton<VerseStatus?>(
          segments: const [
            ButtonSegment(value: null, label: Text("Tout")),
            // Option pour tout voir
            ButtonSegment(value: VerseStatus.learning, label: Text("En cours")),
            ButtonSegment(value: VerseStatus.mastered, label: Text("Connus")),
          ],
          selected: {_currentFilter},
          onSelectionChanged: (newSelection) {
            setState(() => _currentFilter = newSelection.first);
          },
        ),
        const SizedBox(height: 24),

        // --- Affichage de la liste ou d'un message si vide ---
        if (groupedFilteredVerses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("Aucun verset ne correspond à ce filtre.",
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...groupedFilteredVerses.entries.map((entry) {
            final categoryName = entry.key;
            final versesInCategory = entry.value;
            return ExpansionTile(
              title: Text(categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: true, // Garder les tuiles ouvertes
              children: versesInCategory.map((verse) {
                return ListTile(
                  title: Text(verse.reference),
                  trailing: Text("${verse.progressLevel}/5"),
                  leading: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      context.read<VerseLibrary>().removeVerse(verse.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${verse
                              .reference} supprimé de votre bibliothèque"))
                      );
                    },
                  ),
                  // Exemple
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => VerseDetailPage(verse: verse)),
                    );
                  },
                );
              }).toList(),
            );
          }),
      ],
    );
  }

  // Dans la classe _VerseLibraryPageState

  Widget _buildRecommandesTab(VerseLibrary library) {
    // On aplatit la liste des versets de l'utilisateur pour une recherche facile
    final allUserVerses = library.myVerseCategories
        .expand((cat) => cat.verses)
        .toList();

    return ListView.builder(
      itemCount: library.recommendedCategories.length,
      itemBuilder: (context, index) {
        final category = library.recommendedCategories[index];
        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(category.name,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          children: category.verses.map((verseRef) {
            // On vérifie si ce verset recommandé est déjà dans la bibliothèque de l'utilisateur
            final existingVerse = allUserVerses.firstWhereOrNull((v) =>
            v.reference == verseRef);

            return ListTile(
              title: Text(verseRef),
              leading: const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Icon(Icons.article_outlined, size: 22),
              ),
              trailing: IconButton(
                icon: Icon(
                  existingVerse != null ? Icons.check_circle : Icons
                      .add_circle_outline,
                  color: existingVerse != null ? Colors.blueAccent : Colors
                      .green,
                ),
                onPressed: () {
                  if (existingVerse == null) {
                    context.read<VerseLibrary>().addVerse(
                        verseRef, category.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                          "$verseRef ajouté à votre bibliothèque !")),
                    );
                  }
                },
              ),
              // ✅ ON AJOUTE LA LOGIQUE DE CLIC ICI
              onTap: () {
                // S'il existe déjà, on l'utilise pour la navigation
                if (existingVerse != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                        VerseDetailPage(verse: existingVerse)),
                  );
                } else {
                  // Sinon, on crée un objet Verse temporaire pour l'affichage
                  final tempVerse = Verse(
                    id: verseRef,
                    // On utilise la référence comme ID temporaire
                    reference: verseRef,
                    book: category.name,
                    status: VerseStatus.neutral,
                    progressLevel: 0,
                    scores: {},
                    isUserAdded: false,
                    // Important : il n'est pas dans la bibliothèque
                    updatedAt: null,
                    failedAttempts: {},
                    srsLevel: 0,
                    reviewDate: null,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                        VerseDetailPage(verse: tempVerse)),
                  );
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  // La fonction _showAddVerseDialog reste utile pour l'ajout manuel
  // À placer dans la classe _VerseLibraryPageState de votre bibliotheque_page.dart

  void _showAddVerseDialog(BuildContext context) {
    final library = context.read<VerseLibrary>();
    final formKey = GlobalKey<FormState>();
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
    final chapitreController = TextEditingController();
    final versetDebutController = TextEditingController();
    int versetFin = 0;

    // ✅ Contrôleur pour la catégorie (champ libre + suggestions)
    final categoryController = TextEditingController();
    final suggestions = library.recommendedCategories.map((cat) => cat.name).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Ajouter un verset"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Titre ---
                  Text(
                    '1. Choisissez votre passage',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 16),

                  // --- Sélecteur du Livre ---
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Livre'),
                    value: selectedBook,
                    isExpanded: true,
                    items: books
                        .map((book) =>
                        DropdownMenuItem(value: book, child: Text(book)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedBook = value;
                      }
                    },
                    validator: (value) =>
                    value == null ? "Veuillez choisir un livre" : null,
                  ),
                  const SizedBox(height: 16),

                  // --- Chapitre ---
                  TextFormField(
                    controller: chapitreController,
                    decoration: _inputDecoration('Chapitre', hint: 'Ex: 23'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Le chapitre est requis";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- Versets (début + fin) ---
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: versetDebutController,
                          decoration: _inputDecoration('Verset de début'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Verset requis";
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDecoration('Fin (facultatif)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            versetFin = int.tryParse(value) ?? 0;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Champ Catégorie ---
                  Text(
                    '2. Catégorie',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),

                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.isEmpty) return suggestions;
                      return suggestions.where((cat) => cat
                          .toLowerCase()
                          .contains(value.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      categoryController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmit) {
                      categoryController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: _inputDecoration(
                            'Catégorie',
                            hint: "Ex: Confiance, Encouragement"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Une catégorie est requise";
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && selectedBook != null) {
                  final ref = versetFin > 0
                      ? "$selectedBook ${chapitreController.text}:${versetDebutController.text}-$versetFin"
                      : "$selectedBook ${chapitreController.text}:${versetDebutController.text}";

                  library.addVerse(ref, categoryController.text.trim());
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

// 🔹 Helper pour uniformiser le style des inputs
  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }


  Widget _buildStatCard(BuildContext context,
      {required int count, required String title, required IconData icon, required Color color, required VerseStatus targetFilter}) {
    return InkWell(

      onTap: () {
// NAVIGUE VERS LA BIBLIOTHÈQUE AVEC LE BON FILTRE !

        Navigator.push(

          context,

          MaterialPageRoute(builder: (context) =>
              VerseLibraryPage(initialFilter: targetFilter)),

        );
      },

      child: Card(

        child: Padding(

          padding: const EdgeInsets.all(16.0),

          child: Column(

            children: [

              Icon(icon, color: color, size: 40),

              const SizedBox(height: 8),

              Text("$count", style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),

              Text(title, textAlign: TextAlign.center),

            ],

          ),

        ),

      ),

    );
  }

}
// Fichier : lib/progression_dashboard_page.dart

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../widgets/passage_selector_widget.dart';
import '../../widgets/review_list_widget.dart';
import '../../widgets//stats_card_widget.dart';
import '../../models/verse_model.dart';
import 'package:provider/provider.dart';
import '../verse/verse_detail_page.dart';
import '../../Bibliotheque.dart';
import '../games/QcmPage.dart';

class ProgressionDashboardPage extends StatefulWidget {
  const ProgressionDashboardPage({super.key});

  @override
  State<ProgressionDashboardPage> createState() => _ProgressionDashboardPageState();
}

class _ProgressionDashboardPageState extends State<ProgressionDashboardPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Verse? _lastVerseInProgress;
  int _learningCount = 0;
  int _masteredCount = 0;

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
  bool _isLoadingBooks = true;
  String? _newSelectedBook;
  final _newChapterController = TextEditingController();
  final _newStartVerseController = TextEditingController();
  final _newEndVerseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _chargerLivresDepuisJson();
  }

  @override
  void dispose() {
    _newChapterController.dispose();
    _newStartVerseController.dispose();
    _newEndVerseController.dispose();
    super.dispose();
  }

  // Dans votre classe _ProgressionDashboardPageState
// ✅ AJOUT : La fonction de chargement des livres, copiée depuis votre page de jeu
  Future<void> _chargerLivresDepuisJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);
      final Set<String> livresUniques = data.map((item) => item['book_name'] as String).toSet();

      if (mounted) {
        setState(() {
          books = ["Tous les livres", ...livresUniques.toList()..sort()];
          // On peut définir un livre par défaut pour la sélection
          _newSelectedBook = books.isNotEmpty ? "Jean" : null;
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBooks = false);
        // Gérer l'erreur
      }
    }
  }

  Future<void> _fetchDashboardData() async {

    if (user == null) {
      print("Personne n'est connecté !");
      return;
    }

    final String userId = user!.uid;
    try {
      // --- 1. Récupérer le dernier verset en cours d'apprentissage ---
      final lastVerseQuery = await FirebaseFirestore.instance
          .collection('users/$userId/verses')
          .where('status', isEqualTo: 'learning')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (lastVerseQuery.docs.isNotEmpty) {
        _lastVerseInProgress = Verse.fromFirestore(lastVerseQuery.docs.first);
      } else {
        _lastVerseInProgress = null; // Aucun verset en cours
      }

      // --- 2. Compter les versets "en cours" ---
      final learningCountQuery = await FirebaseFirestore.instance
          .collection('users/$userId/verses')
          .where('status', isEqualTo: 'learning')
          .count()
          .get();
      // ✅ CORRIGÉ : On utilise "?? 0" pour éviter une erreur si le résultat est nul
      _learningCount = learningCountQuery.count ?? 0;

      // --- 3. Compter les versets "connus" (mastered) ---
      final masteredCountQuery = await FirebaseFirestore.instance
          .collection('users/$userId/verses')
          .where('status', isEqualTo: 'mastered')
          .count()
          .get();
      // ✅ CORRIGÉ : On utilise "?? 0" pour éviter une erreur si le résultat est nul
      _masteredCount = masteredCountQuery.count ?? 0;

    } catch (e) {
      print("Erreur lors du chargement des données du tableau de bord: $e");
      // Optionnel : afficher un message d'erreur à l'utilisateur
    }

    // --- 4. Mettre à jour l'interface de manière sécurisée ---
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // Dans le fichier lib/progression_dashboard_page.dart
// À l'intérieur de la classe _ProgressionDashboardPageState

  Future<void> _startNewVerse() async {
    // ✅ AJOUT : On récupère l'utilisateur et son ID ici
    final User? user = FirebaseAuth.instance.currentUser;

    // On vérifie si un utilisateur est bien connecté avant de continuer
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : Aucun utilisateur n'est connecté.")),
      );
      return;
    }
    final String userId = user.uid;
    // --- FIN DE L'AJOUT ---
    // 1. Validation : On vérifie que les champs nécessaires sont remplis.
    if (_newSelectedBook == null || _newChapterController.text.isEmpty || _newStartVerseController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez choisir un livre, un chapitre et un verset."), backgroundColor: Colors.red),
        );
      }
      return; // On arrête la fonction ici
    }

    // 2. On construit la référence et on prépare la requête Firestore.
    final reference = "${_newSelectedBook} ${_newChapterController.text}:${_newStartVerseController.text}";
    final verseRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(reference);

    // Affiche un indicateur de chargement
    showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    final verseDoc = await verseRef.get();

    if (mounted) {
      Navigator.of(context).pop(); // Ferme l'indicateur de chargement
    } else {
      return;
    }

    // 3. Logique principale : On gère les deux cas possibles.
    if (verseDoc.exists) {
      // Cas A : Le verset existe déjà.
      // On charge ses données et on navigue vers sa page de détail pour montrer la progression.
      final existingVerse = Verse.fromFirestore(verseDoc);
      if(mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => VerseDetailPage(verse: existingVerse)))
            .then((_) => _fetchDashboardData()); // On rafraîchit le tableau de bord au retour
      }
    } else {
      // Cas B : Le verset est nouveau.
      // On le crée, on le sauvegarde, et on lance directement le premier jeu.
      final newVerse = Verse(
        id: reference,
        reference: reference,
        book: _newSelectedBook!,
        status: VerseStatus.learning, // Statut direct : "en apprentissage"
        progressLevel: 0,
        scores: {},
        isUserAdded: true,
        updatedAt: null,
        failedAttempts: {},
        srsLevel: 0,
        reviewDate: null,
      );
      await verseRef.set(newVerse.toFirestore());

      if(mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => QcmGamePage(verse: newVerse, isSandbox: false)))
            .then((_) => _fetchDashboardData()); // On rafraîchit le tableau de bord au retour
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Apprentissage')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // if (_lastVerseInProgress != null) _buildResumeCard(_lastVerseInProgress!),
          // const SizedBox(height: 24),
          ReviewListWidget(),

          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 16),
          Text("Ma Bibliothèque", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),

          // ✅ Affichez simplement le widget ici
          const StatsCardWidget(),

          const SizedBox(height: 24),
          _buildNewVerseCard(),
        ],
      ),
    );
  }


  Widget _buildResumeCard(Verse verse) {

    return Card(

      color: Colors.indigo[50],

      child: Padding(

        padding: const EdgeInsets.all(16.0),

        child: Column(

          children: [

            Text("Reprendre où vous en étiez", style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            ListTile(

              leading: const Icon(Icons.bookmark, color: Colors.indigo, size: 40),

              title: Text(verse.reference, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

              subtitle: Text("Progression : ${verse.progressLevel}/6"),

            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(

              icon: const Icon(Icons.play_arrow),

              label: const Text("CONTINUER"),

              onPressed: () {
                // On navigue vers la page de détail pour le verset affiché.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VerseDetailPage(verse: verse)
                  ),
                  // On rafraîchit les données du tableau de bord quand l'utilisateur revient.
                ).then((_) => _fetchDashboardData());
              },

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.indigo,

                foregroundColor: Colors.white,

              ),

            ),

          ],

        ),

      ),

    );

  }







  // ✅ AMÉLIORÉ : Utilise le widget réutilisable
  Widget _buildNewVerseCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Commencer un nouveau verset", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Si les livres chargent, on affiche un indicateur
            if (_isLoadingBooks)
              const Center(child: CircularProgressIndicator())
            else
            // Sinon, on affiche l'interface de sélection
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Livre'),
                    value: _newSelectedBook,
                    items: books.map((book) => DropdownMenuItem(value: book, child: Text(book))).toList(),
                    onChanged: (value) => setState(() => _newSelectedBook = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newChapterController,
                    decoration: _inputDecoration('Chapitre'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _newStartVerseController, decoration: _inputDecoration('Début'))),
                      const SizedBox(width: 16),
                      Expanded(child: TextField(controller: _newEndVerseController, decoration: _inputDecoration('Fin (facultatif)'))),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("COMMENCER"),
              onPressed: _startNewVerse,
            ),
          ],
        ),
      ),
    );
  }

  // Fonction de décoration copiée ici aussi
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

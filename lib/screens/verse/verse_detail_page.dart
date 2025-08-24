// Fichier : lib/verse_detail_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../games/recitation_page.dart';
import '../games/remettre_ordre_page.dart';
import 'package:provider/provider.dart';

// Assurez-vous d'importer votre modèle et toutes vos pages de jeu
import '../../Bibliotheque.dart';
import '../games/QcmPage.dart';
import '../games/dictee_page.dart';
import '../games/jeu_trous.dart';
import '../../models/verse_model.dart';
import '../core/pageDeConfiguration.dart'; // Importer la page de configuration
import '../../services/Bible_service.dart';
// import 'trous_facile_game_page.dart'; // Exemple
// ... importez les 6 pages de jeu

class VerseDetailPage extends StatefulWidget {
  final Verse verse;

  const VerseDetailPage({super.key, required this.verse});

  @override
  State<VerseDetailPage> createState() => _VerseDetailPageState();
}

class _VerseDetailPageState extends State<VerseDetailPage> {
  late Verse currentVerse;
  String? userId;
  // La séquence officielle des jeux
  final List<String> gameSequence = [
    "qcm",
    "texte_a_trous",
    "ordre",
    "dictee",
    "recitation"
  ];

  @override
  void initState() {
    super.initState();
    currentVerse = widget.verse;
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  // --- LOGIQUE DE NAVIGATION ---

  Future<void> _startLearning() async {
    final docRef = FirebaseFirestore.instance
        .collection('users/$userId/verses')
        .doc(currentVerse.id);

    await docRef.update({
      'status': 'learning',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // On met à jour l'objet local pour que le changement soit immédiat
    setState(() {
      currentVerse = Verse(
        id: currentVerse.id,
        reference: currentVerse.reference,
        status: VerseStatus.learning, // Le statut change
        progressLevel: 0, // La progression commence
        scores: currentVerse.scores,
        isUserAdded: currentVerse.isUserAdded,
        book: currentVerse.book,
        failedAttempts: {},
        srsLevel: 0,
        reviewDate: null,
      );
    });

    // On lance le premier jeu
    _navigateToGame("qcm");
  }

  void _continueLearning() {
    int currentGameIndex = currentVerse.progressLevel;
    if (currentGameIndex < gameSequence.length) {
      _navigateToGame(gameSequence[currentGameIndex]);
    }
  }

  Future<void> _navigateToGame(String gameMode) async {
    // Ce "routeur" lance la bonne page de jeu
    // C'est ici que vous connecterez toutes vos pages de jeu
    Widget gamePage;
    switch (gameMode) {
      case "qcm":
        gamePage = QcmGamePage(verse: currentVerse, isSandbox: false);
        break;
    case  "texte_a_trous":
      gamePage = TexteATrousPage (verse: currentVerse, isSandbox: false);
      break;
      case "ordre":
        gamePage = RemettreOrdrePage(verse: currentVerse, isSandbox: false);
        break;
      case "dictee"  :
        gamePage = DicteePage(verse: currentVerse, isSandbox: false);
        break;
      case "recitation":
        gamePage = RecitationPage(verse: currentVerse, isSandbox: false);
        break;
      default:
      // Si le jeu n'est pas trouvé, on retourne sur la page avec une erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Page de jeu '$gameMode' non implémentée.")),
        );
        return;
    }

    final gameResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gamePage),
    );

// ✅ CORRECTION: Simplify this block
    if (gameResult == true) {
      // 1. Get the updated verse from Firestore (which you already do)
      await _refreshVerseDataFromFirestore();

      // 2. Launch the next game. The 'currentVerse' has already been updated
      //    by the refresh function, so it has the correct progressLevel.
      //    No need for setState here.
      _launchNextGame();
    }
  }

  void _launchNextGame() {
    final gameSequence = ["qcm", "texte_a_trous", "ordre", "dictee", "recitation"];
    int nextGameIndex = currentVerse.progressLevel;

    if (nextGameIndex < gameSequence.length) {
      String nextGameMode = gameSequence[nextGameIndex];
      print("Étape réussie ! Lancement automatique du jeu suivant : $nextGameMode");
      _navigateToGame(nextGameMode);
    } else {
      print("🎉 PARCOURS TERMINÉ !");
      // Toutes les étapes sont finies, le statut est déjà "mastered" grâce à onGameFinished.
      // On peut afficher un dialogue de félicitations final ici.
    }
  }

// Une fonction pour recharger les données à jour depuis Firestore
  Future<void> _refreshVerseDataFromFirestore() async {
    final doc = await FirebaseFirestore.instance.collection('users/$userId/verses').doc(currentVerse.id).get();
    if (doc.exists) {
      setState(() {
        currentVerse = Verse.fromFirestore(doc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentVerse.reference),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Permet de scroller si le contenu est trop grand
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ NOUVEAU : On affiche TOUJOURS le texte du verset en premier
            _buildVerseTextDisplay(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Le reste de l'interface dépend du statut
            _buildVerseBody(),
          ],
        ),
      ),
    );
  }

  // --- LOGIQUE D'AFFICHAGE ---

  Widget _buildVerseBody() {

    if (!currentVerse.isUserAdded) {
      return _buildNotAddedView();
    }

    switch (currentVerse.status) {
      case VerseStatus.neutral:
        return _buildNeutralView();
      case VerseStatus.learning:
        return _buildLearningView();
      case VerseStatus.mastered:
        return _buildMasteredView();
    }
  }

  Widget _buildNeutralView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Verset Prêt à Apprendre",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
              "Commencez le parcours de mémorisation pour suivre votre progression.",
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.school),
            label: const Text("COMMENCER L'APPRENTISSAGE"),
            onPressed: _startLearning,
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildLearningView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.school, color: Colors.orange, size: 40),
            title: const Text("En cours d'apprentissage",
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
            Text("Étape ${currentVerse.progressLevel + 1} sur 5"),
          ),
        ),
        const SizedBox(height: 24),
        _buildProgressBar(currentVerse.progressLevel),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: const Text("CONTINUER LA PROGRESSION"),
          onPressed: _continueLearning,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.gamepad_outlined),
          label: const Text("Jeu libre (Sandbox)"),
          onPressed: () {
            // Naviguer vers la page de configuration
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PageDeJeuPrincipale(
                  initialReference: currentVerse.reference,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMasteredView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 60, color: Colors.green),
          const SizedBox(height: 20),
          const Text("Verset Connu !",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Félicitations ! Vous avez complété toutes les étapes.",
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text("S'entraîner à nouveau"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PageDeJeuPrincipale(
                    initialReference: currentVerse.reference,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(int progressLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Progression :",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 10,
                decoration: BoxDecoration(
                  color: index < progressLevel ? Colors.green : Colors.grey[300],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ✅ NOUVEAU : Le widget qui affiche le texte du verset/passage
  Widget _buildVerseTextDisplay() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<VerseData>>(
          future: BibleService().getPassageText(currentVerse.reference),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Impossible de charger le texte."));
            }
            final verses = snapshot.data!;
            return RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 20, height: 1.5),
                children: verses.map((verseData) {
                  final verseNumber = verseData.reference.split(':').last;
                  return TextSpan(
                    children: [
                      TextSpan(
                        text: " $verseNumber ",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      TextSpan(text: verseData.text),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Une vue pour les versets consultés mais non ajoutés
  Widget _buildNotAddedView() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Verset non ajouté", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Ajoutez ce verset à votre bibliothèque pour commencer à le mémoriser.", textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("AJOUTER À MA BIBLIOTHÈQUE"),
            onPressed: () async {
              // On appelle la méthode du provider pour l'ajouter à Firestore
              await context.read<VerseLibrary>().addVerse(currentVerse.reference, currentVerse.book);

              // ✅ CORRECTION : On met à jour l'état local pour refléter le changement
              setState(() {
                currentVerse = Verse(
                  id: currentVerse.id,
                  reference: currentVerse.reference,
                  book: currentVerse.book,
                  isUserAdded: true, // Devient vrai
                  status: VerseStatus.neutral, // Le statut de départ
                  progressLevel: 0,
                  scores: {},
                  updatedAt: null, // Firestore s'en chargera
                  failedAttempts: {},
                  srsLevel: 0,
                  reviewDate: null,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${currentVerse.reference} ajouté !")),
              );
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          )
        ],
      ),
    );
  }



}
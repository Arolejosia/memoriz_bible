import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../models/game_session.dart';
import '../../models/verse_model.dart';
import '../../services/Bible_service.dart';
import '../../services/audio_service.dart';
import '../../services/feedback_overlay.dart';

// =======================================================================
// PAGE DE JEU : Texte à trous
// Cette page gère le jeu pour une référence spécifique.
// L'API se charge de la logique pour les passages courts et longs.
// =======================================================================
class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}

class TexteATrousPage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;

  const TexteATrousPage({
    Key? key,
    required this.verse,
    this.isSandbox = false,
  }) : super(key: key);

  @override
  _TexteATrousPageState createState() => _TexteATrousPageState();
}

class _TexteATrousPageState extends State<TexteATrousPage> {
  // --- État de la Session de Jeu ---
  late final GameSession _session;
  bool _isLoading = true;
  int _score = 0;
  final int _objectifFinal = 7; // L'objectif pour gagner
  String _niveauActuel = 'débutant'; // Le niveau de difficulté de départ

  // --- État de la Question Actuelle ---
  String _versetModifie = "";
  List<String> _reponses = [];
  List<TextEditingController> _controllers = [];
  List<bool> _resultatsVerification = [];
  List<int> _indices = [];
  String? _currentReference;
  String _errorMessage = '';

  // --- État de l'UI après une réponse ---
  bool _answered = false;
  bool _bonneReponse = false;
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;

  final String _baseUrl = "https://memoriz-bible-api.onrender.com";

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    super.dispose();
  }

  /// Appelle l'API pour obtenir un nouveau passage à trous.
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _answered = false;
      _resultatsVerification = [];
      _controllers.forEach((c) => c.dispose());
      _controllers = [];
    });

    try {

      // IMPORTANT : Assurez-vous que cette adresse IP est correcte.
      final url = Uri.parse('$_baseUrl/jeu');

      final body = json.encode({
        "reference": widget.verse.reference,
        "niveau": _niveauActuel
      });
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);

      if (mounted && response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _versetModifie = data["verset_modifie"];
          _reponses = List<String>.from(data["reponses"]);
          // ✅ CORRECTION 1 : On met à jour la liste des indices
          _indices = List<int>.from(data["indices"]);

          // ✅ CORRECTION 2 : On met à jour la référence exacte pour l'affichage
          _currentReference = data["reference"];
          _controllers = List.generate(_reponses.length, (_) => TextEditingController());
          _isLoading = false;
        });
        } else {
          _showError("Erreur serveur : ${response.statusCode}");
        }

    } catch (e) {
      if (mounted) {
        _showError("Erreur réseau. Vérifiez l'IP et que le serveur est bien lancé.");
      }
    }
  }

  /// Appelle l'API pour vérifier les réponses de l'utilisateur.
  Future<void> _verifierReponses() async {
    final reponsesUtilisateur = _controllers.map((c) => c.text.trim()).toList();
    try {
      final url = Uri.parse('$_baseUrl/verifier');
      final body = json.encode({"reponses_utilisateur": reponsesUtilisateur, "reponses_correctes": _reponses});
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);

      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<bool> resultats = List<bool>.from(data["resultats"]);
        final bool toutBon = resultats.every((res) => res == true);
        setState(() {
          _answered = true;
          _bonneReponse = toutBon;
          _resultatsVerification = resultats;
          if (toutBon) {
            AudioService.instance.playSound('sound/correct.mp3');
            setState(() {
              _pointAnimations.add(PointAnimationData(_animationIdCounter++, 10));
              _score++;
            });
          } else {
            // Affiche les bonnes réponses dans les champs incorrects
            for (int i = 0; i < _reponses.length; i++) {
              if (!resultats[i]) {
                _controllers[i].text = _reponses[i];
              }
            }
            AudioService.instance.playSound('sound/incorrect.mp3');
          }
        });
      } else {
        if(mounted) _showError("Erreur lors de la vérification.");
      }
    } catch (e) {
      if(mounted) _showError("Erreur réseau lors de la vérification.");
    }
  }


  void _continuerPartie() {
    // 1. On vérifie si l'objectif final est atteint
    if (_score >= _objectifFinal) {
      _concludeGame(didWin: true);
      return;
    }

    // 2. On met à jour la difficulté en fonction du score
    if (_score >= 7 && _niveauActuel != 'expert') {
      setState(() { _niveauActuel = 'expert'; });
    } else if (_score >= 3 && _niveauActuel == 'débutant') {
      setState(() { _niveauActuel = 'intermédiaire'; });
    }

    // 3. On charge la question suivante avec le bon niveau
    _loadQuestion();
  }
  /// Gère la conclusion de la partie (victoire ou abandon).
  Future<void> _concludeGame({required bool didWin}) async { // ✅ 1. Rendez la fonction async
    if (widget.isSandbox) {
      if (didWin) _afficherFelicitationSandbox();
      else if (mounted) Navigator.of(context).pop();
      return;
    }

    final int finalScore = didWin ? 100 : 0;
    if (mounted) {
      // ✅ 2. Attendez que la sauvegarde soit terminée
      await context.read<VerseLibrary>().onGameFinished(
        verse: widget.verse,
        gameMode: "texte_a_trous",
        score: finalScore,
      );
      // ✅ 3. Ne fermez la page qu'après la sauvegarde
      Navigator.of(context).pop(true);
    }
  }

  void _afficherFelicitationSandbox() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("🎉 Bravo !"),
          content: Text("Vous avez atteint l'objectif de $_objectifFinal points !"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme la boîte de dialogue
                  Navigator.pop(context); // Revient à la page de configuration
                },
                child: Text("Terminer")
            )
          ],
        )
    );
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _versetModifie = message;
      _indices = [];
    });
  }

  void _afficherFelicitation() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("🎉 Bravo !"),
          content: Text("Vous avez atteint votre objectif de $_objectifFinal bonnes réponses !"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context); // Ferme la boîte de dialogue
                  Navigator.pop(context); // Revient à la page de configuration
                },
                child: Text("Terminer")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: [Scaffold(
      appBar: AppBar(
        title: Text("Texte à trous"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildGameView(),

    ),
          ..._pointAnimations.map((data) {
            return PointsAnimationWidget(
              key: ValueKey(data.id),
              points: data.points,
              onCompleted: () {
                if (mounted) {
                  setState(() {
                    _pointAnimations.removeWhere((anim) => anim.id == data.id);
                  });
                }
              },
            );
          }),
    ],
    );
  }

  Widget _buildGameView() {
    if (_indices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_versetModifie, textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }

    final mots = _versetModifie.split(" ");
    int champIndex = 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affiche la référence exacte du passage
            if (_currentReference != null)
              Text(
                  _currentReference!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
              ),
            SizedBox(height: 8),
            _barreDeProgression(),
            SizedBox(height: 24),
            // Affiche le texte à trous
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(mots.length, (i) {
                if (_indices.contains(i)) {
                  final controller = _controllers[champIndex];
                  bool estCorrect = _answered && champIndex < _resultatsVerification.length ? _resultatsVerification[champIndex] : false;
                  final champ = SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller,
                      enabled: !_answered,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: _answered,
                        fillColor: _answered ? (estCorrect ? Colors.green[100] : Colors.red[100]) : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  );
                  champIndex++;
                  return champ;
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(mots[i], style: TextStyle(fontSize: 18, height: 1.5)),
                  );
                }
              }),
            ),
            SizedBox(height: 32),
            // Affiche les boutons d'action
            if (!_answered)
              ElevatedButton(
                onPressed: _verifierReponses,
                child: Text("Vérifier"),
              ),
            if (_answered)
              Column(
                children: [
                  _bonneReponse
                      ? Text("✅ Bien joué !", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : Text("❌ Ce n’est pas tout à fait ça...", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text("Continuer"),
                    onPressed: _continuerPartie,
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _barreDeProgression() {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: _score / _objectifFinal ,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            color: Colors.green[600],
          ),
        ),
        SizedBox(width: 12),
        Text("$_score / $_objectifFinal "),
      ],
    );
  }
}

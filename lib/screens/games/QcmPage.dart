import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../models/verse_model.dart';

import '../../Bibliotheque.dart';
import '../../models/game_session.dart';
import '../../services/FeedbackService.dart';
import '../../services/audio_service.dart';
import '../../services/feedback_overlay.dart';

// =======================================================================
// PAGE DE JEU : QCM par Référence
// Cette page gère le jeu QCM pour une référence spécifique,
// qu'elle soit courte ou longue.
// =======================================================================
class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}
class QcmGamePage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;

  const QcmGamePage({Key? key, required this.verse,
    this.isSandbox = false,}) : super(key: key);

  @override
  _QcmGamePageState createState() => _QcmGamePageState();
}

class _QcmGamePageState extends State<QcmGamePage> {
  // --- État du jeu ---
  bool _isLoading = true;
  String _question = "";
  List<String> _options = [];
  String _correctAnswer = "";
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  String? _currentReference;
  final Set<String> _motsAppris = {};

  // --- Le "cerveau" de la logique du jeu ---
  late final GameSession _session;
  final Set<String> _motsApprisDansLaSession = {};
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  final String _baseUrl = "https://memoriz-bible-api.onrender.com";
  @override
  void initState() {
    super.initState();

    // On initialise le cerveau en lui passant le mode de jeu et la fonction à appeler en cas de victoire.
    _session = GameSession(
      isSandbox: widget.isSandbox,
      scoreToWin: 10, // L'objectif de 10 bonnes réponses
      // On dit à la session : "Quand la partie est gagnée, appelle ma fonction _concludeGame".
      onGameWon: () => _concludeGame(didWin: true),
    );
    _loadQuestion();
  }

  /// Appelle l'API pour obtenir une nouvelle question QCM.
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _answered = false;
      _selectedAnswer = null;
    });

    String niveauApi;
    if (_session.difficulty <= 1) {
      niveauApi = "facile";
    } else if (_session.difficulty == 2) {
      niveauApi = "moyen";
    } else {
      niveauApi = "difficile";
    }


    try {
      // ✅ APPEL À L'API : On utilise la route /qcm
      final url = Uri.parse('$_baseUrl/qcm');

      final body = json.encode({
        "reference": widget.verse.reference,
        "niveau": niveauApi, // Le niveau peut être ajusté si nécessaire
        "mots_deja_utilises": _motsApprisDansLaSession.toList()
      });

      final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: body
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data.containsKey('error')) {
            _showError(data['error']);
            return;
          }
          if (data['cycle_recommence'] == true) {
            // Si l'API a réinitialisé le cycle, on vide notre liste locale aussi !
            _motsApprisDansLaSession.clear();
            print("--- Cycle de mots recommencé ! ---");
          }
          setState(() {
            _question = data['question'];
            _options = List<String>.from(data['options']);
            _correctAnswer = data['reponse_correcte'];
            _currentReference = data['reference'];
            _isLoading = false;
          });
        } else {
          _showError("Erreur serveur (${response.statusCode}).");
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("Erreur de connexion. Vérifiez l'IP et que le serveur API est bien lancé.");
      }
    }
  }

  /// Affiche un message d'erreur en cas de problème.
  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _question = message;
      _options = [];
    });
  }

  /// Gère la soumission de la réponse de l'utilisateur.
// In lib/screens/games/QcmPage.dart -> _QcmGamePageState

  void _submitAnswer(String answer) {
    setState(() {
      _answered = true;
      _selectedAnswer = answer;
    });
    final isCorrect = answer == _correctAnswer;

    // ✅ AJOUTEZ CECI POUR VÉRIFIER
    print("Réponse choisie: $answer");
    print("Bonne réponse: $_correctAnswer");
    print("Est-ce correct ? $isCorrect");

    if (isCorrect) {
      _motsApprisDansLaSession.add(_correctAnswer.toLowerCase());
      AudioService.instance.playSound("sound/correct.mp3");
      setState(() {
        _pointAnimations.add(PointAnimationData(_animationIdCounter++, 10));
      });

      Future.delayed(const Duration(milliseconds: 2000), () {
        // ✅ THE FIX: Check here if the game has been won in the meantime.
        // If it has, do nothing.
        if (mounted && !_session.isGameFinished) {
          _loadQuestion();
        }
      });

    } else {
      AudioService.instance.playSound('sound/incorrect.mp3');
    }

    _session.submitAnswer(isCorrect: isCorrect);
  }
// ✅ NOUVELLE FONCTION : gère la fin de la partie et la sauvegarde
  // Dans le fichier qcm_game_page.dart -> _QcmGamePageState

  void _concludeGame({required bool didWin}) {
    // En mode sandbox, on sort simplement.
    if (widget.isSandbox) {
      // Affichez un message de félicitations si le score est atteint
      if (didWin) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Félicitations !"),
            content: Text("Vous avez atteint l'objectif de ${_session.scoreToWin} points !"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        ).then((_) => Navigator.of(context).pop()); // Quitte la page de jeu après le dialogue
      } else {
        Navigator.of(context).pop();
      }
      return;
    }

    // En mode progression :
    final int finalScore = didWin ? 100 : 0;
    context.read<VerseLibrary>().onGameFinished(
      verse: widget.verse,
      gameMode: "qcm",
      score: finalScore,
    );

    // ✅ ON RENVOIE "true" POUR SIGNALER LA VICTOIRE
    Navigator.of(context).pop(true);
  }


  /// Détermine la couleur d'un bouton de réponse.
  Color _getButtonColor(String option) {
    // Si on n'a pas encore répondu, couleur par défaut
    if (!_answered) return Theme.of(context).colorScheme.secondaryContainer;

    // Si cette option EST la bonne réponse, elle est TOUJOURS verte.
    if (option == _correctAnswer) {
      return Colors.green.shade700;
    }

    // Si cette option est celle que l'utilisateur a choisie (et on sait qu'elle est fausse car le premier 'if' n'a pas fonctionné), elle est rouge.
    if (option == _selectedAnswer) {
      return Colors.red.shade700;
    }

    // Sinon, c'est une autre mauvaise réponse, on la grise.
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: [
          Scaffold(
      appBar: AppBar(
        title: Text("Jeu QCM"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("Score: ${_session.score} / ${_session.scoreToWin}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
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
                // When an animation finishes, remove it from the list
                setState(() {
                  _pointAnimations.removeWhere((anim) => anim.id == data.id);
                });
              },
            );
          }),
  ],
    );
  }

  /// Construit la vue principale du jeu (question et options).
  Widget _buildGameView() {
    if (_options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_question, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 18)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _motsAppris.clear();
                    _score = 0;
                  });
                  _loadQuestion();
                },
                child: Text("Recommencer"),
              )
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_currentReference != null)
            Text(
                _currentReference!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
            ),
          SizedBox(height: 16),
          Text('Complétez le verset :', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: Offset(0, 4))]
            ),
            child: Text(_question, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, height: 1.5), textAlign: TextAlign.center),
          ),
          SizedBox(height: 24),
          ..._options.map((option) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _answered ? null : () => _submitAnswer(option),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(option),

                  // ✅ ADD THIS: The background color when the button is DISABLED
                  disabledBackgroundColor: _getButtonColor(option),

                  // ✅ ADD THIS: The color of the text when the button is DISABLED
                  // This ensures the text stays readable (e.g., white or black)
                  disabledForegroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              child: Text(option, textAlign: TextAlign.center),
            ),
          )).toList(),
          Spacer(),
          if (_answered && _selectedAnswer != _correctAnswer)
            ElevatedButton.icon(
              icon: Icon(Icons.arrow_forward),
              label: Text("Question suivante"),
              onPressed: _loadQuestion,
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
            )
        ],
      ),
    );
  }
}
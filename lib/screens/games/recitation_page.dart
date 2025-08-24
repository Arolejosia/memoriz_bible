// Fichier: lib/recitation_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';

// Adaptez les chemins d'importation
import '../../services/Bible_service.dart';
import '../../Bibliotheque.dart';
import '../../services/audio_service.dart'; // Assurez-vous que le chemin est correct

import '../../services/Bible_service.dart';
import '../../models/verse_model.dart';
import '../../services/feedback_overlay.dart';

class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}

class RecitationPage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;

  const RecitationPage({
    super.key,
    required this.verse,
    this.isSandbox = false,
  });

  @override
  State<RecitationPage> createState() => _RecitationPageState();
}

class _RecitationPageState extends State<RecitationPage> {
  final SpeechToText _speech = SpeechToText();
  bool _isSpeechInitialized = false;
  String _transcribedText = "";
  String _correctText = "";
  bool _isLoading = true;
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  // Variables pour la logique de jeu
  bool _isListening = false;
  bool _isVerifying = false;
  bool _isGameOver = false;

  // ✅ NOUVEAU : Gestion des essais
  final int _essaisMax = 3;
  int _essaisRestants = 3;

  @override
  void initState() {
    super.initState();
    _initialize();
  }


  Future<void> _initialize() async {
    // 1. On charge le texte correct du verset (gère les passages)
    final verseDataList = await BibleService().getPassageText(widget.verse.reference);
    if (verseDataList.isNotEmpty && mounted) {
      _correctText = verseDataList.map((v) => v.text).join(" ");
    }

    // 2. On initialise le service de reconnaissance vocale
    _isSpeechInitialized = await _speech.initialize();

    if(mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startListening() {
    if (!_isSpeechInitialized || _isListening) return;
    setState(() {
      _isListening = true;
      _transcribedText = ""; // On réinitialise le texte à chaque nouvel enregistrement
    });
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _transcribedText = result.recognizedWords);
        }
      },
      localeId: "fr_FR",
    );
  }

  void _stopListening() {
    if (!_isListening) return;
    _speech.stop();
    setState(() => _isListening = false);
    _verifyRecitation(); // On lance la vérification dès que l'écoute est terminée
  }

  Future<void> _verifyRecitation() async {
    if (_transcribedText.isEmpty) return;
    setState(() => _isVerifying = true);

    final score = await BibleService().getVerificationScore(_transcribedText, _correctText);
    final isCorrect = score >= 70;

    if (isCorrect) {
      // ✅ NOUVEAU : Calcul du score basé sur les essais
      int finalScore = 0;
      if (_essaisRestants == 3) finalScore = 100;
      else if (_essaisRestants == 2) finalScore = 75;
      else if (_essaisRestants == 1) finalScore = 50;

      if (!widget.isSandbox) {
        AudioService.instance.playSound('sounds/correct_answer.mp3');
        context.read<VerseLibrary>().onGameFinished(
          verse: widget.verse,
          gameMode: "recitation", // Le nom du jeu est crucial
          score: finalScore,
        );
        setState(() {
          _pointAnimations.add(PointAnimationData(_animationIdCounter++, finalScore));
        });

      }
      _showResultDialog(true);
    } else {
      AudioService.instance.playSound('sound/incorrect.mp3');
      // Si la réponse est fausse
      setState(() {
        _essaisRestants--;
        if (_essaisRestants <= 0) {
          _isGameOver = true;
          // C'est ici que la logique de rétrogradation sera déclenchée
          if (!widget.isSandbox) {
            context.read<VerseLibrary>().onGameFinished(
              verse: widget.verse,
              gameMode: "recitation",
              score: 0, // Un score de 0 déclenche la logique d'échec
            );
          }
        }
      });
      _showResultDialog(false);
    }
    setState(() => _isVerifying = false);
  }

  void _showResultDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? "Parfait !" : (_isGameOver ? "Échec de la mémorisation" : "Incorrect")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                isCorrect ? "Votre récitation est excellente." :
                (_isGameOver ? "Vous avez utilisé vos 3 essais." : "Ce n'est pas tout à fait ça. Il vous reste ${_essaisRestants} essai(s).")
            ),
            // ✅ NOUVEAU : On affiche la bonne réponse en cas d'échec
            if (!isCorrect) ...[
              const SizedBox(height: 16),
              const Text("La bonne réponse était :", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("'$_correctText'"),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Ferme la dialogue
              if (isCorrect || _isGameOver) {
                Navigator.of(context).pop(true); // Reviens à la page de détail
              } else {
                // On prépare le prochain essai
                setState(() => _transcribedText = "");
              }
            },
            child: Text(isCorrect || _isGameOver ? "Continuer" : "Recommencer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    return Stack(
        alignment: Alignment.center,
        children: [Scaffold(
      appBar: AppBar(
        title: Text("Récitation"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // Pour centrer horizontalement le contenu
          children: [
            // Zone d'affichage du texte transcrit
            Column( // Enveloppe le titre et le sous-titre dans une colonne
              crossAxisAlignment: CrossAxisAlignment.center, // Centre le contenu de cette colonne
              children: [
                Text(
                  widget.verse.reference,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 18),
                ),
                Text( // Le nouveau Text pour l'essai
                  "Essai ${(_essaisMax - _essaisRestants) + 1}/$_essaisMax",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  _transcribedText.isEmpty ? "Appuyez sur le micro pour commencer à réciter." : _transcribedText,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Bouton microphone et vérification
            Column(
              children: [
                if (_isVerifying)
                  const CircularProgressIndicator()
                else
                  AvatarGlow(
                    animate: _isListening,
                    glowColor: Theme.of(context).primaryColor,
                    duration: const Duration(milliseconds: 2000),
                    repeat: true,
                    child: GestureDetector(
                      onTapDown: (_) => _startListening(),
                      onTapUp: (_) => _stopListening(),
                      onLongPressEnd: (_) => _stopListening(),
                      child: Icon(
                        Icons.mic,
                        size: 80,
                        color: _isListening ? Colors.red : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _isListening ? "Enregistrement en cours..." : "Maintenez pour parler",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
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
}
// Fichier : lib/dictee_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../services/audio_service.dart';
import '../../services/tts_service.dart';
import '../../services/Bible_service.dart';
import '../../models/verse_model.dart';
import '../../services/feedback_overlay.dart';

class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}
class DicteePage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;

  const DicteePage({
    Key? key,
    required this.verse,
    this.isSandbox = false,
  }) : super(key: key);

  @override
  _DicteePageState createState() => _DicteePageState();
}

class _DicteePageState extends State<DicteePage> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _textController = TextEditingController();
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  String _texteCorrect = "";
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isGameOver = false;

  final int _essaisMax = 3;
  int _essaisRestants = 3;

  Timer? _timer;
  int _tempsRestant = 0;
  bool _timerActif = false;

  @override
  void initState() {
    super.initState();
    _loadVerseText();
    _ttsService.setCompletionHandler(() {
      if (mounted) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ttsService.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadVerseText() async {
    try {
      final verseDataList = await BibleService().getPassageText(widget.verse.reference);

      if (verseDataList.isNotEmpty && mounted) {
        setState(() {
          _texteCorrect = verseDataList.map((v) => v.text).join(" ");
        });
      } else if (mounted) {
        // Gère le cas où aucun texte n'a été trouvé pour la référence
        showErrorSnackBar(context,"Impossible de trouver le texte pour ce passage.");
      }
    } catch (e) {
      // Gère les erreurs de connexion ou autres exceptions
      if (mounted) showErrorSnackBar(context,"Erreur de connexion : ${e.toString()}");
    } finally {
      // ✅ Ce bloc s'exécute TOUJOURS, que ça réussisse ou que ça échoue.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void showErrorSnackBar(BuildContext context, String message) {
    // Hide any existing SnackBars to avoid them stacking up
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Show the new error SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent, // Red color for errors
        behavior: SnackBarBehavior.floating, // A modern, floating look
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    final nombreDeMots = _texteCorrect.split(' ').length;
    final tempsInitial = 15 + (nombreDeMots * 1.5).round();

    setState(() {
      _tempsRestant = tempsInitial;
      _timerActif = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_tempsRestant > 0) {
        setState(() => _tempsRestant--);
      } else {
        timer.cancel();
        setState(() => _timerActif = false);
        _verifierReponse();
      }
    });
  }

  Future<void> _verifierReponse() async {
    if(!_timerActif) return;
    _timer?.cancel();
    setState(() { _timerActif = false; _isVerifying = true; });

    final reponseUtilisateur = _textController.text;
    final score = await BibleService().getVerificationScore(reponseUtilisateur, _texteCorrect);
    final isCorrect = score >= 70;

    if (isCorrect) {
      AudioService.instance.playSound('sound/correct.mp3');
      int finalScore = 0;
      if (_essaisRestants == 3) finalScore = 100;
      else if (_essaisRestants == 2) finalScore = 75;
      else if (_essaisRestants == 1) finalScore = 50;
      setState(() {
        _pointAnimations.add(PointAnimationData(_animationIdCounter++, finalScore));
      });

      if (!widget.isSandbox) {
        context.read<VerseLibrary>().onGameFinished(
          verse: widget.verse,
          gameMode: "dictee",
          score: finalScore,
        );
      }
      _showResultDialog(true);
    } else {
      AudioService.instance.playSound('sound/incorrect.mp3');
      setState(() {
        _essaisRestants--;
        if (_essaisRestants <= 0) {
          _isGameOver = true;
          if (!widget.isSandbox) {
            context.read<VerseLibrary>().onGameFinished(
                verse: widget.verse, gameMode: "dictee", score: 0
            );
          }
        }
      });
      _showResultDialog(false);
    }
    setState(() => _isVerifying = false);
  }

  // Fichier: lib/dictee_page.dart
// Dans la classe _DicteePageState

  void _showResultDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        // ✅ Titre plus engageant avec une icône
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle_outline : Icons.error_outline,
              color: isCorrect ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Text(isCorrect ? "Réussi !" : (_isGameOver ? "Partie Terminée" : "Incorrect")),
          ],
        ),
        content: SingleChildScrollView( // Pour éviter les erreurs si le texte est long
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Affiche la référence du verset pour le contexte
              Text(
                widget.verse.reference,
                style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
              ),
              const Divider(height: 24),

              // Le message principal
              Text(
                  isCorrect ? "Vous avez réussi cette dictée. Excellent travail !" :
                  (_isGameOver ? "Vous n'avez plus d'essais." : "Il reste ${_essaisRestants} essai(s).")
              ),

              // ✅ Affichage plus stylé de la bonne réponse en cas d'échec
              if (!isCorrect) ...[
                const SizedBox(height: 16),
                const Text("La bonne réponse était :", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _texteCorrect,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ]
            ],
          ),
        ),
        actions: [
          // ✅ Bouton plus visible
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCorrect || _isGameOver ? Theme.of(context).primaryColor : Colors.orangeAccent,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (isCorrect || _isGameOver) {
                Navigator.of(context).pop(true);
              } else {
                _textController.clear();
              }
            },
            child: Text(isCorrect || _isGameOver ? "Continuer" : "Réessayer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text("Dictée")), body: const Center(child: CircularProgressIndicator()));
    }

    return Stack(
        alignment: Alignment.center,
        children: [ Scaffold(
      appBar: AppBar(
        title: Text("Dictée - Essai ${(_essaisMax - _essaisRestants) + 1}/$_essaisMax"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text("Écouter le Verset"),
              onPressed: _timerActif || _isGameOver ? null : () {
                _ttsService.speak(_texteCorrect);
              },
            ),
            Text(
              widget.verse.reference,
              style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            if (_timerActif)
              Text('Temps restant : $_tempsRestant', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              readOnly: !_timerActif || _isGameOver,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: _timerActif ? "Écrivez ici..." : "Appuyez sur 'Écouter' pour commencer",
              ),
            ),
            const SizedBox(height: 20),
            if (_isVerifying)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _timerActif ? _verifierReponse : null,
                child: const Text("Vérifier"),
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
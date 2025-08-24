// Fichier: remettre_ordre_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../services/Bible_service.dart';
import '../../services/audio_service.dart'; // Importez le service audio
import '../../services/feedback_overlay.dart';
import '../../models/verse_model.dart';
import '../../models/game_session.dart';

class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}



// ✅ NOUVEAU : Un petit objet pour transporter le mot ET son origine
class WordData {
  final String word;
  final int? fromIndex; // null si vient de la banque, sinon index dans la zone de réponse

  WordData({required this.word, this.fromIndex});
}
class RemettreOrdrePage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;

  const RemettreOrdrePage({
    super.key,
    required this.verse,
    this.isSandbox = false,
  });


  @override
  State<RemettreOrdrePage> createState() => _RemettreOrdrePageState();
}


class _RemettreOrdrePageState extends State<RemettreOrdrePage> {
  late final GameSession _session;
  UnscrambleGameData? _currentGameData;
  bool _isLoading = true;
  String _errorMessage = '';

  int _currentVerseIndex = 0;
  List<String> _wordBank = [];
  List<String?> _placedWords = [];
  bool _isAnswered = false;
  List<bool> _wordStates = [];

  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _session = GameSession(
      isSandbox: widget.isSandbox,
      scoreToWin: _getVerseCount(),
      onGameWon: () => _concludeGame(didWin: true),
    );
    _fetchAndSetupGame();
  }

  int _getVerseCount() {
    final ref = widget.verse.reference;
    if (ref.contains('-')) {
      final parts = ref.split(':').last.split('-');
      return int.parse(parts[1]) - int.parse(parts[0]) + 1;
    }
    return 1;
  }

  Future<void> _fetchAndSetupGame() async {
    try {
      final gameData = await BibleService().generateRemettreEnOrdrePassage(reference: widget.verse.reference);
      if (mounted) {
        if (gameData.versets.isNotEmpty) {
          setState(() {
            _currentGameData = gameData;
            _setupVerse(gameData.versets[0]);
            _isLoading = false;
          });
        } else {
          _handleError("No verses found for this game.");
        }
      }
    } catch (e) {
      if (mounted) _handleError("Error loading the game: $e");
    }
  }

  void _setupVerse(MotsMelesData verseData) {
    setState(() {
      _isAnswered = false;
      _wordBank = List.from(verseData.motsMelanges);
      _placedWords = List.filled(verseData.motsCorrects.length, null);
    });
  }

  void _checkAnswer() {
    if (_currentGameData == null) return;
    final correctOrder = _currentGameData!.versets[_currentVerseIndex].motsCorrects;
    final userAnswer = _placedWords.whereType<String>().toList();

    List<bool> newWordStates = [];
    bool isCorrect = true;

    // ✅ On boucle pour comparer chaque mot individuellement
    for (int i = 0; i < correctOrder.length; i++) {
      if (i < userAnswer.length && userAnswer[i] == correctOrder[i]) {
        newWordStates.add(true); // Ce mot est correct
      } else {
        newWordStates.add(false); // Ce mot est incorrect
        isCorrect = false;
      }
    }


    if (isCorrect) {
      AudioService.instance.playSound('sounds/correct.mp3');
      setState(() => _pointAnimations.add(PointAnimationData(_animationIdCounter++, 10)));
    } else {
      AudioService.instance.playSound('sounds/incorrect.mp3');
    }

    _session.submitAnswer(isCorrect: isCorrect);
    setState(() {
      _isAnswered = true;
      _wordStates = newWordStates; // On sauvegarde les résultats détaillés
    });

    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 1500), _handleNextAction);
    }
  }

  void _handleNextAction() {
    if (!mounted || !_isAnswered) return;

    final isCorrect = const ListEquality().equals(_placedWords.whereType<String>().toList(), _currentGameData!.versets[_currentVerseIndex].motsCorrects);

    if (!isCorrect) {
      setState(() => _isAnswered = false);
      return;
    }

    if (_session.isGameFinished) {
      _concludeGame(didWin: true);
      return;
    }

    if (_currentVerseIndex < _currentGameData!.versets.length - 1) {
      setState(() {
        _currentVerseIndex++;
        _setupVerse(_currentGameData!.versets[_currentVerseIndex]);
      });
    } else {
      _concludeGame(didWin: true);
    }
  }

  void _concludeGame({required bool didWin}) {
    if (widget.isSandbox) {
      Navigator.of(context).pop();
      return;
    }

    final int finalScore = didWin ? 100 : 0;
    context.read<VerseLibrary>().onGameFinished(
      verse: widget.verse,
      gameMode: "ordre",
      score: finalScore,
    );
    Navigator.of(context).pop(true);
  }

  void _handleError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Remettre en Ordre")),
          body: _buildGameContent(),
        ),
        ..._pointAnimations.map((data) {
          return PointsAnimationWidget(
            key: ValueKey(data.id),
            points: data.points,
            onCompleted: () => setState(() => _pointAnimations.removeWhere((anim) => anim.id == data.id)),
          );
        }),
      ],
    );
  }

  Widget _buildGameContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage));

    final isCorrect = _isAnswered ? const ListEquality().equals(_placedWords.whereType<String>().toList(), _currentGameData!.versets[_currentVerseIndex].motsCorrects) : false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(_currentGameData!.versets[_currentVerseIndex].reference, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              // This border logic will show green/red feedback
              border: _isAnswered ? Border.all(color: isCorrect ? Colors.green : Colors.red, width: 2) : null,
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_placedWords.length, (index) {
                return DragTarget<WordData>(
                  builder: (context, candidateData, rejectedData) {
                    final word = _placedWords[index];
                    if (word != null && word.isNotEmpty) {
                      return _buildDraggableWord(word, index);
                    } else {
                      // This is an empty slot - Highlight if word is being dragged over it
                      bool isHighlighted = candidateData.isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? Colors.blue.withOpacity(0.3) // Highlight color
                              : Colors.black.withOpacity(0.2), // Default empty slot color
                            borderRadius: BorderRadius.circular(12),
                            border: _isAnswered ? Border.all(color: isCorrect ? Colors.greenAccent : Colors.redAccent, width: 2) : null,
                        ),
                        child: const Text('...'),
                      );
                    }
                  },
                  // ✅ LOGIC FOR WHEN A WORD IS DROPPED HERE
                  onAcceptWithDetails: (details) {
                    setState(() {
                      final receivedData = details.data;
                      final wordToPlace = receivedData.word;
                      final sourceIndex = receivedData.fromIndex;
                      final existingWordInSlot = _placedWords[index];

                      _placedWords[index] = wordToPlace;

                      if (sourceIndex != null) {
                        // Word was dragged from another slot (swap)
                        _placedWords[sourceIndex] = existingWordInSlot;
                      } else {
                        // Word was dragged from the bank
                        _wordBank.remove(wordToPlace);
                        if (existingWordInSlot != null) {
                          _wordBank.add(existingWordInSlot);
                        }
                      }
                    });
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // --- Word Bank (Source & Drop Target) ---
          Expanded(
            child: DragTarget<WordData>(
              // ✅ LOGIC TO ACCEPT WORDS DRAGGED BACK TO THE BANK
              onWillAcceptWithDetails: (details) => details.data.fromIndex != null,
              onAcceptWithDetails: (details) {
                setState(() {
                  final receivedData = details.data;
                  _placedWords[receivedData.fromIndex!] = null; // Empty the slot it came from
                  _wordBank.add(receivedData.word); // Add word back to the bank
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.center,
                    children: _wordBank.map((word) => _buildDraggableWord(word, null)).toList(),
                  ),
                );
              },
            ),
          ),

          // ✅ FINAL ACTION BUTTON
          SizedBox(
            height: 50,
            width: double.infinity,
            child: _isAnswered
                ? ElevatedButton(
              onPressed: _handleNextAction,
              child: Text(isCorrect ? "Continuer" : "Réessayer"),
            )
                : ElevatedButton(
              onPressed: !_placedWords.contains(null) ? _checkAnswer : null,
              child: const Text("Vérifier"),
            ),
          ),
        ],
      ),
    );
  }

// Dans la classe _RemettreOrdrePageState

  Widget _buildDraggableWord(String word, int? fromIndex) {
    final isAnswered = _isAnswered;
    final bool? wordState = isAnswered && fromIndex != null && fromIndex < _wordStates.length
        ? _wordStates[fromIndex]
        : null;

    Color backgroundColor;
    Color fontColor = Colors.black; // Couleur de texte par défaut

    if (wordState == true) {
      backgroundColor = Colors.green.shade700;
      fontColor = Colors.white; // Texte blanc sur fond vert
    } else if (wordState == false) {
      backgroundColor = Colors.red.shade700;
      fontColor = Colors.white; // Texte blanc sur fond rouge
    } else {
      backgroundColor = const Color(0xffe0e0e0); // Couleur de puce par défaut
    }

    // On crée le widget Chip une seule fois pour le réutiliser
    final chip = Chip(
      label: Text(
        word,
        style: TextStyle(
          color: fontColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      // ✅ ON APPLIQUE LA COULEUR CALCULÉE ICI
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    return Draggable<WordData>(
      data: WordData(word: word, fromIndex: fromIndex),
      // Le feedback (ce qu'on voit en glissant) utilise le même style
      feedback: Material(
        color: Colors.transparent,
        elevation: 4.0,
        child: chip,
      ),
      // Ce qui reste derrière utilise aussi le même style
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }

}



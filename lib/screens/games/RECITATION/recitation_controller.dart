import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class RecitationController extends ChangeNotifier {
  // --- Propriétés communes ---
  final SpeechToText speech = SpeechToText();
  bool isSpeechInitialized = false;
  String transcribedText = "";

  // =========================================================================
  // CORRECTION : Les 'getters' qui causaient l'erreur ont été remplacés
  // par de simples variables publiques.
  // Cela leur donne un 'setter' et un 'getter' automatiquement,
  // ce qui résout l'erreur "There isn't a setter".
  // =========================================================================
  bool isListening = false;
  bool isVerifying = false;
  bool isLoading = true;

  // --- Getter Abstrait (doit être implémenté par les sous-classes) ---
  String? get currentReference;

  // --- Méthodes Communes ---
  void toggleListening() {
    if (isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  Future<void> startListening() async {
    if (!isSpeechInitialized || isListening) return;
    await speech.stop();
    isListening = true;
    transcribedText = "";
    notifyListeners();
    await speech.listen(
      onResult: (result) {
        transcribedText = result.recognizedWords;
        notifyListeners();
      },
      localeId: "fr_FR",
      cancelOnError: false,
      partialResults: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    if (!isListening) return;
    await speech.stop();
    isListening = false;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    if (transcribedText.isNotEmpty) {
      await verifyRecitation();
    }
  }

  // --- Méthode Abstraite ---
  Future<void> verifyRecitation();

  @override
  void dispose() {
    speech.stop();
    super.dispose();
  }
}
// Fichier: services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    // Configuration initiale de la voix (optionnel)
    _flutterTts.setLanguage("fr-FR"); // Mettre la voix en français
    _flutterTts.setSpeechRate(0.5); // Ralentir un peu la vitesse de parole
    _flutterTts.setVolume(1.0);     // Volume maximum
  }

  /// Fait lire un texte à voix haute.
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  /// Arrête la lecture.
  Future<void> stop() async {
    await _flutterTts.stop();
  }
  void setCompletionHandler(Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }
}
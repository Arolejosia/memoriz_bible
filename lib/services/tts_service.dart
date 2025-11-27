import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  Function()? _onComplete;
  bool _isInitialized = false;

  // ✅ AJOUT : Méthode initialize
  Future<void> initialize(String language) async {
    try {
      print('🔊 Initializing TTS with language: $language');

      // ✅ CORRECTION : Configurer les paramètres AVANT la langue
      await _flutterTts.setVolume(1.0); // Volume (0.0 à 1.0)
      await _flutterTts.setSpeechRate(0.5); // Vitesse de lecture (0.0 à 1.0)
      await _flutterTts.setPitch(1.0); // Ton de la voix (0.5 à 2.0)

      // ✅ CORRECTION : Sur Android, définir le moteur TTS
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.awaitSpeakCompletion(true);

      // Configurer les handlers
      _flutterTts.setCompletionHandler(() {
        print('🔊 TTS Completion handler called');
        _onComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
        // Ne pas bloquer si erreur, continuer quand même
        _onComplete?.call();
      });

      _flutterTts.setStartHandler(() {
        print('🔊 TTS Started speaking');
      });

      _flutterTts.setCancelHandler(() {
        print('🛑 TTS Cancelled');
        _onComplete?.call();
      });

      // Configurer la langue en dernier
      await setLanguage(language);

      _isInitialized = true;
      print('✅ TTS initialized successfully');

    } catch (e) {
      print('❌ Error initializing TTS: $e');
      _isInitialized = false;
    }
  }

  // ✅ AJOUT : Méthode setLanguage
  Future<void> setLanguage(String language) async {
    try {
      // Convertir le code langue en format TTS
      final ttsLang = _getLanguageCode(language);

      print('🔊 Setting TTS language to: $ttsLang');

      // ✅ CORRECTION : Vérifier les langues disponibles AVANT de définir
      final languages = await _flutterTts.getLanguages;
      print('📋 Available languages: ${languages?.length ?? 0}');

      if (languages != null && languages.isNotEmpty) {
        // Vérifier si la langue demandée est disponible
        bool hasExactMatch = languages.any((lang) =>
            lang.toString().toLowerCase().contains(ttsLang.toLowerCase()));

        bool hasFallback = languages.any((lang) =>
            lang.toString().toLowerCase().startsWith(language.toLowerCase()));

        if (hasExactMatch) {
          print('✅ Exact language match found: $ttsLang');
          await _flutterTts.setLanguage(ttsLang);
        } else if (hasFallback) {
          print('⚠️ Using fallback language for: $language');
          final fallbackLang = languages.firstWhere((lang) =>
              lang.toString().toLowerCase().startsWith(language.toLowerCase()));
          await _flutterTts.setLanguage(fallbackLang.toString());
        } else {
          print('⚠️ Language not available, using default');
          // Utiliser la première langue disponible comme fallback
          await _flutterTts.setLanguage(languages.first.toString());
        }
      } else {
        // Pas de langues disponibles, essayer quand même
        print('⚠️ No languages list available, trying anyway');
        await _flutterTts.setLanguage(ttsLang);
      }

      // ✅ AJOUT : Essayer de définir une voix spécifique pour améliorer la qualité
      await _trySetBestVoice(language);

    } catch (e) {
      print('❌ Error setting language: $e');
      // Continuer même en cas d'erreur
    }
  }

  // ✅ AJOUT : Essayer de trouver la meilleure voix disponible
  Future<void> _trySetBestVoice(String language) async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) {
        print('⚠️ No voices available');
        return;
      }

      print('📋 Available voices: ${voices.length}');

      // Chercher une voix qui correspond à la langue
      final langPrefix = language.toLowerCase();
      final matchingVoices = voices.where((voice) {
        final locale = voice['locale']?.toString().toLowerCase() ?? '';
        return locale.startsWith(langPrefix);
      }).toList();

      if (matchingVoices.isNotEmpty) {
        // Préférer une voix locale si disponible
        final localVoice = matchingVoices.firstWhere(
              (voice) => !(voice['networkConnectionRequired'] ?? false),
          orElse: () => matchingVoices.first,
        );

        print('🔊 Setting voice: ${localVoice['name']} (${localVoice['locale']})');
        await _flutterTts.setVoice(localVoice);
      } else {
        print('⚠️ No matching voice found for language: $language');
      }
    } catch (e) {
      print('❌ Error setting voice: $e');
      // Continuer même si on ne peut pas définir de voix spécifique
    }
  }

  // Helper pour convertir le code langue
  String _getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case 'fr':
      case 'french':
        return 'fr-FR';
      case 'en':
      case 'english':
        return 'en-US';
      default:
        return 'en-US'; // Défaut en anglais
    }
  }

  // Définir le callback de complétion
  void setCompletionHandler(Function() onComplete) {
    _onComplete = onComplete;
    print('🔊 Completion handler set');
  }

  // Parler le texte
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      print('⚠️ TTS not initialized, initializing now...');
      await initialize('fr'); // Défaut en français
    }

    if (text.isEmpty) {
      print('⚠️ Cannot speak empty text');
      return;
    }

    try {
      print('🔊 TTS speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

      // Arrêter toute lecture en cours
      await _flutterTts.stop();

      // ✅ CORRECTION : Attendre un petit délai après stop
      await Future.delayed(const Duration(milliseconds: 100));

      // Démarrer la nouvelle lecture
      final result = await _flutterTts.speak(text);

      if (result == 1) {
        print('✅ TTS speak command successful');
      } else {
        print('⚠️ TTS speak command returned: $result');
        // Même si le résultat n'est pas 1, le TTS peut quand même fonctionner
      }

    } catch (e) {
      print('❌ Error speaking text: $e');
      // ✅ AJOUT : Appeler le handler de complétion même en cas d'erreur
      Future.delayed(const Duration(milliseconds: 500), () {
        _onComplete?.call();
      });
    }
  }

  // Arrêter la lecture
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      print('🛑 TTS stopped');
    } catch (e) {
      print('❌ Error stopping TTS: $e');
    }
  }

  // Mettre en pause (si supporté)
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      print('⏸️ TTS paused');
    } catch (e) {
      print('❌ Error pausing TTS: $e');
    }
  }

  // Vérifier si TTS est en train de parler
  Future<bool> isSpeaking() async {
    try {
      return await _flutterTts.awaitSpeakCompletion(true) ?? false;
    } catch (e) {
      print('❌ Error checking speaking status: $e');
      return false;
    }
  }

  // Obtenir les voix disponibles
  Future<List<dynamic>> getVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      print('📋 Available voices: ${voices?.length ?? 0}');
      return voices ?? [];
    } catch (e) {
      print('❌ Error getting voices: $e');
      return [];
    }
  }

  // Définir une voix spécifique
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
      print('🔊 Voice set to: ${voice['name']}');
    } catch (e) {
      print('❌ Error setting voice: $e');
    }
  }

  // Nettoyer les ressources
  void dispose() {
    _flutterTts.stop();
    _onComplete = null;
    _isInitialized = false;
    print('🗑️ TTS Service disposed');
  }
}
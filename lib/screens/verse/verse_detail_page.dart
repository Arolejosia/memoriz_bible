// Fichier : lib/verse_detail_page.dart
// <--- NOUVEL IMPORT
import 'package:memoriz_bible/models/language_provider.dart';      // <--- NOUVEL IMPORT
import 'package:memoriz_bible/services/bible_validation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/game_context.dart';
import '../games/DICTEE/DicteePage.dart';
import '../games/RECITATION/recitation_page.dart';
import '../games/ORDRE/ordre_game_page.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../games/QCM/QcmPage.dart';
import '../games/TEXTE-TROU/jeu_trous.dart';
import '../../models/verse_model.dart';
import '../core/pageDeConfiguration.dart';
import '../../services/Bible_service.dart';

class VerseDetailPage extends StatefulWidget {
  final Verse verse;
  const VerseDetailPage({super.key, required this.verse});
  @override
  State<VerseDetailPage> createState() => _VerseDetailPageState();
}

class _VerseDetailPageState extends State<VerseDetailPage> {
  late Verse currentVerse;
  String? userId;
  bool _isValidating = false;
  BibleValidationResult? _validationResult;
  final List<String> gameSequence = ["qcm", "texte_a_trous", "ordre", "dictee", "recitation"];

  @override
  void initState() {
    super.initState();
    currentVerse = widget.verse;
    userId = FirebaseAuth.instance.currentUser?.uid;
    _validateVerseOnLoad();
  }

  // Helper pour la traduction
  String t(String key, {Map<String, String>? params}) {
    // Utilise 'read' car on est dans une fonction, pas dans le build
    final lang = context.read<LanguageProvider>().language;
    return VerseDetailTranslations.t(key, lang, params: params);
  }

  Future<void> _validateVerseOnLoad() async {
    setState(() => _isValidating = true);
    try {
      final lang = context.read<LanguageProvider>().language;
      final verseData = await BibleService().getPassageText(
          currentVerse.reference,
          language: lang // 👈 AJOUTÉ
      );
      if (mounted) {
        setState(() {
          if (verseData.isEmpty) {
            _validationResult = BibleValidationResult(
              isValid: false,
              errorMessage: t('ref_not_found', params: {'ref': currentVerse.reference}),
            );
          } else {
            _validationResult = BibleValidationResult(isValid: true);
          }
          _isValidating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationResult = BibleValidationResult(
            isValid: false,
            errorMessage: t('validation_error', params: {'error': e.toString()}),
          );
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _showPreviewBeforeStarting() async {
    if (_validationResult != null && !_validationResult!.isValid) {
      _showValidationError(_validationResult!.errorMessage!);
      return;
    }
    final shouldStart = await _showVersePreview();
    if (shouldStart) {
      await _startLearning();
    }
  }

  Future<bool> _showVersePreview() async {
    final lang = context.read<LanguageProvider>().language;
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // 'context' a accès au provider, pas 'dialogContext' directement
        String tDialog(String key, {Map<String, String>? params}) {

          return VerseDetailTranslations.t(key, lang, params: params);
        }
        return AlertDialog(
          title: Row(children: [ const Icon(Icons.visibility, color: Colors.indigo), const SizedBox(width: 12), Expanded(child: Text(currentVerse.reference, style: const TextStyle(fontSize: 18)))]),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green[300]!)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, size: 16, color: Colors.green[700]), const SizedBox(width: 6), Text(tDialog('ref_valid'), style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))]),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<VerseData>>(
                    future: BibleService().getPassageText(
                        currentVerse.reference,
                        language: lang // 👈 AJOUTÉ
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return _buildPreviewErrorState(tDialog);
                      final verses = snapshot.data!;
                      return Card(
                        elevation: 0, color: Colors.indigo[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              children: verses.map((verseData) {
                                final verseNumber = verseData.reference.split(':').last;
                                return TextSpan(children: [TextSpan(text: " $verseNumber ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), TextSpan(text: verseData.text)]);
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [Icon(Icons.info_outline, size: 18, color: Colors.blue[700]), const SizedBox(width: 8), Expanded(child: Text(tDialog('start_journey'), style: TextStyle(fontSize: 12, color: Colors.blue[900])))]),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(tDialog('cancel'))),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(tDialog('start')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildPreviewErrorState(String Function(String, {Map<String, String>? params}) tDialog) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange[700]),
        const SizedBox(height: 16),
        Text(tDialog('text_unavailable'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(tDialog('text_load_error', params: {'ref': currentVerse.reference}), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange[200]!)),
          child: Row(children: [Icon(Icons.help_outline, size: 18, color: Colors.orange[700]), const SizedBox(width: 8), Expanded(child: Text(tDialog('continue_no_text'), style: TextStyle(fontSize: 12, color: Colors.orange[900])))]),
        ),
      ],
    );
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String tDialog(String key, {Map<String, String>? params}) {
          final lang = context.read<LanguageProvider>().language;
          return VerseDetailTranslations.t(key, lang, params: params);
        }
        return AlertDialog(
          title: Row(children: [Icon(Icons.error_outline, color: Colors.red[700], size: 28), const SizedBox(width: 12), Expanded(child: Text(tDialog('invalid_reference'), style: const TextStyle(fontSize: 20)))]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
                  child: Row(children: [Icon(Icons.close, color: Colors.red[700], size: 20), const SizedBox(width: 8), Expanded(child: Text(currentVerse.reference, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900], fontSize: 16)))]),
                ),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [Icon(Icons.help_outline, size: 18, color: Colors.grey[600]), const SizedBox(width: 8), Expanded(child: Text(tDialog('contact_support_if_error'), style: TextStyle(fontSize: 12, color: Colors.grey[700])))]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: Text(tDialog('contact_support')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tDialog('technical_support'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("${tDialog('reference_label')} ${currentVerse.reference}"),
                        const SizedBox(height: 2),
                        Text("${tDialog('email_label')} support@memorizbible.com"),
                      ],
                    ),
                    backgroundColor: Colors.indigo[700],
                    duration: const Duration(seconds: 8),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: Text(tDialog('got_it')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startLearning() async {
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(currentVerse.id);
    await docRef.update({'status': 'learning', 'updatedAt': FieldValue.serverTimestamp()});
    await _refreshVerseDataFromFirestore();
    _navigateToGame("qcm");
  }

  void _continueLearning() {
    int currentGameIndex = currentVerse.progressLevel;
    if (currentGameIndex < gameSequence.length) {
      _navigateToGame(gameSequence[currentGameIndex]);
    }
  }

  Future<void> _navigateToGame(String gameMode) async {
    Widget gamePage;
    switch (gameMode) {
      case "qcm": gamePage = QcmGamePage(verse: currentVerse, gameContext: GameContext.progression); break;
      case "texte_a_trous": gamePage = TexteATrousPage(verse: currentVerse, gameContext: GameContext.progression); break;
      case "ordre": gamePage = OrdreGamePage(verse: currentVerse, gameContext: GameContext.progression); break;
      case "dictee": gamePage = DicteePage.solo(verse: currentVerse, isSandbox: false); break;
      case "recitation": gamePage = RecitationPage(verse: currentVerse, gameContext: GameContext.progression); break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('game_not_implemented', params: {'gameMode': gameMode}))));
        return;
    }
    final gameResult = await Navigator.push(context, MaterialPageRoute(builder: (context) => gamePage));
    if (gameResult == true) {
      await _refreshVerseDataFromFirestore();
      _launchNextGame();
    }
  }

  void _launchNextGame() {
    int nextGameIndex = currentVerse.progressLevel;
    if (nextGameIndex < gameSequence.length) {
      String nextGameMode = gameSequence[nextGameIndex];
      print(t('step_success_next_game', params: {'nextGameMode': nextGameMode}));
      _navigateToGame(nextGameMode);
    } else {
      print(t('journey_completed'));
    }
  }

  Future<void> _refreshVerseDataFromFirestore() async {
    final doc = await FirebaseFirestore.instance.collection('users/$userId/verses').doc(currentVerse.id).get();
    if (doc.exists) {
      setState(() => currentVerse = Verse.fromFirestore(doc));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilise 'watch' ici pour que l'UI se reconstruise si la langue change
    final lang = context.watch<LanguageProvider>().language;
    // Crée une fonction 't' locale qui utilise la langue actuelle
    String t(String key, {Map<String, String>? params}) => VerseDetailTranslations.t(key, lang, params: params);

    if (_isValidating) {
      return Scaffold(
        appBar: AppBar(title: Text(currentVerse.reference)),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(t('validate_verse'))])),
      );
    }
    if (_validationResult != null && !_validationResult!.isValid) {
      return _buildInvalidVerseScreen(t);
    }
    return Scaffold(
      appBar: AppBar(title: Text(currentVerse.reference), backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [_buildVerseTextDisplay(), const SizedBox(height: 24), const Divider(), const SizedBox(height: 16), _buildVerseBody(t)]),
      ),
    );
  }

  Widget _buildInvalidVerseScreen(String Function(String, {Map<String, String>? params}) t) {
    return Scaffold(
      appBar: AppBar(title: Text(currentVerse.reference), backgroundColor: Colors.red[700], foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
              const SizedBox(height: 24),
              Text(t('invalid_or_nonexistent'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red[700]), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
                child: Text(_validationResult!.errorMessage!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.arrow_back), label: Text(t('back')), onPressed: () => Navigator.of(context).pop())),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: Text(t('delete')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => _showDeleteConfirmation(t),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String Function(String, {Map<String, String>? params}) t) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t('delete_invalid_verse_title')),
          content: Text(t('delete_confirmation_body', params: {'ref': currentVerse.reference})),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users/$userId/verses').doc(currentVerse.id).delete();
                if (mounted) {
                  context.read<VerseLibrary>().reloadAllData();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('verse_deleted_success')), backgroundColor: Colors.green));
                }
              },
              child: Text(t('delete')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVerseBody(String Function(String, {Map<String, String>? params}) t) {
    if (!currentVerse.isUserAdded) return _buildNotAddedView(t);
    switch (currentVerse.status) {
      case VerseStatus.neutral: return _buildNeutralView(t);
      case VerseStatus.learning: return _buildLearningView(t);
      case VerseStatus.mastered: return _buildMasteredView(t);
    }
  }

  Widget _buildNeutralView(String Function(String, {Map<String, String>? params}) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text(t('ready_to_learn'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(t('start_memorization_journey'), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.school),
            label: Text(t('start_learning')),
            onPressed: _showPreviewBeforeStarting,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildLearningView(String Function(String, {Map<String, String>? params}) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.school, color: Colors.orange, size: 40),
            title: Text(t('learning_in_progress'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(t('step_of_5', params: {'step': (currentVerse.progressLevel + 1).toString()})),
          ),
        ),
        const SizedBox(height: 24),
        _buildProgressBar(currentVerse.progressLevel, t),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.play_circle_fill),
          label: Text(t('continue_progress')),
          onPressed: _continueLearning,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.gamepad_outlined),
          label: Text(t('free_play_sandbox')),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PageDeJeuPrincipale(initialReference: currentVerse.reference))),
        ),
      ],
    );
  }

  Widget _buildMasteredView(String Function(String, {Map<String, String>? params}) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 60, color: Colors.green),
          const SizedBox(height: 20),
          Text(t('verse_mastered'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(t('congratulations_all_steps'), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.replay),
            label: Text(t('practice_again')),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PageDeJeuPrincipale(initialReference: currentVerse.reference))),
          )
        ],
      ),
    );
  }

  Widget _buildProgressBar(int progressLevel, String Function(String, {Map<String, String>? params}) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('progress'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 10,
                decoration: BoxDecoration(color: index < progressLevel ? Colors.green : Colors.grey[300], borderRadius: BorderRadius.circular(5)),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVerseTextDisplay() {
    final lang = context.watch<LanguageProvider>().language;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<VerseData>>(
          future: BibleService().getPassageText(
              currentVerse.reference,
              language: lang // 👈 AJOUTÉ
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(t('cannot_load_text')));
            final verses = snapshot.data!;
            return RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 20, height: 1.5),
                children: verses.map((verseData) {
                  final verseNumber = verseData.reference.split(':').last;
                  return TextSpan(children: [TextSpan(text: " $verseNumber ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)), TextSpan(text: verseData.text)]);
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotAddedView(String Function(String, {Map<String, String>? params}) t) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 20),
          Text(t('verse_not_added'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(t('add_to_library_prompt'), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(t('add_to_my_library')),
            onPressed: () async {
              await context.read<VerseLibrary>().addVerse(currentVerse.reference, currentVerse.book, "");
              await _refreshVerseDataFromFirestore();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('verse_added', params: {'ref': currentVerse.reference}))));
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          )
        ],
      ),
    );
  }
}
// File: lib/l10n/verse_detail_translations.dart

class VerseDetailTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final translations = {
      'validate_verse': {'fr': 'Validation du verset...', 'en': 'Validating verse...'},
      'ref_not_found': {'fr': "La référence '{ref}' n'existe pas ou n'a pas pu être trouvée.", 'en': "The reference '{ref}' does not exist or could not be found."},
      'validation_error': {'fr': "Impossible de valider la référence.\n\nErreur: {error}", 'en': "Unable to validate the reference.\n\nError: {error}"},
      'ref_valid': {'fr': 'Référence valide', 'en': 'Valid Reference'},
      'start_journey': {'fr': 'Vous allez commencer le parcours de mémorisation en 5 étapes.', 'en': 'You are about to start the 5-step memorization journey.'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'start': {'fr': 'COMMENCER', 'en': 'START'},
      'text_unavailable': {'fr': 'Texte non disponible', 'en': 'Text Unavailable'},
      'text_load_error': {'fr': "Le texte de {ref} n'a pas pu être chargé.", 'en': "The text for {ref} could not be loaded."},
      'continue_no_text': {'fr': 'Vous pouvez continuer, mais le texte ne sera pas affiché dans les jeux.', 'en': 'You can continue, but the text will not be displayed in the games.'},
      'invalid_reference': {'fr': 'Référence invalide', 'en': 'Invalid Reference'},
      'contact_support_if_error': {'fr': "Si vous pensez qu'il s'agit d'une erreur, contactez notre support technique.", 'en': "If you believe this is an error, please contact our technical support."},
      'contact_support': {'fr': 'Contacter le support', 'en': 'Contact Support'},
      'technical_support': {'fr': 'Support Technique', 'en': 'Technical Support'},
      'reference_label': {'fr': 'Référence:', 'en': 'Reference:'},
      'email_label': {'fr': 'Email:', 'en': 'Email:'},
      'got_it': {'fr': 'Compris', 'en': 'Got it'},
      'game_not_implemented': {'fr': "Page de jeu '{gameMode}' non implémentée.", 'en': "Game page '{gameMode}' not implemented."},
      'step_success_next_game': {'fr': "Étape réussie ! Lancement automatique du jeu suivant : {nextGameMode}", 'en': "Step successful! Automatically launching next game: {nextGameMode}"},
      'journey_complete': {'fr': '🎉 PARCOURS TERMINÉ !', 'en': '🎉 JOURNEY COMPLETE!'},
      'invalid_or_nonexistent': {'fr': 'Référence invalide ou inexistante', 'en': 'Invalid or Nonexistent Reference'},
      'back': {'fr': 'Retour', 'en': 'Back'},
      'delete': {'fr': 'Supprimer', 'en': 'Delete'},
      'delete_invalid_verse_title': {'fr': 'Supprimer le verset invalide ?', 'en': 'Delete invalid verse?'},
      'delete_confirmation_body': {'fr': "Voulez-vous supprimer {ref} de votre bibliothèque ?\n\nCette action est irréversible.", 'en': "Do you want to delete {ref} from your library?\n\nThis action is irreversible."},
      'verse_deleted_success': {'fr': 'Verset supprimé avec succès', 'en': 'Verse deleted successfully'},
      'ready_to_learn': {'fr': 'Verset Prêt à Apprendre', 'en': 'Verse Ready to Learn'},
      'start_memorization_journey': {'fr': 'Commencez le parcours de mémorisation pour suivre votre progression.', 'en': 'Start the memorization journey to track your progress.'},
      'start_learning': {'fr': "COMMENCER L'APPRENTISSAGE", 'en': 'START LEARNING'},
      'learning_in_progress': {'fr': "En cours d'apprentissage", 'en': 'Learning in Progress'},
      'step_of_5': {'fr': 'Étape {step} sur 5', 'en': 'Step {step} of 5'},
      'continue_progress': {'fr': 'CONTINUER LA PROGRESSION', 'en': 'CONTINUE PROGRESS'},
      'free_play_sandbox': {'fr': 'Jeu libre (Sandbox)', 'en': 'Free Play (Sandbox)'},
      'verse_mastered': {'fr': 'Verset Connu !', 'en': 'Verse Mastered!'},
      'congratulations_all_steps': {'fr': 'Félicitations ! Vous avez complété toutes les étapes.', 'en': 'Congratulations! You have completed all the steps.'},
      'practice_again': {'fr': "S'entraîner à nouveau", 'en': 'Practice Again'},
      'progress': {'fr': 'Progression :', 'en': 'Progress:'},
      'cannot_load_text': {'fr': 'Impossible de charger le texte.', 'en': 'Unable to load text.'},
      'verse_not_added': {'fr': 'Verset non ajouté', 'en': 'Verse Not Added'},
      'add_to_library_prompt': {'fr': 'Ajoutez ce verset à votre bibliothèque pour commencer à le mémoriser.', 'en': 'Add this verse to your library to start memorizing it.'},
      'add_to_my_library': {'fr': 'AJOUTER À MA BIBLIOTHÈQUE', 'en': 'ADD TO MY LIBRARY'},
      'verse_added': {'fr': '{ref} ajouté !', 'en': '{ref} added!'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }
}


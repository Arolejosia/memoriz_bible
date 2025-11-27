import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../QUESTION_PERSONALISEE/CustomGamePage.dart';
import '../../QUESTION_PERSONALISEE/CustomQuestionsPage.dart';
import '../../models/game_context.dart';
import '../../services/Bible_service.dart';
import '../core/bible_reference_picker_page.dart';
import '../games/DICTEE/DicteePage.dart';

import '../games/QCM/QcmPage.dart';
import '../games/ORDRE/ordre_game_page.dart';
import '../games/RECITATION/recitation_page.dart';
import '../games/TEXTE-TROU/jeu_trous.dart';
import 'game_results_page.dart';
import 'waiting_room_page.dart';
import '../../QUESTION_PERSONALISEE/CustomQuestionsPage.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import 'multiplayer_translations.dart';

enum GameMode {
  qcm,
  texteATrous,
  remettreEnOrdre,
  dictee,
  recitation,
  questionsPersonnalisees;

  bool get usesQuestionCounter {
    switch (this) {
      case GameMode.qcm:
      case GameMode.texteATrous:
      case GameMode.questionsPersonnalisees:
        return true;
      case GameMode.remettreEnOrdre:
      case GameMode.dictee:
      case GameMode.recitation:
        return false;
    }
  }
}

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  String? _selectedCustomListId;
  String? _selectedCustomListName;

  final TextEditingController _referenceController = TextEditingController(text: "Jean 3:16");
  final TextEditingController _roomCodeController = TextEditingController();

  String _difficulty = "moyen";
  GameMode _selectedGameMode = GameMode.qcm;
  int _numberOfQuestions = 5;
  bool _isLoading = false;
  DateTime? _scheduledStart;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return MPTranslations.t(key, lang, params: params);
  }
  String _translateGameType(GameMode mode) {
    switch (mode) {
      case GameMode.qcm:
        return t('game_type_qcm');
      case GameMode.texteATrous:
        return t('game_type_texteATrous');
      case GameMode.remettreEnOrdre:
        return t('game_type_remettreEnOrdre');
      case GameMode.dictee:
        return t('game_type_dictee');
      case GameMode.recitation:
        return t('game_type_recitation');
      case GameMode.questionsPersonnalisees:
        return t('game_type_questionsPersonnalisees');
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadCustomQuestions(String listId, int maxQuestions) async {
    try {
      final listDoc = await FirebaseFirestore.instance
          .collection('questionLists')
          .doc(listId)
          .get();

      if (!listDoc.exists) {
        throw Exception('Liste de questions introuvable');
      }

      final questionIds = List<String>.from(listDoc.data()!['questionIds']);
      final limitedIds = questionIds.take(maxQuestions).toList();
      final questions = <Map<String, dynamic>>[];

      for (var questionId in limitedIds) {
        final questionDoc = await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(questionId)
            .get();

        if (questionDoc.exists) {
          questions.add(questionDoc.data()!);
        }
      }

      return questions;
    } catch (e) {
      throw Exception('Erreur lors du chargement des questions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateOrdreBatch({
    required String reference,
    required String niveau,
    required int nombre,
    required String language,
  }) async {
    try {
      print("🔍 ========== APPEL ORDRE (via BibleService) ==========");
      print("  📖 Reference: $reference");
      print("  🌍 Language: $language");

      // Appel direct à votre service
      final jeux = await BibleService().generateOrdreBatch(
        reference: reference,
        niveau: niveau,
        nombre: nombre,
        language: language,
      );

      print("  ✅ ${jeux.length} jeux générés par BibleService");
      return jeux;

    } catch (e) {
      print("❌ ========== EXCEPTION ORDRE (BibleService) ==========");
      print("  ❌ Message: $e");
      throw Exception("Erreur API: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _generateRecitationQuestions({
    required String reference,
    required String niveau,
    required int nombre,
    required String language, // ✅ AJOUT DU PARAMÈTRE
  }) async {
    try {
      // ✅ PASSER LA LANGUE À L'API
      final verseDataList = await BibleService().getPassageText(reference, language: language);
      List<Map<String, dynamic>> questions = [];

      for (int i = 0; i < nombre && i < verseDataList.length; i++) {
        final verseData = verseDataList[i];
        questions.add({
          'text': verseData.text,
          'reference': verseData.reference,
        });
      }

      return questions;
    } catch (e) {
      throw Exception('Failed to generate recitation questions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateDicteeQuestions({
    required String reference,
    required String niveau,
    required int nombre,
    required String language, // ✅ AJOUT DU PARAMÈTRE
  }) async {
    try {
      // ✅ PASSER LA LANGUE À L'API
      final verseDataList = await BibleService().getPassageText(reference, language: language);
      List<Map<String, dynamic>> questions = [];

      for (int i = 0; i < nombre && i < verseDataList.length; i++) {
        final verseData = verseDataList[i];
        questions.add({
          'text': verseData.text,
          'reference': verseData.reference,
          'type': 'dictee',
        });
      }

      return questions;
    } catch (e) {
      throw Exception('Failed to generate dictee questions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _generateQcmBatch({
    required String reference,
    required String niveau,
    required int nombre,
    required String language,
  }) async {
    try {
      print("🔍 ========== APPEL QCM (via BibleService) ==========");
      print("  📖 Reference: $reference");
      print("  🌍 Language: $language");

      // Appel direct à votre service
      final questions = await BibleService().generateQcmBatch(
        reference: reference,
        niveau: niveau,
        nombre: nombre,
        language: language,
      );

      print("  ✅ ${questions.length} questions générées par BibleService");
      return questions;

    } catch (e) {
      print("❌ ========== EXCEPTION QCM (BibleService) ==========");
      print("  ❌ Message: $e");
      // Affiche le message d'erreur de l'API (ex: 500)
      throw Exception("Erreur API: $e");
    }
  }
  Future<List<Map<String, dynamic>>> _generateTexteATrousBatch({
    required String reference,
    required String niveau,
    required int nombre,
    required String language,
  }) async {
    final batchData = await BibleService().generateTexteATrousBatch(
      reference: reference,
      niveau: niveau,
      nombre: nombre,
      language: language,
    );

    return batchData.jeux.map((texteATrousData) => {
      'verset_modifie': texteATrousData.versetModifie,
      'reponses': texteATrousData.reponses,
      'indices': texteATrousData.indices,
      'reference': texteATrousData.reference,
    }).toList();
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<String?> _showAliasDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    // 🔹 Étape 1 : récupérer l'utilisateur courant
    final user = FirebaseAuth.instance.currentUser;
    String defaultAlias = "";

    if (user != null) {
      // 🔹 Étape 2 : essayer le displayName d’abord
      defaultAlias = user.displayName ?? "";

      // 🔹 Étape 3 : si vide, vérifier dans Firestore
      if (defaultAlias.isEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          defaultAlias = userDoc.data()?['username'] ?? "";
        }
      }

      // 🔹 Étape 4 : si toujours vide, prendre le préfixe de l’adresse e-mail
      if (defaultAlias.isEmpty && user.email != null) {
        defaultAlias = user.email!.split('@').first;
      }
    }

    final TextEditingController aliasController = TextEditingController(text: defaultAlias);

    // 🔹 Étape 5 : afficher la boîte de dialogue
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('choose_nickname_title')),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: aliasController,
              autofocus: true,
              maxLength: 20,
              decoration: InputDecoration(
                hintText: t("enter_nickname_hint"),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Veuillez entrer un pseudo";
                }
                if (value.trim().length < 3) {
                  return "Au moins 3 caractères";
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(t('cancel')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(t('confirm')),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(aliasController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }




  Future<void> _showCustomListChoiceDialog() async {
    print("🔍 Recherche des listes pour userId: ${currentUser?.uid}");

    final snapshot = await FirebaseFirestore.instance
        .collection('questionLists')
        .where('userId', isEqualTo: currentUser?.uid)
        .get();

    print("📚 Nombre total de listes trouvées: ${snapshot.docs.length}");

    final listsWithQuestions = snapshot.docs.where((doc) {
      final data = doc.data();
      final count = (data['questionIds'] as List).length;
      return count > 0;
    }).toList();

    print("✅ Listes avec questions: ${listsWithQuestions.length}");

    if (!mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text(t("custom_questions"))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (listsWithQuestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t('custom_list_info_count', params: {
                            'count': listsWithQuestions.length.toString(),
                            'plural': listsWithQuestions.length > 1 ? 's' : '',
                          }),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  t('custom_list_info_steps_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 16),

              if (listsWithQuestions.isEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1️⃣', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(child: Text(t('custom_list_info_step1'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2️⃣', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(child: Text(t('custom_list_info_step2'))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3️⃣', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(child: Text(t('custom_list_info_step3'))),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              Text(
                t('what_to_do'),
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Annuler'),
            ),

            // Les 3 boutons en colonne
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bouton "Choisir une liste existante"
                  ElevatedButton.icon(
                    onPressed: listsWithQuestions.isEmpty
                        ? null
                        : () => Navigator.of(context).pop('select'),
                    icon: const Icon(Icons.playlist_play),
                    label: Text(listsWithQuestions.isEmpty
                        ? 'Aucune liste disponible'
                        : 'Choisir une liste existante'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bouton "Créer des questions"
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop('questions'),
                    icon: const Icon(Icons.quiz),
                    label: const Text('Créer des questions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bouton "Créer une liste"
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop('list'),
                    icon: const Icon(Icons.list),
                    label: const Text('Créer une liste'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (choice == 'select') {
      await _showSelectListDialog();
    } else if (choice == 'questions') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomQuestionsPage(userId: currentUser!.uid),
        ),
      );
      if (mounted) {
        _showCreateListAfterQuestions();
      }
    } else if (choice == 'list') {
      await _createNewListAndQuestions();
    }
  }

// Nouvelle fonction pour demander si l'utilisateur veut créer une liste après avoir créé des questions
  Future<void> _showCreateListAfterQuestions() async {
    final shouldCreateList = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('questions_created_title')),
          content: Text(t('questions_created_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t('later')),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.list),
              label: Text(t('create_list')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );

    if (shouldCreateList == true && mounted) {
      await _createNewListAndQuestions();
    }
  }


  // 👇 CRÉER UNE NOUVELLE LISTE
  Future<void> _createNewListAndQuestions() async {
    if (currentUser == null) return;

    // Rediriger vers la page des listes de questions
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionListsPage(userId: currentUser!.uid),
      ),
    );

    // Si une liste a été créée et retournée, la sélectionner automatiquement
    if (result != null && result.containsKey('listId') && result.containsKey('listName')) {
      setState(() {
        _selectedCustomListId = result['listId'];
        _selectedCustomListName = result['listName'];
      });
    }
  }

  // 👇 SÉLECTIONNER UNE LISTE EXISTANTE
  Future<void> _showSelectListDialog() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('questionLists')
        .where('userId', isEqualTo: currentUser?.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      _showSnackBar("Aucune liste disponible. Créez-en une d'abord.");
      return;
    }

    // Filtrer les listes qui ont au moins une question
    final listsWithQuestions = snapshot.docs.where((doc) {
      final data = doc.data();
      final count = (data['questionIds'] as List).length;
      return count > 0;
    }).toList();

    if (listsWithQuestions.isEmpty) {
      _showSnackBar("Aucune liste avec des questions. Ajoutez des questions à vos listes.");
      return;
    }

    if (!mounted) return;

    final selectedListId = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t('select_list_title')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: listsWithQuestions.length,
              itemBuilder: (context, index) {
                final doc = listsWithQuestions[index];
                final data = doc.data();
                final listId = doc.id;
                final name = data['name'];
                final count = (data['questionIds'] as List).length;

                return ListTile(
                  title: Text(name),
                  subtitle: Text(
                    '$count ${count > 1 ? t("question_count_plural") : t("question_count_singular")}',
                  ),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () => Navigator.of(context).pop(listId),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('cancel')),
            ),
          ],
        );
      },
    );

    if (selectedListId != null) {
      final selectedDoc = listsWithQuestions.firstWhere((doc) => doc.id == selectedListId);
      final data = selectedDoc.data();

      setState(() {
        _selectedCustomListId = selectedListId;
        _selectedCustomListName = data['name'];
      });
    }
  }

  Future<void> _createRoom() async {
    if (currentUser == null) {
      _showSnackBar("Veuillez vous connecter.");
      return;
    }

    if (_selectedGameMode != GameMode.questionsPersonnalisees && _referenceController.text.trim().isEmpty) {
      _showSnackBar("Veuillez entrer une référence biblique.");
      return;
    }

    if (_selectedGameMode == GameMode.questionsPersonnalisees && _selectedCustomListId == null) {
      _showSnackBar("Veuillez sélectionner ou créer une liste de questions personnalisées.");
      return;
    }

    final String? alias = await _showAliasDialog(context);
    if (alias == null || alias.isEmpty) return;

    final language = context.read<LanguageProvider>().language;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> gameData;
      final int finalNumberOfQuestions;

      if (_selectedGameMode.usesQuestionCounter) {
        finalNumberOfQuestions = _numberOfQuestions;
      } else {
        finalNumberOfQuestions = _countVersesInReference(_referenceController.text);
      }

      switch (_selectedGameMode) {
        case GameMode.questionsPersonnalisees:
          gameData = await _loadCustomQuestions(_selectedCustomListId!, finalNumberOfQuestions);
          break;

        case GameMode.remettreEnOrdre:
          gameData = await _generateOrdreBatch(
            reference: _referenceController.text.trim(),
            niveau: _difficulty,
            nombre: finalNumberOfQuestions,
            language: language,
          );
          break;

        case GameMode.texteATrous:
          gameData = await _generateTexteATrousBatch(
            reference: _referenceController.text.trim(),
            niveau: _difficulty,
            nombre: finalNumberOfQuestions,
            language: language,
          );
          break;

        case GameMode.recitation:
          gameData = await _generateRecitationQuestions(
            reference: _referenceController.text.trim(),
            niveau: _difficulty,
            nombre: finalNumberOfQuestions,
            language: language, // ✅ PASSER LA LANGUE
          );
          break;

        case GameMode.dictee:
          gameData = await _generateDicteeQuestions(
            reference: _referenceController.text.trim(),
            niveau: _difficulty,
            nombre: finalNumberOfQuestions,
            language: language, // ✅ PASSER LA LANGUE
          );
          break;

        case GameMode.qcm:
        default:
          gameData = await _generateQcmBatch(
            reference: _referenceController.text.trim(),
            niveau: _difficulty,
            nombre: finalNumberOfQuestions,
            language: language,
          );
          break;
      }

      String roomCode;
      bool codeExists = true;
      int attempts = 0;

      do {
        roomCode = _generateRoomCode();
        final docSnapshot = await FirebaseFirestore.instance
            .collection('game_rooms')
            .doc(roomCode)
            .get();
        codeExists = docSnapshot.exists;
        attempts++;
      } while (codeExists && attempts < 10);

      if (codeExists) {
        throw Exception("Impossible de générer un code unique. Réessayez.");
      }

      await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).set({
        'status': 'waiting',
        'hostId': currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'config': {
          'gameType': _selectedGameMode.name,
          'difficulty': _difficulty,
          'numberOfQuestions': finalNumberOfQuestions,
          'reference': _selectedGameMode == GameMode.questionsPersonnalisees
              ? _selectedCustomListName ?? 'Questions personnalisées'
              : _referenceController.text.trim(),
          'customListId': _selectedCustomListId,
          'maxPlayers': 8,
          'scheduledStart': _scheduledStart != null ? Timestamp.fromDate(_scheduledStart!) : null,
          'language': language,
        },
        'players': {
          currentUser!.uid: {
            'name': alias,
            'score': 0,
            'answers': {},
            'isHost': true,
          }
        },
        'questions': gameData,
        'currentQuestionIndex': -1,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('rooms')
          .doc(roomCode)
          .set({
        'roomCode': roomCode,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'gameType': _selectedGameMode.name,
        'reference': _selectedGameMode == GameMode.questionsPersonnalisees
            ? _selectedCustomListName ?? 'Questions personnalisées'
            : _referenceController.text.trim(),
        'difficulty': _difficulty,
        'scheduledStart': _scheduledStart != null ? Timestamp.fromDate(_scheduledStart!) : null,
        'language': language,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomPage(roomCode: roomCode),
          ),
        );
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la création: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      _showSnackBar("Veuillez entrer un code de salle.");
      return;
    }

    if (currentUser == null) {
      _showSnackBar("Veuillez vous connecter.");
      return;
    }

    final String? alias = await _showAliasDialog(context);
    if (alias == null || alias.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        throw Exception("Aucune salle trouvée avec ce code.");
      }

      final roomData = roomDoc.data()!;
      final players = roomData['players'] as Map<String, dynamic>;
      final config = roomData['config'] as Map<String, dynamic>;
      final maxPlayers = config['maxPlayers'] ?? 8;

      if (players.length >= maxPlayers) {
        throw Exception("Cette salle est pleine ($maxPlayers joueurs max).");
      }

      if (roomData['status'] != 'waiting') {
        throw Exception("Cette partie a déjà commencé.");
      }

      if (players.containsKey(currentUser!.uid)) {
        throw Exception("Vous êtes déjà dans cette salle.");
      }

      await roomRef.update({
        'players.${currentUser!.uid}': {
          'name': alias,
          'score': 0,
          'answers': {},
          'isHost': false,
        }
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('rooms')
          .doc(roomCode)
          .set({
        'roomCode': roomCode,
        'status': 'waiting',
        'reference': config['reference'],
        'gameType': config['gameType'],
        'difficulty': config['difficulty'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WaitingRoomPage(roomCode: roomCode),
          ),
        );
      }
    } catch (e) {
      _showSnackBar("Erreur: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  int _countVersesInReference(String ref) {
    final parts = ref.split(':');
    if (parts.length < 2) return 1;

    final versePart = parts[1];
    if (versePart.contains('-')) {
      final rangeParts = versePart.split('-');
      try {
        final start = int.parse(rangeParts[0]);
        final end = int.parse(rangeParts[1]);
        return end - start + 1;
      } catch (e) {
        return 1;
      }
    } else {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('hub_title')),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomQuestionsPage(userId: currentUser!.uid),
                ),
              );
            },
            icon: const Icon(Icons.quiz, color: Colors.green),
            label: Text(t('my_questions'), style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRoomsPage()),
                  );
                },
                icon: const Icon(Icons.meeting_room),
                label: Text(t('my_rooms')),
              ),
            ),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('create_party'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Type de jeu
                    Text(t('game_type'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<GameMode>(
                        value: _selectedGameMode,
                        isExpanded: true,
                        underline: Container(),
                        items: GameMode.values.map((mode) {
                          return DropdownMenuItem<GameMode>(
                            value: mode,
                            child: Text(_translateGameType(mode)),
                          );
                        }).toList(),
                        onChanged: (GameMode? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedGameMode = newValue;
                              if (newValue != GameMode.questionsPersonnalisees) {
                                _selectedCustomListId = null;
                                _selectedCustomListName = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 👇 SECTION QUESTIONS PERSONNALISÉES
                    if (_selectedGameMode == GameMode.questionsPersonnalisees) ...[
                      const Text(
                        "Questions personnalisées",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),

                      if (_selectedCustomListId == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showCustomListChoiceDialog,
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(t('choose_a_list')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        )
                      else
                        Card(
                          color: Colors.green.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedCustomListName ?? t('list_selected'),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(t('list_ready'),
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showCustomListChoiceDialog,
                                  child: Text(t('change')),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else ...[
                      Text(t('biblical_reference'),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: Text(
                          _referenceController.text.isEmpty
                              ? "Choisir une référence"
                              : _referenceController.text,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final selectedRef = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BibleReferencePickerPage()),
                          );

                          if (selectedRef != null) {
                            setState(() {
                              _referenceController.text = selectedRef;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Difficulté (caché pour questions personnalisées)
                    if (_selectedGameMode != GameMode.questionsPersonnalisees) ...[
                      Text(
                        t('difficulty') ,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButton<String>(
                          value: _difficulty,
                          isExpanded: true,
                          underline: Container(),
                          items:  [
                            DropdownMenuItem(value: "facile", child: Text(t('difficulty_easy'))),
                            DropdownMenuItem(value: "moyen", child: Text(t('difficulty_medium'))),
                            DropdownMenuItem(value: "difficile", child: Text(t('difficulty_hard'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _difficulty = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nombre de questions
                    if (_selectedGameMode.usesQuestionCounter) ...[
                      const SizedBox(height: 16),

                      Text(t('number_of_questions'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3,5, 7, 10, 12, 15, 20,25].map((number) {
                          final isSelected = _numberOfQuestions == number;
                          return InkWell(
                            onTap: () {
                              setState(() => _numberOfQuestions = number);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                "$number",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Planifier une heure
                    const SizedBox(height: 16),
                    Text(t('scheduled_time_optional'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _scheduledStart != null
                                  ? "${_scheduledStart!.day}/${_scheduledStart!.month} ${_scheduledStart!.hour}h${_scheduledStart!.minute.toString().padLeft(2, '0')}"
                                  : t('choose_date_time'),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );

                              if (date != null) {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (time != null) {
                                  setState(() {
                                    _scheduledStart = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        if (_scheduledStart != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _scheduledStart = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bouton créer
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createRoom,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.add),
                        label: Text(_isLoading ? t('creating') : t('create_game')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Rejoindre une partie
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('join_party'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(t('room_code'),
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roomCodeController,
                      decoration:  InputDecoration(
                        hintText: t('enter_6_char_code'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _joinRoom,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.login),
                        label: Text(_isLoading ? t('joining') : t('join')),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (currentUser != null)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "${currentUser!.displayName ?? currentUser!.email}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MyRoomsPage extends StatelessWidget {
  const MyRoomsPage({super.key});

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _leaveRoom(String uid, String roomCode) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("rooms")
          .doc(roomCode)
          .delete();

      await FirebaseFirestore.instance
          .collection("game_rooms")
          .doc(roomCode)
          .update({
        "players.$uid": FieldValue.delete(),
      });
    } catch (e) {
      print("Erreur leaveRoom: $e");
    }
  }

  Future<void> _endRoomAsHost(String roomCode) async {
    try {
      final roomRef = FirebaseFirestore.instance.collection("game_rooms").doc(roomCode);
      final snap = await roomRef.get();

      if (!snap.exists) return;

      final data = snap.data()!;
      final players = data["players"] as Map<String, dynamic>? ?? {};

      await roomRef.update({
        "status": "finished",
        "finishedAt": FieldValue.serverTimestamp(),
        "questions": FieldValue.delete(),
        "currentQuestionIndex": FieldValue.delete(),
        "currentQuestionEndsAt": FieldValue.delete(),
      });

      for (final uid in players.keys) {
        final userRoomRef = FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("rooms")
            .doc(roomCode);

        await userRoomRef.set({
          "status": "finished",
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Erreur endRoomAsHost: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Veuillez vous connecter.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Mes Salles")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('rooms')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune salle pour le moment."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomCode = docs[index].id;
              final status = data['status'] ?? "waiting";
              final gameType = data['gameType'] ?? 'qcm';

              IconData icon;
              Color color;
              String subtitle;

              switch (status) {
                case "waiting":
                  icon = Icons.hourglass_empty;
                  color = Colors.orange;
                  subtitle = "En attente";
                  break;
                case "started":
                case "playing":
                  icon = Icons.play_arrow;
                  color = Colors.green;
                  subtitle = "En cours";
                  break;
                case "finished":
                  icon = Icons.check_circle;
                  color = Colors.blueGrey;
                  subtitle = "Terminé";
                  break;
                default:
                  icon = Icons.help;
                  color = Colors.grey;
                  subtitle = status;
              }

              final isHost = data['hostId'] == FirebaseAuth.instance.currentUser!.uid;

              return Card(
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text("Salle $roomCode"),
                  subtitle: Text(
                      "Jeu: ${gameType} • Réf: ${data['reference']} • Diff: ${data['difficulty']} • $subtitle"),
                  trailing: IconButton(
                    icon: Icon(
                      isHost ? Icons.delete_forever : Icons.close,
                      color: isHost ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      if (isHost) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Terminer la salle ?"),
                            content: const Text(
                                "Cela arrêtera la partie pour tous les joueurs."),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Annuler")),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Terminer")),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _endRoomAsHost(roomCode);
                        }
                      } else {
                        await _leaveRoom(
                            FirebaseAuth.instance.currentUser!.uid, roomCode);
                      }
                    },
                  ),
                  onTap: () async {
                    if (status == "waiting") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WaitingRoomPage(roomCode: roomCode),
                        ),
                      );
                    } else if (status == "started" || status == "playing") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            final mode = GameMode.values.firstWhere(
                                  (e) => e.name == gameType,
                              orElse: () => GameMode.qcm,
                            );

                            switch (mode) {
                              case GameMode.questionsPersonnalisees:
                                return CustomQuestionsGamePage(roomCode: roomCode);
                              case GameMode.qcm:
                                return QcmGamePage(
                                    gameContext: GameContext.duel,
                                    roomCode: roomCode);
                              case GameMode.texteATrous:
                                return TexteATrousPage(
                                    gameContext: GameContext.duel,
                                    roomCode: roomCode);
                              case GameMode.remettreEnOrdre:
                                return OrdreGamePage(
                                    roomCode: roomCode,
                                    gameContext: GameContext.duel);
                              case GameMode.dictee:
                                return DicteePage(
                                    verse: null,
                                    isSandbox: false,
                                    roomCode: roomCode);
                              case GameMode.recitation:
                                return RecitationPage(
                                    gameContext: GameContext.duel,
                                    roomCode: roomCode);
                              default:
                                return QcmGamePage(
                                    gameContext: GameContext.duel,
                                    roomCode: roomCode);
                            }
                          },
                        ),
                      );
                    } else if (status == "finished") {
                      final resultDoc = await FirebaseFirestore.instance
                          .collection('game_results')
                          .doc(roomCode)
                          .get();

                      if (resultDoc.exists) {
                        final resultData = resultDoc.data()!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameResultsPage(
                              players: resultData['scores'],
                              questions: resultData['questionsSummary'],
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

}

extension StringCasingExtension on String {
  String capitalizeFirstLetter() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
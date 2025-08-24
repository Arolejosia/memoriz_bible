import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'waiting_room_page.dart';

enum MultiplayerGameMode { qcm, trouverLaReference ,remettreEnOrdre,jeuTrous }

class MultiplayerHubPage extends StatefulWidget {
  const MultiplayerHubPage({super.key});

  @override
  State<MultiplayerHubPage> createState() => _MultiplayerHubPageState();
}

class _MultiplayerHubPageState extends State<MultiplayerHubPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isLoading = false;

  MultiplayerGameMode _selectedGameMode = MultiplayerGameMode.qcm;
  String _selectedBook = "Jean";
  final _chapitreController = TextEditingController(text: "3");
  final _versetDebutController = TextEditingController(text: "16");
  final _versetFinController = TextEditingController();
  double _maxPlayers = 2.0;
  String _difficulty = 'moyen';

  String? _sourceGroup;
  String? _sourceBookForRefGame;

  final List<String> books = const ["Genèse",
    "Exode",
    "Lévitique",
    "Nombres",
    "Deutéronome",
    "Josué",
    "Juges",
    "Ruth",
    "1 Samuel",
    "2 Samuel",
    "1 Rois",
    "2 Rois",
    "1 Chroniques",
    "2 Chroniques",
    "Esdras",
    "Néhémie",
    "Esther",
    "Job",
    "Psaume",
    "Proverbes",
    "Ecclésiaste",
    "Cantique des Cantiques",
    "Ésaïe",
    "Jérémie",
    "Lamentations",
    "Ézéchiel",
    "Daniel",
    "Osée",
    "Joël",
    "Amos",
    "Abdias",
    "Jonas",
    "Michée",
    "Nahum",
    "Habacuc",
    "Sophonie",
    "Aggée",
    "Zacharie",
    "Malachie",
    "Matthieu",
    "Marc",
    "Luc",
    "Jean",
    "Actes",
    "Romains",
    "1 Corinthiens",
    "2 Corinthiens",
    "Galates",
    "Éphésiens",
    "Philippiens",
    "Colossiens",
    "1 Thessaloniciens",
    "2 Thessaloniciens",
    "1 Timothée",
    "2 Timothée",
    "Tite",
    "Philémon",
    "Hébreux",
    "Jacques",
    "1 Pierre",
    "2 Pierre",
    "1 Jean",
    "2 Jean",
    "3 Jean",
    "Jude",
    "Apocalypse",];

  @override
  void dispose() {
    _chapitreController.dispose();
    _versetDebutController.dispose();
    _versetFinController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);
    // --- On construit la configuration en fonction du jeu ---
    Map<String, dynamic> gameConfig = {
      'gameType': _selectedGameMode.name,
      'difficulty': _difficulty,
      'maxPlayers': _maxPlayers.toInt(),
    };

    if (_selectedGameMode == MultiplayerGameMode.trouverLaReference) {
      gameConfig['sourceGroup'] = _sourceGroup;
      gameConfig['sourceBook'] = _sourceBookForRefGame;
    } else {
      String verseStart = _versetDebutController.text;
      String verseEnd = _versetFinController.text;
      String reference = "$_selectedBook ${_chapitreController.text}:$verseStart";
      if (verseEnd.isNotEmpty) {
        reference += "-$verseEnd";
      }
      gameConfig['reference'] = reference;
    }

    String reference = "${_selectedBook} ${_chapitreController.text}:${_versetDebutController.text}-${_versetFinController.text}";
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final String roomCode = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).set({
      'status': 'waiting',
      'hostId': currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'config': {
        'gameType': _selectedGameMode.name,
        'reference': reference,
        'difficulty': 'moyen',
        'maxPlayers': _maxPlayers.toInt(),
      },
      'players': {
        currentUser!.uid: {'name': currentUser!.displayName ?? currentUser!.email, 'score': 0, 'answers': {}}
      },
      'questions': [],
      'currentQuestionIndex': -1,
    });

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoomPage(roomCode: roomCode)));
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();
    if (roomCode.isEmpty || currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) throw Exception("No room found with this code.");

      final roomData = roomDoc.data()!;
      final players = roomData['players'] as Map<String, dynamic>;
      final config = roomData['config'] as Map<String, dynamic>;

      if (players.length >= config['maxPlayers']) throw Exception("This room is full.");
      if (roomData['status'] != 'waiting') throw Exception("This game has already started.");

      await roomRef.update({
        'players.${currentUser!.uid}': {'name': currentUser!.displayName ?? currentUser!.email, 'score': 0, 'answers': {}}
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoomPage(roomCode: roomCode)));
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Multiplayer Game")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Create Game", style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text("1. Choisissez un mode de jeu", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: MultiplayerGameMode.values.map((gameMode) {
                return ChoiceChip(
                  label: Text(gameMode.name),
                  selected: _selectedGameMode == gameMode,
                  onSelected: (isSelected) {
                    if (isSelected) setState(() => _selectedGameMode = gameMode);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text("2. Choisissez la source des versets", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // ✅ AFFICHE CETTE INTERFACE SI LE JEU N'EST PAS "Trouver la Référence"
            if (_selectedGameMode != MultiplayerGameMode.trouverLaReference)
              _buildBroadSourceSelector(),

            // ✅ AFFICHE CETTE INTERFACE UNIQUEMENT POUR "Trouver la Référence"
            if (_selectedGameMode == MultiplayerGameMode.trouverLaReference)
              _buildBroadSourceSelector(),

            const Divider(height: 32),
            Text("3. Paramètres de la partie", style: Theme.of(context).textTheme.titleMedium),
            // ... (Votre Slider pour le nombre de joueurs)

            Text("Number of Players: ${_maxPlayers.toInt()}"),
            Slider(
              value: _maxPlayers, min: 2, max: 6, divisions: 4,
              label: _maxPlayers.toInt().toString(),
              onChanged: (value) => setState(() => _maxPlayers = value),
            ),

            ElevatedButton(
              onPressed: _isLoading ? null : _createRoom,
              child: const Text("Create & Invite"),
            ),

            const Divider(height: 48),

            Text("Join with Code", style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _roomCodeController,
              decoration: const InputDecoration(labelText: "Enter Room Code", border: OutlineInputBorder()),
              textAlign: TextAlign.center,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinRoom,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Join"),
            ),
          ],
        ),
      ),
    );
  }
  /// Widget pour choisir une source large (Toute la Bible, Groupes de livres)
  Widget _buildBroadSourceSelector() {
    return Column(
      children: [
        // Option pour jouer sur toute la Bible
        ListTile(
          title: const Text("Toute la Bible"),
          selectedTileColor: Colors.blue.withOpacity(0.1),
          selected: _sourceBookForRefGame == null && _sourceGroup == null,
          onTap: () => setState(() {
            _sourceBookForRefGame = null;
            _sourceGroup = null;
          }),
        ),

        // Section pour l'Ancien Testament
        ExpansionTile(
          title: const Text("Ancien Testament"),
          children: [
            _buildGroupTile("Pentateuque", "pentateuque"),
            _buildGroupTile("Livres Historiques", "historiques"),
            _buildGroupTile("Livres Poétiques & Sagesse", "poetiques"),
            _buildGroupTile("Prophètes Majeurs", "prophetes_majeurs"),
            _buildGroupTile("Prophètes Mineurs", "prophetes_mineurs"),
          ],
        ),

        // Section pour le Nouveau Testament
        ExpansionTile(
          title: const Text("Nouveau Testament"),
          children: [
            _buildGroupTile("Évangiles", "evangiles"),
            _buildGroupTile("Actes des Apôtres", "histoire_nt"),
            _buildGroupTile("Épîtres de Paul", "epitres_paul"),
            _buildGroupTile("Épîtres Générales", "epitres_generales"),
            _buildGroupTile("Apocalypse", "apocalypse"),
          ],
        ),
      ],
    );
  }

// Helper pour construire les ListTile des groupes afin d'éviter la répétition
// Assurez-vous que cette fonction existe aussi dans votre classe State.
  Widget _buildGroupTile(String title, String groupKey) {
    return ListTile(
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 32.0),
      selectedTileColor: Colors.blue.withOpacity(0.1),
      selected: _sourceGroup == groupKey,
      onTap: () => setState(() {
        _sourceGroup = groupKey;
        _sourceBookForRefGame = null; // On s'assure que le livre unique est désélectionné
      }),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'multiplayer_game_page.dart';
import '../../services/Bible_service.dart';

class WaitingRoomPage extends StatefulWidget {
  final String roomCode;
  const WaitingRoomPage({super.key, required this.roomCode});

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  bool _isStartingGame = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _startGame() async {
    setState(() => _isStartingGame = true);

    final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists || !mounted) return;

    final config = roomDoc.data()!['config'] as Map<String, dynamic>;
    final gameType = config['gameType'];
    final reference = config['reference'];
    final sessionLength = 10;

    try {
      List<Map<String, dynamic>> questionsAsJson = [];
      for (int i = 0; i < sessionLength; i++) {
        switch (gameType) {
          case 'trouverLaReference':
            final q = await BibleService().generateReferenceQuestion(
              difficulty: config['difficulty'],
              sourceGroup: config['sourceGroup'],
            );
            questionsAsJson.add({
              'questionText': q.questionText,
              'options': q.options,
              'correctAnswer': q.correctAnswer
            });
            break;
          case 'qcm':
            final q = await BibleService().generateQcmQuestion(reference: reference);
            questionsAsJson.add({
              'questionText': q.questionText,
              'options': q.options,
              'correctAnswer': q.correctAnswer
            });
            break;

        // ✅ ADDED: Case for "Remettre en Ordre"
          case 'remettreEnOrdre':
            final q = await BibleService().generateRemettreEnOrdreQuestion(reference: reference);
            questionsAsJson.add({
              'questionText': 'Remettez les mots suivants dans le bon ordre :',
              'options': q.motsMelanges,
              'correctAnswer': q.motsCorrects, // The answer is a List<String>
            });
            break;

        // ✅ ADDED: Case for "Texte à Trous"
          case 'jeuTrous':
            final q = await BibleService().generateTexteATrousQuestion(reference: reference);
            questionsAsJson.add({
              'questionText': q.versetModifie,
              'correctAnswer': q.reponses, // The answer is a List<String>
              'options': [], // No options for this game type
            });
            break;
        }

      }

      await roomRef.update({
        'questions': questionsAsJson,
        'currentQuestionIndex': 0,
        'status': 'in_progress',
      });

    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not start game.")));
    } finally {
      if (mounted) setState(() => _isStartingGame = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomStream = FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text("Game Lobby")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("This room no longer exists."));
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          if (roomData['status'] == 'in_progress') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MultiplayerGamePage(roomCode: widget.roomCode)));
              }
            });
          }

          final players = roomData['players'] as Map<String, dynamic>;
          final config = roomData['config'] as Map<String, dynamic>;

          final isHost = currentUser?.uid == roomData['hostId'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectableText(widget.roomCode, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                Card(
                  child: ListTile(
                    title: Text("Game: ${config['gameType']}"),
                    subtitle: Text("Players: ${players.length}/${config['maxPlayers']}"),
                  ),
                ),
                const Divider(height: 32),
                Text("Players", style: Theme.of(context).textTheme.titleLarge),
                Expanded(
                  child: ListView(
                    children: players.entries.map((entry) {
                      return Card(child: ListTile(title: Text(entry.value['name'])));
                    }).toList(),
                  ),
                ),
                if (isHost)
                  ElevatedButton(
                    onPressed: (players.length >= 2 && !_isStartingGame) ? _startGame : null,
                    child: _isStartingGame ? const CircularProgressIndicator() : const Text("Start Game"),
                  )
                else
                  const Text("Waiting for the host to start...", textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}
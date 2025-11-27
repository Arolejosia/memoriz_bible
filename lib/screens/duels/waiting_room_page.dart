import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../../QUESTION_PERSONALISEE/CustomGamePage.dart';
import '../../models/game_context.dart';
import '../../models/language_provider.dart';
import '../../utils/string_extensions.dart';
import '../games/DICTEE/DicteeMultiplayerPage.dart';
import '../games/DICTEE/DicteePage.dart';
import '../games/QCM/QcmPage.dart';
import '../games/RECITATION/recitation_page.dart';
import '../games/TEXTE-TROU/jeu_trous.dart';
import '../games/ordre/ordre_game_page.dart';
import '../../models/verse_model.dart';
import 'game_results_page.dart';
import 'multiplayer_translations.dart';

class WaitingRoomPage extends StatefulWidget {
  final String roomCode;

  const WaitingRoomPage({super.key, required this.roomCode});

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // ✅ COMME RÉCITATION : Helper avec context.read
  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return MPTranslations.t(key, lang, params: params);
  }

  Future<void> _startGame() async {
    final roomRef =
    FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode);

    await roomRef.update({
      'status': 'started',
      'currentQuestionIndex': 0,
    });

    final roomSnap = await roomRef.get();
    final players = (roomSnap['players'] as Map<String, dynamic>);

    // Vérifier le nombre minimum de joueurs
    if (players.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('error_min_2_players')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mettre à jour les sous-rooms utilisateurs
    for (final uid in players.keys) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('rooms')
          .doc(widget.roomCode)
          .update({'status': 'started'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomRef =
    FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('room_title', params: {'roomCode': widget.roomCode})),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                t('share_invite_message', params: {'roomCode': widget.roomCode}),
                subject: t('share_invite_subject'),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return Center(child: Text(t('room_not_exist')));
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final config = roomData['config'] as Map<String, dynamic>;
          final players = (roomData['players'] as Map<String, dynamic>?) ?? {};
          final isHost = roomData['hostId'] == currentUser?.uid;

          // Redirection auto quand status == started
          if (roomData['status'] == 'started') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              // Lire la langue pour les pages qui en ont besoin
              final lang = context.read<LanguageProvider>().language;

              Widget destinationPage;

              switch (config['gameType']) {
                case 'remettreEnOrdre':
                  destinationPage = OrdreGamePage(
                    gameContext: GameContext.duel,
                    roomCode: widget.roomCode,
                  );
                  break;

                case 'qcm':
                  destinationPage = QcmGamePage(
                    gameContext: GameContext.duel,
                    roomCode: widget.roomCode,
                  );
                  break;

                case 'texteATrous':
                  destinationPage = TexteATrousPage(
                    gameContext: GameContext.duel,
                    roomCode: widget.roomCode,
                  );
                  break;

                case 'questionsPersonnalisees':
                  destinationPage = CustomQuestionsGamePage(
                    roomCode: widget.roomCode,
                  );
                  break;

                case 'recitation':
                  destinationPage = RecitationPage(
                    gameContext: GameContext.duel,
                    roomCode: widget.roomCode,
                  );
                  break;

                case 'dictee':
                  destinationPage = DicteeMultiplayerPage(
                    roomCode: widget.roomCode,
                  );
                  break;

                default:
                  destinationPage = QcmGamePage(
                    gameContext: GameContext.duel,
                    roomCode: widget.roomCode,
                  );
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => destinationPage),
              );
            });

            // Loader pendant la redirection
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.transparent),
              ),
            );
          }

          final scheduled = (config['scheduledStart'] as Timestamp?)?.toDate();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Infos du jeu
                Text("${t('game_type')}: ${_translateGameType(config['gameType'] ?? 'qcm')}"),
                Text("${t('reference')}: ${config['reference']}"),
                Text("${t('difficulty')}: ${_translateDifficulty(config['difficulty'])}"),
                Text("${t('questions')}: ${config['numberOfQuestions']}"),

                if (scheduled != null)
                  Text(
                    t('scheduled_for', params: {
                      'day': scheduled.day.toString(),
                      'month': scheduled.month.toString(),
                      'hour': scheduled.hour.toString(),
                      'minute': scheduled.minute.toString().padLeft(2, '0'),
                    }),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),

                const SizedBox(height: 24),

                // Liste joueurs
                Text(
                  t('players_count', params: {
                    'count': players.length.toString(),
                    'max': (config['maxPlayers'] ?? 8).toString(),
                  }),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: players.entries.map((entry) {
                      final uid = entry.key;
                      final player = entry.value as Map<String, dynamic>;
                      final name = player['name'] ?? t('unknown_player');
                      final isHostPlayer = player['isHost'] ?? false;

                      return ListTile(
                        leading: isHostPlayer
                            ? const Icon(Icons.star, color: Colors.orange)
                            : const Icon(Icons.person),
                        title: Text(name),
                        subtitle: Text(uid == roomData['hostId'] ? t('host') : t('player')),
                        trailing: isHost && uid != currentUser!.uid
                            ? IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () async {
                            await roomRef.update({
                              "players.$uid": FieldValue.delete(),
                            });

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('rooms')
                                .doc(widget.roomCode)
                                .delete();
                          },
                        )
                            : null,
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await roomRef.update({
                            "players.${currentUser!.uid}": FieldValue.delete(),
                          });

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser!.uid)
                              .collection('rooms')
                              .doc(widget.roomCode)
                              .delete();

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: Text(t('leave')),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (isHost)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: players.length >= 2 ? _startGame : null,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            players.length >= 2
                                ? t('start_game')
                                : t('waiting_for_player', params: {'count': players.length.toString()}),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: players.length >= 2 ? null : Colors.grey,
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  String _translateGameType(String gameType) {
    return t('game_type_$gameType');
  }

  String _translateDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
      case 'easy':
        return t('difficulty_easy');
      case 'moyen':
      case 'medium':
        return t('difficulty_medium');
      case 'difficile':
      case 'hard':
        return t('difficulty_hard');
      default:
        return difficulty;
    }
  }
}
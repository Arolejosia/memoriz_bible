import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import 'multiplayer_translations.dart';

class GameResultsPage extends StatelessWidget {
  final Map<String, dynamic> players;
  final List<dynamic> questions;

  const GameResultsPage({
    super.key,
    required this.players,
    required this.questions,
  });

  // ✅ COMME RÉCITATION : Helper avec context.read
  String t(BuildContext context, String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return MPTranslations.t(key, lang, params: params);
  }

  @override
  Widget build(BuildContext context) {
    // Sort players by score
    final sortedPlayers = players.entries.toList()
      ..sort((a, b) => (b.value['score'] as int).compareTo(a.value['score'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'results_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ================== PODIUM ==================
              if (sortedPlayers.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd Place
                      if (sortedPlayers.length > 1)
                        _buildPodiumPlace(
                          sortedPlayers[1].value['name'] ?? t(context, 'unknown_player'),
                          sortedPlayers[1].value['score'],
                          Colors.grey,
                          120,
                          "🥈",
                        ),
                      // 1st Place
                      _buildPodiumPlace(
                        sortedPlayers[0].value['name'] ?? t(context, 'unknown_player'),
                        sortedPlayers[0].value['score'],
                        Colors.amber,
                        160,
                        "🥇",
                      ),
                      // 3rd Place
                      if (sortedPlayers.length > 2)
                        _buildPodiumPlace(
                          sortedPlayers[2].value['name'] ?? t(context, 'unknown_player'),
                          sortedPlayers[2].value['score'],
                          Colors.brown,
                          100,
                          "🥉",
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 50),

              // ================== CLASSEMENT FINAL ==================
              Text(
                t(context, 'final_ranking'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  final player = sortedPlayers[index];
                  return Card(
                    child: ListTile(
                      leading: Text(
                        "#${index + 1}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(player.value['name'] ?? t(context, 'unknown_player')),
                      trailing: Text(
                        "${player.value['score']} ${t(context, 'pts', params: {})}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 32),

              // ================== RÉSUMÉ DES QUESTIONS ==================
              Text(
                t(context, 'questions_summary'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index] as Map<String, dynamic>;

                  String answerText = '';
                  bool isTexteATrous = q['reponses'] != null;

                  if (isTexteATrous) {
                    final answersData = q['reponses'];
                    if (answersData is List) {
                      answerText = (answersData as List<dynamic>).join(', ');
                    }
                  } else {
                    answerText = q['answer']?.toString() ?? t(context, 'unknown');
                  }

                  // Priorité : référence > verset_modifie > question
                  String questionText = q['question'] ?? t(context, 'unknown');

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t(context, 'question_number',
                                    params: {'number': (index + 1).toString()}),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (q['reference'] != null)
                                Text(
                                  q['reference'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            questionText,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(context, 'answers_label', params: {'answers': answerText}),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(t(context, 'back_to_home')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================== WIDGET PODIUM ==================
  Widget _buildPodiumPlace(
      String name,
      int score,
      Color color,
      double height,
      String medal,
      ) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(medal, style: const TextStyle(fontSize: 30)),
          Container(
            height: height,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$score",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
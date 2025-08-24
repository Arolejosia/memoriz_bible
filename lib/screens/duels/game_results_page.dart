import 'package:flutter/material.dart';

class GameResultsPage extends StatelessWidget {
  final Map<String, dynamic> players;
  final List<dynamic> questions;

  const GameResultsPage({
    super.key,
    required this.players,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = players.entries.toList()
      ..sort((a, b) => (b.value['score'] as int).compareTo(a.value['score'] as int));

    return Scaffold(
      appBar: AppBar(title: const Text("Results"), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🏆 Winner! 🏆", style: TextStyle(fontSize: 24, color: Colors.amber)),
              Text(
                sortedPlayers.first.value['name'],
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Text("Final Scores", style: Theme.of(context).textTheme.headlineSmall),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedPlayers.length,
                  itemBuilder: (context, index) {
                    final player = sortedPlayers[index];
                    return Card(
                      child: ListTile(
                        leading: Text("#${index + 1}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        title: Text(player.value['name']),
                        trailing: Text("${player.value['score']} pts", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
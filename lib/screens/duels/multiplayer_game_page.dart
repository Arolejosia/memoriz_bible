import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/questions_list.dart';
import '../../models/verse_model.dart';
import '../../models/language_provider.dart';
import '../games/QCM/qcm_multiplayer_controller.dart';
import 'game_results_page.dart';
import 'multiplayer_translations.dart';

class MultiplayerGamePage extends StatelessWidget {
  final String roomCode;
  final Verse verse;

  const MultiplayerGamePage({
    super.key,
    required this.roomCode,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QcmMultiplayerController(roomCode: roomCode),
      child: _MultiplayerQcmView(),
    );
  }
}

class _MultiplayerQcmView extends StatelessWidget {
  // ✅ COMME RÉCITATION : Helper avec context.read
  String t(BuildContext context, String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return MPTranslations.t(key, lang, params: params);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QcmMultiplayerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'duel_in_progress')),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timer
            Text(
              "${controller.timeLeft}",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),

            // Question
            Text(
              controller.questionText,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Options
            Expanded(
              child: ListView(
                children: controller.options.map((option) {
                  return Card(
                    child: ListTile(
                      title: Text(option),
                      onTap: controller.iHaveAnswered || controller.timeLeft == 0
                          ? null
                          : () => controller.submitAnswer(option),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Bouton suivant (host only)
            if (controller.currentUserId == controller.hostId)
              ElevatedButton(
                onPressed: controller.loadNextQuestion,
                child: Text(t(context, 'next_question')),
              ),
          ],
        ),
      ),
    );
  }
}
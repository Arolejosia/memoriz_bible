// Fichier: lib/widgets/review_list_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Bibliotheque.dart';
import '../models/verse_model.dart';


class ReviewListWidget extends StatelessWidget {
  const ReviewListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // On utilise Consumer pour accéder à la bibliothèque et se reconstruire si elle change
    return Consumer<VerseLibrary>(
      builder: (context, library, child) {

        // On filtre la liste complète pour ne garder que les versets à réviser
        final allVerses = library.myVerseCategories.expand((cat) => cat.verses);
        final now = DateTime.now();
        final versesToReview = allVerses.where((verse) {
          return verse.status == VerseStatus.mastered &&
              verse.reviewDate != null &&
              verse.reviewDate!.isBefore(now);
        }).toList();

        if (versesToReview.isEmpty) {
          // Si aucun verset n'est à réviser, on affiche un message d'encouragement
          return const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text("Aucune révision pour aujourd'hui !"),
              subtitle: Text("Vous êtes à jour."),
            ),
          );
        }

        // Si des versets sont à réviser, on affiche la liste
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "À réviser aujourd'hui (${versesToReview.length})",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...versesToReview.map((verse) => _buildReviewCard(context, verse)),
          ],
        );
      },
    );
  }

  /// Construit la carte pour un seul verset à réviser
  Widget _buildReviewCard(BuildContext context, Verse verse) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(verse.reference, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text("Vous souvenez-vous de ce verset ?"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text("J'avais oublié"),
                  onPressed: () {
                    context.read<VerseLibrary>().handleVerseReview(verse, wasSuccessful: false);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text("Je m'en souviens"),
                  onPressed: () {
                    context.read<VerseLibrary>().handleVerseReview(verse, wasSuccessful: true);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
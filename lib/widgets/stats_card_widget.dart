// Fichier : lib/widgets/stats_card_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart'; // Adaptez le chemin d'importation
import '../../models/verse_model.dart'; // Adaptez le chemin d'importation

class StatsCardWidget extends StatelessWidget {
  const StatsCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On utilise un Consumer pour écouter la VerseLibrary
    return Consumer<VerseLibrary>(
      builder: (context, library, child) {
        // Si les données ne sont pas prêtes, on affiche des cartes vides
        if (library.isLoading) {
          return const Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 80))),
              SizedBox(width: 16),
              Expanded(child: Card(child: SizedBox(height: 80))),
            ],
          );
        }

        // --- La logique de calcul est ici, au même endroit ---
        final allVerses = library.myVerseCategories.expand((cat) => cat.verses);
        final learningCount = allVerses.where((v) => v.status == VerseStatus.learning).length;
        final masteredCount = allVerses.where((v) => v.status == VerseStatus.mastered).length;

        // --- L'affichage est ici ---
        return Row(
          children: [
            Expanded(child: _buildStatCard(context, count: learningCount, title: "En cours", icon: Icons.school, color: Colors.orange, targetFilter: VerseStatus.learning)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(context, count: masteredCount, title: "Connus", icon: Icons.check_circle, color: Colors.green, targetFilter: VerseStatus.mastered)),
          ],
        );
      },
    );
  }

  // J'ai déplacé cette fonction ici pour que le widget soit autonome
  Widget _buildStatCard(BuildContext context, {required int count, required String title, required IconData icon, required Color color, required VerseStatus targetFilter}) {
    return InkWell(
      onTap: () {
        // Navigue vers la bibliothèque en passant le filtre
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerseLibraryPage(initialFilter: targetFilter),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(count.toString(), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text(title),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

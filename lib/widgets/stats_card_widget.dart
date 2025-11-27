// Fichier : lib/widgets/stats_card_widget.dart
// Affiche 3 cartes : Ajoutés, En cours, Connus

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../models/language_provider.dart';      // <--- NOUVEL IMPORT
import '../../models/verse_model.dart';

class StatsCardWidget extends StatelessWidget {
  const StatsCardWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On récupère la langue pour la traduction
    final lang = context.watch<LanguageProvider>().language;

    return Consumer<VerseLibrary>(
      builder: (context, library, child) {
        if (library.isLoading) {
          return const Row(
            children: [
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 8),
              Expanded(child: Card(child: SizedBox(height: 100))),
              SizedBox(width: 8),
              Expanded(child: Card(child: SizedBox(height: 100))),
            ],
          );
        }

        final allVerses = library.myVerseCategories.expand((cat) => cat.verses);

        final addedCount =
            allVerses.where((v) => v.status == VerseStatus.neutral).length;

        final learningCount =
            allVerses.where((v) => v.status == VerseStatus.learning).length;

        final masteredCount =
            allVerses.where((v) => v.status == VerseStatus.mastered).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                count: addedCount,
                title: StatsCardTranslations.t('added', lang), // <--- TRADUIT
                icon: Icons.library_add,
                color: Colors.blue,
                targetFilter: VerseStatus.neutral,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                title: StatsCardTranslations.t('learning', lang), // <--- TRADUIT
                count: learningCount,
                icon: Icons.school,
                color: Colors.orange,
                targetFilter: VerseStatus.learning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                count: masteredCount,
                title: StatsCardTranslations.t('mastered', lang), // <--- TRADUIT
                icon: Icons.check_circle,
                color: Colors.green,
                targetFilter: VerseStatus.mastered,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, {
        required int count,
        required String title,
        required IconData icon,
        required Color color,
        required VerseStatus targetFilter,
      }) {
    return InkWell(
      onTap: () {
        // On récupère la langue actuelle pour la passer à la page suivante
        final lang = context.read<LanguageProvider>().language;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerseLibraryPage(
              initialFilter: targetFilter,
              language: lang, // Assurez-vous que VerseLibraryPage accepte ce paramètre
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 14),

                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
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
}

// File: lib/l10n/stats_card_translations.dart

class StatsCardTranslations {
  static String t(String key, String lang) {
    final Map<String, Map<String, String>> translations = {
      'added': {'fr': 'Ajoutés', 'en': 'Added'},
      'learning': {'fr': 'En cours', 'en': 'Learning'},
      'mastered': {'fr': 'Connus', 'en': 'Mastered'},
    };
    return translations[key]?[lang] ?? key;
  }
}
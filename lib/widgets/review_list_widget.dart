// Fichier: lib/widgets/review_list_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Bibliotheque.dart';

import '../models/language_provider.dart';     // <--- NOUVEL IMPORT
import '../models/verse_model.dart';

class ReviewListWidget extends StatelessWidget {
  const ReviewListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VerseLibrary>(
      builder: (context, library, child) {
        // On récupère la langue actuelle
        final lang = context.watch<LanguageProvider>().language;

        // Helper pour simplifier les appels
        String t(String key, {Map<String, String>? params}) {
          return ReviewListTranslations.t(key, lang, params: params);
        }

        final allVerses = library.myVerseCategories.expand((cat) => cat.verses);
        final now = DateTime.now();
        final versesToReview = allVerses.where((verse) {
          return verse.status == VerseStatus.mastered &&
              verse.reviewDate != null &&
              verse.reviewDate!.isBefore(now);
        }).toList();

        if (versesToReview.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(t('no_reviews_today')), // <--- TRADUIT
              subtitle: Text(t('up_to_date')),     // <--- TRADUIT
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // On utilise les 'params' pour insérer le nombre
              t('to_review_today', params: {'count': versesToReview.length.toString()}), // <--- TRADUIT
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...versesToReview.map((verse) => _buildReviewCard(context, verse, t)), // On passe la fonction 't'
          ],
        );
      },
    );
  }

  /// Construit la carte pour un seul verset à réviser
  Widget _buildReviewCard(BuildContext context, Verse verse, String Function(String) t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(verse.reference, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(t('do_you_remember')), // <--- TRADUIT
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: Text(t('i_forgot')), // <--- TRADUIT
                  onPressed: () {
                    context.read<VerseLibrary>().handleVerseReview(verse, wasSuccessful: false);
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: Text(t('i_remember')), // <--- TRADUIT
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

// File: lib/l10n/review_list_translations.dart

class ReviewListTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'no_reviews_today': {
        'fr': 'Aucune révision pour aujourd\'hui !',
        'en': 'No reviews for today!'
      },
      'up_to_date': {
        'fr': 'Vous êtes à jour.',
        'en': 'You are up to date.'
      },
      'to_review_today': {
        'fr': 'À réviser aujourd\'hui ({count})',
        'en': 'To review today ({count})'
      },
      'do_you_remember': {
        'fr': 'Vous souvenez-vous de ce verset ?',
        'en': 'Do you remember this verse?'
      },
      'i_forgot': {
        'fr': 'J\'avais oublié',
        'en': 'I forgot'
      },
      'i_remember': {
        'fr': 'Je m\'en souviens',
        'en': 'I remember'
      },
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }
}
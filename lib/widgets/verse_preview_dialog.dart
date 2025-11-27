// Fichier: lib/widgets/verse_preview_dialog.dart

import 'package:flutter/material.dart';
import 'package:memoriz_bible/services/bible_service.dart';
import 'package:memoriz_bible/services/bible_validation_service.dart';
import 'package:memoriz_bible/models/verse_model.dart';

class VersePreviewDialog {
  /// Affiche une prévisualisation du verset avec validation
  /// Retourne true si l'utilisateur veut continuer, false sinon
  static Future<bool> show(BuildContext context, String reference) async {
    // Étape 1 : Valider la référence
    final validationResult = await BibleValidationService.validateReference(reference);

    if (!validationResult.isValid) {
      // Afficher l'erreur de validation
      await _showValidationError(context, reference, validationResult.errorMessage!);
      return false;
    }

    // Étape 2 : Charger et afficher le texte
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reference,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<VerseData>>(
              future: BibleService().getPassageText(reference),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorState(reference);
                }

                final verses = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge de validation
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                            const SizedBox(width: 6),
                            Text(
                              "Référence valide",
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Texte du verset
                      Card(
                        elevation: 0,
                        color: Colors.indigo[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                              children: verses.map((verseData) {
                                final verseNumber = verseData.reference.split(':').last;
                                return TextSpan(
                                  children: [
                                    TextSpan(
                                      text: " $verseNumber ",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                      ),
                                    ),
                                    TextSpan(text: verseData.text),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Informations supplémentaires
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${verses.length} verset${verses.length > 1 ? 's' : ''} • Version Segond 1910",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Annuler"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("COMMENCER"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Widget _buildErrorState(String reference) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.orange[700],
        ),
        const SizedBox(height: 16),
        const Text(
          "Texte non disponible",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Le texte de $reference n'a pas pu être chargé.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Vous pouvez continuer, mais le texte ne sera pas affiché dans l'application.",
                  style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _showValidationError(
      BuildContext context,
      String reference,
      String errorMessage,
      ) async {
    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Référence invalide",
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // La référence problématique
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reference,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Message d'erreur
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Section d'aide
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Conseils :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "• Vérifiez l'orthographe du livre\n"
                                "• Assurez-vous que le chapitre existe\n"
                                "• Vérifiez que le numéro de verset est correct",
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contact support
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Si vous pensez qu'il s'agit d'une erreur, contactez notre support technique.",
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text("Contacter le support"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Support Technique",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Référence: $reference"),
                        const SizedBox(height: 2),
                        const Text("Email: support@memorizbible.com"),
                      ],
                    ),
                    backgroundColor: Colors.indigo[700],
                    duration: const Duration(seconds: 8),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text("Compris"),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// EXEMPLE D'UTILISATION
// ==========================================

/*
// Dans progression_dashboard_page.dart ou bibliotheque.dart

// Remplacez _showVersePreview par :

Future<bool> _showVersePreview(String reference) async {
  return await VersePreviewDialog.show(context, reference);
}

// Ou utilisez directement :

final shouldContinue = await VersePreviewDialog.show(context, reference);
if (shouldContinue) {
  // L'utilisateur veut continuer
  // Ajouter le verset ou lancer le jeu
}
*/
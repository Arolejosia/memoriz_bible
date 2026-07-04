// File: lib/screens/public/support_page.dart

import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Besoin d\'aide avec MemorizBible ?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nous sommes là pour vous aider. Voici comment nous contacter '
                'ou trouver des réponses rapides.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                icon: Icons.email_outlined,
                title: 'Nous contacter',
                content:
                    'Pour toute question, suggestion ou problème technique, '
                    'écrivez-nous à : damgnearole@icloud.com\n\n'
                    'Nous répondons généralement sous 48 heures.',
              ),
              _buildSection(
                context,
                icon: Icons.help_outline,
                title: 'Questions fréquentes',
                content:
                    '• Comment réinitialiser mon mot de passe ?\n'
                    'Depuis l\'écran de connexion, appuyez sur "Mot de passe oublié".\n\n'
                    '• Comment supprimer mon compte ?\n'
                    'Rendez-vous dans Paramètres > Compte > Supprimer mon compte, '
                    'ou contactez-nous directement.\n\n'
                    '• L\'application ne se synchronise pas correctement.\n'
                    'Vérifiez votre connexion internet, puis redémarrez l\'application. '
                    'Si le problème persiste, contactez le support.',
              ),
              _buildSection(
                context,
                icon: Icons.bug_report_outlined,
                title: 'Signaler un bug',
                content:
                    'Si vous rencontrez un problème technique, décrivez-le le plus '
                    'précisément possible (étapes pour reproduire, appareil utilisé) '
                    'et envoyez-le à damgnearole@icloud.com',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}

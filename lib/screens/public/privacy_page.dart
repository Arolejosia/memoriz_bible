// File: lib/screens/public/privacy_page.dart

import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
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
                'Politique de confidentialité',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Dernière mise à jour : 04/07/2026',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _p(
                'MemorizBible ("nous", "notre application") respecte votre vie '
                'privée. Cette politique explique quelles données nous collectons, '
                'pourquoi, et comment elles sont protégées.',
              ),
              _h('1. Données que nous collectons'),
              _p(
                '• Informations de compte : adresse e-mail, nom (si fourni)\n'
                '• Données d\'utilisation : progression dans les jeux, versets '
                'mémorisés, statistiques d\'engagement (ex. jours actifs)\n'
                '• Données techniques : type d\'appareil, système d\'exploitation, '
                'identifiants anonymes à des fins de diagnostic',
              ),
              _h('2. Comment nous utilisons vos données'),
              _p(
                '• Fournir et améliorer les fonctionnalités de l\'application\n'
                '• Sauvegarder votre progression et vos préférences\n'
                '• Envoyer des notifications liées à votre activité (rappels, badges)\n'
                '• Assurer la sécurité et prévenir les abus',
              ),
              _h('3. Partage des données'),
              _p(
                'Nous ne vendons jamais vos données personnelles à des tiers. '
                'Vos données peuvent être partagées uniquement avec :\n'
                '• Nos fournisseurs d\'infrastructure (ex. Firebase/Google Cloud) '
                'pour l\'hébergement et l\'authentification\n'
                '• Les autorités compétentes si la loi l\'exige',
              ),
              _h('4. Stockage et sécurité'),
              _p(
                'Vos données sont stockées de manière sécurisée via des services '
                'd\'hébergement reconnus (Firebase/Google Cloud). Nous mettons en '
                'œuvre des mesures raisonnables pour protéger vos informations '
                'contre l\'accès non autorisé.',
              ),
              _h('5. Vos droits'),
              _p(
                'Vous pouvez à tout moment :\n'
                '• Accéder à vos données personnelles\n'
                '• Demander leur correction\n'
                '• Demander la suppression de votre compte et de vos données\n\n'
                'Pour exercer ces droits, contactez-nous à privacy@memorizbible.app',
              ),
              _h('6. Données des mineurs'),
              _p(
                
                '"MemorizBible peut être utilisée par des mineurs sous la '
                'supervision d\'un parent ou tuteur. Nous ne collectons pas '
                'sciemment de données au-delà de ce qui est nécessaire au '
                'fonctionnement de l\'application.',
              ),
              _h('7. Modifications de cette politique'),
              _p(
                'Nous pouvons mettre à jour cette politique de temps à autre. '
                'Toute modification importante vous sera communiquée via '
                'l\'application ou par e-mail.',
              ),
              _h('8. Nous contacter'),
              _p(
                'Pour toute question concernant cette politique de confidentialité, '
                'contactez-nous à : damgearole@icloud.com',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _h(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      );

  Widget _p(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, height: 1.6),
        ),
      );
}

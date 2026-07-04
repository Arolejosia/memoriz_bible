// File: lib/screens/public/terms_page.dart

import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
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
                'Conditions d\'utilisation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Dernière mise à jour : 04/07/2026 ',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _p(
                'En utilisant MemorizBible, vous acceptez les présentes conditions '
                'd\'utilisation. Merci de les lire attentivement.',
              ),
              _h('1. Acceptation des conditions'),
              _p(
                'En créant un compte ou en utilisant l\'application MemorizBible, '
                'vous confirmez accepter ces conditions dans leur intégralité. '
                'Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser '
                'l\'application.',
              ),
              _h('2. Description du service'),
              _p(
                'MemorizBible est une application éducative permettant de '
                'mémoriser des versets bibliques via des jeux interactifs '
                '(quiz, remise en ordre, dictée, etc.), seul ou en groupe.',
              ),
              _h('3. Compte utilisateur'),
              _p(
                '• Vous devez fournir des informations exactes lors de la création '
                'de votre compte\n'
                '• Vous êtes responsable de la confidentialité de vos identifiants\n'
                '• Vous devez nous informer immédiatement de toute utilisation '
                'non autorisée de votre compte',
              ),
              _h('4. Utilisation acceptable'),
              _p(
                'Vous acceptez de ne pas :\n'
                '• Utiliser l\'application à des fins illégales\n'
                '• Tenter de perturber ou de compromettre la sécurité de l\'application\n'
                '• Publier du contenu offensant, diffamatoire ou inapproprié dans '
                'les fonctionnalités communautaires (groupes, notes partagées)\n'
                '• Usurper l\'identité d\'une autre personne',
              ),
              _h('5. Propriété intellectuelle'),
              _p(
                'Le contenu de l\'application (design, code, logo, textes) est la '
                'propriété de MemorizBible, sauf le texte biblique lui-même qui '
                'appartient au domaine public ou à ses éditeurs respectifs selon '
                'la version utilisée.',
              ),
              _h('6. Fonctionnalités communautaires et groupes'),
              _p(
                'Si vous participez à des groupes ou défis, vous acceptez que '
                'votre nom d\'utilisateur et votre progression puissent être '
                'visibles par les autres membres de ce groupe.',
              ),
              _h('7. Résiliation'),
              _p(
                'Nous nous réservons le droit de suspendre ou de résilier votre '
                'compte en cas de violation de ces conditions. Vous pouvez '
                'également supprimer votre compte à tout moment depuis les '
                'paramètres de l\'application ou en nous contactant.',
              ),
              _h('8. Limitation de responsabilité'),
              _p(
                'MemorizBible est fournie "telle quelle", sans garantie d\'aucune '
                'sorte. Nous ne pouvons être tenus responsables de toute perte de '
                'données ou interruption de service.',
              ),
              _h('9. Modifications des conditions'),
              _p(
                'Nous pouvons modifier ces conditions à tout moment. Les '
                'modifications importantes vous seront communiquées via '
                'l\'application.',
              ),
              _h('10. Nous contacter'),
              _p(
                'Pour toute question concernant ces conditions, contactez-nous à : '
                'damgnearole@icloud.com',
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

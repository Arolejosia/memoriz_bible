import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <- pour kReleaseMode
import '../auth/auth_gate.dart';
import 'intro_page.dart';
import '../auth/authentification.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Récupère ton thème global

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Logo (ADMIN caché: appui long)
            GestureDetector(
              onLongPress: () {
                // 👇 ouvre la page d’admin pour générer des codes
                Navigator.of(context).pushNamed('/admin/generate');
              },
              child: Image.asset(
                'assets/logo.png', // Remplace avec ton vrai logo
                height: 200,
              ),
            ),

            // Slogan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Ta parole est une lampe à mes pieds, une lumière sur mon sentier.        Psaume 119:105',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(),

            // Bouton "C’EST PARTI !"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MemorizationIntroPage()),
                    );
                  },
                  child: const Text("Let go, let God!"),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton "J’AI DÉJÀ UN COMPTE"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) =>  AuthGate()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                  ),
                  child: const Text("J’AI DÉJÀ UN COMPTE"),
                ),
              ),
            ),

            // Petit bouton Admin visible seulement en debug (pas en release)

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

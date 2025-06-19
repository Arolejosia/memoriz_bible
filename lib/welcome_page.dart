import 'package:flutter/material.dart';
import 'intro_page.dart';
import 'authentification.dart';
import 'bible_verse_page.dart';
 // futur espace connecté
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

            // Logo
            Image.asset(
              'assets/logo.png', // Remplace avec ton vrai logo
              height: 200,

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
                      MaterialPageRoute(builder: (context) => AuthPage()),
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

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
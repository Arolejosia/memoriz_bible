// fichier: lib/home_page.dart

import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../widgets/main_drawer.dart';
import 'progression_dashboard_page.dart'; // On va créer cette page
import'pageDeConfiguration.dart';// Votre page de configuration existante

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MemorizBible',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0, // Taille de police augmentée
          ),
        ),

      ),
      drawer: const MainDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- BOUTON 1 : APPRENTISSAGE ---
              ElevatedButton.icon(
                icon: const Icon(Icons.school, size: 36), // Taille de l'icône augmentée
                label: const Text("Mode Apprentissage", style: TextStyle(fontSize: 22)), // Taille du texte augmentée
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressionDashboardPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32), // Padding augmenté
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder( // Coins arrondis
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5, // Ajout d'une ombre
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Suivez un parcours structuré pour mémoriser les versets à long terme. Votre progression est enregistrée.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
                // Vous pouvez aussi augmenter la taille de ce texte si besoin
                // style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 48),

              // --- BOUTON 2 : JEU LIBRE ---
              OutlinedButton.icon(
                icon: const Icon(Icons.gamepad_outlined, size: 36), // Taille de l'icône augmentée
                label: const Text("Mode Jeu Libre", style: TextStyle(fontSize: 22)), // Taille du texte augmentée
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const  PageDeJeuPrincipale()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32), // Padding augmenté
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // Bordure plus épaisse
                  shape: RoundedRectangleBorder( // Coins arrondis
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Entraînez-vous sur n'importe quel jeu et n'importe quel passage, sans que cela n'affecte votre progression.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
                // Vous pouvez aussi augmenter la taille de ce texte si besoin
                // style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
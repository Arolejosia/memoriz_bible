// Fichier: lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/home_page.dart';
import 'authentification.dart'; // Votre page de connexion

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Écoute en temps réel les changements de statut de connexion
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // L'utilisateur n'est pas encore authentifié, on attend
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si un utilisateur est connecté, on affiche la page d'accueil
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Sinon, on affiche la page de connexion/inscription
        return const AuthPage();
      },
    );
  }
}
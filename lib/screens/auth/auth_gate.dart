// File: lib/auth/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/home_page.dart';
import 'authentification.dart';
import 'verify_email_page.dart';

/// Authentication gate that manages user authentication flow
/// Portail d'authentification qui gère le flux d'authentification des utilisateurs
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking authentication state
        // Afficher l'indicateur de chargement pendant la vérification de l'état d'authentification
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // If no user is connected, go to login page
        // Si aucun utilisateur n'est connecté, aller à la page de connexion
        if (!snapshot.hasData) {
          return const AuthPage();
        }

        // User is connected, but is their email verified?
        // L'utilisateur est connecté, mais son email est-il vérifié ?
        final user = snapshot.data!;
        if (!user.emailVerified) {
          // If NO, show verification page
          // Si NON, afficher la page de vérification
          return const VerifyEmailPage();
        }

        // If YES, show home page
        // Si OUI, afficher la page d'accueil
        return const HomePage();
      },
    );
  }
}
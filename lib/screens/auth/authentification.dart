import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/pageDeConfiguration.dart';

import '../core/home_page.dart';



class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String _errorMessage = '';
  bool _isLoading = false; // ✅ 1. État pour le chargement

  Future<void> _authenticate() async {
    // ✅ 2. On vérifie que les champs ne sont pas vides
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs.");
      return;
    }

    setState(() {
      _isLoading = true; // On commence le chargement
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'username': '', // On initialise le nom d'utilisateur comme une chaîne vide
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) { // ✅ 3. On intercepte les erreurs Firebase
      print(e.code); // Pour le débogage
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "Aucun utilisateur trouvé pour cet email.";
          break;
        case 'wrong-password':
          message = "Mot de passe incorrect.";
          break;
        case 'weak-password':
          message = "Le mot de passe doit contenir au moins 6 caractères.";
          break;
        case 'email-already-in-use':
          message = "Un compte existe déjà pour cet email.";
          break;
        case 'invalid-email':
          message = "L'adresse email n'est pas valide.";
          break;
        default:
          message = "Une erreur est survenue. Veuillez réessayer.";
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // On arrête le chargement, même en cas d'erreur
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Connexion' : 'Inscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder())),
            const SizedBox(height: 16),

            // ✅ 4. Le bouton affiche un indicateur de chargement
            ElevatedButton(
              onPressed: _isLoading ? null : _authenticate, // Désactivé pendant le chargement
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isLogin ? 'Se connecter' : "S'inscrire"),
            ),

            TextButton(
              onPressed: _isLoading ? null : () {
                setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = '';
                });
              },
              child: Text(_isLogin ? "Pas encore de compte ? S'inscrire" : "Déjà un compte ? Se connecter"),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
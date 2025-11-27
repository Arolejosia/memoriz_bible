import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDeletionService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Supprime complètement le compte utilisateur
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      final userId = user.uid;

      // 1. Suppression des données Firestore
      await _deleteUserData(userId);

      // 2. Suppression du compte d'authentification
      await user.delete();

      // 3. Déconnexion (automatique après delete, mais explicite)
      await _auth.signOut();

    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs d'authentification
      if (e.code == 'requires-recent-login') {
        throw Exception('Veuillez vous reconnecter avant de supprimer votre compte');
      }
      throw Exception('Erreur d\'authentification: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  /// Supprime toutes les données utilisateur de Firestore
  Future<void> _deleteUserData(String userId) async {
    // Suppression du document principal
    await _firestore.collection('users').doc(userId).delete();

    // Si vous avez d'autres collections à supprimer :
    // await _firestore.collection('userProgress').doc(userId).delete();
    // await _firestore.collection('userSettings').doc(userId).delete();
  }

  /// Ré-authentifie l'utilisateur (nécessaire si dernière connexion > 5 min)
  Future<void> reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Aucun utilisateur connecté');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }
}


class DeleteAccountButton extends StatefulWidget {
  @override
  State<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  final AccountDeletionService _deletionService = AccountDeletionService();
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Supprimer mon compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible et supprimera :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Toutes vos données de progression'),
            Text('• Votre compte d\'authentification'),
            Text('• Tous vos paramètres'),
            SizedBox(height: 16),
            Text(
              'Êtes-vous absolument certain ?',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _confirmWithPassword();
    }
  }

  Future<void> _confirmWithPassword() async {
    final passwordController = TextEditingController();

    final passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer avec votre mot de passe'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );

    if (passwordConfirmed == true && passwordController.text.isNotEmpty) {
      await _performDeletion(passwordController.text);
    }
  }

  Future<void> _performDeletion(String password) async {
    setState(() => _isDeleting = true);

    try {
      // 1. Ré-authentification
      await _deletionService.reauthenticateUser(password);

      // 2. Suppression du compte
      await _deletionService.deleteUserAccount();

      // 3. Navigation vers l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compte supprimé avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isDeleting ? null : _showDeleteConfirmation,
      icon: _isDeleting
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(Icons.delete_forever),
      label: Text(_isDeleting ? 'Suppression...' : 'Supprimer mon compte'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
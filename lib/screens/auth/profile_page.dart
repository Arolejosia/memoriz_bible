// Fichier: lib/profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../widgets/main_drawer.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  // On récupère l'utilisateur actuellement connecté
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // On charge le nom d'utilisateur actuel au démarrage
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    if (_user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (userDoc.exists && userDoc.data()!.containsKey('username')) {
      setState(() {
        _usernameController.text = userDoc.data()!['username'];
      });
    }
  }

  Future<void> _saveUsername() async {
    if (_user == null || _usernameController.text.trim().isEmpty) return;

    // On sauvegarde le nouveau nom dans Firestore
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'username': _usernameController.text.trim(),
      'email': _user!.email, // On sauvegarde l'email en même temps
    }, SetOptions(merge: true)); // merge: true pour ne pas écraser d'autres champs

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nom d'utilisateur mis à jour !")),
    );
  }


  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      drawer: const MainDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),

            // ✅ NOUVEAU : Champ de texte pour le nom d'utilisateur
            _isEditing
                ? TextField(
              controller: _usernameController,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "Entrez votre nom"),
            )
                : Text(
              _usernameController.text.isEmpty ? "Ajouter un nom" : _usernameController.text,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),
            Text(
              // On affiche l'email de l'utilisateur
              _user?.email ?? "Utilisateur inconnu",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Divider(),
          Consumer<VerseLibrary>(
          builder: (context, library, child) {
      // Affiche les statistiques dans une rangée
      return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("En Apprentissage", library.totalInProgressCount),
        _buildStatItem("Verset Maîtrisés", library.totalMasteredCount),
      ],
    );
  },
    ),
    // Pousse le bouton vers le bas
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Se déconnecter"),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // Le AuthGate dans main.dart détectera automatiquement ce changement
                // et affichera la page de connexion.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
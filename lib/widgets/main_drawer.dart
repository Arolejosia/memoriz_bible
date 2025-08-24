// fichier: lib/widgets/main_drawer.dart

import 'package:flutter/material.dart';

// Importez vos pages ici. Assurez-vous que les chemins sont corrects !
import '../Bibliotheque.dart';
import '../screens/auth/profile_page.dart';
import '../screens/core/settings_page.dart';
import '../screens/duels/multiplayer_hub_page.dart';
import '../screens/games/trouver_reference_config_page.dart';
import '../screens/groups/create_group_page.dart';
import '../screens/groups/groups_list_page.dart';


class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Important: Retirez tout padding de la ListView.
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.indigo,
            ),
            child: Text(
              'MemorizBible',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bibliothèque'),
            onTap: () {
              // Ferme le drawer puis navigue
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const VerseLibraryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil & Progrès'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Divider(),

          // ✅ 2. AJOUTEZ CE BLOC POUR LES GROUPES
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Mes Groupes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsListPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('Créer un groupe'),
            onTap: () {
              Navigator.pop(context); // Ferme le drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupPage()),
              );
            },
          ),


          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Paramètres'),
            onTap: () {
              // Ferme le drawer avant d'ouvrir la nouvelle page
              Navigator.pop(context);
              // Ouvre la page de paramètres
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: const Text('Jeu : Trouver la Référence'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrouverReferenceConfigPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Multiplayer / Duels'),
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MultiplayerHubPage()),
              );
            },
          ),
          // Ajoutez d'autres liens ici (Paramètres, À Propos, etc.)
        ],
      ),
    );
  }
}
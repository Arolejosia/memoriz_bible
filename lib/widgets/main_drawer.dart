// fichier: lib/widgets/main_drawer.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Bibliotheque.dart';

import '../screens/auth/authentification.dart';
import '../screens/auth/profile_page.dart';
import '../screens/core/about_page.dart';
import '../screens/core/bible_reader_page.dart';
import '../screens/core/home_page.dart';
import '../screens/core/settings_page.dart';
import '../screens/duels/multiplayer_hub_page.dart';
import '../screens/games/trouver_reference_config_page.dart';
import '../screens/groups/create_group_page.dart';
import '../screens/groups/groups_list_page.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';


class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // On récupère la langue actuelle. 'watch' permet de reconstruire si la langue change.
    final lang = context.watch<LanguageProvider>().language;

    // Helper pour simplifier les appels de traduction
    String t(String key) => DrawerTranslations.t(key, lang);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.indigo,
            ),
            child: Text(
              t('title'), // <--- TRADUIT
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: Text(t('home')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.menu_book, color: Colors.brown.shade400),
            title: Text(t('bible')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BibleReaderPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.book),
            title: Text(t('library')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerseLibraryPage(
                    language: context.read<LanguageProvider>().language,
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: Text(t('profile')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: Text(t('my_groups')), // <--- TRADUIT
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
            title: Text(t('create_group')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupPage()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(t('settings')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(t('game_find_ref')), // <--- TRADUIT
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
            title: Text(t('multiplayer')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HubPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t('about')), // <--- TRADUIT
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          const Divider(),
          if (_user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: Text(t('logout')), // <--- TRADUIT
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthPage()),
                          (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// File: lib/l10n/drawer_translations.dart

class DrawerTranslations {
  static String t(String key, String lang) {
    final Map<String, Map<String, String>> translations = {
      'title': {'fr': 'MemorizBible', 'en': 'MemorizBible'},
      'home': {'fr': 'Accueil', 'en': 'Home'},
      'bible': {'fr': 'Bible', 'en': 'Bible'},
      'library': {'fr': 'Bibliothèque', 'en': 'Library'},
      'profile': {'fr': 'Profil & Progrès', 'en': 'Profile & Progress'},
      'my_groups': {'fr': 'Mes Groupes', 'en': 'My Groups'},
      'create_group': {'fr': 'Créer un groupe', 'en': 'Create a Group'},
      'settings': {'fr': 'Paramètres', 'en': 'Settings'},
      'game_find_ref': {'fr': 'Jeu : Trouver la Référence', 'en': 'Game: Find the Reference'},
      'multiplayer': {'fr': 'Multiplayer / Duels', 'en': 'Multiplayer / Duels'},
      'about': {'fr': 'À propos', 'en': 'About'},
      'logout': {'fr': 'Se déconnecter', 'en': 'Log Out'},
    };
    return translations[key]?[lang] ?? key;
  }
}
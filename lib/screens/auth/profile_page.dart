// File: lib/screens/profile/profile_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../widgets/main_drawer.dart';
import '../../models/verse_model.dart';
import '../verse/verse_detail_page.dart';
import '../auth/authentification.dart';
import '../../models/language_provider.dart';

/// Translations for profile page
/// Traductions pour la page de profil
class ProfileTranslations {
  static String t(String key, String lang) {
    final translations = {
      'my_profile': {'fr': 'Mon Profil', 'en': 'My Profile'},
      'back': {'fr': 'Retour', 'en': 'Back'},
      'add_username': {'fr': 'Ajouter un Pseudonyme', 'en': 'Add a Username'},
      'enter_username': {'fr': 'Entrez votre pseudonyme', 'en': 'Enter your username'},
      'edit_name': {'fr': 'Modifier le nom', 'en': 'Edit name'},
      'save': {'fr': 'Enregistrer', 'en': 'Save'},
      'unknown_user': {'fr': 'Utilisateur inconnu', 'en': 'Unknown user'},
      'username_updated': {'fr': 'Nom d\'utilisateur mis à jour !', 'en': 'Username updated!'},
      'added_verses': {'fr': 'Versets Ajoutés', 'en': 'Added Verses'},
      'in_progress': {'fr': 'En Apprentissage', 'en': 'In Progress'},
      'mastered': {'fr': 'Maîtrisés', 'en': 'Mastered'},
      'progress_by_level': {'fr': 'Répartition par niveau', 'en': 'Progress by Level'},
      'no_progress_data': {'fr': 'Aucune donnée de progression', 'en': 'No progress data available'},
      'progress_legend': {
        'fr': 'Niveau de progression (0: Nouveau → 5: Maîtrisé)',
        'en': 'Progress level (0: New → 5: Mastered)'
      },
      'recent_verses': {'fr': 'Derniers versets', 'en': 'Recent Verses'},
      'view_all': {'fr': 'Voir tout', 'en': 'View all'},
      'start_learning': {
        'fr': 'Commencez à apprendre des versets !',
        'en': 'Start learning your first verses!'
      },
      'logout': {'fr': 'Se déconnecter', 'en': 'Log out'},
      'sign_in': {'fr': 'Se connecter', 'en': 'Sign in'},
      'new': {'fr': 'Nouveau', 'en': 'New'},
      'learning': {'fr': 'En cours', 'en': 'Learning'},
    };
    return translations[key]?[lang] ?? key;
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _usernameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
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

    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'username': _usernameController.text.trim(),
    });

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('username_updated'))),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  String t(String key) {
    final lang = context.watch<LanguageProvider>().language;
    return ProfileTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t('back'),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('my_profile')),
      ),
      drawer: const MainDrawer(),
      body: Consumer<VerseLibrary>(
        builder: (context, library, child) {
          if (library.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allVerses = library.myVerseCategories.expand((cat) => cat.verses).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 20),

                // --- Username section / Section nom d'utilisateur ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: _isEditing
                          ? TextField(
                        controller: _usernameController,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: t('enter_username'),
                        ),
                      )
                          : Text(
                        _usernameController.text.isEmpty
                            ? t('add_username')
                            : _usernameController.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _isEditing
                          ? TextButton(
                        onPressed: _saveUsername,
                        child: Text(t('save')),
                      )
                          : IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: t('edit_name'),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _user?.email ?? t('unknown_user'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Divider(),

                // --- Stats section / Section statistiques ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(t('added_verses'), allVerses.length),
                      _buildStatItem(t('in_progress'), library.totalInProgressCount),
                      _buildStatItem(t('mastered'), library.totalMasteredCount),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 24),

                _buildProgressChart(library),
                const SizedBox(height: 24),
                const Divider(),

                _buildRecentVerses(allVerses),
                const SizedBox(height: 24),

                if (_user != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(t('logout')),
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
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  )
                else
                  ElevatedButton(
                    child: Text(t('sign_in')),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const AuthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
              ],
            ),
          );
        },
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
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProgressChart(VerseLibrary library) {
    final allVerses = library.myVerseCategories.expand((cat) => cat.verses).toList();

    if (allVerses.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                t('no_progress_data'),
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    Map<int, int> progressDistribution = {};
    for (int i = 0; i <= 5; i++) {
      progressDistribution[i] = allVerses.where((v) => v.progressLevel == i).length;
    }
    final maxCount = progressDistribution.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('progress_by_level'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(6, (index) {
                  final count = progressDistribution[index]!;
                  final heightPercent = maxCount > 0 ? count / maxCount : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Container(
                            height: 130 * heightPercent,
                            decoration: BoxDecoration(
                              color: _getColorForLevel(index),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(index.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('progress_legend'),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVerses(List<Verse> allVerses) {
    final recentVerses = allVerses.where((v) => v.updatedAt != null).toList()
      ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
    final displayVerses = recentVerses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t('recent_verses'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (allVerses.length > 5) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final lang = context.read<LanguageProvider>().language;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerseLibraryPage(language: lang),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 20),
                tooltip: t('view_all'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (displayVerses.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.book_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      t('start_learning'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...displayVerses.map((verse) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getColorForLevel(verse.progressLevel),
                child: Text(
                  '${verse.progressLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                verse.reference,
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(verse.book, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (verse.category != null && verse.category!.isNotEmpty)
                    Text(
                      verse.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: _buildStatusBadge(verse.status),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VerseDetailPage(verse: verse)),
                );
              },
            ),
          )),
      ],
    );
  }

  Widget _buildStatusBadge(VerseStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case VerseStatus.neutral:
        color = Colors.grey;
        label = t('new');
        icon = Icons.fiber_new;
        break;
      case VerseStatus.learning:
        color = Colors.orange;
        label = t('learning');
        icon = Icons.school;
        break;
      case VerseStatus.mastered:
        color = Colors.green;
        label = t('mastered');
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue[300]!;
      case 2:
        return Colors.lightBlue;
      case 3:
        return Colors.orange[300]!;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
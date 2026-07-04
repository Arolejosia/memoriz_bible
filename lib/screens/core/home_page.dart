import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/screens/core/settings_page.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../prayer/screens/prayer_home_screen.dart';
import '../../widgets/main_drawer.dart';
import '../../models/language_provider.dart';
import '../auth/profile_page.dart';
import '../badges_screen.dart';
import '../groups/groups_list_page.dart';
import 'about_page.dart';
import 'progression_dashboard_page.dart';
import 'pageDeConfiguration.dart';




class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String _userName = '';
  bool _isLoading = true;
  int _pendingInvitationsCount = 0;  // ✅ AJOUT : Compteur d'invitations

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToInvitations();  // ✅ AJOUT : Écouter les invitations
  }

  Future<void> _loadUserData() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc.data()?['fullName'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Erreur lors du chargement des données utilisateur: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ AJOUT : Écouter les invitations en temps réel
  void _listenToInvitations() {
    if (_user == null) return;

    FirebaseFirestore.instance
        .collection('invitations')
        .where('invitedUserId', isEqualTo: _user!.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _pendingInvitationsCount = snapshot.docs.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.language == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MemorizBible',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        actions: [
          // 🔄 Bouton pour changer de langue directement
          IconButton(
            icon: Text(languageProvider.flagEmoji, style: const TextStyle(fontSize: 22)),
            tooltip: isEnglish ? "Change language" : "Changer de langue",
            onPressed: () => languageProvider.toggleLanguage(),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: isEnglish ? "Profile & Progress" : "Profil & Progrès",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: isEnglish ? "Settings" : "Paramètres",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          // --- CONTENU PRINCIPAL AVEC SCROLL ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_userName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0, top: 12),
                    child: Text(
                      isEnglish
                          ? '👋 Welcome, $_userName!'
                          : '👋 Bienvenue, $_userName !',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),

                const SizedBox(height: 24),

                // === MODE APPRENTISSAGE ===
                _buildMainButton(
                  icon: Icons.school,
                  label: isEnglish ? "Learning Mode" : "Mode Apprentissage",
                  color: Colors.indigo,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProgressionDashboardPage()),
                    );
                  },
                  description: isEnglish
                      ? "Follow a structured path to memorize verses for long-term retention."
                      : "Suivez un parcours structuré pour mémoriser les versets à long terme.",
                ),

                const SizedBox(height: 32),

                // === MODE JEU LIBRE ===
                _buildOutlinedButton(
                  icon: Icons.gamepad_outlined,
                  label: isEnglish ? "Free Game Mode" : "Mode Jeu Libre",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PageDeJeuPrincipale()),
                    );
                  },
                  description: isEnglish
                      ? "Train with any passage without affecting your progress."
                      : "Entraînez-vous sur n'importe quel passage sans affecter votre progression.",
                ),

                const SizedBox(height: 40),
                const Divider(height: 30, thickness: 1.2),

                Text(
                  isEnglish ? "📚 Other sections" : "📚 Autres espaces",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),

                _buildCardTile(
                  icon: Icons.access_time, // ou Icons.favorite ou Icons.self_improvement
                  title: isEnglish ? "Prayer Time" : "Temps de Prière",
                  subtitle: isEnglish
                      ? "Track your daily prayer time and write spiritual notes."
                      : "Suivez votre temps de prière quotidien et notez vos réflexions spirituelles.",
                  color: Colors.deepPurple.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrayerHomeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16), // ⬅️ AJOUT
                _buildCardTile(               // ⬅️ AJOUT — nouvelle carte Badges
                  icon: Icons.emoji_events,
                  title: isEnglish ? "My Badges" : "Mes Badges",
                  subtitle: isEnglish
                      ? "Track your daily engagement and unlock rewards."
                      : "Suivez votre engagement quotidien et débloquez des récompenses.",
                  color: Colors.amber.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BadgesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 50),

                const SizedBox(height: 16),

                // ✅ MODIFICATION : Bouton "Mes Groupes" avec badge de notification
                _buildCardTileWithBadge(
                  icon: Icons.group_outlined,
                  title: isEnglish ? "My Groups" : "Mes Groupes",
                  subtitle: isEnglish
                      ? "Chat, share, and learn with your community."
                      : "Discutez, partagez et apprenez avec votre communauté.",
                  color: Colors.teal.shade400,
                  badgeCount: _pendingInvitationsCount,  // ✅ Badge avec nombre d'invitations
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GroupsListPage()),
                    );
                  },
                ),
                _buildCardTile(
                  icon: Icons.access_time, // ou Icons.favorite ou Icons.self_improvement
                  title: isEnglish ? "Prayer Time" : "Temps de Prière",
                  subtitle: isEnglish
                      ? "Track your daily prayer time and write spiritual notes."
                      : "Suivez votre temps de prière quotidien et notez vos réflexions spirituelles.",
                  color: Colors.deepPurple.shade400,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrayerHomeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 50),

              ],
            ),



          ),

          // --- BOUTON "?" EN HAUT À DROITE ---
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              tooltip: isEnglish ? "About MemorizBible" : "À propos de MemorizBible",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.help_outline, color: Colors.indigo),
              ),
            ),
          ),
        ],
      ),


    );
  }

  // --- Bouton principal plein ---
  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    required String description,
  }) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(icon, size: 36),
          label: Text(label, style: const TextStyle(fontSize: 22)),
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            elevation: 5,
          ),
        ),
        const SizedBox(height: 8),
        Text(description,
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // --- Bouton contour ---
  Widget _buildOutlinedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required String description,
  }) {
    return Column(
      children: [
        OutlinedButton.icon(
          icon: Icon(icon, size: 36),
          label: Text(label, style: const TextStyle(fontSize: 22)),
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        const SizedBox(height: 8),
        Text(description,
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // --- Carte "accès rapide" ---
  Widget _buildCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NOUVEAU : Carte avec badge de notification
  Widget _buildCardTileWithBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ✅ Stack pour ajouter le badge sur l'icône
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  // ✅ Badge de notification
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
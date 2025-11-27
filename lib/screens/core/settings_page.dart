import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../models/language_provider.dart'; // 👈 NOUVEAU
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// === Enumérations ===
enum NotificationFrequency { daily, weekly }

// === Page Paramètres ===
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // === Variables Notification ===
  bool _notificationsEnabled = true;
  TimeOfDay? _selectedTime;
  NotificationFrequency _frequency = NotificationFrequency.daily;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};

  // === Variables Audio ===
  double _musicVolume = 0.7;
  double _effectsVolume = 0.6;
  double _voiceVolume = 0.8;

  // === Objectifs quotidiens ===
  int _dailyMinutes = 15;
  int _dailyPoints = 50;
  int _dailyVerses = 3;

  // === Fusée Aurée (rappel intelligent) ===
  bool _smartRemindersEnabled = true;

  final AccountDeletionService _deletionService = AccountDeletionService();
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmation(BuildContext context) async {
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

    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. Ré-authentification
      await _deletionService.reauthenticateUser(password);

      // 2. Suppression du compte
      await _deletionService.deleteUserAccount();

      // 3. Fermer le loader
      if (mounted) Navigator.pop(context);

      // 4. Navigation vers l'écran de connexion
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
      // Fermer le loader
      if (mounted) Navigator.pop(context);

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

  // ===================================================
  // Notifications
  // ===================================================
  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _scheduleNotification();
    }
  }

  Future<void> _scheduleNotification() async {
    if (_selectedTime == null || !_notificationsEnabled) {
      await NotificationService.instance.cancelAll();
      return;
    }

    if (_frequency == NotificationFrequency.daily) {
      await NotificationService.instance.scheduleDaily(
        id: 0,
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        title: '📖 C est l heure de votre révision !',
        body: 'Quelques versets vous attendent pour être mémorisés.',
      );
    } else {
      if (_selectedDays.isEmpty) {
        await NotificationService.instance.cancelAll();
        return;
      }
      await NotificationService.instance.scheduleWeekly(
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        days: _selectedDays.toList(),
        title: '📖 C est l heure de votre révision !',
        body: 'Quelques versets vous attendent pour être mémorisés.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rappel programmé avec succès !")),
      );
    }
  }

  // ===================================================
  // UI principale
  // ===================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>( // 👈 NOUVEAU : Wrap avec Consumer
      builder: (context, langProvider, child) {
        final isFrench = langProvider.language == 'fr';

        return Scaffold(
          appBar: AppBar(
            title: Text(isFrench ? "Paramètres" : "Settings"),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ---------------------------------------------------
              // SECTION 1 — Langue d'apprentissage
              // ---------------------------------------------------
              Text(
                isFrench ? "🌍 Langue d'apprentissage" : "🌍 Learning Language",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Option Français
              RadioListTile<String>(
                title: Row(
                  children: [
                    Text('🇫🇷', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Text('Français'),
                  ],
                ),
                value: 'fr',
                groupValue: langProvider.language,
                onChanged: (value) {
                  if (value != null) {
                    langProvider.setLanguage(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Langue changée en Français'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // Option English
              RadioListTile<String>(
                title: Row(
                  children: [
                    Text('🇬🇧', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Text('English'),
                  ],
                ),
                value: 'en',
                groupValue: langProvider.language,
                onChanged: (value) {
                  if (value != null) {
                    langProvider.setLanguage(value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to English'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // Bouton reset
              ListTile(
                leading: Icon(Icons.phone_android),
                title: Text(
                  isFrench
                      ? 'Utiliser la langue du téléphone'
                      : 'Use phone language',
                ),
                onTap: () async {
                  await langProvider.resetToSystemLanguage();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFrench ? 'Langue réinitialisée' : 'Language reset',
                      ),
                    ),
                  );
                },
              ),

              const Divider(height: 32),

              // ---------------------------------------------------
              // SECTION 2 — Audio
              // ---------------------------------------------------
              Text(
                isFrench ? "🎧 Audio" : "🎧 Audio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildVolumeSlider(
                isFrench ? "Musique" : "Music",
                _musicVolume,
                    (v) => setState(() => _musicVolume = v),
              ),
              _buildVolumeSlider(
                isFrench ? "Effets sonores" : "Sound effects",
                _effectsVolume,
                    (v) => setState(() => _effectsVolume = v),
              ),
              _buildVolumeSlider(
                isFrench ? "Voix" : "Voice",
                _voiceVolume,
                    (v) => setState(() => _voiceVolume = v),
              ),

              const Divider(height: 32),

              // ---------------------------------------------------
              // SECTION 3 — Objectifs Quotidiens
              // ---------------------------------------------------
              Text(
                isFrench ? "🎯 Objectifs Quotidiens" : "🎯 Daily Goals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _buildCounter(
                isFrench ? "Minutes d'étude" : "Study minutes",
                _dailyMinutes,
                5,
                120,
                    (v) => setState(() => _dailyMinutes = v),
              ),
              _buildCounter(
                isFrench ? "Points à atteindre" : "Points to reach",
                _dailyPoints,
                10,
                1000,
                    (v) => setState(() => _dailyPoints = v),
              ),
              _buildCounter(
                isFrench ? "Versets à réviser" : "Verses to review",
                _dailyVerses,
                1,
                20,
                    (v) => setState(() => _dailyVerses = v),
              ),

              const Divider(height: 32),

              // ---------------------------------------------------
              // SECTION 4 — Notifications & Rappels
              // ---------------------------------------------------
              Text(
                isFrench ? "⏰ Notifications" : "⏰ Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SwitchListTile(
                title: Text(isFrench ? "Activer les rappels" : "Enable reminders"),
                value: _notificationsEnabled,
                onChanged: (v) {
                  setState(() => _notificationsEnabled = v);
                  _scheduleNotification();
                },
              ),

              ListTile(
                leading: const Icon(Icons.timer),
                title: Text(isFrench ? "Heure du rappel" : "Reminder time"),
                subtitle: Text(_selectedTime?.format(context) ??
                    (isFrench ? "Choisir une heure" : "Choose a time")),
                onTap: _notificationsEnabled ? () => _selectTime(context) : null,
              ),

              DropdownButtonFormField<NotificationFrequency>(
                value: _frequency,
                decoration: InputDecoration(
                  labelText: isFrench ? "Fréquence" : "Frequency",
                ),
                items: [
                  DropdownMenuItem(
                    value: NotificationFrequency.daily,
                    child: Text(isFrench ? "Chaque jour" : "Every day"),
                  ),
                  DropdownMenuItem(
                    value: NotificationFrequency.weekly,
                    child: Text(isFrench ? "Chaque semaine" : "Every week"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _frequency = value);
                    _scheduleNotification();
                  }
                },
              ),

              if (_frequency == NotificationFrequency.weekly)
                Wrap(
                  spacing: 8,
                  children: [
                    for (int i = 1; i <= 7; i++)
                      ChoiceChip(
                        label: Text(
                          isFrench
                              ? ['L', 'M', 'M', 'J', 'V', 'S', 'D'][i - 1]
                              : ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i - 1],
                        ),
                        selected: _selectedDays.contains(i),
                        onSelected: (s) {
                          setState(() {
                            if (s)
                              _selectedDays.add(i);
                            else
                              _selectedDays.remove(i);
                          });
                          _scheduleNotification();
                        },
                      ),
                  ],
                ),

              SwitchListTile(
                title: Text(
                  isFrench
                      ? "Fusée Aurée — Rappels intelligents"
                      : "Smart Reminders",
                ),
                subtitle: Text(
                  isFrench
                      ? "Envoie les rappels aux moments où vous êtes le plus actif."
                      : "Sends reminders when you're most active.",
                ),
                value: _smartRemindersEnabled,
                onChanged: (v) => setState(() => _smartRemindersEnabled = v),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Supprimer mon compte',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showDeleteConfirmation(context),
              ),


            ],
          ),
        );
      },
    );
  }

  // ===================================================
  // Widgets utilitaires
  // ===================================================
  Widget _buildVolumeSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Slider(
          value: value,
          min: 0,
          max: 1,
          divisions: 10,
          label: "${(value * 100).round()}%",
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, int min, int max,
      ValueChanged<int> onChanged) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text("$value",
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}




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
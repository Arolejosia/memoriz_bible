// Fichier: lib/screens/groups/create_group_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import 'group_settings_page.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final lang = context.read<LanguageProvider>().language;
    String t(String key) => CreateGroupTranslations.t(key, lang);

    try {
      final newGroupRef = await FirebaseFirestore.instance.collection('groups').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPublic': _isPublic,
        'adminId': currentUser.uid,
        'members': [currentUser.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              title: Text(t('success_title')),
              content: Text(t('success_body')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text(t('close')),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: Text(t('view_group')),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSettingsPage(
                          groupId: newGroupRef.id,
                          groupData: {
                            'name': _nameController.text.trim(),
                            'description': _descriptionController.text.trim(),
                            'isPublic': _isPublic,
                            'adminId': currentUser.uid,
                            'members': [currentUser.uid],
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error creating group: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('error_creating_group'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key) => CreateGroupTranslations.t(key, lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('create_group_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t('group_name_label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t('group_name_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: t('description_label'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(t('public_group_label')),
                subtitle: Text(_isPublic ? t('public_subtitle') : t('private_subtitle')),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(t('create_group_button')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// File: lib/l10n/create_group_translations.dart

class CreateGroupTranslations {
  static String t(String key, String lang) {
    final Map<String, Map<String, String>> translations = {
      'create_group_title': {'fr': 'Créer un nouveau groupe', 'en': 'Create a New Group'},
      'group_name_label': {'fr': 'Nom du groupe', 'en': 'Group Name'},
      'group_name_error': {'fr': 'Veuillez entrer un nom de groupe.', 'en': 'Please enter a group name.'},
      'description_label': {'fr': 'Description', 'en': 'Description'},
      'public_group_label': {'fr': 'Groupe public', 'en': 'Public Group'},
      'public_subtitle': {'fr': 'Tout le monde peut trouver et rejoindre ce groupe.', 'en': 'Anyone can find and join this group.'},
      'private_subtitle': {'fr': 'Seuls les membres invités peuvent rejoindre ce groupe.', 'en': 'Only invited members can join this group.'},
      'create_group_button': {'fr': 'Créer le groupe', 'en': 'Create Group'},
      'success_title': {'fr': '✅ Groupe créé avec succès', 'en': '✅ Group Created Successfully'},
      'success_body': {'fr': 'Votre groupe a été créé. Que souhaitez-vous faire maintenant ?', 'en': 'Your group has been created. What would you like to do now?'},
      'close': {'fr': 'Fermer', 'en': 'Close'},
      'view_group': {'fr': 'Voir le groupe', 'en': 'View Group'},
      'error_creating_group': {'fr': 'La création du groupe a échoué. Veuillez réessayer.', 'en': 'Failed to create group. Please try again.'},
    };
    return translations[key]?[lang] ?? key;
  }
}
// lib/screens/groups/invite_user_dialog.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({super.key});

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Map<String, dynamic>> _selectedUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(Map<String, dynamic> user, String fallbackName) {
    final exists = _selectedUsers.any((u) => u['id'] == user['id']);
    setState(() {
      if (exists) {
        _selectedUsers.removeWhere((u) => u['id'] == user['id']);
      } else {
        // Ensure username is not null when adding
        user['username'] = user['username'] ?? fallbackName;
        _selectedUsers.add(user);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedUsers);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) =>
        InviteUserTranslations.t(key, lang, params: params);

    return AlertDialog(
      title: Text(t('dialog_title')),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t('search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isEmpty)
              Expanded(
                child: Center(
                  child: Text(t('type_to_search')),
                ),
              )
            else
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return Center(child: Text(t('no_users_found')));
                    }

                    final results = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username =
                      (data['username'] ?? '').toString().toLowerCase();
                      final email =
                      (data['email'] ?? '').toString().toLowerCase();
                      return username.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();

                    if (results.isEmpty) {
                      return Center(child: Text(t('no_results')));
                    }

                    return ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final doc = results[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected =
                        _selectedUsers.any((u) => u['id'] == doc.id);

                        return Card(
                          color: isSelected ? Colors.blue.shade100 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              child: Text(
                                ((data['username'] ?? 'U') as String).isNotEmpty
                                    ? (data['username'] as String)[0]
                                    .toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(data['username'] ?? t('nameless')),
                            subtitle: Text(data['email'] ?? ''),
                            trailing: Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            onTap: () => _toggleSelection(
                              {
                                'id': doc.id,
                                'username': data['username'], // Can be null
                                'email': data['email'] ?? '',
                              },
                              t('user_fallback'), // Pass fallback
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel'))),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: Text(
            _selectedUsers.isEmpty
                ? t('invite')
                : t('invite_count',
                params: {'count': _selectedUsers.length.toString()}),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _selectedUsers.isEmpty ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _selectedUsers.isEmpty ? null : _confirmSelection,
        ),
      ],
    );
  }
}

// File: lib/l10n/invite_user_translations.dart

class InviteUserTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'dialog_title': {'fr': 'Inviter des utilisateurs', 'en': 'Invite Users'},
      'search_hint': {
        'fr': 'Rechercher par nom ou e-mail...',
        'en': 'Search by name or email...'
      },
      'type_to_search': {
        'fr': 'Tapez un nom ou un e-mail pour rechercher',
        'en': 'Type a name or email to search'
      },
      'no_users_found': {
        'fr': 'Aucun utilisateur trouvé',
        'en': 'No users found'
      },
      'no_results': {'fr': 'Aucun résultat', 'en': 'No results'},
      'nameless': {'fr': 'Sans nom', 'en': 'Nameless'},
      'user_fallback': {'fr': 'Utilisateur', 'en': 'User'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'invite': {'fr': 'Inviter', 'en': 'Invite'},
      'invite_count': {'fr': 'Inviter ({count})', 'en': 'Invite ({count})'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }
}
// lib/screens/groups/invite_user_dialog.dart
// ✅ VERSION FINALE CORRIGÉE
// - Affiche TOUS les utilisateurs dès l'ouverture
// - Recherche fonctionne dès le 1er caractère
// - Performance optimisée (chargement unique)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ✅ AJOUT : Cache des utilisateurs pour éviter de recharger à chaque recherche
  List<QueryDocumentSnapshot>? _allUsers;
  bool _isLoading = true;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  // ✅ NOUVEAU : Charger TOUS les utilisateurs une seule fois au démarrage
  Future<void> _loadAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      if (mounted) {
        setState(() {
          _allUsers = snapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement utilisateurs: $e');
      if (mounted) {
        setState(() {
          _allUsers = [];
          _isLoading = false;
        });
      }
    }
  }

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
        user['username'] = user['username'] ?? fallbackName;
        _selectedUsers.add(user);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedUsers);
  }

  // ✅ NOUVEAU : Filtrer les utilisateurs selon la recherche
  List<QueryDocumentSnapshot> _getFilteredUsers() {
    if (_allUsers == null) return [];

    // Si pas de recherche, afficher TOUS les utilisateurs (sauf soi-même)
    if (_searchQuery.isEmpty) {
      return _allUsers!.where((doc) => doc.id != _currentUserId).toList();
    }

    // Filtrer selon la recherche (username OU email)
    return _allUsers!.where((doc) {
      if (doc.id == _currentUserId) return false;

      final data = doc.data() as Map<String, dynamic>;
      final username = (data['username'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return username.contains(searchLower) || email.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) =>
        InviteUserTranslations.t(key, lang, params: params);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_add, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(t('dialog_title'))),
        ],
      ),
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUsersList(t),
            ),

            if (_selectedUsers.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      t('selected_count', params: {'count': _selectedUsers.length.toString()}),
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('cancel')),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: Text(
            _selectedUsers.isEmpty
                ? t('invite')
                : t('invite_count', params: {'count': _selectedUsers.length.toString()}),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedUsers.isEmpty ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _selectedUsers.isEmpty ? null : _confirmSelection,
        ),
      ],
    );
  }

  Widget _buildUsersList(String Function(String, {Map<String, String>? params}) t) {
    final filteredUsers = _getFilteredUsers();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? t('no_users_available') : t('no_results'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                t('try_different_search'),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, i) {
        final doc = filteredUsers[i];
        final data = doc.data() as Map<String, dynamic>;
        final isSelected = _selectedUsers.any((u) => u['id'] == doc.id);

        final username = data['username'] ?? t('nameless');
        final email = data['email'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? Colors.blue.shade50 : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              username,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Text(email, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            trailing: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                size: 32,
              ),
            ),
            onTap: () => _toggleSelection(
              {'id': doc.id, 'username': username, 'email': email},
              t('user_fallback'),
            ),
          ),
        );
      },
    );
  }
}

// File: lib/l10n/invite_user_translations.dart

class InviteUserTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'dialog_title': {'fr': 'Inviter des utilisateurs', 'en': 'Invite Users'},
      'search_hint': {'fr': 'Rechercher par nom ou e-mail...', 'en': 'Search by name or email...'},
      'no_users_available': {'fr': 'Aucun utilisateur disponible', 'en': 'No users available'},
      'no_results': {'fr': 'Aucun résultat', 'en': 'No results'},
      'try_different_search': {'fr': 'Essayez une recherche différente', 'en': 'Try a different search'},
      'nameless': {'fr': 'Sans nom', 'en': 'Nameless'},
      'user_fallback': {'fr': 'Utilisateur', 'en': 'User'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'invite': {'fr': 'Inviter', 'en': 'Invite'},
      'invite_count': {'fr': 'Inviter ({count})', 'en': 'Invite ({count})'},
      'selected_count': {'fr': '{count} sélectionné(s)', 'en': '{count} selected'},
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
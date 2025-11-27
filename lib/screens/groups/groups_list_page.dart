// lib/screens/groups/groups_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/language_provider.dart';
import 'chat_page.dart';
import 'create_group_page.dart';

class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _discoverSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForInvitations();
    });
  }

  String t(String key, {Map<String, String>? params}) {
    // Use read here as it's often called outside the build method
    final lang = context.read<LanguageProvider>().language;
    return GroupsListTranslations.t(key, lang, params: params);
  }

  Future<void> _checkForInvitations() async {
    if (currentUser == null) return;
    await Future.delayed(const Duration(milliseconds: 500));
    final invitations = await FirebaseFirestore.instance
        .collection('invitations')
        .where('invitedUserId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (invitations.docs.isNotEmpty && mounted) {
      final count = invitations.docs.length;
      final message = count == 1
          ? t('pending_invitation_singular')
          : t('pending_invitations_plural', params: {'count': count.toString()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _joinGroup(String groupId, String groupName) async {
    if (currentUser == null) return;
    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

    await groupRef.update({
      'members': FieldValue.arrayUnion([currentUser!.uid]),
    });

    final username = currentUser!.displayName ?? t('a_member');
    await groupRef.collection('messages').add({
      'text': t('user_joined_group', params: {'username': username}),
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': 'system',
      'senderName': t('system'),
    });

    final groupDoc = await groupRef.get();
    final adminId = (groupDoc.data()?['adminId'] ?? '') as String? ?? '';
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'join_group',
      'groupId': groupId,
      'groupName': groupName,
      'userId': currentUser!.uid,
      'adminId': adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('you_joined_group'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use watch here to rebuild tabs if language changes
    final lang = context.watch<LanguageProvider>().language;
    String t(String key) => GroupsListTranslations.t(key, lang);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('groups_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: t('my_groups_tab'), icon: const Icon(Icons.group)),
              Tab(text: t('discover_tab'), icon: const Icon(Icons.explore)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGroupsList(
              FirebaseFirestore.instance
                  .collection('groups')
                  .where('members', arrayContains: currentUser?.uid)
                  .snapshots(),
              isMemberTab: true,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t('search_public_group_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _discoverSearchQuery = v.trim().toLowerCase()),
                  ),
                ),
                Expanded(
                  child: _buildGroupsList(
                    FirebaseFirestore.instance
                        .collection('groups')
                        .where('isPublic', isEqualTo: true)
                        .snapshots(),
                    isMemberTab: false,
                    filterByName: _discoverSearchQuery,
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGroupPage()),
            );
          },
          tooltip: t('create_group_tooltip'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildGroupsList(
      Stream<QuerySnapshot> stream, {
        required bool isMemberTab,
        String filterByName = '',
      }) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) => GroupsListTranslations.t(key, lang, params: params);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(isMemberTab ? t('no_groups_joined') : t('no_public_groups_found')),
          );
        }

        var groups = snapshot.data!.docs;

        if (!isMemberTab && filterByName.isNotEmpty) {
          groups = groups.where((g) {
            final data = g.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(filterByName);
          }).toList();
        }

        if (groups.isEmpty) {
          return Center(child: Text(t('no_results')));
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupData = group.data() as Map<String, dynamic>;
            final groupName = groupData['name'] ?? t('untitled_group');
            final description = groupData['description'] ?? '';
            final List members = (groupData['members'] ?? []) as List;
            final bool isMember = members.contains(currentUser?.uid);

            final memberCount = members.length;
            final memberText = memberCount == 1
                ? t('member_count_singular', params: {'count': memberCount.toString()})
                : t('member_count_plural', params: {'count': memberCount.toString()});

            return ListTile(
              title: Text(groupName),
              subtitle: Text("$description\n$memberText"),
              isThreeLine: true,
              trailing: isMemberTab || isMember
                  ? const Icon(Icons.check, color: Colors.green)
                  : ElevatedButton(
                onPressed: () => _joinGroup(group.id, groupName),
                child: Text(t('join_button')),
              ),
              onTap: () {
                if (isMemberTab || isMember) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        groupId: group.id,
                        groupName: groupName,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

// File: lib/l10n/groups_list_translations.dart

class GroupsListTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'pending_invitation_singular': {
        'fr': 'Vous avez 1 invitation en attente',
        'en': 'You have 1 pending invitation'
      },
      'pending_invitations_plural': {
        'fr': 'Vous avez {count} invitations en attente',
        'en': 'You have {count} pending invitations'
      },
      'user_joined_group': {
        'fr': '{username} a rejoint le groupe.',
        'en': '{username} joined the group.'
      },
      'a_member': {'fr': 'Un membre', 'en': 'A member'},
      'system': {'fr': 'Système', 'en': 'System'},
      'you_joined_group': {
        'fr': 'Vous avez rejoint le groupe !',
        'en': 'You have joined the group!'
      },
      'groups_title': {'fr': 'Groupes', 'en': 'Groups'},
      'my_groups_tab': {'fr': 'Mes groupes', 'en': 'My Groups'},
      'discover_tab': {'fr': 'Découvrir', 'en': 'Discover'},
      'search_public_group_hint': {
        'fr': 'Rechercher un groupe public...',
        'en': 'Search for a public group...'
      },
      'no_groups_joined': {
        'fr': "Vous n'avez rejoint aucun groupe pour le moment.",
        'en': "You haven't joined any groups yet."
      },
      'no_public_groups_found': {
        'fr': 'Aucun groupe public trouvé.',
        'en': 'No public groups found.'
      },
      'no_results': {'fr': 'Aucun résultat.', 'en': 'No results.'},
      'untitled_group': {'fr': 'Groupe sans titre', 'en': 'Untitled Group'},
      'member_count_singular': {'fr': '{count} membre', 'en': '{count} member'},
      'member_count_plural': {'fr': '{count} membres', 'en': '{count} members'},
      'join_button': {'fr': 'Rejoindre', 'en': 'Join'},
      'create_group_tooltip': {'fr': 'Créer un groupe', 'en': 'Create a group'},
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
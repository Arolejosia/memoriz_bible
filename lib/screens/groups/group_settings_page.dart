// lib/screens/groups/group_settings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import 'invite_user_dialog.dart';

class GroupSettingsPage extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> groupData;

  const GroupSettingsPage({
    super.key,
    required this.groupId,
    required this.groupData,
  });

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool get isAdmin => widget.groupData['adminId'] == currentUser?.uid;
  bool get isMember => (widget.groupData['members'] as List).contains(currentUser?.uid);

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return GroupSettingsTranslations.t(key, lang, params: params);
  }

  Future<void> _leaveGroup() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('you_left_group'))));
    }
  }

  Future<void> _deleteGroup() async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).delete();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('group_deleted'))));
    }
  }

  Future<void> _inviteUsers() async {
    if (!isAdmin) return;
    final selected = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => const InviteUserDialog(),
    );
    if (selected == null || selected.isEmpty) return;

    for (final user in selected) {
      await FirebaseFirestore.instance.collection('invitations').add({
        'groupId': widget.groupId,
        'groupName': widget.groupData['name'] ?? '',
        'invitedUserId': user['id'],
        'invitedBy': currentUser!.uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('invitations_sent', params: {'count': selected.length.toString()}))),
      );
    }
  }

  void _openMembers() {
    final members = List<String>.from(widget.groupData['members'] ?? []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupMembersPage(
          groupId: widget.groupId,
          members: members,
          adminId: widget.groupData['adminId'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) => GroupSettingsTranslations.t(key, lang, params: params);

    if (!isMember) {
      return Scaffold(
        appBar: AppBar(title: Text(t('settings_title'))),
        body: Center(child: Text(t('not_a_member'))),
      );
    }
    final membersCount = (widget.groupData['members'] as List).length;

    return Scaffold(
      appBar: AppBar(title: Text(t('settings_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(widget.groupData['name'] ?? t('default_group_name')),
            subtitle: Text(widget.groupData['description'] ?? ''),
            leading: const Icon(Icons.group),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(t('members_count', params: {'count': membersCount.toString()})),
            subtitle: Text(t('view_members_list')),
            onTap: _openMembers,
          ),
          const Divider(height: 32),
          if (isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: Text(t('invite_users')),
              onPressed: _inviteUsers,
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(isAdmin ? Icons.delete_forever : Icons.exit_to_app),
            label: Text(isAdmin ? t('delete_group') : t('leave_group')),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdmin ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: isAdmin ? _deleteGroup : _leaveGroup,
          ),
        ],
      ),
    );
  }
}

class GroupMembersPage extends StatelessWidget {
  final String groupId;
  final List<String> members;
  final String adminId;

  const GroupMembersPage({
    super.key,
    required this.groupId,
    required this.members,
    required this.adminId,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key) => GroupSettingsTranslations.t(key, lang);

    return Scaffold(
      appBar: AppBar(title: Text(t('members_page_title'))),
      body: ListView.separated(
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final userId = members[i];

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return ListTile(title: Text(t('loading')));
              }
              final data = snap.data!.data() as Map<String, dynamic>?;
              final username = (data?['username'] ?? t('default_username')).toString();
              final email = (data?['email'] ?? '').toString();

              final currentUser = FirebaseAuth.instance.currentUser;
              final isCurrentUser = userId == currentUser?.uid;
              final isAdmin = userId == adminId;

              final displayName = isCurrentUser ? t('you') : username;
              final roleLabel = isAdmin ? t('admin_role') : t('member_role');

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAdmin ? Colors.orangeAccent : Colors.blueGrey.shade200,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                        color: isCurrentUser ? Colors.blueAccent : Colors.black87,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.orangeAccent, size: 18),
                    ]
                  ],
                ),
                subtitle: Text(
                  isCurrentUser
                      ? (isAdmin ? t('subtitle_you_admin') : t('subtitle_you'))
                      : "$email — $roleLabel",
                ),
                trailing: isCurrentUser ? const Icon(Icons.person, color: Colors.blueAccent) : null,
              );
            },
          );
        },
      ),
    );
  }
}
// File: lib/l10n/group_settings_translations.dart

class GroupSettingsTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // GroupSettingsPage
      'you_left_group': {'fr': 'Vous avez quitté le groupe.', 'en': 'You have left the group.'},
      'group_deleted': {'fr': 'Groupe supprimé.', 'en': 'Group deleted.'},
      'invitations_sent': {'fr': '{count} invitation(s) envoyée(s).', 'en': '{count} invitation(s) sent.'},
      'settings_title': {'fr': 'Paramètres du groupe', 'en': 'Group Settings'},
      'not_a_member': {'fr': "Vous n'êtes pas membre de ce groupe.", 'en': 'You are not a member of this group.'},
      'default_group_name': {'fr': 'Groupe', 'en': 'Group'},
      'members_count': {'fr': 'Membres ({count})', 'en': 'Members ({count})'},
      'view_members_list': {'fr': 'Voir la liste des membres', 'en': 'View the member list'},
      'invite_users': {'fr': 'Inviter des utilisateurs', 'en': 'Invite Users'},
      'delete_group': {'fr': 'Supprimer le groupe', 'en': 'Delete Group'},
      'leave_group': {'fr': 'Quitter le groupe', 'en': 'Leave Group'},

      // GroupMembersPage
      'members_page_title': {'fr': 'Membres du groupe', 'en': 'Group Members'},
      'loading': {'fr': 'Chargement...', 'en': 'Loading...'},
      'default_username': {'fr': 'Utilisateur', 'en': 'User'},
      'you': {'fr': 'Vous', 'en': 'You'},
      'admin_role': {'fr': 'Admin', 'en': 'Admin'},
      'member_role': {'fr': 'Membre', 'en': 'Member'},
      'subtitle_you_admin': {'fr': '(C’est vous, Admin)', 'en': '(This is you, Admin)'},
      'subtitle_you': {'fr': '(C’est vous)', 'en': '(This is you)'},
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
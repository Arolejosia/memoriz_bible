// lib/screens/groups/invitations_page.dart
// ✅ VERSION AVEC LOGS DÉTAILLÉS POUR DEBUG

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import 'chat_page.dart';

class InvitationsPage extends StatefulWidget {
  const InvitationsPage({super.key});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    print('🔵 [InvitationsPage] initState - UID: ${currentUser?.uid}');
    _debugInvitations();
  }

  // ✅ NOUVEAU : Debug pour voir toutes les invitations
  Future<void> _debugInvitations() async {
    if (currentUser == null) {
      print('❌ [Debug] Pas d\'utilisateur connecté');
      return;
    }

    try {
      print('🔍 [Debug] Recherche des invitations pour UID: ${currentUser!.uid}');

      // Toutes les invitations (peu importe le status)
      final allInvitations = await FirebaseFirestore.instance
          .collection('invitations')
          .where('invitedUserId', isEqualTo: currentUser!.uid)
          .get();

      print('📊 [Debug] Total invitations: ${allInvitations.docs.length}');

      for (var doc in allInvitations.docs) {
        final data = doc.data();
        print('  📋 ID: ${doc.id}');
        print('     Status: ${data['status']}');
        print('     Groupe: ${data['groupName']}');
        print('     Timestamp: ${data['timestamp']}');
      }

      // Invitations pending seulement
      final pendingInvitations = await FirebaseFirestore.instance
          .collection('invitations')
          .where('invitedUserId', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      print('⏳ [Debug] Invitations PENDING: ${pendingInvitations.docs.length}');

    } catch (e) {
      print('❌ [Debug] Erreur: $e');
    }
  }

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return InvitationsTranslations.t(key, lang, params: params);
  }

  Future<String> _getUserDisplayName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        final fullName = data?['fullName'] as String?;
        final username = data?['username'] as String?;
        final email = data?['email'] as String?;

        if (fullName != null && fullName.isNotEmpty) {
          return fullName;
        } else if (username != null && username.isNotEmpty) {
          return username;
        } else if (email != null && email.isNotEmpty) {
          return email.split('@').first;
        }
      }
    } catch (e) {
      print('❌ Erreur récupération nom utilisateur: $e');
    }

    return t('a_member');
  }

  Future<void> _acceptInvitation(DocumentSnapshot invitation) async {
    if (currentUser == null) return;

    final invitationData = invitation.data() as Map<String, dynamic>;
    final groupId = invitationData['groupId'] as String;
    final groupName = invitationData['groupName'] as String?;

    print('✅ [Accept] Début acceptation invitation: ${invitation.id}');
    print('   Groupe: $groupName ($groupId)');

    try {
      // 1. Ajouter l'utilisateur au groupe
      print('📝 [Accept] Ajout au groupe...');
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser!.uid]),
      });
      print('✅ [Accept] Ajouté au groupe');

      // 2. Marquer l'invitation comme acceptée
      print('📝 [Accept] Mise à jour status...');
      await invitation.reference.update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [Accept] Status mis à jour: accepted');

      // 3. Ajouter un message système dans le groupe
      final userDisplayName = await _getUserDisplayName(currentUser!.uid);
      print('📝 [Accept] Ajout message système ($userDisplayName)...');

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add({
        'text': t('user_joined_group', params: {'username': userDisplayName}),
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': 'system',
        'senderName': t('system'),
      });
      print('✅ [Accept] Message système ajouté');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('invitation_accepted')),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: t('open_group'),
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      groupId: groupId,
                      groupName: groupName ?? t('group'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }

      print('✅ [Accept] Acceptation terminée avec succès');
    } catch (e) {
      print('❌ [Accept] Erreur acceptation invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('error_accepting')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(DocumentSnapshot invitation) async {
    print('🔴 [Decline] Début refus invitation: ${invitation.id}');

    try {
      await invitation.reference.update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [Decline] Status mis à jour: declined');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('invitation_declined')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ [Decline] Erreur refus invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('error_declining')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) =>
        InvitationsTranslations.t(key, lang, params: params);

    print('🔄 [Build] Reconstruction de InvitationsPage');

    return Scaffold(
      appBar: AppBar(
        title: Text(t('invitations_title')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // ✅ NOUVEAU : Bouton de debug
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
            onPressed: () {
              _debugInvitations();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('invitations')
            .where('invitedUserId', isEqualTo: currentUser?.uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print('📡 [StreamBuilder] État: ${snapshot.connectionState}');

          if (snapshot.hasError) {
            print('❌ [StreamBuilder] Erreur: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            print('📊 [StreamBuilder] Données reçues: ${snapshot.data!.docs.length} invitations');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ [StreamBuilder] Chargement...');
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('📭 [StreamBuilder] Aucune invitation pending');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('no_pending_invitations'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('invitations_appear_here'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // ✅ Bouton pour forcer un refresh
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rafraîchir'),
                    onPressed: () {
                      print('🔄 Rafraîchissement manuel demandé');
                      _debugInvitations();
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          }

          final invitations = snapshot.data!.docs;
          print('✅ [StreamBuilder] Affichage de ${invitations.length} invitation(s)');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final data = invitation.data() as Map<String, dynamic>;
              final groupName = data['groupName'] ?? t('untitled_group');
              final timestamp = data['timestamp'] as Timestamp?;
              final invitedBy = data['invitedBy'] as String?;

              print('🎴 [Card] Affichage invitation: $groupName (${invitation.id})');

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.group_add,
                              color: Colors.blue.shade700,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('invitation_to_group'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  groupName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (timestamp != null) ...[
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (invitedBy != null)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(invitedBy)
                              .get(),
                          builder: (context, userSnap) {
                            if (userSnap.hasData) {
                              final userData = userSnap.data?.data() as Map<String, dynamic>?;
                              final inviterName = userData?['username'] ?? t('someone');

                              return Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('invited_by', params: {'name': inviterName}),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(t('decline')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red.shade300, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _declineInvitation(invitation),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(t('accept')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _acceptInvitation(invitation),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return t('minutes_ago', params: {'minutes': difference.inMinutes.toString()});
    } else if (difference.inHours < 24) {
      return t('hours_ago', params: {'hours': difference.inHours.toString()});
    } else if (difference.inDays < 7) {
      return t('days_ago', params: {'days': difference.inDays.toString()});
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class InvitationsTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'invitations_title': {'fr': 'Mes Invitations', 'en': 'My Invitations'},
      'no_pending_invitations': {
        'fr': 'Aucune invitation en attente',
        'en': 'No pending invitations'
      },
      'invitations_appear_here': {
        'fr': 'Les invitations aux groupes apparaîtront ici',
        'en': 'Group invitations will appear here'
      },
      'invitation_to_group': {
        'fr': 'Invitation au groupe',
        'en': 'Invitation to group'
      },
      'invited_by': {
        'fr': 'Invité par {name}',
        'en': 'Invited by {name}'
      },
      'someone': {'fr': 'quelqu\'un', 'en': 'someone'},
      'accept': {'fr': 'Accepter', 'en': 'Accept'},
      'decline': {'fr': 'Refuser', 'en': 'Decline'},
      'invitation_accepted': {
        'fr': 'Invitation acceptée !',
        'en': 'Invitation accepted!'
      },
      'invitation_declined': {
        'fr': 'Invitation refusée',
        'en': 'Invitation declined'
      },
      'open_group': {'fr': 'Ouvrir', 'en': 'Open'},
      'group': {'fr': 'Groupe', 'en': 'Group'},
      'error_accepting': {
        'fr': 'Erreur lors de l\'acceptation',
        'en': 'Error accepting invitation'
      },
      'error_declining': {
        'fr': 'Erreur lors du refus',
        'en': 'Error declining invitation'
      },
      'untitled_group': {'fr': 'Groupe sans titre', 'en': 'Untitled Group'},
      'a_member': {'fr': 'Un membre', 'en': 'A member'},
      'user_joined_group': {
        'fr': '{username} a rejoint le groupe.',
        'en': '{username} joined the group.'
      },
      'system': {'fr': 'Système', 'en': 'System'},
      'minutes_ago': {'fr': 'Il y a {minutes} min', 'en': '{minutes} min ago'},
      'hours_ago': {'fr': 'Il y a {hours}h', 'en': '{hours}h ago'},
      'days_ago': {'fr': 'Il y a {days}j', 'en': '{days}d ago'},
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
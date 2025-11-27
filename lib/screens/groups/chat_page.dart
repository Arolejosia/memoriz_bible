// lib/screens/groups/chat_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import '../../services/user_moderation_service.dart';
import 'group_settings_page.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper for translations
  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return ChatPageTranslations.t(key, lang, params: params);
  }
// 🔴 NOUVELLE MÉTHODE : Menu sur appui long d'un message
  Future<void> _showMessageOptions(String senderId, String senderName, String messageId) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.flag, color: Colors.orange),
              title: Text(isFrench ? 'Signaler ce message' : 'Report this message'),
              onTap: () {
                Navigator.pop(context);
                _reportMessage(senderId, senderName, messageId);
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text(isFrench ? 'Bloquer $senderName' : 'Block $senderName'),
              onTap: () {
                Navigator.pop(context);
                _blockUser(senderId, senderName);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text(isFrench ? 'Annuler' : 'Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

// 🔴 NOUVELLE MÉTHODE : Menu sur appui de l'avatar
  Future<void> _showUserProfileOptions(String userId, String userName) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    // Vérifier si déjà bloqué
    final isBlocked = await UserModerationService.isUserBlocked(userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                userName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            if (!isBlocked)
              ListTile(
                leading: Icon(Icons.flag, color: Colors.orange),
                title: Text(isFrench ? 'Signaler cet utilisateur' : 'Report this user'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser(userId, userName);
                },
              ),
            ListTile(
              leading: Icon(
                isBlocked ? Icons.check_circle : Icons.block,
                color: isBlocked ? Colors.green : Colors.red,
              ),
              title: Text(
                isBlocked
                    ? (isFrench ? 'Débloquer $userName' : 'Unblock $userName')
                    : (isFrench ? 'Bloquer $userName' : 'Block $userName'),
              ),
              onTap: () {
                Navigator.pop(context);
                if (isBlocked) {
                  _unblockUser(userId, userName);
                } else {
                  _blockUser(userId, userName);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text(isFrench ? 'Annuler' : 'Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

// 🔴 NOUVELLE MÉTHODE : Signaler un message
  Future<void> _reportMessage(String reportedUserId, String senderName, String messageId) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFrench ? 'Signaler ce message' : 'Report this message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrench
                  ? 'Pourquoi signalez-vous ce message de $senderName ?'
                  : 'Why are you reporting this message from $senderName?',
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isFrench ? 'Raison' : 'Reason',
                border: OutlineInputBorder(),
                hintText: isFrench
                    ? 'Contenu inapproprié, spam, etc.'
                    : 'Inappropriate content, spam, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isFrench ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(isFrench ? 'Signaler' : 'Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await UserModerationService.reportMessage(
          messageId: messageId,
          reportedUserId: reportedUserId,
          groupId: widget.groupId,
          reason: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? 'Message signalé avec succès' : 'Message reported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? 'Erreur lors du signalement' : 'Error reporting message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// 🔴 NOUVELLE MÉTHODE : Signaler un utilisateur
  Future<void> _reportUser(String reportedUserId, String userName) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFrench ? 'Signaler $userName' : 'Report $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrench
                  ? 'Pourquoi signalez-vous cet utilisateur ?'
                  : 'Why are you reporting this user?',
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isFrench ? 'Raison' : 'Reason',
                border: OutlineInputBorder(),
                hintText: isFrench
                    ? 'Comportement inapproprié, harcèlement, etc.'
                    : 'Inappropriate behavior, harassment, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isFrench ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(isFrench ? 'Signaler' : 'Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        await UserModerationService.reportUser(
          reportedUserId: reportedUserId,
          reason: reasonController.text.trim(),
          groupId: widget.groupId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? 'Utilisateur signalé avec succès' : 'User reported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? 'Erreur lors du signalement' : 'Error reporting user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// 🔴 NOUVELLE MÉTHODE : Bloquer un utilisateur
  Future<void> _blockUser(String userId, String userName) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFrench ? 'Bloquer $userName ?' : 'Block $userName?'),
        content: Text(
          isFrench
              ? 'Vous ne verrez plus les messages de cet utilisateur.'
              : 'You will no longer see messages from this user.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isFrench ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isFrench ? 'Bloquer' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserModerationService.blockUser(userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? '$userName a été bloqué' : '$userName has been blocked'),
              backgroundColor: Colors.green,
            ),
          );
          // Rafraîchir l'affichage
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFrench ? 'Erreur lors du blocage' : 'Error blocking user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

// 🔴 NOUVELLE MÉTHODE : Débloquer un utilisateur
  Future<void> _unblockUser(String userId, String userName) async {
    final lang = context.read<LanguageProvider>().language;
    final isFrench = lang == 'fr';

    try {
      await UserModerationService.unblockUser(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFrench ? '$userName a été débloqué' : '$userName has been unblocked'),
            backgroundColor: Colors.green,
          ),
        );
        // Rafraîchir l'affichage
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFrench ? 'Erreur lors du déblocage' : 'Error unblocking user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final unknownUser = t('unknown_user');
    final email = currentUser!.email ?? "$unknownUser@example.com";
    final defaultUsername = email.split('@')[0];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    String senderName;
    if (userDoc.exists && (userDoc.data()?['username'] ?? '').toString().isNotEmpty) {
      senderName = userDoc.data()!['username'];
    } else if ((currentUser!.displayName ?? '').isNotEmpty) {
      senderName = currentUser!.displayName!;
    } else {
      senderName = defaultUsername;
    }

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUser!.uid,
      'senderName': senderName,
      'type': 'text',
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for language changes to rebuild the UI
    final lang = context.watch<LanguageProvider>().language;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .snapshots(),
      builder: (context, groupSnapshot) {
        if (!groupSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final doc = groupSnapshot.data;

        if (doc == null || !doc.exists || doc.data() == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t('group_not_found'))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t('group_no_longer_exists'),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final groupData = doc.data() as Map<String, dynamic>;
        final members = List<String>.from(groupData['members'] ?? []);
        final isMember = currentUser != null && members.contains(currentUser!.uid);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.groupName,
              style: const TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis),
            ),
            actions: [
              if (isMember)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSettingsPage(
                          groupId: widget.groupId,
                          groupData: groupData,
                        ),
                      ),
                    );
                  },
                  tooltip: t('group_settings'),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: UserModerationService.getBlockedUsers(),
                  builder: (context, blockedSnapshot) {
                    final blockedUsers = blockedSnapshot.data ?? [];

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text(t('no_messages_yet')));
                        }

                        // 🔴 FILTRER les messages des utilisateurs bloqués
                        final messages = snapshot.data!.docs.where((msg) {
                          final data = msg.data() as Map<String, dynamic>;
                          final senderId = data['senderId'] as String?;
                          return senderId == null || !blockedUsers.contains(senderId);
                        }).toList();

                        if (messages.isEmpty) {
                          return Center(child: Text(t('no_messages_yet')));
                        }

                        return ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final data = msg.data() as Map<String, dynamic>;
                            final isMe = data['senderId'] == currentUser?.uid;

                            if ((data['type'] ?? '') == 'system') {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Center(
                                  child: Text(
                                    (data['text'] ?? '').toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              );
                            }

                            bool showAvatarAndName = true;
                            if (index < messages.length - 1) {
                              final previous = messages[index + 1].data() as Map<String, dynamic>;
                              if (previous['senderId'] == data['senderId']) {
                                showAvatarAndName = false;
                              }
                            }

                            return _buildMessageBubble(data, isMe, showAvatarAndName, lang);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (isMember) _buildMessageInput(),
              if (!isMember)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    t('not_a_member'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: t('enter_message_hint'),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _getFirstLetter(String? text) {
    if (text == null || text.isEmpty) return "?";
    return text.substring(0, 1).toUpperCase();
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe, bool showAvatar, String lang) {
    final senderName = (messageData['senderName'] ?? '').toString().trim();
    final senderId = (messageData['senderId'] ?? '').toString();
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
    final displayName = isMe ? t('me') : senderName;

    final myBubbleColor = Theme.of(context).primaryColor;
    final otherBubbleColor = Colors.grey.shade200;

    String formattedTime = "";
    if (timestamp != null) {
      formattedTime = formatMessageTime(timestamp, lang);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: GestureDetector(
        // 🔴 AJOUT : Menu contextuel sur appui long
        onLongPress: () {
          if (!isMe && senderId.isNotEmpty) {
            _showMessageOptions(senderId, senderName, messageData.toString());
          }
        },
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar)
              GestureDetector(
                // 🔴 AJOUT : Menu sur appui de l'avatar
                onTap: () => _showUserProfileOptions(senderId, senderName),
                child: CircleAvatar(
                  backgroundColor: myBubbleColor.withOpacity(0.2),
                  child: Text(
                    _getFirstLetter(senderName),
                    style: TextStyle(color: myBubbleColor, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else if (!isMe)
              const SizedBox(width: 40),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMe
                        ? [myBubbleColor.withBlue(myBubbleColor.blue + 10), myBubbleColor]
                        : [otherBubbleColor, otherBubbleColor.withBlue(230)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                    bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe && showAvatar && senderName.isNotEmpty)
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isMe ? Colors.white : Theme.of(context).primaryColorDark,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      (messageData['text'] ?? '').toString(),
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatMessageTime(DateTime timestamp, String lang) {
    final now = DateTime.now();
    final difference = now.difference(timestamp).inDays;

    // Format manuel simple et fiable (pas besoin d'initialiser intl)
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (now.year == timestamp.year && now.month == timestamp.month && now.day == timestamp.day) {
      return t('today_at_time', params: {'time': timeStr});
    } else if (difference == 1) {
      return t('yesterday_at_time', params: {'time': timeStr});
    } else {
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      final year = timestamp.year;
      return '$day/$month/$year $timeStr';
    }
  }
}

// File: lib/l10n/chat_page_translations.dart

class ChatPageTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      'unknown_user': {'fr': 'inconnu', 'en': 'unknown'},
      'group_not_found': {'fr': 'Groupe introuvable', 'en': 'Group Not Found'},
      'group_no_longer_exists': {
        'fr': "Ce groupe n'existe plus ou vous n'y avez plus accès.",
        'en': "This group no longer exists or you no longer have access."
      },
      'group_settings': {'fr': 'Paramètres du groupe', 'en': 'Group Settings'},
      'no_messages_yet': {
        'fr': 'Aucun message pour le moment.',
        'en': 'No messages yet.'
      },
      'not_a_member': {
        'fr': "Vous n'êtes pas membre de ce groupe.",
        'en': "You are not a member of this group."
      },
      'enter_message_hint': {
        'fr': 'Entrez un message...',
        'en': 'Enter a message...'
      },
      'me': {'fr': 'Moi', 'en': 'Me'},
      'today_at_time': {'fr': "Aujourd'hui {time}", 'en': "Today {time}"},
      'yesterday_at_time': {'fr': 'Hier {time}', 'en': 'Yesterday {time}'},
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
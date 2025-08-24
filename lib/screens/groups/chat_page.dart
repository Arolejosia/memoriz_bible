// Fichier: lib/screens/groups/chat_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Sends a new message to the group's message subcollection
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) {
      return;
    }

    // Reference to the 'messages' subcollection
    final messagesCollection = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages');

    // Add the new message document
    await messagesCollection.add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUser!.uid,
      'senderName': currentUser!.displayName ?? currentUser!.email, // Use username if available
    });

    // Clear the input field
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupName,
          style: const TextStyle(
            fontSize: 18, // Adjust font size to fit in AppBar
            overflow: TextOverflow.ellipsis, // Handle long names
          ),
        ),
      ),
      body: Column(
        // Text(widget.groupName),
        children: [
          // ✅ The list of messages, updated in real-time
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Newest messages at the bottom
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                // Dans votre ListView.builder

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUser?.uid;

                    // ✅ Logique pour n'afficher l'avatar/nom que pour le premier message d'un groupe
                    bool showAvatarAndName = true;
                    if (index < messages.length - 1) {
                      final previousMessage = messages[index + 1].data() as Map<String, dynamic>;
                      if (previousMessage['senderId'] == messageData['senderId']) {
                        showAvatarAndName = false;
                      }
                    }

                    return _buildMessageBubble(messageData, isMe, showAvatarAndName);
                  },
                );
              },
            ),
          ),
          // ✅ The message input field
          _buildMessageInput(),
        ],
      ),
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
              decoration: const InputDecoration(
                hintText: "Enter a message...",
                border: OutlineInputBorder(),
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

  // Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
  //   return Align(
  //     alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
  //         borderRadius: BorderRadius.circular(16),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             messageData['senderName'] ?? 'Unknown User',
  //             style: TextStyle(
  //               fontWeight: FontWeight.bold,
  //               color: isMe ? Colors.white : Colors.black87,
  //             ),
  //           ),
  //           Text(
  //             messageData['text'] ?? '',
  //             style: TextStyle(color: isMe ? Colors.white : Colors.black87),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
// Dans votre classe _ChatPageState

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe, bool showAvatar) {
    final senderName = messageData['senderName'] ?? 'Utilisateur Inconnu';
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();

    // Définition des couleurs pour un accès facile
    final myBubbleColor = Theme.of(context).primaryColor;
    final otherBubbleColor = Colors.grey.shade200;

    return Padding(
      padding: EdgeInsets.only(
        top: 4.0,
        bottom: 4.0,
        left: 8.0,
        right: 8.0,
        // On ajoute un peu d'espace entre les bulles de différents expéditeurs
        // C'est un détail qui améliore grandement la lisibilité
        // (Vous aurez besoin de connaître le message précédent pour cette logique)
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // --- AVATAR (seulement pour les autres et si c'est le dernier message du groupe) ---
          if (!isMe && showAvatar)
            CircleAvatar(
              backgroundColor: myBubbleColor.withOpacity(0.2),
              child: Text(
                  senderName.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: myBubbleColor, fontWeight: FontWeight.bold)
              ),
            )
          else if (!isMe)
          // Espace réservé pour garder l'alignement
            const SizedBox(width: 40),

          const SizedBox(width: 8),

          // --- BULLE DE MESSAGE ---
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // Dégradé subtil pour un look plus moderne
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ]
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Nom de l'expéditeur (seulement pour les autres)
                  if (!isMe && showAvatar)
                    Text(
                      senderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Theme.of(context).primaryColorDark,
                        fontSize: 12,
                      ),
                    ),

                  // Texte du message
                  Text(
                    messageData['text'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Heure d'envoi
                  Text(
                    timestamp != null ? "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}" : "",
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
    );
  }
// Dans votre classe _ChatPageState

}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModerationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // BLOCAGE D'UTILISATEURS
  // ==========================================

  /// Bloque un utilisateur
  static Future<void> blockUser(String userIdToBlock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([userIdToBlock])
    });
  }

  /// Débloque un utilisateur
  static Future<void> unblockUser(String userIdToUnblock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([userIdToUnblock])
    });
  }

  /// Récupère la liste des utilisateurs bloqués
  static Future<List<String>> getBlockedUsers() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];

    final doc = await _firestore.collection('users').doc(currentUserId).get();
    if (!doc.exists) return [];

    final data = doc.data();
    return List<String>.from(data?['blockedUsers'] ?? []);
  }

  /// Vérifie si un utilisateur est bloqué
  static Future<bool> isUserBlocked(String userId) async {
    final blockedUsers = await getBlockedUsers();
    return blockedUsers.contains(userId);
  }

  // ==========================================
  // SIGNALEMENT
  // ==========================================

  /// Signale un message
  static Future<void> reportMessage({
    required String messageId,
    required String reportedUserId,
    required String groupId,
    required String reason,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('reports').add({
      'type': 'message',
      'messageId': messageId,
      'reportedUserId': reportedUserId,
      'reporterId': currentUserId,
      'groupId': groupId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Signale un utilisateur
  static Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? groupId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('reports').add({
      'type': 'user',
      'reportedUserId': reportedUserId,
      'reporterId': currentUserId,
      'groupId': groupId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
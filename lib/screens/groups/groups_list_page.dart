// Fichier: lib/screens/groups/groups_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'create_group_page.dart'; // To navigate to the create page

class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  /// Makes the current user join a group
  Future<void> _joinGroup(String groupId) async {
    if (currentUser == null) return;

    final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

    // Use FieldValue.arrayUnion to safely add the user's ID to the members list
    await groupRef.update({
      'members': FieldValue.arrayUnion([currentUser!.uid])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have joined the group!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // We have two tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Groups"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "My Groups", icon: Icon(Icons.group)),
              Tab(text: "Discover", icon: Icon(Icons.explore)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ✅ Tab 1: Groups the user is already in
            _buildGroupsList(
              FirebaseFirestore.instance
                  .collection('groups')
                  .where('members', arrayContains: currentUser?.uid)
                  .snapshots(),
              isMember: true,
            ),

            // ✅ Tab 2: Public groups the user can join
            _buildGroupsList(
              FirebaseFirestore.instance
                  .collection('groups')
                  .where('isPublic', isEqualTo: true)
                  .snapshots(),
              isMember: false,
            ),
          ],
        ),
        // ✅ Floating Action Button to create a new group
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateGroupPage()),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Create a group',
        ),
      ),
    );
  }

  /// A reusable widget to build a list of groups from a stream
  Widget _buildGroupsList(Stream<QuerySnapshot> stream, {required bool isMember}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(isMember ? "You haven't joined any groups yet." : "No public groups found."));
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final groupData = group.data() as Map<String, dynamic>;
            final userIsAlreadyMember = (groupData['members'] as List).contains(currentUser?.uid);

            return ListTile(
              title: Text(groupData['name'] ?? 'Untitled Group'),
              subtitle: Text(groupData['description'] ?? ''),
              trailing: isMember || userIsAlreadyMember
                  ? const Icon(Icons.check, color: Colors.green) // Already a member
                  : ElevatedButton(
                onPressed: () => _joinGroup(group.id),
                child: const Text("Join"),
              ),
              onTap: () {
                // ✅ Only allow navigating to the chat if the user is a member
                if (isMember || userIsAlreadyMember) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatPage(
                            groupId: group.id,
                            groupName: groupData['name'],
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
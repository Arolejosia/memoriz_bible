// Fichier: lib/screens/groups/create_group_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  // Controllers to get the text from the input fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Handles the creation of the group in Firestore
  Future<void> _createGroup() async {
    // First, validate the form inputs
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle error: user is not logged in
      setState(() => _isLoading = false);
      return;
    }

    try {
      // ✅ Add a new document to the 'groups' collection
      await FirebaseFirestore.instance.collection('groups').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPublic': _isPublic,
        'adminId': currentUser.uid,
        'members': [currentUser.uid], // The creator is the first member
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate back after successful creation
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle potential errors (e.g., no internet connection)
      print("Error creating group: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create group. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create a New Group"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Field for the group name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Group Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ✅ Field for the group description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ✅ Switch for public/private setting
              SwitchListTile(
                title: const Text("Public Group"),
                subtitle: const Text("Anyone can find and join this group."),
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
              ),


              // ✅ The create button
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Group"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
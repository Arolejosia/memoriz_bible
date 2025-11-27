// ============= 1. MODÈLE DE DONNÉES =============

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';
import 'custom_questions_translations.dart';

import 'EditQCMPage.dart';
import 'creationQuestions.dart';

enum QuestionType {
  qcm,
  texteTrous,
  vraiFaux,
  ouverte,
}

class CustomQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String>? options;
  final int? correctAnswerIndex;
  final List<int>? blankIndices;
  final String? openAnswer;
  final String userId;
  final DateTime createdAt;

  CustomQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    this.correctAnswerIndex,
    this.blankIndices,
    this.openAnswer,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'blankIndices': blankIndices,
      'openAnswer': openAnswer,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomQuestion.fromMap(Map<String, dynamic> map) {
    return CustomQuestion(
      id: map['id'],
      type: QuestionType.values.firstWhere((e) => e.name == map['type']),
      question: map['question'],
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswerIndex: map['correctAnswerIndex'],
      blankIndices: map['blankIndices'] != null ? List<int>.from(map['blankIndices']) : null,
      openAnswer: map['openAnswer'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class QuestionList {
  final String id;
  final String name;
  final String? description;
  final List<String> questionIds;
  final DateTime createdAt;
  final String userId;

  QuestionList({
    required this.id,
    required this.name,
    this.description,
    required this.questionIds,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'questionIds': questionIds,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory QuestionList.fromMap(Map<String, dynamic> map) {
    return QuestionList(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      questionIds: List<String>.from(map['questionIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'],
    );
  }
}

// ============= 2. WIDGETS RÉUTILISABLES =============

class _QuestionTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _QuestionTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final CustomQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(String) t;

  const _QuestionCard({
    required this.question,
    required this.onEdit,
    required this.onDelete,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeInfo['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(typeInfo['icon'], size: 16, color: typeInfo['color']),
                      const SizedBox(width: 4),
                      Text(
                        typeInfo['label'],
                        style: TextStyle(
                          fontSize: 12,
                          color: typeInfo['color'],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  color: Colors.blue[400],
                  tooltip: t('edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red[400],
                  tooltip: t('delete'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo() {
    switch (question.type) {
      case QuestionType.qcm:
        return {'icon': Icons.list_alt, 'label': t('mcq'), 'color': Colors.blue};
      case QuestionType.texteTrous:
        return {'icon': Icons.text_fields, 'label': t('fill_blank'), 'color': Colors.orange};
      case QuestionType.vraiFaux:
        return {'icon': Icons.check_circle_outline, 'label': t('true_false'), 'color': Colors.green};
      case QuestionType.ouverte:
        return {'icon': Icons.edit_note, 'label': t('open_question'), 'color': Colors.purple};
    }
  }
}

// ============= 3. PAGE PRINCIPALE =============

class CustomQuestionsPage extends StatelessWidget {
  final String userId;

  const CustomQuestionsPage({Key? key, required this.userId}) : super(key: key);

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  Future<void> _editQuestion(BuildContext context, Map<String, dynamic> question) async {
    Widget editPage;

    switch (question['type']) {
      case 'qcm':
        editPage = EditQCMPage(question: question);
        break;
      case 'texteTrous':
        editPage = EditTexteTrousPage(question: question);
        break;
      case 'vraiFaux':
        editPage = EditVraiFauxPage(question: question);
        break;
      case 'ouverte':
        editPage = EditQuestionOuvertePage(question: question);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(context, 'unknown_question_type'))),
        );
        return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => editPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'my_questions')),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuestionListsPage(userId: userId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder),
                  Text(t(context, 'lists'), style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customQuestions')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${t(context, 'error')}: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  Text(
                    t(context, 'check_firestore_permissions'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(t(context, 'loading_questions')),
                ],
              ),
            );
          }

          final questions = snapshot.data?.docs ?? [];

          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    t(context, 'no_questions_yet'),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(context, 'create_first_question'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final questionData = questions[index].data() as Map<String, dynamic>;
              final question = CustomQuestion.fromMap(questionData);

              return _QuestionCard(
                question: question,
                t: (key) => t(context, key),
                onEdit: () => _editQuestion(context, questionData),
                onDelete: () => _showDeleteDialog(context, question.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuestionTypeSelector(context),
        icon: const Icon(Icons.add),
        label: Text(t(context, 'create_question')),
      ),
    );
  }

  void _showQuestionTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(context, 'question_types'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _QuestionTypeOption(
                icon: Icons.list_alt,
                title: t(context, 'mcq'),
                description: t(context, 'mcq_desc'),
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QCMCreationPage(userId: userId),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.check_circle_outline,
                title: t(context, 'true_false'),
                description: t(context, 'true_false_desc'),
                color: Colors.green,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VraiFauxCreationPage(userId: userId),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.text_fields,
                title: t(context, 'fill_blank'),
                description: t(context, 'fill_blank_desc'),
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TexteTrousCreationPage(userId: userId),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.edit_note,
                title: t(context, 'open_question'),
                description: t(context, 'open_question_desc'),
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionOuverteCreationPage(userId: userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(context, 'delete_question')),
        content: Text(t(context, 'delete_question_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(questionId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(context, 'question_deleted'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t(context, 'error_deleting')}: $e')),
          );
        }
      }
    }
  }
}

// ============= 4. PAGE DES LISTES =============

class QuestionListsPage extends StatelessWidget {
  final String userId;

  const QuestionListsPage({Key? key, required this.userId}) : super(key: key);

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'my_lists')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('questionLists')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${t(context, 'error')}: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final lists = snapshot.data?.docs ?? [];

          if (lists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    t(context, 'no_lists_yet'),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(context, 'create_first_list'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final listData = lists[index].data() as Map<String, dynamic>;
              final questionList = QuestionList.fromMap(listData);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.folder, color: Colors.blue),
                  title: Text(questionList.name),
                  subtitle: Text(
                    '${questionList.questionIds.length} ${t(context, 'questions')}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteListDialog(context, questionList.id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListDetailPage(
                          listId: questionList.id,
                          listName: questionList.name,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateListDialog(context),
        icon: const Icon(Icons.add),
        label: Text(t(context, 'create_list')),
      ),
    );
  }

  Future<void> _showCreateListDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(context, 'create_list')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: t(context, 'list_name'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: t(context, 'description_optional'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t(context, 'create')),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        final listId = FirebaseFirestore.instance.collection('questionLists').doc().id;

        await FirebaseFirestore.instance.collection('questionLists').doc(listId).set({
          'id': listId,
          'name': nameController.text.trim(),
          'description': descController.text.trim().isNotEmpty
              ? descController.text.trim()
              : null,
          'questionIds': [],
          'userId': userId,
          'createdAt': DateTime.now().toIso8601String(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(context, 'list_created'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t(context, 'error')}: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteListDialog(BuildContext context, String listId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(context, 'delete_list')),
        content: Text(t(context, 'delete_list_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t(context, 'delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('questionLists')
            .doc(listId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t(context, 'list_deleted'))),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t(context, 'error')}: $e')),
          );
        }
      }
    }
  }
}

// ============= 5. PAGE DÉTAIL LISTE =============

class ListDetailPage extends StatefulWidget {
  final String listId;
  final String listName;
  final String userId;

  const ListDetailPage({
    Key? key,
    required this.listId,
    required this.listName,
    required this.userId,
  }) : super(key: key);

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final questionIds = List<String>.from(data['questionIds'] ?? []);
          final isEmpty = questionIds.isEmpty;

          return Stack(
            children: [
              if (isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        t('empty_list'),
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('add_first_question'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questionIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('customQuestions')
                          .doc(questionIds[index])
                          .get(),
                      builder: (context, questionSnapshot) {
                        if (!questionSnapshot.hasData) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final questionData = questionSnapshot.data!.data() as Map<String, dynamic>;
                        final question = CustomQuestion.fromMap(questionData);

                        return _QuestionCard(
                          question: question,
                          t: t,
                          onEdit: () {},
                          onDelete: () => _removeQuestionFromList(questionIds[index]),
                        );
                      },
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final questionIds = List<String>.from(data['questionIds'] ?? []);
          final isEmpty = questionIds.isEmpty;

          if (isEmpty) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showQuestionTypeSelector(context),
                    icon: const Icon(Icons.add_circle),
                    label: Text(t('create_question')),
                    backgroundColor: Colors.blue,
                    heroTag: 'create_question',
                  ),
                );
              },
            );
          } else {
            return FloatingActionButton.extended(
              onPressed: () => _showQuestionTypeSelector(context),
              icon: const Icon(Icons.add),
              label: Text(t('add_question')),
              heroTag: 'add_question',
            );
          }
        },
      ),
    );
  }

  void _showQuestionTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t('create_for')}: ${widget.listName}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _QuestionTypeOption(
                icon: Icons.list_alt,
                title: t('mcq'),
                description: t('mcq_desc'),
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QCMCreationPage(
                        userId: widget.userId,
                        listId: widget.listId,
                        listName: widget.listName,
                      ),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.check_circle_outline,
                title: t('true_false'),
                description: t('true_false_desc'),
                color: Colors.green,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VraiFauxCreationPage(
                        userId: widget.userId,
                        listId: widget.listId,
                        listName: widget.listName,
                      ),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.text_fields,
                title: t('fill_blank'),
                description: t('fill_blank_desc'),
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TexteTrousCreationPage(
                        userId: widget.userId,
                        listId: widget.listId,
                        listName: widget.listName,
                      ),
                    ),
                  );
                },
              ),
              _QuestionTypeOption(
                icon: Icons.edit_note,
                title: t('open_question'),
                description: t('open_question_desc'),
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuestionOuverteCreationPage(
                        userId: widget.userId,
                        listId: widget.listId,
                        listName: widget.listName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeQuestionFromList(String questionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('questionLists')
          .doc(widget.listId)
          .update({
        'questionIds': FieldValue.arrayRemove([questionId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('question_removed_from_list'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error')}: $e')),
        );
      }
    }
  }
}
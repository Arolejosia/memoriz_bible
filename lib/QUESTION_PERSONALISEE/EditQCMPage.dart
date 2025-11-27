import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';
import 'custom_questions_translations.dart';

// ============= PAGE D'ÉDITION QCM =============

class EditQCMPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditQCMPage({Key? key, required this.question}) : super(key: key);

  @override
  State<EditQCMPage> createState() => _EditQCMPageState();
}

class _EditQCMPageState extends State<EditQCMPage> {
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late final List<TextEditingController> _optionControllers;
  late int _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question['question']);
    _explanationController = TextEditingController(text: widget.question['explanation'] ?? '');
    _correctAnswerIndex = widget.question['correctAnswerIndex'] ?? 0;

    final options = List<String>.from(widget.question['options'] ?? []);
    _optionControllers = options.map((opt) => TextEditingController(text: opt)).toList();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
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
        title: Text(t('edit_qcm')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('question_text'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('answers'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ..._optionControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    final isCorrect = _correctAnswerIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: _correctAnswerIndex,
                            onChanged: (value) => setState(() => _correctAnswerIndex = value!),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: '${t('answer')} ${String.fromCharCode(65 + index)}',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: isCorrect,
                                fillColor: isCorrect ? Colors.green.withOpacity(0.1) : null,
                              ),
                            ),
                          ),
                          if (index >= 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (_optionControllers.length <= 2) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t('cannot_delete_only_2'))),
                                  );
                                  return;
                                }
                                setState(() {
                                  _optionControllers.removeAt(index);
                                  if (_correctAnswerIndex == index) {
                                    _correctAnswerIndex = 0;
                                  } else if (_correctAnswerIndex > index) {
                                    _correctAnswerIndex--;
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  }),
                  if (_optionControllers.length < 6)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _optionControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: Text(t('add_answer')),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    t('explanation_optional'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t('explanation_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text(t('save_changes')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    // Validation
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    final validOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();

    if (validOptions.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_2_answers'))),
      );
      return;
    }

    if (_correctAnswerIndex >= validOptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_correct_answer'))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('customQuestions')
          .doc(widget.question['id'])
          .update({
        'question': _questionController.text.trim(),
        'options': validOptions,
        'correctAnswerIndex': _correctAnswerIndex,
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('qcm_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_updating_qcm')}: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_question')),
        content: Text(t('delete_question_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(widget.question['id'])
            .delete();

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('question_deleted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t('error_deleting')}: $e')),
          );
        }
      }
    }
  }
}

// ============= PAGE D'ÉDITION VRAI/FAUX =============

class EditVraiFauxPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditVraiFauxPage({Key? key, required this.question}) : super(key: key);

  @override
  State<EditVraiFauxPage> createState() => _EditVraiFauxPageState();
}

class _EditVraiFauxPageState extends State<EditVraiFauxPage> {
  late final TextEditingController _questionController;
  late final TextEditingController _explanationController;
  late bool _correctAnswer;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question['question']);
    _explanationController = TextEditingController(text: widget.question['explanation'] ?? '');
    _correctAnswer = widget.question['correctAnswer'] ?? true;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _explanationController.dispose();
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
        title: Text(t('edit_true_false')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('statement'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('correct_answer'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(t('is_true')),
                          value: true,
                          groupValue: _correctAnswer,
                          onChanged: (value) => setState(() => _correctAnswer = value!),
                          activeColor: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(t('is_false')),
                          value: false,
                          groupValue: _correctAnswer,
                          onChanged: (value) => setState(() => _correctAnswer = value!),
                          activeColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('explanation_optional'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t('explanation_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text(t('save_changes')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('customQuestions')
          .doc(widget.question['id'])
          .update({
        'question': _questionController.text.trim(),
        'correctAnswer': _correctAnswer,
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('true_false_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving')}: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_question')),
        content: Text(t('delete_question_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(widget.question['id'])
            .delete();

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('question_deleted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t('error_deleting')}: $e')),
          );
        }
      }
    }
  }
}

// ============= PAGE D'ÉDITION TEXTE À TROUS =============

class EditTexteTrousPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditTexteTrousPage({Key? key, required this.question}) : super(key: key);

  @override
  State<EditTexteTrousPage> createState() => _EditTexteTrousPageState();
}

class _EditTexteTrousPageState extends State<EditTexteTrousPage> {
  late final TextEditingController _textController;
  late final TextEditingController _explanationController;
  late final List<TextEditingController> _answerControllers;
  int _blankCount = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question['textWithBlanks']);
    _explanationController = TextEditingController(text: widget.question['explanation'] ?? '');

    final answers = List<String>.from(widget.question['answers'] ?? []);
    _answerControllers = answers.map((a) => TextEditingController(text: a)).toList();
    _blankCount = _countBlanks(_textController.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  int _countBlanks(String text) {
    return '[...]'.allMatches(text).length;
  }

  void _updateBlankCount() {
    final newCount = _countBlanks(_textController.text);
    if (newCount != _blankCount) {
      setState(() {
        _blankCount = newCount;
        while (_answerControllers.length < newCount) {
          _answerControllers.add(TextEditingController());
        }
        while (_answerControllers.length > newCount) {
          _answerControllers.removeLast().dispose();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('edit_fill_blank')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('text_with_blanks'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t('use_brackets'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    onChanged: (_) => _updateBlankCount(),
                    decoration: InputDecoration(
                      hintText: t('text_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_blankCount > 0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_blankCount ${t('found_blanks')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_blankCount > 0) ...[
                    Text(
                      t('answers'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ..._answerControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: '${t('blank')} ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    t('explanation_optional'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t('explanation_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text(t('save_changes')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    if (_blankCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('no_blanks_found'))),
      );
      return;
    }

    final answers = _answerControllers.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('fill_all_answers'))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('customQuestions')
          .doc(widget.question['id'])
          .update({
        'textWithBlanks': _textController.text.trim(),
        'answers': answers,
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('fill_blank_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving')}: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_question')),
        content: Text(t('delete_question_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(widget.question['id'])
            .delete();

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('question_deleted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t('error_deleting')}: $e')),
          );
        }
      }
    }
  }
}

// ============= PAGE D'ÉDITION QUESTION OUVERTE =============

class EditQuestionOuvertePage extends StatefulWidget {
  final Map<String, dynamic> question;

  const EditQuestionOuvertePage({Key? key, required this.question}) : super(key: key);

  @override
  State<EditQuestionOuvertePage> createState() => _EditQuestionOuvertePageState();
}

class _EditQuestionOuvertePageState extends State<EditQuestionOuvertePage> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _explanationController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question['question']);
    _answerController = TextEditingController(text: widget.question['openAnswer']);
    _explanationController = TextEditingController(text: widget.question['explanation'] ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
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
        title: Text(t('edit_open_question')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('question_text'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('expected_answer'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t('explanation_optional'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _explanationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t('explanation_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Text(t('save_changes')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_answer'))),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('customQuestions')
          .doc(widget.question['id'])
          .update({
        'question': _questionController.text.trim(),
        'openAnswer': _answerController.text.trim(),
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('open_question_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving')}: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_question')),
        content: Text(t('delete_question_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('customQuestions')
            .doc(widget.question['id'])
            .delete();

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('question_deleted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t('error_deleting')}: $e')),
          );
        }
      }
    }
  }
}
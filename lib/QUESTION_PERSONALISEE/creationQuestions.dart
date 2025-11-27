import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';
import 'custom_questions_translations.dart';

// ============= 1. CRÉATION QCM =============

class QCMCreationPage extends StatefulWidget {
  final String userId;
  final String? listId;
  final String? listName;

  const QCMCreationPage({
    Key? key,
    required this.userId,
    this.listId,
    this.listName,
  }) : super(key: key);

  @override
  State<QCMCreationPage> createState() => _QCMCreationPageState();
}

class _QCMCreationPageState extends State<QCMCreationPage> {
  int _currentStep = 0;
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correctAnswerIndex;

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
        title: Text(widget.listName != null
            ? '${t('qcm_for')}: ${widget.listName}'
            : t('create_qcm')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
          _buildStep4(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.quiz, size: 60, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  t('step_1_write_question'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _questionController,
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('question_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onNext: _questionController.text.trim().isNotEmpty
              ? () => setState(() => _currentStep = 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('step_2_add_answers'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[index],
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: '${t('answer')} ${index + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (index >= 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _optionControllers.removeAt(index).dispose();
                                if (_correctAnswerIndex == index) {
                                  _correctAnswerIndex = null;
                                } else if (_correctAnswerIndex != null && _correctAnswerIndex! > index) {
                                  _correctAnswerIndex = _correctAnswerIndex! - 1;
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
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 0),
          onNext: _optionControllers.where((c) => c.text.trim().isNotEmpty).length >= 2
              ? () => setState(() => _currentStep = 2)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final validOptions = _optionControllers
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  t('step_3_select_correct'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ...validOptions.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  final isSelected = _correctAnswerIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _correctAnswerIndex = index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 1),
          onNext: _correctAnswerIndex != null
              ? () => setState(() => _currentStep = 3)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lightbulb_outline, size: 60, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  t('step_4_explanation'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _explanationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('explanation_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 2),
          showSkip: true,
          onSkip: _saveQuestion,
          onNext: _saveQuestion,
          nextLabel: t('finish'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    bool showSkip = false,
    String? nextLabel,
  }) {
    return Container(
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
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(t('previous')),
                ),
              ),
            if (onBack != null && (onNext != null || showSkip)) const SizedBox(width: 12),
            if (showSkip)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: Text(t('skip')),
                ),
              ),
            if (showSkip && onNext != null) const SizedBox(width: 12),
            if (onNext != null)
              Expanded(
                flex: onBack == null ? 1 : 1,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: Text(nextLabel ?? t('next')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
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
        SnackBar(content: Text(t('need_at_least_2_answers'))),
      );
      return;
    }

    if (_correctAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('select_correct_answer_first'))),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      final questionId = FirebaseFirestore.instance.collection('customQuestions').doc().id;

      await FirebaseFirestore.instance.collection('customQuestions').doc(questionId).set({
        'id': questionId,
        'type': 'qcm',
        'question': _questionController.text.trim(),
        'options': validOptions,
        'correctAnswerIndex': _correctAnswerIndex,
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'userId': widget.userId,
        'listId': widget.listId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (widget.listId != null) {
        await FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .update({
          'questionIds': FieldValue.arrayUnion([questionId]),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listId != null
                ? t('qcm_saved_in_list')
                : t('qcm_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving_qcm')}: $e')),
        );
      }
    }
  }
}

// ============= 2. CRÉATION VRAI/FAUX =============

class VraiFauxCreationPage extends StatefulWidget {
  final String userId;
  final String? listId;
  final String? listName;

  const VraiFauxCreationPage({
    Key? key,
    required this.userId,
    this.listId,
    this.listName,
  }) : super(key: key);

  @override
  State<VraiFauxCreationPage> createState() => _VraiFauxCreationPageState();
}

class _VraiFauxCreationPageState extends State<VraiFauxCreationPage> {
  int _currentStep = 0;
  final _statementController = TextEditingController();
  final _explanationController = TextEditingController();
  bool? _isTrue;

  @override
  void dispose() {
    _statementController.dispose();
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
        title: Text(widget.listName != null
            ? '${t('true_false_for')}: ${widget.listName}'
            : t('create_true_false')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  t('step_1_write_question'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _statementController,
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('statement_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onNext: _statementController.text.trim().isNotEmpty
              ? () => setState(() => _currentStep = 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.help_outline, size: 60, color: Colors.blue),
                const SizedBox(height: 24),
                Text(
                  t('step_2_choose_answer'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                InkWell(
                  onTap: () => setState(() => _isTrue = true),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isTrue == true ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                      border: Border.all(
                        color: _isTrue == true ? Colors.green : Colors.grey[300]!,
                        width: _isTrue == true ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTrue == true ? Icons.check_circle : Icons.circle_outlined,
                          color: _isTrue == true ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          t('is_true'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _isTrue == true ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setState(() => _isTrue = false),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isTrue == false ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                      border: Border.all(
                        color: _isTrue == false ? Colors.red : Colors.grey[300]!,
                        width: _isTrue == false ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTrue == false ? Icons.cancel : Icons.circle_outlined,
                          color: _isTrue == false ? Colors.red : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          t('is_false'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: _isTrue == false ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 0),
          onNext: _isTrue != null ? () => setState(() => _currentStep = 2) : null,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lightbulb_outline, size: 60, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  t('step_4_explanation'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _explanationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('explanation_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 1),
          showSkip: true,
          onSkip: _saveQuestion,
          onNext: _saveQuestion,
          nextLabel: t('finish'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    bool showSkip = false,
    String? nextLabel,
  }) {
    return Container(
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
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(t('previous')),
                ),
              ),
            if (onBack != null && (onNext != null || showSkip)) const SizedBox(width: 12),
            if (showSkip)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: Text(t('skip')),
                ),
              ),
            if (showSkip && onNext != null) const SizedBox(width: 12),
            if (onNext != null)
              Expanded(
                flex: onBack == null ? 1 : 1,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: Text(nextLabel ?? t('next')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (_statementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    if (_isTrue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('choose_answer_first'))),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final questionId = FirebaseFirestore.instance.collection('customQuestions').doc().id;

      await FirebaseFirestore.instance.collection('customQuestions').doc(questionId).set({
        'id': questionId,
        'type': 'vraiFaux',
        'question': _statementController.text.trim(),
        'correctAnswer': _isTrue,
        'correctAnswerIndex': _isTrue == true ? 1 : 0,
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'userId': widget.userId,
        'listId': widget.listId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (widget.listId != null) {
        await FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .update({
          'questionIds': FieldValue.arrayUnion([questionId]),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listId != null
                ? t('true_false_saved_in_list')
                : t('true_false_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving_true_false')}: $e')),
        );
      }
    }
  }
}

// ============= 3. CRÉATION TEXTE À TROUS =============

class TexteTrousCreationPage extends StatefulWidget {
  final String userId;
  final String? listId;
  final String? listName;

  const TexteTrousCreationPage({
    Key? key,
    required this.userId,
    this.listId,
    this.listName,
  }) : super(key: key);

  @override
  State<TexteTrousCreationPage> createState() => _TexteTrousCreationPageState();
}

class _TexteTrousCreationPageState extends State<TexteTrousCreationPage> {
  int _currentStep = 0;
  final _textController = TextEditingController();
  final _explanationController = TextEditingController();
  List<String> _words = [];
  final Set<int> _selectedIndices = {};

  @override
  void dispose() {
    _textController.dispose();
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
        title: Text(widget.listName != null
            ? '${t('fill_blank_for')}: ${widget.listName}'
            : t('create_fill_blank')),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.text_fields, size: 60, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  t('step_1_write_text'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _textController,
                  autofocus: true,
                  maxLines: 5,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('text_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onNext: _textController.text.trim().isNotEmpty
              ? () {
            setState(() {
              _words = _textController.text.trim().split(' ');
              _currentStep = 1;
            });
          }
              : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Text(
                t('step_2_select_words'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedIndices.length} ${t('words_selected')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _words.asMap().entries.map((entry) {
                final index = entry.key;
                final word = entry.value;
                final isSelected = _selectedIndices.contains(index);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIndices.remove(index);
                      } else {
                        _selectedIndices.add(index);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[200],
                      border: Border.all(
                        color: isSelected ? Colors.orange : Colors.grey[400]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.orange[900] : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 0),
          onNext: _selectedIndices.isNotEmpty
              ? () => setState(() => _currentStep = 2)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lightbulb_outline, size: 60, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  t('step_4_explanation'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _explanationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('explanation_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 1),
          showSkip: true,
          onSkip: _saveQuestion,
          onNext: _saveQuestion,
          nextLabel: t('finish'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    bool showSkip = false,
    String? nextLabel,
  }) {
    return Container(
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
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(t('previous')),
                ),
              ),
            if (onBack != null && (onNext != null || showSkip)) const SizedBox(width: 12),
            if (showSkip)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: Text(t('skip')),
                ),
              ),
            if (showSkip && onNext != null) const SizedBox(width: 12),
            if (onNext != null)
              Expanded(
                flex: onBack == null ? 1 : 1,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: Text(nextLabel ?? t('next')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('need_question'))),
      );
      return;
    }

    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('select_words_first'))),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final questionId = FirebaseFirestore.instance.collection('customQuestions').doc().id;

      await FirebaseFirestore.instance.collection('customQuestions').doc(questionId).set({
        'id': questionId,
        'type': 'texteTrous',
        'question': _textController.text.trim(),
        'blankIndices': _selectedIndices.toList()..sort(),
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'userId': widget.userId,
        'listId': widget.listId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (widget.listId != null) {
        await FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .update({
          'questionIds': FieldValue.arrayUnion([questionId]),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listId != null
                ? t('fill_blank_saved_in_list')
                : t('fill_blank_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving_fill_blank')}: $e')),
        );
      }
    }
  }
}

// ============= 4. CRÉATION QUESTION OUVERTE =============

class QuestionOuverteCreationPage extends StatefulWidget {
  final String userId;
  final String? listId;
  final String? listName;

  const QuestionOuverteCreationPage({
    Key? key,
    required this.userId,
    this.listId,
    this.listName,
  }) : super(key: key);

  @override
  State<QuestionOuverteCreationPage> createState() => _QuestionOuverteCreationPageState();
}

class _QuestionOuverteCreationPageState extends State<QuestionOuverteCreationPage> {
  int _currentStep = 0;
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _explanationController = TextEditingController();

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
        title: Text(widget.listName != null
            ? '${t('open_question_for')}: ${widget.listName}'
            : t('create_open_question')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.edit_note, size: 60, color: Colors.purple),
                const SizedBox(height: 24),
                Text(
                  t('step_1_write_question'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _questionController,
                  autofocus: true,
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('question_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onNext: _questionController.text.trim().isNotEmpty
              ? () => setState(() => _currentStep = 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  t('step_2_write_answer'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _answerController,
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('answer_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 0),
          onNext: _answerController.text.trim().isNotEmpty
              ? () => setState(() => _currentStep = 2)
              : null,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.lightbulb_outline, size: 60, color: Colors.amber),
                const SizedBox(height: 24),
                Text(
                  t('step_4_explanation'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _explanationController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: t('explanation_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildNavigationButtons(
          onBack: () => setState(() => _currentStep = 1),
          showSkip: true,
          onSkip: _saveQuestion,
          onNext: _saveQuestion,
          nextLabel: t('finish'),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    bool showSkip = false,
    String? nextLabel,
  }) {
    return Container(
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
        child: Row(
          children: [
            if (onBack != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: Text(t('previous')),
                ),
              ),
            if (onBack != null && (onNext != null || showSkip)) const SizedBox(width: 12),
            if (showSkip)
              Expanded(
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: Text(t('skip')),
                ),
              ),
            if (showSkip && onNext != null) const SizedBox(width: 12),
            if (onNext != null)
              Expanded(
                flex: onBack == null ? 1 : 1,
                child: ElevatedButton(
                  onPressed: onNext,
                  child: Text(nextLabel ?? t('next')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final questionId = FirebaseFirestore.instance.collection('customQuestions').doc().id;

      await FirebaseFirestore.instance.collection('customQuestions').doc(questionId).set({
        'id': questionId,
        'type': 'ouverte',
        'question': _questionController.text.trim(),
        'openAnswer': _answerController.text.trim(),
        'explanation': _explanationController.text.trim().isNotEmpty
            ? _explanationController.text.trim()
            : null,
        'userId': widget.userId,
        'listId': widget.listId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (widget.listId != null) {
        await FirebaseFirestore.instance
            .collection('questionLists')
            .doc(widget.listId)
            .update({
          'questionIds': FieldValue.arrayUnion([questionId]),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.listId != null
                ? t('open_question_saved_in_list')
                : t('open_question_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_saving_open_question')}: $e')),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =======================================================================
// PAGE DU JEU QCM - MODE ALÉATOIRE
// Cette page est autonome et gère la logique pour ne pas répéter les mots.
// =======================================================================
class QcmRandomGamePage extends StatefulWidget {
  final String? livre;
  final int? chapitre;
  const QcmRandomGamePage({Key? key, this.livre, this.chapitre}) : super(key: key);
  @override
  _QcmRandomGamePageState createState() => _QcmRandomGamePageState();
}

class _QcmRandomGamePageState extends State<QcmRandomGamePage> {
  bool _isLoading = true;
  String _question = "";
  List<String> _options = [];
  String _correctAnswer = "";
  String? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  String? _currentReference; // Pour stocker la référence du verset
  final Set<String> _motsAppris = {};
  final String _baseUrl = "https://memoriz-bible-api.onrender.com";

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() { _isLoading = true; _answered = false; _selectedAnswer = null; });
    try {
      final url = Uri.parse('$_baseUrl/qcm/random'); // Mettez votre IP

      final requestBody = json.encode({
        "livre": widget.livre,
        "chapitre": widget.chapitre,
        "mots_deja_utilises": _motsAppris.toList()
      });

      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: requestBody);

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data.containsKey('error')) { _showError(data['error']); return; }
          setState(() {
            _question = data['question'];
            _options = List<String>.from(data['options']);
            _correctAnswer = data['reponse_correcte'];
            _currentReference = data['reference']; // On récupère la référence
            _isLoading = false;
          });
        } else { _showError("Erreur du serveur (${response.statusCode})."); }
      }
    } catch (e) { if (mounted) { _showError("Erreur de connexion."); } }
  }

  void _submitAnswer(String answer) {
    setState(() {
      _answered = true;
      _selectedAnswer = answer;
      if (answer == _correctAnswer) {
        _score++;
        _motsAppris.add(_correctAnswer.toLowerCase());
      }
    });
  }

  void _showError(String message) { setState(() { _isLoading = false; _question = message; _options = []; }); }
  Color _getButtonColor(String option) { if (!_answered) return Theme.of(context).colorScheme.secondaryContainer; if (option == _correctAnswer) return Colors.green.withOpacity(0.7); if (option == _selectedAnswer) return Colors.red.withOpacity(0.7); return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Partie Aléatoire"),
        actions: [Center(child: Padding(padding: const EdgeInsets.only(right: 16.0), child: Text("Score: $_score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))))],
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : _buildGameView(),
    );
  }

  Widget _buildGameView() {
    if (_options.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text(_question, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 18))));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ MODIFIÉ : Affiche la référence du verset
          if (_currentReference != null)
            Text(
                _currentReference!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
            ),
          SizedBox(height: 16),
          Text('Complétez le verset :', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: Offset(0, 4))]),
            child: Text(_question, style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, height: 1.5), textAlign: TextAlign.center),
          ),
          SizedBox(height: 24),
          ..._options.map((option) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _answered ? null : () => _submitAnswer(option),
              style: ElevatedButton.styleFrom(backgroundColor: _getButtonColor(option), foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer, padding: EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              child: Text(option, textAlign: TextAlign.center),
            ),
          )).toList(),
          Spacer(),
          if (_answered) ElevatedButton.icon(icon: Icon(Icons.arrow_forward), label: Text("Question suivante"), onPressed: _loadQuestion, style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)))
        ],
      ),
    );
  }
}

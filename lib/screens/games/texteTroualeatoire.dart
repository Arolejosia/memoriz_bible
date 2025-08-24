import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =======================================================================
// PAGE DE JEU : Texte à trous Aléatoire
// Cette page gère le jeu de texte à trous avec un passage aléatoire,
// potentiellement filtré par livre et/ou chapitre.
// =======================================================================
class TexteATrousRandomPage extends StatefulWidget {
  final String? livre;
  final int? chapitre;

  const TexteATrousRandomPage({Key? key, this.livre, this.chapitre}) : super(key: key);

  @override
  _TexteATrousRandomPageState createState() => _TexteATrousRandomPageState();
}

class _TexteATrousRandomPageState extends State<TexteATrousRandomPage> {
  // --- État du jeu ---
  bool _isLoading = true;
  String _versetModifie = "";
  List<String> _reponses = [];
  List<int> _indices = [];
  List<TextEditingController> _controllers = [];
  List<bool> _resultatsVerification = [];
  bool _answered = false;
  bool _bonneReponse = false;
  int _score = 0;
  String? _currentReference;
  String _niveau = 'débutant'; // Ou passez-le en paramètre si nécessaire
  final String _baseUrl = "https://memoriz-bible-api.onrender.com";
  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    super.dispose();
  }

  /// Appelle l'API pour obtenir un nouveau passage à trous aléatoire.
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _answered = false;
      _resultatsVerification = [];
    });

    try {
      final url = Uri.parse('$_baseUrl/jeu/random');

      final requestBody = json.encode({
        "livre": widget.livre,
        "chapitre": widget.chapitre,
        "niveau": _niveau,
        // Vous pouvez ajouter une logique de longueur si vous le souhaitez
        "longueur": "court"
      });

      final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: requestBody
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          if (data.containsKey('error')) {
            _showError(data['error']);
            return;
          }
          setState(() {
            _versetModifie = data['verset_modifie'];
            _reponses = List<String>.from(data['reponses']);
            _indices = List<int>.from(data['indices']);
            _currentReference = data['reference'];
            _controllers = List.generate(_reponses.length, (_) => TextEditingController());
            _isLoading = false;
          });
        } else {
          _showError("Erreur du serveur (${response.statusCode}).");
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("Erreur de connexion. Vérifiez l'IP et que le serveur API est bien lancé.");
      }
    }
  }

  /// Appelle l'API pour vérifier les réponses de l'utilisateur.
  Future<void> _verifierReponses() async {
    final reponsesUtilisateur = _controllers.map((c) => c.text.trim()).toList();
    try {
      final url = Uri.parse('$_baseUrl/verifier');
      final body = json.encode({"reponses_utilisateur": reponsesUtilisateur, "reponses_correctes": _reponses});
      final response = await http.post(url, headers: {"Content-Type": "application/json"}, body: body);

      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<bool> resultats = List<bool>.from(data["resultats"]);
        final bool toutBon = resultats.every((res) => res == true);
        setState(() {
          _answered = true;
          _bonneReponse = toutBon;
          _resultatsVerification = resultats;
          if (toutBon) {
            _score++;
          } else {
            for (int i = 0; i < _reponses.length; i++) {
              if (!resultats[i]) {
                _controllers[i].text = _reponses[i];
              }
            }
          }
        });
      } else {
        if(mounted) _showError("Erreur lors de la vérification.");
      }
    } catch (e) {
      if(mounted) _showError("Erreur réseau lors de la vérification.");
    }
  }

  /// Affiche un message d'erreur.
  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _versetModifie = message;
      _indices = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Texte à trous Aléatoire"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text("Score: $_score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildGameView(),
    );
  }

  /// Construit la vue principale du jeu.
  Widget _buildGameView() {
    if (_indices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_versetModifie, textAlign: TextAlign.center, style: TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }

    final mots = _versetModifie.split(" ");
    int champIndex = 0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentReference != null)
              Text(
                  _currentReference!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)
              ),
            SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(mots.length, (i) {
                if (_indices.contains(i)) {
                  final controller = _controllers[champIndex];
                  bool estCorrect = _answered && champIndex < _resultatsVerification.length ? _resultatsVerification[champIndex] : false;
                  final champ = SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller,
                      enabled: !_answered,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: _answered,
                        fillColor: _answered ? (estCorrect ? Colors.green[100] : Colors.red[100]) : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  );
                  champIndex++;
                  return champ;
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(mots[i], style: TextStyle(fontSize: 18, height: 1.5)),
                  );
                }
              }),
            ),
            SizedBox(height: 32),
            if (!_answered)
              ElevatedButton(
                onPressed: _verifierReponses,
                child: Text("Vérifier"),
              ),
            if (_answered)
              Column(
                children: [
                  _bonneReponse
                      ? Text("✅ Bien joué !", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : Text("❌ Ce n’est pas tout à fait ça...", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text("Question suivante"),
                    onPressed: _loadQuestion,
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
// Fichier : lib/widgets/passage_selector_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// Ce widget est maintenant autonome et réutilisable
class PassageSelectorWidget extends StatefulWidget {
  // Il reçoit les contrôleurs de son parent pour que le parent puisse lire les valeurs
  final ValueChanged<String?> onBookChanged;
  final TextEditingController chapterController;
  final TextEditingController startVerseController;
  final TextEditingController endVerseController;

  const PassageSelectorWidget({
    Key? key,
    required this.onBookChanged,
    required this.chapterController,
    required this.startVerseController,
    required this.endVerseController,
  }) : super(key: key);

  @override
  _PassageSelectorWidgetState createState() => _PassageSelectorWidgetState();
}

class _PassageSelectorWidgetState extends State<PassageSelectorWidget> {
  List<String> books = [
    "Genèse",
    "Exode",
    "Lévitique",
    "Nombres",
    "Deutéronome",
    "Josué",
    "Juges",
    "Ruth",
    "1 Samuel",
    "2 Samuel",
    "1 Rois",
    "2 Rois",
    "1 Chroniques",
    "2 Chroniques",
    "Esdras",
    "Néhémie",
    "Esther",
    "Job",
    "Psaume",
    "Proverbes",
    "Ecclésiaste",
    "Cantique des Cantiques",
    "Ésaïe",
    "Jérémie",
    "Lamentations",
    "Ézéchiel",
    "Daniel",
    "Osée",
    "Joël",
    "Amos",
    "Abdias",
    "Jonas",
    "Michée",
    "Nahum",
    "Habacuc",
    "Sophonie",
    "Aggée",
    "Zacharie",
    "Malachie",
    "Matthieu",
    "Marc",
    "Luc",
    "Jean",
    "Actes",
    "Romains",
    "1 Corinthiens",
    "2 Corinthiens",
    "Galates",
    "Éphésiens",
    "Philippiens",
    "Colossiens",
    "1 Thessaloniciens",
    "2 Thessaloniciens",
    "1 Timothée",
    "2 Timothée",
    "Tite",
    "Philémon",
    "Hébreux",
    "Jacques",
    "1 Pierre",
    "2 Pierre",
    "1 Jean",
    "2 Jean",
    "3 Jean",
    "Jude",
    "Apocalypse",
  ];
  String? selectedBook;
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _chargerLivresDepuisJson();
  }

  Future<void> _chargerLivresDepuisJson() async {
    // ... (Votre logique exacte pour charger les livres depuis assets/segond_1910.json)
    // C'est exactement la même fonction que vous aviez déjà.
    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);
      final Set<String> livresUniques = data.map((item) => item['book_name'] as String).toSet();

      if (mounted) {
        setState(() {
          books = ["Tous les livres", ...livresUniques.toList()..sort()];
          selectedBook = "Jean";
          _isLoadingBooks = false;
          widget.onBookChanged(selectedBook); // Informe le parent du livre par défaut
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBooks = false);
        _afficherMessageErreur("Impossible de charger la liste des livres.");
      }// Gérer l'erreur
    }
  }
  void _afficherMessageErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: _inputDecoration('Livre'),
          value: selectedBook,
          isExpanded: true,
          items: books.map((book) => DropdownMenuItem(value: book, child: Text(book))).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedBook = value);
              widget.onBookChanged(value); // Informe le parent du changement
            }
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: widget.chapterController, // Utilise le contrôleur du parent
          decoration: _inputDecoration('Chapitre', hint: 'Ex: 23'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.startVerseController, // Utilise le contrôleur du parent
                decoration: _inputDecoration('Début (facultatif)', hint: 'Ex: 1'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: widget.endVerseController, // Utilise le contrôleur du parent
                decoration: _inputDecoration('Fin (facultatif)', hint: 'Ex: 3'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Fonction de décoration (vous pouvez aussi la mettre dans un fichier séparé)
  // Fonction de décoration (vous pouvez aussi la mettre dans un fichier séparé)
  InputDecoration _inputDecoration(String label, {String? hint}) {
    // ✅ On retourne un objet InputDecoration, ce qui corrige l'erreur.
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
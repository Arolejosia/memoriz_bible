import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JeuPage extends StatefulWidget {
  @override
  _JeuPageState createState() => _JeuPageState();
}

class _JeuPageState extends State<JeuPage> {
  List<bool> resultats = [];
  TextEditingController referenceController = TextEditingController();
  String selectedNiveau = "debutant";
  String versetModifie = "";
  List<String> reponses = [];
  List<int> indices = [];
  List<TextEditingController> controllers = [];
  String versetOriginal = "";
  bool niveauDebloque = false;
  int scoreTotal = 0;
  int niveauActuel = 1;
  int bonnesReponses = 0;
  int tentatives = 0;
  bool partieCommencee = false;

  final List<String> livres = [
    "Genèse", "Exode", "Lévitique", "Nombres", "Deutéronome",
    "Josué", "Juges", "Ruth", "1 Samuel", "2 Samuel",
    "1 Rois", "2 Rois", "1 Chroniques", "2 Chroniques", "Esdras",
    "Néhémie", "Esther", "Job", "Psaumes", "Proverbes",
    "Ecclésiaste", "Cantique des cantiques", "Ésaïe", "Jérémie", "Lamentations",
    "Ézéchiel", "Daniel", "Osée", "Joël", "Amos",
    "Abdias", "Jonas", "Michée", "Nahum", "Habacuc",
    "Sophonie", "Aggée", "Zacharie", "Malachie", "Matthieu",
    "Marc", "Luc", "Jean", "Actes", "Romains",
    "1 Corinthiens", "2 Corinthiens", "Galates", "Éphésiens", "Philippiens",
    "Colossiens", "1 Thessaloniciens", "2 Thessaloniciens", "1 Timothée", "2 Timothée",
    "Tite", "Philémon", "Hébreux", "Jacques", "1 Pierre",
    "2 Pierre", "1 Jean", "2 Jean", "3 Jean", "Jude", "Apocalypse"
  ];
  String selectedBook = "Psaumes"; // valeur par défaut
  TextEditingController chapitreController = TextEditingController();
  TextEditingController versetController = TextEditingController();

  String niveauToString(int niveau) {
    switch (niveau) {
      case 1:
        return "debutant";
      case 2:
        return "intermediaire";
      case 3:
        return "expert";
      default:
        return "expert";
    }
  }


  bool versetCharge = false;

  Future<void> envoyerReference() async {
    final reference = "$selectedBook ${chapitreController.text.trim()}"
        "${versetController.text.trim().isNotEmpty ? ":${versetController.text.trim()}" : ""}";

    final niveau = selectedNiveau;

    final response = await http.post(
      Uri.parse('http://192.168.0.54:8000/jeu'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"reference": reference, "niveau": niveau}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["verset_modifie"] != null &&
          data["reponses"] != null &&
          data["indices"] != null) {
        setState(() {
          versetModifie = data["verset_modifie"];
          reponses = List<String>.from(data["reponses"]);
          indices = List<int>.from(data["indices"]);
          controllers =
              List.generate(reponses.length, (_) => TextEditingController());
          versetCharge = true;
          bonnesReponses = 0;
          tentatives = 0;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Erreur inconnue.")),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau ou parsing: ")),
      );
    }
  }

  void validerReponses() async {
    List<String> reponsesJoueur = controllers.map((c) => c.text.trim()).toList();

    final response = await http.post(
      Uri.parse("http://192.168.0.54:8000/verifier"), // remplace par ton IP si elle change
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "reponses_joueur": reponsesJoueur,
        "reponses_attendues": reponses
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      int corrects = data["score"];
      List details = data["details"];

      setState(() async {
        bonnesReponses = corrects;
        scoreTotal += corrects;
        tentatives++;
        resultats = details.map<bool>((d) => d["correct"] as bool).toList();

        if (scoreTotal >= 10 && niveauActuel < 3) {
          niveauDebloque = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("🎉 Niveau suivant débloqué ! Clique sur le bouton pour continuer.")),
          );
        }
        else if (corrects == reponses.length) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Tu as ${corrects} bonnes réponses. Continue .")), );
          // ✅ Toutes les réponses sont correctes → nouvelle grille
          await Future.delayed(Duration(milliseconds: 500));
          envoyerReference();
        }
         else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tu as ${corrects} bonnes réponses. Continue .")),
          );

        }

        versetCharge = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur serveur: ${response.statusCode}")),
      );
    }
  }

  List<Widget> afficherResultats() {
    List<Widget> widgets = [];

    for (int i = 0; i < reponses.length; i++) {
      final couleur = resultats.isNotEmpty && resultats[i] ? Colors.green : Colors.red;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Ta réponse : ${controllers[i].text} — Réponse attendue : ${reponses[i]}',
            style: TextStyle(color: couleur, fontSize: 16),
          ),
        ),
      );
    }

    return widgets;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Jeu - Complète le verset")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (partieCommencee) ...[
              Text(
                "📖 $selectedBook ${chapitreController.text}:${versetController.text}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    partieCommencee = false;
                    versetCharge = false;
                    versetOriginal = "";
                    versetModifie = "";
                    chapitreController.clear();
                    versetController.clear();
                    controllers.clear();
                    reponses.clear();
                    indices.clear();
                    resultats.clear();
                    scoreTotal = 0;
                    niveauActuel = 1;
                    niveauDebloque = false;
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text("Terminer la partie"),
              ),
        ],
        if (!partieCommencee) ...[
            DropdownButton<String>(
              value: selectedBook,
              isExpanded: true,
              onChanged: (val) => setState(() => selectedBook = val!),
              items: livres.map((book) => DropdownMenuItem(
                value: book,
                child: Text(book),
              )).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: chapitreController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Chapitre"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: versetController,
              decoration: InputDecoration(labelText: "Verset(s) (ex: 1 ou 1-3)"),
            ),

            SizedBox(height: 10),
            Text("Choisir un niveau :"),
            Row(
              children: [
                Radio(
                  value: "debutant",
                  groupValue: selectedNiveau,
                  onChanged: null,),

                Text("Débutant"),
                Radio(
                  value: "intermediaire",
                  groupValue: selectedNiveau,
                  onChanged: null
                ),
                Text("Intermédiaire"),
                Radio(
                  value: "expert",
                  groupValue: selectedNiveau,
                  onChanged: null
                ),
                Text("Expert"),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  partieCommencee = true;
                });
                envoyerReference();
              },
              child: Text("Jouer"),
            ),
        ],
            SizedBox(height: 20),
            Text("Niveau actuel : $niveauActuel | Score : $scoreTotal"),
            SizedBox(height: 20),
            if (versetCharge) ...[
              Wrap(
                children: versetModifie.split(" ").asMap().entries.map((entry) {
                  final index = entry.key;
                  final mot = entry.value;
                  if (mot == "_____") {
                    final ctrlIndex = indices.indexOf(index);
                    return Container(
                      width: 80,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: controllers[ctrlIndex],
                        decoration: InputDecoration(hintText: "?"),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(mot),
                    );
                  }
                }).toList(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: validerReponses,
                child: Text("Valider mes réponses"),
              ),
            ],
    if (!versetCharge && resultats.isNotEmpty && resultats.contains(false)) ...[
    SizedBox(height: 20),
    Divider(),
    ...afficherResultats(),
      SizedBox(height: 16),
      if (!niveauDebloque)
        ElevatedButton(
          onPressed: envoyerReference,
          child: Text("Continuer"),
        )
    ],
            if (niveauDebloque && partieCommencee) ...[
              SizedBox(height: 20),
              Text(
                "🎉 Tu as débloqué le niveau ${niveauActuel + 1} !",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final reference = "$selectedBook ${chapitreController.text.trim()}"
                      "${versetController.text.trim().isNotEmpty ? ":${versetController.text.trim()}" : ""}";
                  final nouveauNiveau = niveauToString(niveauActuel + 1);

                  final response = await http.post(
                    Uri.parse('http://192.168.0.54:8000/jeu'),
                    headers: {"Content-Type": "application/json"},
                    body: json.encode({"reference": reference, "niveau": nouveauNiveau}),
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    setState(() {
                      niveauActuel++;
                      selectedNiveau = nouveauNiveau;
                      scoreTotal = 0;
                      niveauDebloque = false;

                      versetModifie = data["verset_modifie"];
                      reponses = List<String>.from(data["reponses"]);
                      indices = List<int>.from(data["indices"]);
                      controllers = List.generate(reponses.length, (_) => TextEditingController());
                      resultats.clear();
                      versetCharge = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("🚀 Niveau $niveauActuel lancé – Bonne chance !")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur serveur : ${response.statusCode}")),
                    );
                  }
                },
                child: Text("Passer au niveau ${niveauActuel + 1}"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ]

          ],
        ),
      ),
    );
  }
}



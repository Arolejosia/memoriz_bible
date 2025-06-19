import 'package:flutter/material.dart';
import 'questions_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentification.dart';

class MemorizationIntroPage extends StatefulWidget {
  @override
  _MemorizationIntroPageState createState() => _MemorizationIntroPageState();
}

class _MemorizationIntroPageState extends State<MemorizationIntroPage> {
  PageController _pageController = PageController();
  Map<int, dynamic> userResponses = {};
  int currentIndex = 0;

  Future<void> saveResponsesToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('userResponses').add({
        "timestamp": FieldValue.serverTimestamp(),
        "answers": userResponses,
      });
      print("Réponses enregistrées avec succès !");
    } catch (e) {
      print("Erreur lors de l'enregistrement : $e");
    }
  }

  void nextPage() async {
    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentIndex == questions.length - 1) {
      await saveResponsesToFirestore();
      setState(() => currentIndex++); // aller à la page de remerciement
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentIndex == questions.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    }
  }

  bool isAnswered(int index) {
    final response = userResponses[index];
    final q = questions[index - 1];

    if (q.isTextInput) {
      return response != null && response.toString().trim().isNotEmpty;
    } else if (q.isMultipleChoice) {
      return response != null && (response as List).isNotEmpty;
    } else {
      return response != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        itemCount: questions.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 60),
                  Image.asset("assets/ange.png", height: 150),
                  SizedBox(height: 30),
                  Text(
                    "Bienvenue dans ton voyage avec la Parole de Dieu ✨",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Nous allons t’aider à graver les versets dans ton cœur.\nPrêt(e) ? Réponds à quelques petites questions 💬",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text("CONTINUER"),
                  ),
                ],
              ),
            );
          }

          if (index == questions.length + 1) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/ange.png", height: 120),
                  SizedBox(height: 20),
                  Text(
                    "Merci d’avoir répondu aux questions ✨",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Tu peux maintenant ouvrir une session pour commencer ton parcours avec la Parole de Dieu.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => AuthPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: Text("Ouvrir ma session"),
                  ),
                ],
              ),
            );
          }

          final q = questions[index - 1];
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: 60),
                Image.asset("assets/ange.png", height: 120),
                SizedBox(height: 20),
                Text(
                  q.question,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                if (q.isTextInput)
                  TextField(
                    onChanged: (value) => setState(() => userResponses[index] = value),
                    decoration: InputDecoration(
                      hintText: "Écris ta réponse ici...",
                      border: OutlineInputBorder(),
                    ),
                  )
                else if (q.isMultipleChoice)
                  SizedBox(
                    height: 200, // tu peux ajuster cette hauteur selon ton besoin
                    child: ListView.builder(
                      itemCount: q.options.length,
                      itemBuilder: (context, i) {
                        final option = q.options[i];
                        final selected = (userResponses[index] ?? []).contains(option);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: FilterChip(
                            label: Text(option),
                            selected: selected,
                            onSelected: (bool value) {
                              setState(() {
                                final list = List<String>.from(userResponses[index] ?? []);
                                if (value) {
                                  list.add(option);
                                } else {
                                  list.remove(option);
                                }
                                userResponses[index] = list;
                              });
                            },
                            selectedColor: Colors.green.shade200,
                            backgroundColor: Colors.grey.shade200,
                            checkmarkColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  )


                else
                  Column(
                    children: q.options.map((option) {
                      final isSelected = userResponses[index] == option;
                      return RadioListTile(
                        title: Text(option),
                        value: option,
                        groupValue: userResponses[index],
                        onChanged: (val) {
                          setState(() {
                            userResponses[index] = val;
                          });
                        },
                      );
                    }).toList(),
                  ),
                Spacer(),
                ElevatedButton(
                  onPressed: isAnswered(index) ? nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAnswered(index) ? Colors.green : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text("CONTINUER"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

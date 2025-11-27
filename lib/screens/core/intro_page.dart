import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import '../../screens/auth/authentification.dart';
import '../../models/questions_list.dart';
import '../../models/language_provider.dart';

class MemorizationIntroPage extends StatefulWidget {
  @override
  _MemorizationIntroPageState createState() => _MemorizationIntroPageState();
}

class _MemorizationIntroPageState extends State<MemorizationIntroPage> {
  final PageController _pageController = PageController();
  Map<int, dynamic> userResponses = {};
  int currentIndex = 0;
  List<Question> questions = [];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

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

  void previousPage() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void nextPage() async {
    if (currentIndex < questions.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentIndex == questions.length) {
      await saveResponsesToFirestore();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (currentIndex == questions.length + 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthPage()),
      );
    }
  }

  bool isAnswered(int index) {
    if (index <= 0 || index > questions.length) return false;
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.language == 'en';
    questions = getQuestions(languageProvider.language);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length + 2,
            onPageChanged: (int page) {
              setState(() {
                currentIndex = page;
                if (currentIndex == questions.length + 1) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _confettiController.play();
                  });
                }
              });
            },
            itemBuilder: (context, index) {
              // --- PAGE 1 : Introduction ---
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, double value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Image.asset("assets/ange.png", height: 150),
                      ),
                      const SizedBox(height: 30),
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 1000),
                        builder: (context, double value, child) {
                          return Opacity(opacity: value, child: child);
                        },
                        child: Text(
                          isEnglish
                              ? "Welcome to your journey with God's Word ✨"
                              : "Bienvenue dans ton voyage avec la Parole de Dieu ✨",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isEnglish
                            ? "We’re going to help you engrave Scripture in your heart.\nReady? Answer a few quick questions 💬"
                            : "Nous allons t'aider à graver les versets dans ton cœur.\nPrêt(e) ? Réponds à quelques petites questions 💬",
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        child: Text(isEnglish ? "CONTINUE" : "CONTINUER"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }

              // --- PAGE FINALE : Remerciements ---
              if (index == questions.length + 1) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/ange.png", height: 120),
                      const SizedBox(height: 20),
                      Text(
                        isEnglish
                            ? "Thank you for your answers ✨"
                            : "Merci d'avoir répondu aux questions ✨",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish
                            ? "You can now sign in to start your journey with God's Word."
                            : "Tu peux maintenant ouvrir une session pour commencer ton parcours avec la Parole de Dieu.",
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        child:
                        Text(isEnglish ? "Sign In" : "Ouvrir ma session"),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }

              // --- PAGES DE QUESTIONS ---
              final q = questions[index - 1];
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Image.asset("assets/ange.png", height: 120),
                    const SizedBox(height: 15),
                    Text(
                      q.question,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // --- Type de question ---
                    if (q.isTextInput)
                      TextField(
                        onChanged: (value) =>
                            setState(() => userResponses[index] = value),
                        decoration: InputDecoration(
                          hintText: isEnglish
                              ? "Write your answer here..."
                              : "Écris ta réponse ici...",
                          border: const OutlineInputBorder(),
                        ),
                      )
                    else if (q.isMultipleChoice)
                      Expanded(
                        child: ListView.builder(
                          itemCount: q.options.length,
                          itemBuilder: (context, i) {
                            final option = q.options[i];
                            final selected =
                            (userResponses[index] ?? []).contains(option);
                            return Padding(
                              padding:
                              const EdgeInsets.symmetric(vertical: 4.0),
                              child: FilterChip(
                                label: Text(option),
                                selected: selected,
                                onSelected: (bool value) {
                                  setState(() {
                                    final list = List<String>.from(
                                        userResponses[index] ?? []);
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

                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: previousPage,
                          child:
                          Text(isEnglish ? "PREVIOUS" : "PRÉCÉDENT"),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: isAnswered(index) ? nextPage : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAnswered(index)
                                ? Colors.green
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                          ),
                          child: Text(isEnglish ? "CONTINUE" : "CONTINUER"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          // 🎉 CONFETTIS
          if (currentIndex == questions.length + 1) ...[
            Align(
              alignment: Alignment.topLeft,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 0.7,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 15,
                gravity: 0.1,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: 2.4,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 15,
                gravity: 0.1,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

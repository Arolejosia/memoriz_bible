class Question {
  final String question;
  final List<String> options;
  final bool isMultipleChoice;
  final bool isTextInput;

  Question({
    required this.question,
    this.options = const [],
    this.isMultipleChoice = false,
    this.isTextInput = false,
  });
}

final List<Question> questions = [
  Question(
    question: "As-tu déjà essayé de mémoriser la Parole ?\n\nMême une petite tentative est déjà un pas vers Dieu.",
    options: [
      "Oui, régulièrement",
      "De temps en temps",
      "Jamais encore",
      "J’ai essayé mais j’ai abandonné"
    ],
  ),
  Question(
    question: "Quels sont tes défis principaux ?\nPartage ce qui te freine : ensemble, on trouvera comment t’aider pas à pas.",
    options: [
      "Trouver le temps",
      "Retenir les versets",
      "Choisir les versets",
      "Comprendre le sens",
      "Manque de motivation",
      "Ne pas savoir par où commencer",
    ],
    isMultipleChoice: true,
  ),
  Question(
    question: "À quel rythme veux-tu méditer ?\n\nPeu importe la fréquence : l’essentiel, c’est la constance dans l’amour de Dieu.",
    options: [
      "Tous les jours",
      "Quelques fois par semaine",
      "Une fois par semaine",
      "De temps en temps"
    ],
  ),
  Question(
    question: "Comment apprends-tu le mieux ?\n\nMieux tu te connais, plus tu apprendras avec joie.",
    options: [
      "Visuel",
      "Auditif",
      "Kinesthésique",
      "Lecture/écriture",
      "Je ne sais pas encore"
    ],
  ),
  Question(
    question: "Tu préfères apprendre...\n\nIl n’y a pas de petite portion dans la Parole : chaque verset est une puissance.",
    options: [
      "De petits versets",
      "De courts passages",
      "Des chapitres entiers"
    ],
  ),
  Question(
    question: "On te propose des thèmes !\n\nChoisis ce qui résonne avec ton cœur aujourd’hui 💖",
    options: [
      "Foi",
      "Amour",
      "Paix",
      "Espérance",
      "Prière",
      "Guérison",
      "Protection",
      "Louange",
    ],
    isMultipleChoice: true,
  ),
];

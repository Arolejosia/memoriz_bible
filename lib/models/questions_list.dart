// File: lib/questions_list.dart

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

// French questions / Questions en français
final List<Question> questionsFr = [
  Question(
    question: "As-tu déjà essayé de mémoriser la Parole ?\n\nMême une petite tentative est déjà un pas vers Dieu.",
    options: [
      "Oui, régulièrement",
      "Jamais encore",
      "J'ai essayé mais j'ai abandonné"
    ],
  ),
  Question(
    question: "Quels sont tes défis principaux ?\nPartage ce qui te freine : ensemble, on trouvera comment t'aider pas à pas.",
    options: [
      "Trouver le temps",
      "Retenir les versets",
      "Choisir les versets à lire",
      "Comprendre le verset",
      "Manque de motivation",
      "Ne pas savoir par où commencer",
    ],
    isMultipleChoice: true,
  ),
  Question(
    question: "À quel rythme veux-tu méditer ?\n\nPeu importe la fréquence : l'essentiel, c'est la constance dans l'amour de Dieu.",
    options: [
      "Tous les jours",
      "Quelques fois par semaine",
      "Une fois par semaine",
    ],
  ),
  Question(
    question: "Comment apprends-tu le mieux ?\n\nMieux tu te connais, plus tu apprendras avec joie.",
    options: [
      "Visuel",
      "Auditif",
      "Lecture/écriture",
      "Tous ces moyens",
      "Je ne sais pas encore"
    ],
  ),
  Question(
    question: "Tu préfères apprendre...\n\nIl n'y a pas de petite portion dans la Parole : chaque verset est une puissance.",
    options: [
      "De petits versets",
      "De courts passages",
      "Des chapitres entiers"
    ],
  ),
  Question(
    question: "On te propose des thèmes !\n\nChoisis ce qui résonne avec ton cœur aujourd'hui 💖",
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

// English questions / Questions en anglais
final List<Question> questionsEn = [
  Question(
    question: "Have you ever tried to memorize Scripture?\n\nEven a small attempt is already a step towards God.",
    options: [
      "Yes, regularly",
      "Never yet",
      "I tried but gave up"
    ],
  ),
  Question(
    question: "What are your main challenges?\nShare what holds you back: together, we'll find how to help you step by step.",
    options: [
      "Finding time",
      "Remembering verses",
      "Choosing verses to read",
      "Understanding the verse",
      "Lack of motivation",
      "Not knowing where to start",
    ],
    isMultipleChoice: true,
  ),
  Question(
    question: "How often do you want to meditate?\n\nNo matter the frequency: what matters is consistency in God's love.",
    options: [
      "Every day",
      "A few times a week",
      "Once a week",
    ],
  ),
  Question(
    question: "How do you learn best?\n\nThe better you know yourself, the more joyfully you'll learn.",
    options: [
      "Visual",
      "Auditory",
      "Reading/writing",
      "All of these ways",
      "I don't know yet"
    ],
  ),
  Question(
    question: "You prefer to learn...\n\nThere's no small portion in Scripture: each verse is powerful.",
    options: [
      "Short verses",
      "Brief passages",
      "Entire chapters"
    ],
  ),
  Question(
    question: "We're offering you themes!\n\nChoose what resonates with your heart today 💖",
    options: [
      "Faith",
      "Love",
      "Peace",
      "Hope",
      "Prayer",
      "Healing",
      "Protection",
      "Praise",
    ],
    isMultipleChoice: true,
  ),
];

// Helper function to get questions based on language
// Fonction d'aide pour obtenir les questions selon la langue
List<Question> getQuestions(String language) {
  return language == 'en' ? questionsEn : questionsFr;
}
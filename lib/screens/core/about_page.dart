import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/language_provider.dart';
import '../../services/url_launcher_service.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isEnglish = languageProvider.language == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? "About MemorizBible" : "À propos de MemorizBible"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Logo / Image ---
            Center(
              child: Image.asset(
                "assets/logo.png",
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // --- Nom de l’application ---
            Text(
              "MemorizBible",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isEnglish
                  ? "Your companion to memorize and live the Word of God."
                  : "Ton compagnon pour mémoriser et vivre la Parole de Dieu.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // --- Section 1 : Mission ---
            _buildSectionTitle(
              isEnglish ? "✨ Our Mission" : "✨ Notre mission",
            ),
            _buildCard(
              context,
              isEnglish
                  ? "MemorizBible helps believers strengthen their faith by learning, meditating, and sharing Bible verses interactively and joyfully."
                  : "MemorizBible aide les croyants à fortifier leur foi en apprenant, méditant et partageant les versets bibliques de manière interactive et joyeuse.",
            ),

            const SizedBox(height: 20),

            // --- Section 2 : Features ---
            _buildSectionTitle(isEnglish ? "📱 Key Features" : "📱 Fonctionnalités principales"),
            _buildListCard(
              context,
              isEnglish
                  ? [
                "Different game modes (QCM, Recitation, Dictation, Text gaps, etc.)",
                "Bible available in multiple languages (KJV, APEE, etc.)",
                "Learning progress tracking",
                "Groups and community sharing",
                "Daily verses and notifications",
              ]
                  : [
                "Différents modes de jeu (QCM, Récitation, Dictée, Texte à trous, etc.)",
                "Bible disponible en plusieurs langues (KJV, APEE, etc.)",
                "Suivi de progression personnalisé",
                "Groupes et partage communautaire",
                "Verset du jour et notifications",
              ],
            ),

            const SizedBox(height: 20),

            // --- Section 3 : Team / Credits ---
            _buildSectionTitle(isEnglish ? "🤝 Created with love" : "🤝 Créé avec amour"),
            _buildCard(
              context,
              isEnglish
                  ? "MemorizBible was developed by Ulrich and Josia — two young developers passionate about the Word of God, "
                  "driven by a desire to make Scripture an unfailing weapon for Christians around the world. "
                  "Their vision is to combine technology and faith to help believers memorize, live, and share God's Word every day."
                  : "MemorizBible a été développé par Ulrich et Josia — deux jeunes développeurs passionnés par la Parole de Dieu, "
                  "animés par le désir de faire de cette Parole une arme infaillible pour les chrétiens du monde entier. "
                  "Leur vision est de combiner technologie et foi pour aider les croyants à mémoriser, vivre et partager la Parole de Dieu au quotidien.",
            ),


            const SizedBox(height: 20),

            // --- Section 4 : Contact / Support ---
            _buildSectionTitle(isEnglish ? "📧 Contact & Support" : "📧 Contact & support"),
            _buildCard(
              context,
              isEnglish
                  ? "If you have questions, suggestions, or wish to contribute, feel free to reach out."
                  : "Pour toute question, suggestion ou contribution, n’hésitez pas à nous contacter.",
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: Text(isEnglish ? "Contact us" : "Nous contacter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                UrlLauncherService.contactSupport(
                  context,
                  subject: isEnglish
                      ? 'Feedback on MemorizBible App'
                      : 'Commentaires sur l’application MemorizBible',
                  body: isEnglish
                      ? 'Hello,\n\nI would like to share my feedback about MemorizBible...\n\nBlessings,'
                      : 'Bonjour,\n\nJe souhaite partager mes commentaires sur MemorizBible...\n\nBénédictions,',
                );
              },
            ),

            const SizedBox(height: 40),

            // --- Version & Mentions légales ---
            Text(
              "© 2025 MemorizBible - ${isEnglish ? "All rights reserved." : "Tous droits réservés."}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              isEnglish
                  ? "Bible texts from the King James Version (Public Domain)."
                  : "Textes bibliques issus de la version King James (domaine public).",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---- Widgets utilitaires ----

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, List<String> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: items
              .map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style:
                    const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ))
              .toList(),
        ),
      ),
    );
  }
}

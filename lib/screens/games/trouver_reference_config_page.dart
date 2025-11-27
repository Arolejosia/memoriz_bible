// Fichier: lib/screens/games/trouver_reference_config_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../models/language_provider.dart';
import '../../models/verse_model.dart';
import 'GameTranslations.dart';
import 'trouver_reference_session_page.dart';

class TrouverReferenceConfigPage extends StatefulWidget {
  const TrouverReferenceConfigPage({super.key});

  @override
  State<TrouverReferenceConfigPage> createState() => _TrouverReferenceConfigPageState();
}

class _TrouverReferenceConfigPageState extends State<TrouverReferenceConfigPage> {
  String _difficulty = "moyen";

  // Méthode pour obtenir les catégories de l'Ancien Testament traduites
  Map<String, String> _getOldTestamentCategories(String lang) {
    return {
      "pentateuque": GameTranslations.get("category_pentateuch", lang),
      "historiques": GameTranslations.get("category_historical", lang),
      "poetiques": GameTranslations.get("category_poetic", lang),
      "prophetes_majeurs": GameTranslations.get("category_major_prophets", lang),
      "prophetes_mineurs": GameTranslations.get("category_minor_prophets", lang),
    };
  }

  // Méthode pour obtenir les catégories du Nouveau Testament traduites
  Map<String, String> _getNewTestamentCategories(String lang) {
    return {
      "evangiles": GameTranslations.get("category_gospels", lang),
      "histoire_nt": GameTranslations.get("category_acts", lang),
      "epitres_paul": GameTranslations.get("category_paul_letters", lang),
      "epitres_generales": GameTranslations.get("category_general_letters", lang),
      "apocalypse": GameTranslations.get("category_revelation", lang),
    };
  }

  void _launchGame({
    int sessionLength = 10,
    String? sourceGroup,
    List<String>? sourceRefs,
    String? sourceBook,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrouverReferenceSessionPage(
          difficulty: _difficulty,
          sessionLength: sessionLength,
          sourceGroup: sourceGroup,
          sourceBook: sourceBook,
          sourceRefs: sourceRefs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<VerseLibrary>();
    final languageProvider = context.watch<LanguageProvider>();
    final lang = languageProvider.language;

    final masteredVerses = library.myVerseCategories
        .expand((cat) => cat.verses)
        .where((v) => v.status == VerseStatus.mastered)
        .toList();
    final canPlayFromLibrary = masteredVerses.length >= 10;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          GameTranslations.get("config_title", lang),
          style: const TextStyle(decoration: TextDecoration.underline),
        ),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // --- Sélecteur de Difficulté ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDifficultySelector(lang),
            ),
          ),

          // --- Cartes de Sélection de Source ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildSourceCard(
                  icon: Icons.public,
                  title: GameTranslations.get("source_whole_bible", lang),
                  onTap: () => _launchGame(),
                ),
                _buildSourceCard(
                  icon: Icons.school,
                  title: GameTranslations.get("source_my_library", lang),
                  subtitle: canPlayFromLibrary
                      ? "${masteredVerses.length} ${GameTranslations.get("verses_count", lang)}"
                      : "10 ${GameTranslations.get("verses_required", lang)}",
                  onTap: canPlayFromLibrary
                      ? () => _launchGame(
                    sourceRefs: masteredVerses.map((v) => v.reference).toList(),
                    sessionLength: masteredVerses.length,
                  )
                      : null,
                ),
                _buildSourceCard(
                  icon: Icons.book_outlined,
                  title: GameTranslations.get("source_old_testament", lang),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        SubcategorySelectionPage(
                          testamentTitle: GameTranslations.get("source_old_testament", lang),
                          testamentKey: "ancien_testament",
                          categories: _getOldTestamentCategories(lang),
                          difficulty: _difficulty,
                        )
                    ));
                  },
                ),
                _buildSourceCard(
                  icon: Icons.book,
                  title: GameTranslations.get("source_new_testament", lang),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        SubcategorySelectionPage(
                          testamentTitle: GameTranslations.get("source_new_testament", lang),
                          testamentKey: "nouveau_testament",
                          categories: _getNewTestamentCategories(lang),
                          difficulty: _difficulty,
                        )
                    ));
                  },
                ),
                _buildSourceCard(
                  icon: Icons.search,
                  title: GameTranslations.get("source_specific_book", lang),
                  onTap: () async {
                    final selectedBook = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const BookSelectionPage()),
                    );

                    if (selectedBook != null) {
                      _launchGame(sourceBook: selectedBook);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le sélecteur de difficulté stylisé
  Widget _buildDifficultySelector(String lang) {
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
            value: "facile",
            label: Text(GameTranslations.get("difficulty_easy", lang)),
            icon: const Icon(Icons.sentiment_very_satisfied)
        ),
        ButtonSegment(
            value: "moyen",
            label: Text(GameTranslations.get("difficulty_medium", lang)),
            icon: const Icon(Icons.sentiment_satisfied)
        ),
        ButtonSegment(
            value: "difficile",
            label: Text(GameTranslations.get("difficulty_hard", lang)),
            icon: const Icon(Icons.sentiment_very_dissatisfied)
        ),
      ],
      selected: {_difficulty},
      onSelectionChanged: (newSelection) {
        setState(() => _difficulty = newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        foregroundColor: Colors.black.withOpacity(0.7),
        selectedForegroundColor: Colors.white,
        backgroundColor: Colors.black.withOpacity(0.1),
        selectedBackgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  // Widget pour les cartes de sélection de source
  Widget _buildSourceCard({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? [Colors.blue.shade100, Colors.blue.shade300]
                : [Colors.grey.shade200, Colors.grey.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isEnabled ? Colors.blue.shade700 : Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isEnabled ? Colors.black87 : Colors.black54,
                    fontWeight: FontWeight.bold
                )
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                  subtitle,
                  style: TextStyle(
                      color: isEnabled ? Colors.black54 : Colors.black38,
                      fontSize: 12
                  )
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class BookSelectionPage extends StatefulWidget {
  const BookSelectionPage({super.key});

  @override
  State<BookSelectionPage> createState() => _BookSelectionPageState();
}

class _BookSelectionPageState extends State<BookSelectionPage> {
  // La liste complète de tous les livres (en français - clés internes)
  final List<String> _allBooksKeys = const [
    "Genèse", "Exode", "Lévitique", "Nombres", "Deutéronome", "Josué", "Juges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Rois", "2 Rois", "1 Chroniques", "2 Chroniques", "Esdras", "Néhémie", "Esther",
    "Job", "Psaumes", "Proverbes", "Ecclésiaste", "Cantique des Cantiques", "Ésaïe", "Jérémie", "Lamentations",
    "Ézéchiel", "Daniel", "Osée", "Joël", "Amos", "Abdias", "Jonas", "Michée", "Nahum", "Habacuc", "Sophonie",
    "Aggée", "Zacharie", "Malachie", "Matthieu", "Marc", "Luc", "Jean", "Actes", "Romains", "1 Corinthiens",
    "2 Corinthiens", "Galates", "Éphésiens", "Philippiens", "Colossiens", "1 Thessaloniciens", "2 Thessaloniciens",
    "1 Timothée", "2 Timothée", "Tite", "Philémon", "Hébreux", "Jacques", "1 Pierre", "2 Pierre", "1 Jean",
    "2 Jean", "3 Jean", "Jude", "Apocalypse"
  ];

  List<String> _filteredBooksKeys = [];

  @override
  void initState() {
    super.initState();
    _filteredBooksKeys = _allBooksKeys;
  }

  void _filterBooks(String query, String lang) {
    setState(() {
      _filteredBooksKeys = _allBooksKeys.where((bookKey) {
        final translatedName = GameTranslations.getBookName(bookKey, lang);
        return translatedName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final lang = languageProvider.language;

    return Scaffold(
      backgroundColor: const Color(0xff1a2333),
      appBar: AppBar(
        title: TextField(
          onChanged: (query) => _filterBooks(query, lang),
          autofocus: true,
          decoration: InputDecoration(
            hintText: GameTranslations.get("search_book_hint", lang),
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xff212d40),
      ),
      body: ListView.builder(
        itemCount: _filteredBooksKeys.length,
        itemBuilder: (context, index) {
          final bookKey = _filteredBooksKeys[index];
          final translatedName = GameTranslations.getBookName(bookKey, lang);

          return ListTile(
            title: Text(translatedName, style: const TextStyle(color: Colors.white)),
            onTap: () {
              // Renvoie la clé du livre (nom français) pour compatibilité avec le système existant
              Navigator.pop(context, bookKey);
            },
          );
        },
      ),
    );
  }
}

class SubcategorySelectionPage extends StatelessWidget {
  final String testamentTitle;
  final String testamentKey;
  final Map<String, String> categories;
  final String difficulty;

  const SubcategorySelectionPage({
    super.key,
    required this.testamentTitle,
    required this.testamentKey,
    required this.categories,
    required this.difficulty,
  });

  void _launchGame(BuildContext context, {String? sourceGroup}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrouverReferenceSessionPage(
          difficulty: difficulty,
          sessionLength: 10,
          sourceGroup: sourceGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final lang = languageProvider.language;

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text(testamentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // L'option pour jouer sur tout le testament
            _buildCategoryCard(
              context,
              title: "${GameTranslations.get("all_testament", lang)} $testamentTitle",
              icon: Icons.auto_stories,
              onTap: () => _launchGame(context, sourceGroup: testamentKey),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Colors.blueGrey),
            const SizedBox(height: 16),
            // La liste des sous-catégories
            ...categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildCategoryCard(
                  context,
                  title: entry.value,
                  icon: Icons.category,
                  onTap: () => _launchGame(context, sourceGroup: entry.key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }
}
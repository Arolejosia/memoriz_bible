// Fichier: lib/screens/games/trouver_reference_config_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Bibliotheque.dart';
import '../../models/verse_model.dart';
import 'trouver_reference_session_page.dart';



class TrouverReferenceConfigPage extends StatefulWidget {
  const TrouverReferenceConfigPage({super.key});

  @override
  State<TrouverReferenceConfigPage> createState() => _TrouverReferenceConfigPageState();
}

class _TrouverReferenceConfigPageState extends State<TrouverReferenceConfigPage> {
  String _difficulty = "moyen";
  // ✅ On définit nos sous-catégories ici
  final Map<String, String> oldTestamentCategories = const {
    "pentateuque": "Pentateuque",
    "historiques": "Livres Historiques",
    "poetiques": "Livres Poétiques & Sagesse",
    "prophetes_majeurs": "Prophètes Majeurs",
    "prophetes_mineurs": "Prophètes Mineurs",
  };
  final Map<String, String> newTestamentCategories = const {
    "evangiles": "Évangiles",
    "histoire_nt": "Actes des Apôtres",
    "epitres_paul": "Épîtres de Paul",
    "epitres_generales": "Épîtres Générales",
    "apocalypse": "Apocalypse",
  };

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
    final masteredVerses = library.myVerseCategories
        .expand((cat) => cat.verses)
        .where((v) => v.status == VerseStatus.mastered)
        .toList();
    final canPlayFromLibrary = masteredVerses.length >= 10;

    // Souligner ce texte
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Configurer la Partie",
          style: TextStyle(decoration: TextDecoration.underline),
        ),
        backgroundColor: Colors.blue.shade100, // Fond bleu clair pour l'AppBar
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // --- Sélecteur de Difficulté ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildDifficultySelector(),
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
                  title: "Toute la Bible",
                  onTap: () => _launchGame(),
                ),
                _buildSourceCard(
                  icon: Icons.school,
                  title: "Ma Bibliothèque",
                  subtitle: canPlayFromLibrary ? "${masteredVerses.length} versets" : "10 versets requis",
                  onTap: canPlayFromLibrary
                      ? () => _launchGame(
                    sourceRefs: masteredVerses.map((v) => v.reference).toList(),
                    sessionLength: masteredVerses.length,
                  )
                      : null,
                ),
                _buildSourceCard(
                  icon: Icons.book_outlined,
                  title: "Ancien Testament",
                  onTap: () { // ✅ MODIFIÉ : Navigue vers la page de sous-catégories
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        SubcategorySelectionPage(
                          testamentTitle: "Ancien Testament",
                          testamentKey: "ancien_testament",
                          categories: oldTestamentCategories,
                          difficulty: _difficulty,
                        )
                    ));
                  },
                ),
                _buildSourceCard(
                  icon: Icons.book,
                  title: "Nouveau Testament",
                  onTap: () { // ✅ MODIFIÉ : Navigue vers la page de sous-catégories
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                        SubcategorySelectionPage(
                          testamentTitle: "Nouveau Testament",
                          testamentKey: "nouveau_testament",
                          categories: newTestamentCategories,
                          difficulty: _difficulty,
                        )
                    ));
                  },
                ),
                _buildSourceCard(
                  icon: Icons.search,
                  title: "Choisir un Livre Spécifique",
                  onTap: () async {
                    // Ouvre la page de sélection et attend le résultat
                    final selectedBook = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const BookSelectionPage()),
                    );

                    // Si l'utilisateur a choisi un livre, on lance le jeu
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
  Widget _buildDifficultySelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: "facile", label: Text("Facile"), icon: Icon(Icons.sentiment_very_satisfied)),
        ButtonSegment(value: "moyen", label: Text("Moyen"), icon: Icon(Icons.sentiment_satisfied)),
        ButtonSegment(value: "difficile", label: Text("Difficile"), icon: Icon(Icons.sentiment_very_dissatisfied)),
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
                ? [Colors.blue.shade100, Colors.blue.shade300] // Dégradé de bleu pour les cartes actives
                : [Colors.grey.shade200, Colors.grey.shade400], // Dégradé de gris pour les cartes inactives
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)), // Bordure grise subtile
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: isEnabled ? Colors.blue.shade700 : Colors.grey.shade600), // Icônes bleues ou grises
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: isEnabled ? Colors.black87 : Colors.black54, fontWeight: FontWeight.bold)), // Texte noir ou gris
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: isEnabled ? Colors.black54 : Colors.black38, fontSize: 12)), // Sous-titre gris
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
  // La liste complète de tous les livres
  final List<String> _allBooks = const [
    "Genèse", "Exode", "Lévitique", "Nombres", "Deutéronome", "Josué", "Juges", "Ruth",
    "1 Samuel", "2 Samuel", "1 Rois", "2 Rois", "1 Chroniques", "2 Chroniques", "Esdras", "Néhémie", "Esther",
    "Job", "Psaumes", "Proverbes", "Ecclésiaste", "Cantique des Cantiques", "Ésaïe", "Jérémie", "Lamentations",
    "Ézéchiel", "Daniel", "Osée", "Joël", "Amos", "Abdias", "Jonas", "Michée", "Nahum", "Habacuc", "Sophonie",
    "Aggée", "Zacharie", "Malachie", "Matthieu", "Marc", "Luc", "Jean", "Actes", "Romains", "1 Corinthiens",
    "2 Corinthiens", "Galates", "Éphésiens", "Philippiens", "Colossiens", "1 Thessaloniciens", "2 Thessaloniciens",
    "1 Timothée", "2 Timothée", "Tite", "Philémon", "Hébreux", "Jacques", "1 Pierre", "2 Pierre", "1 Jean",
    "2 Jean", "3 Jean", "Jude", "Apocalypse"
  ];

  // La liste qui sera affichée (et filtrée par la recherche)
  List<String> _filteredBooks = [];

  @override
  void initState() {
    super.initState();
    _filteredBooks = _allBooks;
  }

  void _filterBooks(String query) {
    setState(() {
      _filteredBooks = _allBooks
          .where((book) => book.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1a2333),
      appBar: AppBar(
        title: TextField(
          onChanged: _filterBooks,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher un livre...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xff212d40),
      ),
      body: ListView.builder(
        itemCount: _filteredBooks.length,
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          return ListTile(
            title: Text(book, style: const TextStyle(color: Colors.white)),
            onTap: () {
              // ✅ Renvoie le livre sélectionné à la page précédente
              Navigator.pop(context, book);
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
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Fond légèrement bleuté
      appBar: AppBar(
        title: Text(testamentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black, // Bleu plus soutenu pour l'AppBar
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // L'option pour jouer sur tout le testament
            _buildCategoryCard(
              context,
              title: "Tout $testamentTitle",
              icon: Icons.auto_stories, // Icône représentant un livre ouvert
              onTap: () => _launchGame(context, sourceGroup: testamentKey),
            ),
            const SizedBox(height: 16), // Espace entre les cartes
            const Divider(thickness: 1, color: Colors.blueGrey),
            const SizedBox(height: 16),
            // La liste des sous-catégories
            ...categories.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildCategoryCard(
                  context,
                  title: entry.value,
                  icon: Icons.category, // Icône générique pour les catégories
                  onTap: () => _launchGame(context, sourceGroup: entry.key),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Widget pour les cartes de catégorie
  Widget _buildCategoryCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 30),        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }
}
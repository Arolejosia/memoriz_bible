import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/services/Bible_service.dart';
import 'package:memoriz_bible/screens/verse/verse_detail_page.dart';
import 'package:memoriz_bible/widgets/main_drawer.dart';
import 'package:memoriz_bible/widgets/stats_card_widget.dart';
import 'package:memoriz_bible/models/verse_model.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 👈 AJOUT 1: Importer les traductions des livres
import 'package:memoriz_bible/constants/book_translations.dart';
// 👈 AJOUT 2: Importer le provider de langue
import 'package:memoriz_bible/models/language_provider.dart';


// =======================================================================
// Classes de modèles
// =======================================================================

// ... (VerseCategory et RecommendedCategory restent inchangés)
class VerseCategory {
  final String name;
  final List<Verse> verses;
  VerseCategory({required this.name, required this.verses});
}

class RecommendedCategory {
  final String name;
  final List<String> verses;
  RecommendedCategory({required this.name, required this.verses});
}

// =======================================================================
// Traductions
// =======================================================================

// ... (La classe AppTranslations reste inchangée)
class AppTranslations {
  static String t(String key, String lang) {
    // ...
    final translations = {
      'library': {'fr': 'Bibliothèque', 'en': 'Library'},
      'my_library': {'fr': 'Ma Bibliothèque', 'en': 'My Library'},
      'recommended': {'fr': 'Recommandés', 'en': 'Recommended'},
      'my_stats': {'fr': 'Mes Statistiques', 'en': 'My Statistics'},
      'my_verses': {'fr': 'Mes Versets', 'en': 'My Verses'},
      'loading_library': {'fr': 'Chargement de votre bibliothèque...', 'en': 'Loading your library...'},
      'add_personal_verse': {'fr': 'Ajouter un verset personnel', 'en': 'Add a personal verse'},
      'sort_by': {'fr': 'Trier par', 'en': 'Sort by'},
      'by_name': {'fr': 'Par nom', 'en': 'By name'},
      'by_progression': {'fr': 'Par progression', 'en': 'By progression'},
      'most_recent': {'fr': 'Plus récents', 'en': 'Most recent'},
      'by_book': {'fr': 'Par livre', 'en': 'By book'},
      'quick_home_return': {'fr': 'Retour rapide à l\'accueil', 'en': 'Quick return to home'},
      'search_verse': {'fr': 'Rechercher un verset...', 'en': 'Search for a verse...'},
      'all': {'fr': 'Tout', 'en': 'All'},
      'added': {'fr': 'Ajoutés', 'en': 'Added'},
      'in_progress': {'fr': 'En cours', 'en': 'In progress'},
      'known': {'fr': 'Connus', 'en': 'Known'},
      'no_verse_found': {'fr': 'Aucun verset trouvé pour', 'en': 'No verse found for'},
      'no_verse_filter': {'fr': 'Aucun verset ne correspond à ce filtre.', 'en': 'No verse matches this filter.'},
      'back_to_home': {'fr': 'Retour à l\'accueil', 'en': 'Back to home'},
      'verses_count': {'fr': 'verset(s)', 'en': 'verse(s)'},
      'progression': {'fr': 'Progression', 'en': 'Progression'},
      'category': {'fr': 'Catégorie', 'en': 'Category'},
      'edit_category': {'fr': 'Modifier la catégorie', 'en': 'Edit category'},
      'delete': {'fr': 'Supprimer', 'en': 'Delete'},
      'confirm_deletion': {'fr': 'Confirmer la suppression', 'en': 'Confirm deletion'},
      'delete_confirmation_message': {'fr': 'Voulez-vous vraiment supprimer', 'en': 'Do you really want to delete'},
      'from_library': {'fr': 'de votre bibliothèque ?', 'en': 'from your library?'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'deleted_from_library': {'fr': 'supprimé de votre bibliothèque', 'en': 'deleted from your library'},
      'recommended_verses': {'fr': 'Versets Recommandés', 'en': 'Recommended Verses'},
      'added_to_library': {'fr': 'ajouté à votre bibliothèque !', 'en': 'added to your library!'},
      'add_verse': {'fr': 'Ajouter un verset', 'en': 'Add a verse'},
      'book': {'fr': 'Livre', 'en': 'Book'},
      'choose_book': {'fr': 'Choisir un livre', 'en': 'Choose a book'},
      'chapter': {'fr': 'Chapitre', 'en': 'Chapter'},
      'chapter_required': {'fr': 'Chapitre requis', 'en': 'Chapter required'},
      'verse_start': {'fr': 'Verset début', 'en': 'Start verse'},
      'verse_required': {'fr': 'Verset requis', 'en': 'Verse required'},
      'verse_end_optional': {'fr': 'Verset fin (optionnel)', 'en': 'End verse (optional)'},
      'category_optional': {'fr': 'Catégorie (optionnel)', 'en': 'Category (optional)'},
      'add': {'fr': 'Ajouter', 'en': 'Add'},
      'reference_invalid': {'fr': 'Référence invalide', 'en': 'Invalid reference'},
      'reference_not_exist': {'fr': 'n\'existe pas.', 'en': 'does not exist.'},
      'error_adding': {'fr': 'Erreur lors de l\'ajout', 'en': 'Error while adding'},
      'in_category': {'fr': 'dans la catégorie', 'en': 'in category'},
      'contact_support': {'fr': 'Contacter le support', 'en': 'Contact support'},
      'support_message': {'fr': 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez notre support.', 'en': 'If you think this is an error, contact our support.'},
      'new_category': {'fr': 'Nouvelle catégorie', 'en': 'New category'},
      'leave_empty_group_by_book': {'fr': 'Laissez vide pour regrouper par livre.', 'en': 'Leave empty to group by book.'},
      'save': {'fr': 'Enregistrer', 'en': 'Save'},
      'category_deleted': {'fr': 'Catégorie supprimée', 'en': 'Category deleted'},
      'category_updated': {'fr': 'Catégorie mise à jour', 'en': 'Category updated'},
    };
    return translations[key]?[lang] ?? key;
  }
}

// =======================================================================
// VerseLibrary
// =======================================================================

// ... (VerseLibrary reste inchangé, y compris la fonction 'addVerse' corrigée)
class VerseLibrary extends ChangeNotifier {
  List<VerseCategory> myVerseCategories = [];
  List<RecommendedCategory> recommendedCategories = [];
  bool isLoading = true;
  final String? userId;
  String language;

  int get totalMasteredCount {
    if (isLoading) return 0;
    return myVerseCategories
        .expand((category) => category.verses)
        .where((verse) => verse.status == VerseStatus.mastered)
        .length;
  }

  int get totalInProgressCount {
    if (isLoading) return 0;
    return myVerseCategories
        .expand((category) => category.verses)
        .where((verse) => verse.status == VerseStatus.learning)
        .length;
  }

  VerseLibrary(this.userId, {this.language = 'fr'}) {
    if (userId != null && userId!.isNotEmpty) {
      _loadAllData();
    } else {
      isLoading = false;
      myVerseCategories = [];
      recommendedCategories = [];
    }
  }

  Future<void> updateLanguage(String newLanguage) async {
    if (language != newLanguage) {
      language = newLanguage;
      await _loadAllData(); // Recharge tout avec la nouvelle langue
    }
  }



  Future<void> reloadAllData() async {
    await _loadAllData();
  }

  Future<void> _loadAllData() async {
    isLoading = true;
    notifyListeners();

    await Future.wait([
      _loadMyVersesFromFirestore(),
      _loadRecommendedCategories(),
    ]);

    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMyVersesFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users/$userId/verses')
        .get();

    final userVerses = snapshot.docs.map((doc) => Verse.fromFirestore(doc)).toList();

    final Map<String, List<Verse>> versesByBook = {};
    for (var verse in userVerses) {
      (versesByBook[verse.book] ??= []).add(verse);
    }
    myVerseCategories = versesByBook.entries.map((entry) {
      return VerseCategory(name: entry.key, verses: entry.value);
    }).toList();
  }

  Future<void> _loadRecommendedCategories() async {
    final data = _getRecommendedData();
    recommendedCategories = data.map((d) => RecommendedCategory(
        name: d['category'] as String,
        verses: List<String>.from(d['verses'] as List)
    )).toList();
  }

  List<Map<String, dynamic>> _getRecommendedData() {
    if (language == 'en') {
      return [
        {"category": "Fundamentals of Faith", "verses": ["John 3:16", "Romans 3:23", "Romans 6:23", "Ephesians 2:8-9", "John 14:6"]},
        {"category": "Comfort and Peace", "verses": ["Psalms 23:1-4", "Philippians 4:6-7", "Matthew 11:28", "John 14:27", "Isaiah 41:10"]},
        {"category": "Trust in God", "verses": ["Proverbs 3:5-6", "Jeremiah 29:11", "Joshua 1:9", "Psalms 37:5", "Hebrews 13:5"]},
        {"category": "Love and Relationships", "verses": ["1 Corinthians 13:4-7", "John 13:34-35", "1 John 4:7-8", "Ephesians 4:2-3", "Colossians 3:13-14"]},
        {"category": "Hope and Encouragement", "verses": ["Romans 8:28", "Isaiah 40:31", "2 Corinthians 12:9", "Psalms 121:1-2", "Hebrews 11:1"]},
        {"category": "Strength in Trials", "verses": ["Philippians 4:13", "Isaiah 40:29-31", "2 Timothy 1:7", "Psalms 46:1", "1 Peter 5:7"]},
        {"category": "Prayer", "verses": ["Matthew 6:9-13", "1 Thessalonians 5:16-18", "Mark 11:24", "Jeremiah 33:3", "Philippians 4:6"]},
        {"category": "Wisdom", "verses": ["James 1:5", "Proverbs 1:7", "Proverbs 9:10", "Psalms 119:105", "Colossians 3:16"]},
        {"category": "Christian Life", "verses": ["Galatians 2:20", "Matthew 5:14-16", "Romans 12:1-2", "2 Corinthians 5:17", "Colossians 3:23"]},
        {"category": "God's Promises", "verses": ["Deuteronomy 31:6", "Psalms 91:1-2", "John 10:28-29", "2 Corinthians 1:20", "Revelation 21:4"]},
      ];
    } else {
      return [
        {"category": "Les Fondamentaux de la Foi", "verses": ["Jean 3:16", "Romains 3:23", "Romains 6:23", "Éphésiens 2:8-9", "Jean 14:6"]},
        {"category": "Réconfort et Paix", "verses": ["Psaumes 23:1-4", "Philippiens 4:6-7", "Matthieu 11:28", "Jean 14:27", "Ésaïe 41:10"]},
        {"category": "Confiance en Dieu", "verses": ["Proverbes 3:5-6", "Jérémie 29:11", "Josué 1:9", "Psaumes 37:5", "Hébreux 13:5"]},
        {"category": "Amour et Relations", "verses": ["1 Corinthiens 13:4-7", "Jean 13:34-35", "1 Jean 4:7-8", "Éphésiens 4:2-3", "Colossiens 3:13-14"]},
        {"category": "Espoir et Encouragement", "verses": ["Romains 8:28", "Ésaïe 40:31", "2 Corinthiens 12:9", "Psaumes 121:1-2", "Hébreux 11:1"]},
        {"category": "Force dans l'Épreuve", "verses": ["Philippiens 4:13", "Ésaïe 40:29-31", "2 Timothée 1:7", "Psaumes 46:1", "1 Pierre 5:7"]},
        {"category": "La Prière", "verses": ["Matthieu 6:9-13", "1 Thessaloniciens 5:16-18", "Marc 11:24", "Jérémie 33:3", "Philippiens 4:6"]},
        {"category": "La Sagesse", "verses": ["Jacques 1:5", "Proverbes 1:7", "Proverbes 9:10", "Psaumes 119:105", "Colossiens 3:16"]},
        {"category": "La Vie Chrétienne", "verses": ["Galates 2:20", "Matthieu 5:14-16", "Romains 12:1-2", "2 Corinthiens 5:17", "Colossiens 3:23"]},
        {"category": "Promesses de Dieu", "verses": ["Deutéronome 31:6", "Psaumes 91:1-2", "Jean 10:28-29", "2 Corinthiens 1:20", "Apocalypse 21:4"]},
      ];
    }
  }

  Future<void> addVerse(String reference, String book, String category) async {
    final newVerseId = reference;
    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(newVerseId);

    // VÉRIFIER D'ABORD SI LE VERSET EXISTE
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // LE VERSET EST NOUVEAU, CRÉONS-LE
      final newVerse = Verse(
        id: newVerseId,
        reference: reference,
        status: VerseStatus.neutral, // Commence comme 'neutre'
        progressLevel: 0,
        scores: {},
        isUserAdded: true,
        book: book,
        category: category.isNotEmpty ? category : null,
        updatedAt: DateTime.now(), // Définir l'heure d'ajout
        failedAttempts: {},
        srsLevel: 0,
        reviewDate: null,
      );

      await docRef.set(newVerse.toFirestore());
    }
    // S'il existe déjà, nous ne faisons rien (on ne veut pas écraser la progression)

    // Dans tous les cas, recharger les données locales
    await _loadMyVersesFromFirestore();
    notifyListeners();
  }

  Future<void> onGameFinished({
    required Verse verse,
    required String gameMode,
    required int score,
  }) async {
    final int minScoreToPass = 70;
    final gameSequence = ["qcm", "texte_a_trous", "ordre", "dictee", "recitation"];

    final updatedScores = Map<String, int>.from(verse.scores);
    final updatedFailedAttempts = Map<String, int>.from(verse.failedAttempts);

    updatedScores[gameMode] = score;

    int newProgressLevel = verse.progressLevel;
    VerseStatus newStatus = verse.status;

    if (gameMode == "recitation" && score < minScoreToPass) {
      int currentFails = (updatedFailedAttempts['recitation'] ?? 0) + 1;
      updatedFailedAttempts['recitation'] = currentFails;

      if (currentFails >= 3) {
        newProgressLevel = 2;
        updatedFailedAttempts['recitation'] = 0;
        updatedScores.remove('dictee');
        updatedScores.remove('recitation');
      }
    } else if (score >= minScoreToPass) {
      updatedFailedAttempts[gameMode] = 0;

      int currentLevel = 0;
      for (final game in gameSequence) {
        if ((updatedScores[game] ?? 0) >= minScoreToPass) {
          currentLevel++;
        } else {
          break;
        }
      }
      newProgressLevel = currentLevel;
      if (newProgressLevel == gameSequence.length) {
        newStatus = VerseStatus.mastered;
      }
    }

    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(verse.id);
    await docRef.update({
      'scores': updatedScores,
      'failedAttempts': updatedFailedAttempts,
      'progressLevel': newProgressLevel,
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _loadMyVersesFromFirestore();
    notifyListeners();
  }

  Future<void> removeVerse(String verseId) async {
    await FirebaseFirestore.instance
        .collection('users/$userId/verses')
        .doc(verseId)
        .delete();

    await _loadMyVersesFromFirestore();
    notifyListeners();
  }

  Future<void> handleVerseReview(Verse verse, {required bool wasSuccessful}) async {
    final List<int> srsIntervals = [1, 3, 7, 16, 35, 75, 180];
    int newSrsLevel = verse.srsLevel;
    DateTime nextReviewDate;

    if (wasSuccessful) {
      newSrsLevel++;
      if (newSrsLevel >= srsIntervals.length) {
        newSrsLevel = srsIntervals.length - 1;
      }
      final int daysToAdd = srsIntervals[newSrsLevel];
      nextReviewDate = DateTime.now().add(Duration(days: daysToAdd));
    } else {
      newSrsLevel = 0;
      nextReviewDate = DateTime.now().add(const Duration(days: 1));
    }

    final docRef = FirebaseFirestore.instance.collection('users/$userId/verses').doc(verse.id);
    await docRef.update({
      'srsLevel': newSrsLevel,
      'reviewDate': Timestamp.fromDate(nextReviewDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _loadMyVersesFromFirestore();
    notifyListeners();
  }
}

// =======================================================================
// Page principale
// =======================================================================

enum SortOption { name, progression, dateAdded, book }

class VerseLibraryPage extends StatefulWidget {
  final VerseStatus? initialFilter;
  // ⛔ CORRECTION 1: Supprimer 'language' du constructeur
  // final String language;

  const VerseLibraryPage({
    Key? key,
    this.initialFilter, required String language,
    // this.language = 'fr', // ⛔ CORRECTION 1: Supprimer 'language'
  }) : super(key: key);

  @override
  State<VerseLibraryPage> createState() => _VerseLibraryPageState();
}

class _VerseLibraryPageState extends State<VerseLibraryPage> {
  late VerseStatus? _currentFilter;
  SortOption _currentSort = SortOption.name;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ CORRECTION 2: Mettre à jour 't()' pour lire le Provider
  String t(String key) {
    // Lire la langue actuelle depuis le LanguageProvider
    // Utiliser read au lieu de watch pour éviter les erreurs dans les callbacks
    final lang = context.read<LanguageProvider>().language;
    return AppTranslations.t(key, lang);
  }

  String _normalize(String text) {
    // ... (inchangé)
    const accents = 'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿ';
    const sansAccents = 'AAAAAAaaaaaaCcEEEEeeeeIIIIiiiiNnOOOOOOooooooUUUUuuuuYyy';
    String result = text;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], sansAccents[i]);
    }
    return result.toLowerCase().trim();
  }

  void _navigateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  List<Verse> _sortVerses(List<Verse> verses) {
    // ... (inchangé)
    final sorted = List<Verse>.from(verses);
    switch (_currentSort) {
      case SortOption.name:
        sorted.sort((a, b) => a.reference.compareTo(b.reference));
        break;
      case SortOption.progression:
        sorted.sort((a, b) => b.progressLevel.compareTo(a.progressLevel));
        break;
      case SortOption.dateAdded:
        sorted.sort((a, b) {
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return 1;
          if (b.updatedAt == null) return -1;
          return b.updatedAt!.compareTo(a.updatedAt!);
        });
        break;
      case SortOption.book:
        sorted.sort((a, b) => a.book.compareTo(b.book));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements de langue pour reconstruire l'interface
    context.watch<LanguageProvider>();

    // ... (Le widget 'PopScope' et 'DefaultTabController' restent inchangés)
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _navigateToHome();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(t('library'), style: const TextStyle(fontWeight: FontWeight.w600)),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            bottom: TabBar(
              tabs: [
                Tab(text: t('my_library'), icon: const Icon(Icons.person)),
                Tab(text: t('recommended'), icon: const Icon(Icons.star)),
              ],
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
          ),
          drawer: const MainDrawer(),
          body: Consumer<VerseLibrary>(
            builder: (context, library, child) {
              if (library.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(t('loading_library'), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return TabBarView(
                children: [
                  _buildMyLibraryTab(library),
                  _buildRecommendedTab(library),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddVerseDialog(context),
            backgroundColor: Colors.blue,
            tooltip: t('add_personal_verse'),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildMyLibraryTab(VerseLibrary library) {
    // ✅ AJOUT: Obtenir la langue actuelle pour la traduction d'affichage
    final lang = context.watch<LanguageProvider>().language;

    final allVerses = library.myVerseCategories.expand((cat) => cat.verses).toList();

    var filteredVerses = allVerses.where((verse) {
      if (_currentFilter == null) return true;
      return verse.status == _currentFilter;
    }).toList(); //

    if (_searchQuery.isNotEmpty) {
      // ... (logique de recherche inchangée)
      final normalizedQuery = _normalize(_searchQuery);
      filteredVerses = filteredVerses.where((verse) {
        final ref = _normalize(verse.reference);
        final book = _normalize(verse.book);
        final cat = _normalize(verse.category ?? '');
        return ref.contains(normalizedQuery) || book.contains(normalizedQuery) || cat.contains(normalizedQuery);
      }).toList();
    }

    final sortedVerses = _sortVerses(filteredVerses); //

    // La logique de groupement reste inchangée.
    // 'groupKey' sera le nom canonique français (ex: "Jean" ou "Confiance en Dieu")
    final groupedFilteredVerses = <String, List<Verse>>{};
    for (var verse in sortedVerses) {
      final groupKey = verse.category?.isNotEmpty == true ? verse.category! : verse.book;
      (groupedFilteredVerses[groupKey] ??= []).add(verse);
    } //

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // ... (StatsCardWidget et la barre de recherche restent inchangés)
        Text(t('my_stats'), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const StatsCardWidget(),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('my_verses'), style: Theme.of(context).textTheme.headlineSmall),
            Row(
              children: [
                PopupMenuButton<SortOption>(
                  icon: Icon(Icons.sort, color: Colors.blue.shade600),
                  tooltip: t('sort_by'),
                  onSelected: (value) => setState(() => _currentSort = value),
                  itemBuilder: (context) => [
                    _buildSortMenuItem(SortOption.name, Icons.sort_by_alpha, t('by_name')),
                    _buildSortMenuItem(SortOption.progression, Icons.trending_up, t('by_progression')),
                    _buildSortMenuItem(SortOption.dateAdded, Icons.access_time, t('most_recent')),
                    _buildSortMenuItem(SortOption.book, Icons.menu_book, t('by_book')),
                  ],
                ),
                IconButton(
                  onPressed: _navigateToHome,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.home_rounded, color: Colors.blue.shade600, size: 20),
                  ),
                  tooltip: t('quick_home_return'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: t('search_verse'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ""; }))
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 16),
        SegmentedButton<VerseStatus?>(
          segments: [
            ButtonSegment(value: null, label: Text(t('all'))),
            ButtonSegment(value: VerseStatus.neutral, label: Text(t('added'))),
            ButtonSegment(value: VerseStatus.learning, label: Text(t('in_progress'))),
            ButtonSegment(value: VerseStatus.mastered, label: Text(t('known'))),
          ],
          selected: {_currentFilter},
          onSelectionChanged: (newSelection) => setState(() => _currentFilter = newSelection.first),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                final selected = _currentFilter;
                if (selected == null) return Colors.grey;
                if (selected == VerseStatus.neutral) return Colors.blue;
                if (selected == VerseStatus.learning) return Colors.orange;
                if (selected == VerseStatus.mastered) return Colors.green;
              }
              return Colors.grey.shade200;
            }),
            foregroundColor: MaterialStateProperty.resolveWith<Color>((states) =>
            states.contains(MaterialState.selected) ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 24),
        if (groupedFilteredVerses.isEmpty)
          Center(
            // ... (logique 'aucun verset' inchangée)
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty ? "${t('no_verse_found')} \"$_searchQuery\"" : t('no_verse_filter'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToHome,
                    icon: const Icon(Icons.home),
                    label: Text(t('back_to_home')),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else
          ...groupedFilteredVerses.entries.map((entry) {
            final categoryName = entry.key; // C'est le nom canonique (ex: "Jean")
            final versesInCategory = entry.value;

            // ✅ CORRECTION 3: Traduire le nom du livre/catégorie avant de l'afficher
            final String displayName = BookTranslations.translate(categoryName, lang);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                // ✅ CORRECTION 3: Utiliser 'displayName'
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${versesInCategory.length} ${t('verses_count')}"),
                initiallyExpanded: _searchQuery.isNotEmpty,
                children: versesInCategory.map((verse) {
                  return ListTile(
                    title: Text(verse.reference),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${t('progression')}: ${verse.progressLevel}/5"),
                        if (verse.category != null && verse.category!.isNotEmpty)
                        // ✅ CORRECTION 4: Traduire aussi la catégorie dans le sous-titre
                          Text(
                              "${t('category')}: ${BookTranslations.translate(verse.category!, lang)}",
                              style: TextStyle(fontSize: 12, color: Colors.blue[700])
                          ),
                      ],
                    ),
                    trailing: Row(
                      // ... (trailing row inchangé)
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${verse.progressLevel}/5"),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditCategoryDialog(context, verse, library),
                          tooltip: t('edit_category'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(context, verse, library),
                          tooltip: t('delete'),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VerseDetailPage(verse: verse))),
                  );
                }).toList(),
              ),
            );
          }),
      ],
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(SortOption value, IconData icon, String label) {
    // ... (inchangé)
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: _currentSort == value ? Colors.blue : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: _currentSort == value ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildRecommendedTab(VerseLibrary library) {
    // ... (inchangé)
    final allUserVerses = library.myVerseCategories.expand((cat) => cat.verses).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: library.recommendedCategories.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('recommended_verses'), style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: _navigateToHome,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.home_rounded, color: Colors.blue.shade600, size: 20),
                  ),
                  tooltip: t('back_to_home'),
                ),
              ],
            ),
          );
        }

        final category = library.recommendedCategories[index - 1];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            initiallyExpanded: false,
            title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${category.verses.length} ${t('verses_count')}"),
            children: category.verses.map((verseRef) {
              final existingVerse = allUserVerses.firstWhereOrNull((v) => v.reference == verseRef);

              return ListTile(
                title: Text(verseRef),
                leading: const Padding(padding: EdgeInsets.only(left: 16.0), child: Icon(Icons.article_outlined, size: 22)),
                trailing: IconButton(
                  icon: Icon(
                    existingVerse != null ? Icons.check_circle : Icons.add_circle_outline,
                    color: existingVerse != null ? Colors.green : Colors.blue,
                  ),
                  onPressed: () {
                    if (existingVerse == null) {
                      // ✅ CORRECTION 5: S'assurer que le livre est stocké en français
                      final bookInFrench = BookTranslations.toFrench(verseRef.split(' ')[0]);
                      context.read<VerseLibrary>().addVerse(verseRef, bookInFrench, category.name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$verseRef ${t('added_to_library')}"), backgroundColor: Colors.green),
                      );
                    }
                  },
                ),
                onTap: () {
                  if (existingVerse != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VerseDetailPage(verse: existingVerse)));
                  } else {
                    final tempVerse = Verse(
                      id: verseRef, reference: verseRef, book: category.name, status: VerseStatus.neutral,
                      progressLevel: 0, scores: {}, isUserAdded: false, updatedAt: null,
                      failedAttempts: {}, srsLevel: 0, reviewDate: null,
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VerseDetailPage(verse: tempVerse)));
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, Verse verse, VerseLibrary library) {
    // ✅ AJOUT: Obtenir la langue actuelle
    final lang = context.read<LanguageProvider>().language;
    final categoryController = TextEditingController(text: verse.category ?? "");

    // Les suggestions sont déjà dans la bonne langue
    final suggestions = library.recommendedCategories.map((cat) => cat.name).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? selectedCategory = verse.category;

        return AlertDialog(
          title: Text(t('edit_category')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verse.reference, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue value) {
                    if (value.text.isEmpty) return suggestions;
                    return suggestions.where((cat) => cat.toLowerCase().contains(value.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    categoryController.text = selection;
                    selectedCategory = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    controller.text = categoryController.text;
                    controller.addListener(() {
                      categoryController.text = controller.text;
                      selectedCategory = controller.text.trim();
                    });

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: t('new_category'),
                        // ✅ CORRECTION 6: Utiliser 'lang'
                        hintText: lang == 'fr' ? "Ex: Confiance" : "Ex: Trust",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            categoryController.clear();
                            selectedCategory = null;
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(t('leave_empty_group_by_book'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          actions: [
            // ... (Actions du dialogue inchangées)
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t('cancel'))),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              label: Text(t('save')),
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) return;

                final newCategory = selectedCategory?.trim() ?? "";

                await FirebaseFirestore.instance.collection('users/$userId/verses').doc(verse.id).update({
                  'category': newCategory.isEmpty ? null : newCategory,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                await library.reloadAllData();

                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(newCategory.isEmpty ? t('category_deleted') : "${t('category_updated')}: $newCategory"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Verse verse, VerseLibrary library) {
    // ... (inchangé)
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t('confirm_deletion')),
          content: Text("${t('delete_confirmation_message')} ${verse.reference} ${t('from_library')}"),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                library.removeVerse(verse.id);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${verse.reference} ${t('deleted_from_library')}"), backgroundColor: Colors.red),
                );
              },
              child: Text(t('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddVerseDialog(BuildContext context) async {
    // ✅ CORRECTION 7: Lire la langue depuis le Provider
    final lang = context.read<LanguageProvider>().language;
    final library = context.read<VerseLibrary>();

    // ... (listes booksFr et booksEn inchangées)
    final List<String> booksFr = [
      "Genèse", "Exode", "Lévitique", "Nombres", "Deutéronome", "Josué", "Juges", "Ruth",
      "1 Samuel", "2 Samuel", "1 Rois", "2 Rois", "1 Chroniques", "2 Chroniques",
      "Esdras", "Néhémie", "Esther", "Job", "Psaume", "Proverbes", "Ecclésiaste",
      "Cantique des Cantiques", "Ésaïe", "Jérémie", "Lamentations", "Ézéchiel",
      "Daniel", "Osée", "Joël", "Amos", "Abdias", "Jonas", "Michée", "Nahum",
      "Habacuc", "Sophonie", "Aggée", "Zacharie", "Malachie", "Matthieu", "Marc",
      "Luc", "Jean", "Actes", "Romains", "1 Corinthiens", "2 Corinthiens", "Galates",
      "Éphésiens", "Philippiens", "Colossiens", "1 Thessaloniciens", "2 Thessaloniciens",
      "1 Timothée", "2 Timothée", "Tite", "Philémon", "Hébreux", "Jacques",
      "1 Pierre", "2 Pierre", "1 Jean", "2 Jean", "3 Jean", "Jude", "Apocalypse",
    ];

    final List<String> booksEn = [
      "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy", "Joshua", "Judges", "Ruth",
      "1 Samuel", "2 Samuel", "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles",
      "Ezra", "Nehemiah", "Esther", "Job", "Psalms", "Proverbs", "Ecclesiastes",
      "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations", "Ezekiel",
      "Daniel", "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah", "Nahum",
      "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi", "Matthew", "Mark",
      "Luke", "John", "Acts", "Romans", "1 Corinthians", "2 Corinthians", "Galatians",
      "Ephesians", "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians",
      "1 Timothy", "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
      "1 Peter", "2 Peter", "1 John", "2 John", "3 John", "Jude", "Revelation",
    ];


    // ✅ CORRECTION 7: Utiliser 'lang'
    final books = lang == 'en' ? booksEn : booksFr;
    final formKey = GlobalKey<FormState>();
    final chapitreController = TextEditingController();
    final versetDebutController = TextEditingController();
    final versetFinController = TextEditingController();
    final categoryController = TextEditingController();
    final suggestions = library.recommendedCategories.map((c) => c.name).toList();
    // ✅ CORRECTION 7: Utiliser 'lang'
    String? selectedBook = lang == 'en' ? "John" : "Jean";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t('add_verse')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Dropdown et champs de texte inchangés)
                  DropdownButtonFormField<String>(
                    value: selectedBook,
                    decoration: _inputDecoration(t('book')),
                    isExpanded: true,
                    items: books.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (value) => selectedBook = value,
                    validator: (value) => value == null ? t('choose_book') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: chapitreController,
                    decoration: _inputDecoration(t('chapter'), hint: 'Ex: 3'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? t('chapter_required') : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: versetDebutController,
                          decoration: _inputDecoration(t('verse_start'), hint: 'Ex: 16'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? t('verse_required') : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: versetFinController,
                          decoration: _inputDecoration(t('verse_end_optional')),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(t('category_optional'), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo)),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue value) {
                      if (value.text.isEmpty) return suggestions;
                      return suggestions.where((cat) => cat.toLowerCase().contains(value.text.toLowerCase()));
                    },
                    onSelected: (String selection) => categoryController.text = selection,
                    fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                      controller.text = categoryController.text;
                      controller.addListener(() => categoryController.text = controller.text);
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        // ✅ CORRECTION 7: Utiliser 'lang'
                        decoration: _inputDecoration(t('category'), hint: lang == 'fr' ? "Ex: Confiance" : "Ex: Trust"),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final ref = versetFinController.text.isNotEmpty
                    ? "$selectedBook ${chapitreController.text}:${versetDebutController.text}-${versetFinController.text}"
                    : "$selectedBook ${chapitreController.text}:${versetDebutController.text}";

                Navigator.of(dialogContext).pop();
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                try {
                  // ✅ CORRECTION 8: Passer 'lang' à l'API
                  final verseData = await BibleService().getPassageText(ref, language: lang);
                  if (context.mounted) Navigator.of(context).pop();

                  if (verseData.isEmpty) {
                    // ✅ CORRECTION 8: Utiliser 'lang'
                    if (context.mounted) {
                      _showValidationError(context, "${lang == 'fr' ? 'La référence' : 'The reference'} '$ref' ${t('reference_not_exist')}");
                    }
                    return;
                  }

                  // ✅ CORRECTION 9: Convertir le livre en français avant de sauvegarder
                  final bookInFrench = BookTranslations.toFrench(selectedBook!);
                  await library.addVerse(ref, bookInFrench, categoryController.text.trim());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$ref ${t('added_to_library')}${categoryController.text.isNotEmpty ? ' ${t('in_category')} \"${categoryController.text}\"' : ''}."),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${t('error_adding')}: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(t('add')),
            ),
          ],
        );
      },
    );
  }

  void _showValidationError(BuildContext context, String message) {
    // ✅ CORRECTION 10: Lire la langue depuis le Provider
    final lang = context.read<LanguageProvider>().language;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(child: Text(t('reference_invalid'))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.help_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t('support_message'), style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.email),
              label: Text(t('contact_support')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Support: support@memorizbible.com"), backgroundColor: Colors.blue, duration: Duration(seconds: 5)),
                );
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              // ✅ CORRECTION 10: Utiliser 't'
              child: Text(t('ok')),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    // ... (inchangé)
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
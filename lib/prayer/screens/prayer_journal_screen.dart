// lib/features/prayer/screens/prayer_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../prayer_translations.dart';
import '../providers/prayer_notes_provider.dart';
import '../models/prayer_note.dart';
import '../widgets/note_editor_widget.dart';
import 'note_read_screen.dart';
import 'guided_meditation_screen.dart' show appLang;


class PrayerJournalScreen extends StatefulWidget {
  /// ✅ NOUVEAU : filtre appliqué à l'ouverture (ex. "Tout voir" des méditations)
  final NoteType? initialFilter;

  const PrayerJournalScreen({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<PrayerJournalScreen> createState() => _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends State<PrayerJournalScreen> {
  NoteType? _filterType;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    return Scaffold(
      appBar: AppBar(
        title: Text('📖 ${t.prayerJournal}'),
        actions: [
          // Bouton de recherche
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres par type
          _TypeFilterChips(
            selectedType: _filterType,
            onTypeSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
          ),

          // Liste des notes
          Expanded(
            child: Consumer<PrayerNotesProvider>(
              builder: (context, notesProvider, child) {
                if (notesProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (notesProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          notesProvider.errorMessage!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => notesProvider.loadNotes(),
                          child: Text(t.retry),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer les notes
                // ✅ CORRIGÉ : la recherche s'applique d'abord,
                // puis le filtre par type (avant, la recherche écrasait le filtre)
                var notes = _searchQuery.isNotEmpty
                    ? notesProvider.searchNotes(_searchQuery)
                    : notesProvider.notes;
                if (_filterType != null) {
                  notes = notes.where((n) => n.type == _filterType).toList();
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? t.noNotesFound : t.noNotes,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.createFirstNote,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => notesProvider.loadNotes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteCard(
                        note: note,
                        onTap: () => _openNote(note),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearchDialog() {
    final t = PrayerTranslations.of(appLang(context));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔍 ${t.search}'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.searchInNotes,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(context);
            },
            child: Text(t.clear),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: Text(t.search),
          ),
        ],
      ),
    );
  }

  void _createNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditorWidget(),
      ),
    );
  }

  // ✅ MODIFIÉ : le tap ouvre la vue de lecture (le bouton Modifier y est)
  void _openNote(PrayerNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteReadScreen(noteId: note.id),
      ),
    );
  }
}

// Chips de filtrage par type
class _TypeFilterChips extends StatelessWidget {
  final NoteType? selectedType;
  final Function(NoteType?) onTypeSelected;

  const _TypeFilterChips({
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tout
            FilterChip(
              label: Text(t.all),
              selected: selectedType == null,
              onSelected: (selected) {
                onTypeSelected(null);
              },
            ),
            const SizedBox(width: 8),
            // Types
            ...NoteType.values.map((type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t.locale == 'en' ? type.displayNameEn : type.displayNameFr),
                selected: selectedType == type,
                onSelected: (selected) {
                  onTypeSelected(selected ? type : null);
                },
                selectedColor: _getTypeColor(type).withOpacity(0.3),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.gratitude:
        return Colors.green;
      case NoteType.demande:
        return Colors.blue;
      case NoteType.intercession:
        return Colors.pink;
      case NoteType.revelation:
        return Colors.purple;
      case NoteType.meditation:
        return Colors.teal;
      case NoteType.confession:
        return Colors.indigo;
      case NoteType.louange:
        return Colors.amber;
      case NoteType.engagement:
        return Colors.deepOrange;
      case NoteType.combat:
        return Colors.red;
      case NoteType.temoignage:
        return Colors.lightGreen;
      case NoteType.autre:
        return Colors.grey;
    }
  }
}

// Carte pour chaque note
class _NoteCard extends StatelessWidget {
  final PrayerNote note;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(note.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      note.type == NoteType.autre && note.customTypeLabel != null
                          ? '✏️ ${note.customTypeLabel}'
                          : (t.locale == 'en' ? note.type.displayNameEn : note.type.displayNameFr),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(note.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(t, note.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contenu (✅ MODIFIÉ : tronqué à 3 lignes)
              _TruncatedContent(text: note.content),

              // Verset
              if (note.verseReference != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        note.verseReference!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Tags
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: note.tags.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.gratitude:
        return Colors.green;
      case NoteType.demande:
        return Colors.blue;
      case NoteType.intercession:
        return Colors.pink;
      case NoteType.revelation:
        return Colors.purple;
      case NoteType.meditation:
        return Colors.teal;
      case NoteType.confession:
        return Colors.indigo;
      case NoteType.louange:
        return Colors.amber;
      case NoteType.engagement:
        return Colors.deepOrange;
      case NoteType.combat:
        return Colors.red;
      case NoteType.temoignage:
        return Colors.lightGreen;
      case NoteType.autre:
        return Colors.grey;
    }
  }

  String _formatDate(PrayerTranslations t, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return t.justNow;
    } else if (diff.inMinutes < 60) {
      return t.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return t.hoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return t.yesterday;
    } else if (diff.inDays < 7) {
      return t.daysAgo(diff.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ✅ NOUVEAU : contenu limité à 3 lignes avec "Lire la suite"
// (l'indicateur n'apparaît que si le texte est réellement coupé)
class _TruncatedContent extends StatelessWidget {
  final String text;
  const _TruncatedContent({required this.text});

  static const _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context)
        .style
        .merge(const TextStyle(fontSize: 15, height: 1.5));

    final t = PrayerTranslations.of(appLang(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mesure si le texte dépasse 3 lignes
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            if (painter.didExceedMaxLines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  t.readMore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
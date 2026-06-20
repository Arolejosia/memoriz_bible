// lib/features/prayer/screens/prayer_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_notes_provider.dart';
import '../models/prayer_note.dart';
import '../widgets/note_editor_widget.dart';

class PrayerJournalScreen extends StatefulWidget {
  const PrayerJournalScreen({Key? key}) : super(key: key);

  @override
  State<PrayerJournalScreen> createState() => _PrayerJournalScreenState();
}

class _PrayerJournalScreenState extends State<PrayerJournalScreen> {
  NoteType? _filterType;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Journal de Prière'),
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
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                // Filtrer les notes
                var notes = notesProvider.notes;
                if (_filterType != null) {
                  notes = notes.where((n) => n.type == _filterType).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  notes = notesProvider.searchNotes(_searchQuery);
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
                          _searchQuery.isNotEmpty
                              ? 'Aucune note trouvée'
                              : 'Aucune note pour le moment',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Appuyez sur + pour créer votre première note',
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
                        onTap: () => _editNote(note),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 Rechercher'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher dans vos notes...',
            border: OutlineInputBorder(),
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
            child: const Text('Effacer'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Rechercher'),
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

  void _editNote(PrayerNote note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorWidget(note: note),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Tout
            FilterChip(
              label: const Text('Tout'),
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
                label: Text(type.displayNameFr),
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
                          : note.type.displayNameFr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(note.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Contenu
              Text(
                note.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

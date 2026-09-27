// lib/prayer/screens/prayer_home_screen.dart
// L'écran s'ouvre sur la méditation de la Parole — ✅ bilingue FR/EN
// La prière (journal, minuteur, stats) reste accessible, plus bas.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../prayer_translations.dart';
import '../providers/prayer_timer_provider.dart';
import '../providers/prayer_notes_provider.dart';
import '../widgets/prayer_timer_widget.dart';
import '../models/prayer_note.dart';

import 'prayer_journal_screen.dart';
import 'prayer_settings_screen.dart';
import 'prayer_history_screen.dart';
import 'passage_picker_screen.dart';
import 'guided_meditation_screen.dart';
import 'note_read_screen.dart';

const _teal = Color(0xFF1F5C57);
const _fond = Color(0xFFF3F5F2);
const _bordure = Color(0xFFD5DBD6);
const _gris = Color(0xFF5B6661);

class PrayerHomeScreen extends StatefulWidget {
  const PrayerHomeScreen({Key? key}) : super(key: key);

  @override
  State<PrayerHomeScreen> createState() => _PrayerHomeScreenState();
}

class _PrayerHomeScreenState extends State<PrayerHomeScreen> {
  MeditationMode _mode = MeditationMode.guidee;

  void _choisirPassage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PassagePickerScreen(mode: _mode)),
    );
  }

  void _mediter(String reference) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedMeditationScreen(reference: reference, mode: _mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));

    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        backgroundColor: _fond,
        foregroundColor: const Color(0xFF1C2622),
        elevation: 0,
        title: Text(
          t.meditation,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: t.history,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: t.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerSettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PrayerNotesProvider>().loadNotes(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 1. Choisir son passage
            _ChoisirPassageCard(
              onRechercher: _choisirPassage,
              onReprendre: _mediter,
            ),

            const SizedBox(height: 14),

            // 2. Choisir la façon de méditer
            _ModeSelector(
              selected: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),

            const SizedBox(height: 28),

            // 3. Méditations récentes (cliquables)
            const _MeditationsRecentes(),

            const SizedBox(height: 16),

            // 4. Journal de prière, en second plan
            const _LienJournal(),

            const SizedBox(height: 28),

            // 5. Temps de prière (minuteur + stats)
            const _TempsDePriere(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Carte "Quel passage veux-tu méditer ?"
// ─────────────────────────────────────────────
class _ChoisirPassageCard extends StatelessWidget {
  final VoidCallback onRechercher;
  final ValueChanged<String> onReprendre;

  const _ChoisirPassageCard({
    required this.onRechercher,
    required this.onReprendre,
  });

  @override
  Widget build(BuildContext context) {
    // Dernier passage médité, pour le raccourci "Reprendre"
    final t = PrayerTranslations.of(appLang(context));
    final notes = context.watch<PrayerNotesProvider>().notes;
    String? dernierPassage;
    for (final n in notes) {
      if (n.type == NoteType.meditation &&
          n.verseReference != null &&
          n.verseReference!.isNotEmpty) {
        dernierPassage = n.verseReference;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.whichPassage,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onRechercher,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: _teal),
                      const SizedBox(width: 10),
                      Text(
                        t.passageSearchHint,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF3F4A45)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (dernierPassage != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => onReprendre(dernierPassage!),
              icon: const Icon(Icons.replay, size: 16),
              label: Text(t.resumePassage(dernierPassage!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF5E8F8A)),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Guidée / Rapide / Libre
// ─────────────────────────────────────────────
class _ModeSelector extends StatelessWidget {
  final MeditationMode selected;
  final ValueChanged<MeditationMode> onChanged;

  const _ModeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    return Row(
      children: MeditationMode.values.map((mode) {
        final actif = mode == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: mode == MeditationMode.values.last ? 0 : 8),
            child: Material(
              color: actif ? const Color(0xFFE3EEEC) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: actif ? _teal : _bordure,
                  width: actif ? 2 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(mode),
                child: SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        mode.label(t),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.duree(t),
                        style: const TextStyle(fontSize: 12, color: _gris),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Méditations récentes — ✅ maintenant cliquables
// ─────────────────────────────────────────────
class _MeditationsRecentes extends StatelessWidget {
  const _MeditationsRecentes();

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerNotesProvider>(
      builder: (context, notesProvider, child) {
        final t = PrayerTranslations.of(appLang(context));
        final recentes = notesProvider.notes
            .where((n) => n.type == NoteType.meditation)
            .take(3)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.recentMeditations,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                if (recentes.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrayerJournalScreen(
                          initialFilter: NoteType.meditation,
                        ),
                      ),
                    ),
                    child: Text(t.viewAll),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bordure),
                ),
                child: Text(
                  t.noMeditationsYet,
                  style: const TextStyle(fontSize: 14, color: _gris, height: 1.4),
                ),
              )
            else
              ...recentes.map((note) => _MeditationTile(note: note)),
          ],
        );
      },
    );
  }
}

class _MeditationTile extends StatelessWidget {
  final PrayerNote note;
  const _MeditationTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    // Pour une méditation guidée, on affiche la première réponse plutôt que la question
    final lignes = note.content.split('\n');
    final apercu = lignes.length > 1 && lignes.first.contains(' — ')
        ? lignes.skip(1).join(' ')
        : note.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _bordure),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteReadScreen(noteId: note.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.verseReference ?? t.meditation,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(t, note.createdAt),
                            style: const TextStyle(fontSize: 12, color: _gris),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        apercu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF3F4A45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: _gris),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(PrayerTranslations t, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return t.yesterday;
    if (diff.inDays < 7) return t.daysAgo(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────
// Lien vers le journal de prière (second plan)
// ─────────────────────────────────────────────
class _LienJournal extends StatelessWidget {
  const _LienJournal();

  @override
  Widget build(BuildContext context) {
    final t = PrayerTranslations.of(appLang(context));
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFAEB8B2)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const Icon(Icons.book_outlined, color: _teal),
        title: Text(
          t.prayerJournal,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(t.prayerJournalSubtitle),
        trailing: const Icon(Icons.chevron_right, color: _gris),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrayerJournalScreen()),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Minuteur + statistiques du jour
// ─────────────────────────────────────────────
class _TempsDePriere extends StatelessWidget {
  const _TempsDePriere();

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimerProvider?>(
      builder: (context, timerProvider, child) {
        if (timerProvider == null || timerProvider.isLoading) {
          return const SizedBox.shrink();
        }
        final t = PrayerTranslations.of(appLang(context));
        final stats = timerProvider.todayStats;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.prayerTimeSection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const PrayerTimerWidget(),
            if (stats != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.access_time,
                      label: t.today2,
                      value: stats.formattedTotal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.repeat,
                      label: t.sessions,
                      value: '${stats.sessionsCount}',
                    ),
                  ),
                  if (stats.streak > 0) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.local_fire_department,
                        label: t.daysInARow,
                        value: '${stats.streak}',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordure),
      ),
      child: Column(
        children: [
          Icon(icon, color: _teal, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: _gris),
          ),
        ],
      ),
    );
  }
}
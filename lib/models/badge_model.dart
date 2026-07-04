// File: lib/models/badge_model.dart

class BadgeModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int thresholdDays;
  final bool betaOnly;
  final bool unlocked;
  final DateTime? unlockedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.thresholdDays,
    this.betaOnly = false,
    this.unlocked = false,
    this.unlockedAt,
  });

  BadgeModel copyWith({bool? unlocked, DateTime? unlockedAt}) {
    return BadgeModel(
      id: id,
      name: name,
      emoji: emoji,
      description: description,
      thresholdDays: thresholdDays,
      betaOnly: betaOnly,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  BadgeModel mergeFromFirestore(Map<String, dynamic>? data) {
    if (data == null) return this;
    return copyWith(
      unlocked: data['unlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? DateTime.tryParse(data['unlockedAt'])
          : null,
    );
  }
}

/// Liste statique des badges du défi MemorizBible
/// Static list of MemorizBible challenge badges
const List<BadgeModel> kBadgeDefinitions = [
  BadgeModel(
    id: 'premierPas',
    name: 'Premier pas',
    emoji: '📅',
    description: 'Tu as commencé ton parcours avec MemorizBible !',
    thresholdDays: 1,
  ),
  BadgeModel(
    id: 'perseverant',
    name: 'Persévérant',
    emoji: '🔥',
    description: '3 jours d\'engagement, tu tiens le rythme !',
    thresholdDays: 3,
  ),
  BadgeModel(
    id: 'discipleFidele',
    name: 'Disciple fidèle',
    emoji: '📖',
    description: 'Une semaine complète, bravo !',
    thresholdDays: 7,
  ),
  BadgeModel(
    id: 'gardienParole',
    name: 'Gardien de la Parole',
    emoji: '🛡️',
    description: '10 jours d\'engagement, tu es un vrai gardien !',
    thresholdDays: 10,
  ),
  BadgeModel(
    id: 'pionnier',
    name: 'Pionnier MemorizBible',
    emoji: '🚀',
    description: 'Badge exclusif aux bêta-testeurs — 14 jours !',
    thresholdDays: 14,
    betaOnly: true,
  ),
];
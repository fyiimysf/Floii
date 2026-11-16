import 'package:flutter/material.dart';

enum CyclePhase {
  menstrual('Menstrual', '🌑'),
  follicular('Follicular', '🌱'),
  ovulation('Ovulation', '🌕'),
  luteal('Luteal', '🍂');

  final String name;
  final String icon;

  const CyclePhase(this.name, this.icon);

  String get displayName => '$icon $name';
}

enum Mood {
  happy('😊', 'Happy', Icons.sentiment_very_satisfied),
  neutral('😐', 'Neutral', Icons.sentiment_neutral),
  sad('😢', 'Sad', Icons.sentiment_dissatisfied),
  angry('😡', 'Angry', Icons.sentiment_very_dissatisfied),
  tired('😴', 'Tired', Icons.snooze),
  energetic('💪', 'Energetic', Icons.fitness_center);

  /// Kept because it is the persisted identity of a logged mood: storage writes
  /// [emoji] and [fromEmoji] reads it back, so existing history stays readable.
  /// Display widgets should use [icon] instead.
  final String emoji;

  final String label;

  /// Vector counterpart to [emoji], so a mood renders identically across
  /// platforms and at every size. Material has no "angry" face, so [Mood.angry]
  /// borrows the lowest sentiment icon.
  final IconData icon;

  const Mood(this.emoji, this.label, this.icon);

  static Mood fromEmoji(String emoji) {
    return Mood.values.firstWhere(
      (m) => m.emoji == emoji,
      orElse: () => Mood.neutral,
    );
  }
}

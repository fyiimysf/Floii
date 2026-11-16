import 'package:flutter/material.dart';
import '../utils/constants/colors.dart';

/// Metadata for one entry on the Learn page. The [id] also keys the article
/// copy in `LearnContent`.
class LearnTopic {
  final String id;
  final IconData icon;
  final Color color;

  const LearnTopic({
    required this.id,
    required this.icon,
    required this.color,
  });
}

/// Ordered catalogue backing the Learn page. Not const because the palette
/// entries are lazily initialised.
final List<LearnTopic> learnTopics = [
  LearnTopic(
    id: 'basics',
    icon: Icons.water_drop_outlined,
    color: AppColors.menstrual,
  ),
  LearnTopic(
    id: 'phases',
    icon: Icons.timeline_rounded,
    color: AppColors.follicular,
  ),
  LearnTopic(
    id: 'symptoms',
    icon: Icons.psychology_alt_outlined,
    color: AppColors.luteal,
  ),
  LearnTopic(
    id: 'selfCare',
    icon: Icons.spa_outlined,
    color: AppColors.primary,
  ),
  LearnTopic(
    id: 'myths',
    icon: Icons.fact_check_outlined,
    color: AppColors.secondary,
  ),
  LearnTopic(
    id: 'warningSigns',
    icon: Icons.health_and_safety_outlined,
    color: AppColors.error,
  ),
  LearnTopic(
    id: 'firstPeriod',
    icon: Icons.child_care_outlined,
    color: AppColors.peach,
  ),
  LearnTopic(
    id: 'contraception',
    icon: Icons.shield_outlined,
    color: AppColors.mint,
  ),
];

LearnTopic? topicById(String id) {
  for (final topic in learnTopics) {
    if (topic.id == id) return topic;
  }
  return null;
}

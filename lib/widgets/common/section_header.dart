import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';

/// Compact section heading with an icon badge and optional caption, used
/// between content blocks on the calendar pages.
class SectionHeader extends StatelessWidget {
  final String title;
  final List<List<dynamic>> icon;
  final String? caption;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.caption,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? AppColors.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.smallSpacing),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: HugeIcon(icon: icon, size: 16, color: accent),
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
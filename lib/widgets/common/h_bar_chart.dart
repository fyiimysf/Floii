import 'package:flutter/material.dart';

import '../../utils/constants/dimensions.dart';

/// Horizontal ranking bars for distribution comparisons: a label, a track and
/// a value-scaled fill for each entry.
class HBarChart extends StatelessWidget {
  final List<({String label, double value, Color color})> items;
  final double height;
  final Color? trackColor;

  const HBarChart({
    super.key,
    required this.items,
    this.height = 14,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = items.fold(0.0, (m, e) => e.value > m ? e.value : m);
    final track = trackColor ?? theme.colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.smallSpacing),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.smallSpacing),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(height / 2),
                    child: Stack(
                      children: [
                        Container(height: height, color: track),
                        FractionallySizedBox(
                          widthFactor:
                              max == 0 ? 0 : (item.value / max).clamp(0.0, 1.0),
                          child: Container(height: height, color: item.color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

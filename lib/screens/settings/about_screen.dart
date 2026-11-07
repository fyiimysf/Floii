import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/constants/strings.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';

/// About page: what the app is, its key features, credits and the legal links.
/// Laid out with the same accent-bar section headings as the Learn pages so it
/// reads as reference material rather than a settings list.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _version = '1.0.0';
  static const String _released = 'February 2026';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 70,
            collapsedHeight: 70,
            toolbarHeight: 70,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppDimensions.tinySpacing,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      context.tr('about'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildHero(context),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionTitle(context, context.tr('version'),
                    AppColors.primary),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 0,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.new_releases,
                        iconColor: AppColors.primary,
                        label: context.tr('version'),
                        value: _version,
                      ),
                      _divider(theme),
                      _buildInfoRow(
                        context,
                        icon: Icons.calendar_today,
                        iconColor: AppColors.secondary,
                        label: context.tr('released'),
                        value: _released,
                      ),
                      _divider(theme),
                      _buildInfoRow(
                        context,
                        icon: Icons.code,
                        iconColor: AppColors.mint,
                        label: context.tr('builtWith'),
                        value: 'Flutter',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionTitle(
                    context, context.tr('keyFeatures'), AppColors.secondary),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 1,
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        context,
                        icon: Icons.track_changes,
                        title: context.tr('featureTracking'),
                        description: context.tr('featureTrackingDesc'),
                      ),
                      _divider(theme),
                      _buildFeatureItem(
                        context,
                        icon: Icons.auto_awesome,
                        title: context.tr('featurePrediction'),
                        description: context.tr('featurePredictionDesc'),
                      ),
                      _divider(theme),
                      _buildFeatureItem(
                        context,
                        icon: Icons.insights,
                        title: context.tr('featureInsights'),
                        description: context.tr('featureInsightsDesc'),
                      ),
                      _divider(theme),
                      _buildFeatureItem(
                        context,
                        icon: Icons.privacy_tip,
                        title: context.tr('featurePrivacy'),
                        description: context.tr('featurePrivacyDesc'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionTitle(
                    context, context.tr('legal'), AppColors.secondaryLight),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 2,
                  child: Column(
                    children: [
                      _buildLinkRow(
                        context,
                        icon: Icons.privacy_tip_outlined,
                        iconColor: AppColors.primary,
                        title: context.tr('privacyPolicy'),
                        subtitle: context.tr('privacyPolicySubtitle'),
                        onTap: () =>
                            Navigator.pushNamed(context, '/privacy-policy'),
                      ),
                      _divider(theme),
                      _buildLinkRow(
                        context,
                        icon: Icons.gavel_outlined,
                        iconColor: AppColors.secondary,
                        title: context.tr('termsAndConditions'),
                        subtitle: context.tr('termsConditionsSubtitle'),
                        onTap: () => Navigator.pushNamed(context, '/terms'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionTitle(
                    context, context.tr('credits'), AppColors.ovulation),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 3,
                  child: Column(
                    children: [
                      _buildCreditItem(
                        context,
                        icon: Icons.brush_outlined,
                        label: context.tr('developedBy'),
                        value: context.tr('creator'),
                      ),
                      _divider(theme),
                      _buildCreditItem(
                        context,
                        icon: Icons.code,
                        label: context.tr('builtWith'),
                        value: 'Flutter & Dart',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                Center(
                  child: Text(
                    context.trArgs('copyright', {
                      'year': '${DateTime.now().year}',
                      'app': AppStrings.appName,
                    }),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(AppDimensions.smallSpacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(90),
              child: Image.asset(
                'lib/icons/icon-192.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          Text(
            AppStrings.appName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Text(
            AppStrings.appTagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Accent-bar heading matching the Learn article section style.
  Widget _buildSectionTitle(BuildContext context, String title, Color accent) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.smallSpacing + 2),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _divider(ThemeData theme) => Divider(
        height: 1,
        indent: 0,
        color: theme.colorScheme.outline.withValues(alpha: 0.1),
      );

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _iconBadge(icon, iconColor),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLinkRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: _iconBadge(icon, iconColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _iconBadge(icon, AppColors.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildCreditItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _iconBadge(icon, AppColors.ovulation),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.smallSpacing),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: AppDimensions.iconSmall),
    );
  }
}

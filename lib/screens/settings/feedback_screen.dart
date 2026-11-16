import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';

/// Send Feedback form. Submitting shows an in-page thank-you state rather than
/// closing the sheet immediately, so the confirmation is not missed.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _feedbackController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'UI/UX Feedback',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    Icons.feedback_outlined,
                    color: AppColors.ovulation,
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      context.tr('sendFeedback'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
          ),
          if (_submitted)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildSuccess(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.elementSpacing),
                  Text(
                    context.tr('weLoveToHearFromYou'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.smallSpacing),
                  Text(
                    context.tr('feedbackDescription'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: AppDimensions.sectionSpacing),
                  Form(
                    key: _formKey,
                    child: _buildForm(context),
                  ),
                  const SizedBox(height: AppDimensions.sectionSpacing),
                  _buildReassuranceCard(context),
                  const SizedBox(height: AppDimensions.sectionSpacing * 2),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClayCard(
      entranceStep: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('feedbackCategory'),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Wrap(
            spacing: AppDimensions.smallSpacing,
            runSpacing: AppDimensions.smallSpacing,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: AppDimensions.durationFast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.elementSpacing,
                    vertical: AppDimensions.smallSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : theme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              context,
              label: context.tr('nameOptional'),
              hint: context.tr('enterYourName'),
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _decoration(
              context,
              label: context.tr('emailOptional'),
              hint: context.tr('enterYourEmail'),
              icon: Icons.email_outlined,
            ),
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          TextFormField(
            controller: _feedbackController,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.tr('pleaseEnterFeedback');
              }
              if (value.trim().length < 10) {
                return context.tr('feedbackMinLength');
              }
              return null;
            },
            decoration: _decoration(
              context,
              label: context.tr('yourFeedback'),
              hint: context.tr('tellUsWhatYouThink'),
              icon: Icons.message_outlined,
            ),
          ),
          const SizedBox(height: AppDimensions.sectionSpacing),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      size: 20, color: Colors.white),
              label: Text(
                _isSubmitting
                    ? context.tr('sending')
                    : context.tr('sendFeedback'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.elementSpacing),
              ),
              onPressed: _isSubmitting ? null : _submitFeedback,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
    );
  }

  Widget _buildReassuranceCard(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      entranceStep: 1,
      color: AppColors.primary.withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.elementSpacing),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: AppDimensions.iconMedium,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('thankYouExclamation'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  context.tr('weReadEveryFeedback'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.elementSpacing),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: AppDimensions.iconXL,
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Text(
              context.tr('feedbackThankYou'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimensions.smallSpacing),
            Text(
              context.tr('weReadEveryFeedback'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppDimensions.sectionSpacing),
            ClayButton(
              onTap: () => Navigator.pop(context),
              color: AppColors.primary,
              child: Text(
                context.tr('done'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

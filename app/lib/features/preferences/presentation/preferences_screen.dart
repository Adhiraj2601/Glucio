import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../data/models/user_preferences.dart';
import '../../../data/repositories/product_repository.dart';
import '../../log/presentation/providers/daily_tracker_providers.dart';
import 'widgets/preference_importance_selector.dart';

/// Screen allowing the user to configure dietary preferences, allergen exclusions,
/// and nutritional priorities in the spirit of Open Food Facts.
class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  PreferenceCategory? _selectedCategory; // null = all

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlucioTheme.bgCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
        ),
        title: const Text(
          'Reset Preferences?',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 20,
            color: GlucioTheme.inkBlack,
          ),
        ),
        content: const Text(
          'This will reset all allergen, diet, and nutrition preferences back to default settings (Low Sugar: Important).',
          style: TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 13,
            color: GlucioTheme.inkBlack,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(ctx).pop();
              ref.read(userPreferencesProvider.notifier).resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preferences reset to default values'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GlucioTheme.levelHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: const Text(
                'Reset All',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDailyLimitDialog(BuildContext context, double currentLimit) {
    final textController = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );
    final presets = [20.0, 25.0, 35.0, 50.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlucioTheme.bgCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: GlucioTheme.inkBlack, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Sugar Limit',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontDisplay,
                          fontSize: 22,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: GlucioTheme.inkBlack),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WHO recommends under 25g/day (≈6 teaspoons) of free sugars for adults. Choose a preset or enter your custom target:',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: presets.map((preset) {
                      final isSelected =
                          (double.tryParse(textController.text) ?? 0.0) == preset;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            textController.text = preset.toStringAsFixed(0);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? GlucioTheme.accentLime
                                : GlucioTheme.cardCream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: GlucioTheme.inkBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            '${preset.toStringAsFixed(0)}g',
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Custom limit in grams',
                      suffixText: 'grams / day',
                      fillColor: GlucioTheme.cardCream,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: GlucioTheme.primaryGreen,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      final val = double.tryParse(textController.text.trim());
                      if (val != null && val > 0) {
                        ref.read(dailyLimitProvider.notifier).updateLimit(val);
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: GlucioTheme.accentLime,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: GlucioTheme.inkBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Save Daily Limit',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: GlucioTheme.inkBlack,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(userPreferencesProvider);
    final currentDailyLimit = ref.watch(dailyLimitProvider).value ?? 25.0;

    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: const Text(
          'Personal Preferences',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 22,
            color: GlucioTheme.inkBlack,
          ),
        ),
        elevation: 0,
        backgroundColor: GlucioTheme.bgCream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlucioTheme.inkBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset to Defaults',
            icon: const Icon(Icons.restart_alt_rounded, color: GlucioTheme.inkBlack, size: 26),
            onPressed: _showResetConfirmDialog,
          ),
        ],
      ),
      body: prefsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading preferences: $err'),
        ),
        data: (prefs) {
          final categories = PreferenceCategory.values;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Information Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.cardCream,
                  radius: 16,
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tune_rounded,
                        color: GlucioTheme.inkBlack, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personalized Food Alerts',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontDisplay,
                              fontSize: 16,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Glucio checks ingredients against your preferences on every scan. Mandatory restrictions trigger red warnings.',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Category Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilterChip(
                      label: 'All (${prefs.criteria.length})',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    for (final cat in categories) ...[
                      _buildCategoryFilterChip(
                        label: '${cat.label} (${prefs.getByCategory(cat).length})',
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Categories & Criteria List
              for (final cat in categories) ...[
                if (_selectedCategory == null || _selectedCategory == cat) ...[
                  _buildCategorySection(
                    cat,
                    prefs.getByCategory(cat),
                    currentDailyLimit,
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GlucioTheme.accentLime : GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlucioTheme.inkBlack, width: isSelected ? 2 : 1.5),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: GlucioTheme.inkBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: GlucioTheme.inkBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    PreferenceCategory category,
    List<PreferenceCriterion> criteria,
    double currentDailyLimit,
  ) {
    IconData icon;
    switch (category) {
      case PreferenceCategory.allergen:
        icon = Icons.warning_amber_rounded;
        break;
      case PreferenceCategory.diet:
        icon = Icons.eco_outlined;
        break;
      case PreferenceCategory.nutrition:
        icon = Icons.restaurant_outlined;
        break;
      case PreferenceCategory.processing:
        icon = Icons.science_outlined;
        break;
      case PreferenceCategory.environment:
        icon = Icons.public_rounded;
        break;
    }

    return Container(
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 18,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: GlucioTheme.inkBlack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontDisplay,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < criteria.length; i++) ...[
            _buildCriterionItem(criteria[i], currentDailyLimit),
            if (i < criteria.length - 1)
              const Divider(color: Colors.black12, height: 24, thickness: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildCriterionItem(PreferenceCriterion criterion, double currentDailyLimit) {
    final isLowSugar = criterion.id == 'nutr_low_sugar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criterion.label,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    criterion.description,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isLowSugar) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showEditDailyLimitDialog(context, currentDailyLimit),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, size: 14, color: GlucioTheme.inkBlack),
                  const SizedBox(width: 6),
                  Text(
                    'WHO Limit: ${currentDailyLimit.toStringAsFixed(0)}g/day (Tap to change)',
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        PreferenceImportanceSelector(
          selected: criterion.importance,
          onChanged: (newImportance) {
            ref
                .read(userPreferencesProvider.notifier)
                .updateCriterion(criterion.id, newImportance);
          },
        ),
      ],
    );
  }
}

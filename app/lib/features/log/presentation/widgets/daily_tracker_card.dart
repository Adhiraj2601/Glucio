import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../core/utils/sugar_calculator.dart';
import '../../../../data/models/food_log_entry.dart';
import '../providers/daily_tracker_providers.dart';

/// Interactive Neo-brutalist Daily Sugar Tracker card.
/// Displays consumed sugar today, daily allowance progress bar, and list of logged foods.
class DailyTrackerCard extends ConsumerStatefulWidget {
  final VoidCallback? onViewTrends;

  const DailyTrackerCard({
    super.key,
    this.onViewTrends,
  });

  @override
  ConsumerState<DailyTrackerCard> createState() => _DailyTrackerCardState();
}

class _DailyTrackerCardState extends ConsumerState<DailyTrackerCard> {
  bool _isListExpanded = true;

  void _showEditLimitDialog(BuildContext context, double currentLimit) {
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
                    'Daily Sugar Target',
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
              // Preset chips
              Wrap(
                spacing: 8,
                children: presets.map((preset) {
                  final isSelected =
                      (double.tryParse(textController.text) ?? 0.0) == preset;
                  return GestureDetector(
                    onTap: () {
                      textController.text = preset.toStringAsFixed(0);
                      (ctx as Element).markNeedsBuild();
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
                        '${preset.toStringAsFixed(0)}g${preset == 25.0 ? ' (WHO)' : ''}',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Custom input
              TextField(
                controller: textController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: false,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: GlucioTheme.inkBlack,
                ),
                decoration: InputDecoration(
                  labelText: 'Target Limit (grams)',
                  labelStyle: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    color: Colors.black87,
                  ),
                  filled: true,
                  fillColor: GlucioTheme.cardCream,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: GlucioTheme.inkBlack,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: GlucioTheme.primaryGreen,
                      width: 2.5,
                    ),
                  ),
                  suffixText: 'grams',
                ),
              ),
              const SizedBox(height: 20),
              // Save button
              GestureDetector(
                onTap: () {
                  final val = double.tryParse(textController.text);
                  if (val != null && val > 0) {
                    ref.read(dailyLimitProvider.notifier).updateLimit(val);
                    Navigator.of(ctx).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: GlucioTheme.primaryGreen,
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
                      'Save Target Limit',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
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
  }

  @override
  Widget build(BuildContext context) {
    final limitAsync = ref.watch(dailyLimitProvider);
    final logsAsync = ref.watch(todayFoodLogsProvider);
    final totalSugar = ref.watch(todayTotalSugarProvider);
    final totalTsp = ref.watch(todayTotalTeaspoonsProvider);
    final unknownCount = ref.watch(todayUnknownSugarCountProvider);

    final limitG = limitAsync.value ?? 25.0;
    final ratio = limitG > 0 ? (totalSugar / limitG) : 0.0;
    final remainingG = limitG - totalSugar;
    final isExceeded = remainingG < 0;

    // Progress bar color based on consumed percentage
    final Color progressColor;
    if (ratio <= 0.50) {
      progressColor = GlucioTheme.levelLow;
    } else if (ratio <= 1.00) {
      progressColor = GlucioTheme.levelMedium;
    } else {
      progressColor = GlucioTheme.levelHigh;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GlucioTheme.accentLime,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: GlucioTheme.inkBlack,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        "Today's Sugar",
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontDisplay,
                          fontSize: 20,
                          color: GlucioTheme.inkBlack,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Daily Limit Edit Button
              GestureDetector(
                onTap: () => _showEditLimitDialog(context, limitG),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: GlucioTheme.bgCream,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Limit: ${limitG.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: GlucioTheme.inkBlack,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Sugar Intake Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                totalSugar.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 34,
                  color: GlucioTheme.inkBlack,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'g',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 18,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${limitG.toStringAsFixed(0)}g target',
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              // Allowance badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? GlucioTheme.levelHigh.withValues(alpha: 0.2)
                      : GlucioTheme.levelLow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExceeded
                        ? GlucioTheme.levelHigh
                        : GlucioTheme.levelLow,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isExceeded
                      ? '+${(-remainingG).toStringAsFixed(1)}g over'
                      : '${remainingG.toStringAsFixed(1)}g left',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isExceeded
                        ? GlucioTheme.levelHigh
                        : const Color(0xFF007A4D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Teaspoons Subtitle
          Text(
            totalSugar > 0
                ? '≈ ${SugarCalculator.formatTeaspoonsPlain(totalTsp, isVerifiedZero: false)} consumed today'
                : '0 teaspoons consumed today',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Thick Neo-brutalist Progress Bar
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GlucioTheme.inkBlack, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                child: Container(
                  color: progressColor,
                ),
              ),
            ),
          ),

          // Missing Sugar notice if any logged food had missing sugar
          if (unknownCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$unknownCount item${unknownCount > 1 ? "s" : ""} logged with missing sugar data',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.onViewTrends != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onViewTrends,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: GlucioTheme.cardCream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: GlucioTheme.inkBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 16, color: GlucioTheme.inkBlack),
                    SizedBox(width: 6),
                    Text(
                      'View 7-Day Sugar Trends',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: GlucioTheme.inkBlack),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Divider
          Container(
            height: 1.5,
            color: GlucioTheme.inkBlack.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 8),

          // Collapsible Logged Items Section Header
          logsAsync.when(
            data: (logs) {
              final count = logs.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _isListExpanded = !_isListExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            "Today's Food Log ($count)",
                            style: const TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isListExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: GlucioTheme.inkBlack,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isListExpanded) ...[
                    const SizedBox(height: 6),
                    if (logs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No snacks logged yet today. Scan a barcode to check sugar and log it here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) =>
                            _buildLogItem(logs[idx]),
                      ),
                  ],
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Error loading logs: $e',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 12,
                color: GlucioTheme.levelHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(FoodLogEntry entry) {
    final sugarText = entry.sugarGrams != null
        ? '${entry.sugarGrams!.toStringAsFixed(1)}g sugar'
        : 'Sugar unknown';

    final tspText = entry.teaspoons != null
        ? ' (${SugarCalculator.formatTeaspoonsPlain(entry.teaspoons!, isVerifiedZero: false)})'
        : '';

    // Format time HH:MM
    final hour = entry.loggedAt.hour.toString().padLeft(2, '0');
    final min = entry.loggedAt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GlucioTheme.bgCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${entry.portionLabel} • $timeStr',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$sugarText$tspText',
                  style: TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: entry.sugarGrams != null
                        ? GlucioTheme.inkBlack
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.black54,
            ),
            onPressed: () {
              if (entry.id != null) {
                ref.read(todayFoodLogsProvider.notifier).deleteLog(entry.id!);
              }
            },
          ),
        ],
      ),
    );
  }
}

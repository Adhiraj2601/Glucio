import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/glucio_theme.dart';
import '../../../core/utils/sugar_calculator.dart';
import '../../../data/models/food_log_entry.dart';
import '../../../data/models/product_list.dart';
import '../../../data/models/scan_history_entry.dart';
import '../../../data/repositories/product_repository.dart';
import '../../analytics/presentation/providers/weekly_tracker_providers.dart';
import '../../compare/presentation/compare_screen.dart';
import '../../product/presentation/product_result_screen.dart';

/// Full history timeline screen supporting Logs, Scans, and Custom Lists,
/// complete with multi-select comparison and data export.
class FoodHistoryScreen extends ConsumerStatefulWidget {
  const FoodHistoryScreen({super.key});

  @override
  ConsumerState<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends ConsumerState<FoodHistoryScreen> {
  int _selectedSegment = 0; // 0 = Logs, 1 = Scans, 2 = Lists

  bool _isMultiSelect = false;
  final Set<String> _selectedBarcodes = {};
  final Set<int> _selectedLogIds = {};

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelect = false;
      _selectedBarcodes.clear();
      _selectedLogIds.clear();
    });
  }

  void _toggleBarcodeSelection(String barcode, {int? logId}) {
    setState(() {
      if (_selectedBarcodes.contains(barcode)) {
        _selectedBarcodes.remove(barcode);
        if (logId != null) _selectedLogIds.remove(logId);
      } else {
        _selectedBarcodes.add(barcode);
        if (logId != null) _selectedLogIds.add(logId);
      }
      if (_selectedBarcodes.isEmpty) {
        _isMultiSelect = false;
      }
    });
  }

  Future<void> _compareSelected() async {
    final barcodes = _selectedBarcodes.take(4).toList();
    if (barcodes.isEmpty) return;

    final repo = ref.read(productRepositoryProvider);
    final compareNotifier = ref.read(productCompareProvider.notifier);
    compareNotifier.clear();

    for (final code in barcodes) {
      final p = await repo.getProductByBarcode(code);
      if (p != null) {
        compareNotifier.addProduct(p);
      }
    }

    if (!mounted) return;
    _exitMultiSelect();

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CompareScreen()),
    );
  }

  void _exportSelectedLogs(List<FoodLogEntry> allLogs) {
    final selectedLogs = allLogs.where((l) => _selectedLogIds.contains(l.id)).toList();
    if (selectedLogs.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('barcode,name,brand,portion,sugar_grams,logged_at');
    for (final l in selectedLogs) {
      buffer.writeln(
        '${l.barcode},"${l.name}","${l.brand}","${l.portionLabel}",${l.sugarGrams ?? ""},${l.loggedAt.toIso8601String()}',
      );
    }
    final csvString = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlucioTheme.bgCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
        ),
        title: const Text(
          'Export Selected Logs (CSV)',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 18,
            color: GlucioTheme.inkBlack,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
          ),
          child: SingleChildScrollView(
            child: Text(
              csvString,
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 10,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.black54)),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: csvString));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard!')),
              );
              _exitMultiSelect();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: const Text(
                'Copy CSV',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog() {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlucioTheme.bgCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
        ),
        title: const Text(
          'Create Product List',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            fontSize: 20,
            color: GlucioTheme.inkBlack,
          ),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Low Sugar Breakfast, Treats, Avoid',
            labelText: 'List Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: GlucioTheme.inkBlack, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          GestureDetector(
            onTap: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(productListsProvider.notifier).createList(name);
                Navigator.of(ctx).pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: const Text(
                'Create',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Food History',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 26,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  if (_isMultiSelect) ...[
                    GestureDetector(
                      onTap: _exitMultiSelect,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlucioTheme.cardCream,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: GlucioTheme.fontBody,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.refresh, color: GlucioTheme.inkBlack),
                      onPressed: () {
                        ref.read(allFoodLogsHistoryProvider.notifier).reload();
                        ref.read(scanHistoryProvider.notifier).refresh();
                        ref.read(productListsProvider.notifier).refresh();
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Neo Segmented Tab Selector (Logs, Scans, Lists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: GlucioTheme.cardCream,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: GlucioTheme.inkBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildSegmentTab(0, 'Logs'),
                    _buildSegmentTab(1, 'Scans'),
                    _buildSegmentTab(2, 'Lists'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Main Segment Body
            Expanded(
              child: _buildSegmentBody(context),
            ),

            // Floating Multi-Select Bottom Bar
            if (_isMultiSelect) ...[
              _buildMultiSelectBottomBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSelected = _selectedSegment == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSegment = index;
            _exitMultiSelect();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GlucioTheme.accentLime : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: GlucioTheme.inkBlack, width: 1.5)
                : null,
          ),
          child: Center(
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
        ),
      ),
    );
  }

  Widget _buildSegmentBody(BuildContext context) {
    switch (_selectedSegment) {
      case 0:
        return _buildLogsTab(context);
      case 1:
        return _buildScansTab(context);
      case 2:
        return _buildListsTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // TAB 0: FOOD LOGS TIMELINE
  // ==========================================

  Widget _buildLogsTab(BuildContext context) {
    final historyAsync = ref.watch(allFoodLogsHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
      ),
      error: (err, _) => Center(
        child: Text('Error loading history: $err'),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 48, color: Colors.black38),
                  const SizedBox(height: 12),
                  const Text(
                    'No food logged yet',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Scan snacks or beverages on the home tab to build your sugar log timeline.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(weeklyFoodLogsProvider.notifier).seedSampleWeek();
                        await ref.read(allFoodLogsHistoryProvider.notifier).reload();
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 16),
                      label: const Text('Seed Sample Week Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlucioTheme.accentLime,
                        foregroundColor: GlucioTheme.inkBlack,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final grouped = _groupLogsByDate(logs);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            for (final entry in grouped.entries)
              _buildDateGroup(context, entry.key, entry.value),
          ],
        );
      },
    );
  }

  Map<DateTime, List<FoodLogEntry>> _groupLogsByDate(List<FoodLogEntry> logs) {
    final Map<DateTime, List<FoodLogEntry>> map = {};
    for (final l in logs) {
      final dateKey = DateTime(l.loggedAt.year, l.loggedAt.month, l.loggedAt.day);
      map.putIfAbsent(dateKey, () => []).add(l);
    }
    return map;
  }

  Widget _buildDateGroup(BuildContext context, DateTime date, List<FoodLogEntry> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String title;
    if (date == today) {
      title = 'Today';
    } else if (date == yesterday) {
      title = 'Yesterday';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      title = '${months[date.month - 1]} ${date.day}, ${date.year}';
    }

    double daySugar = 0.0;
    for (final it in items) {
      if (it.sugarGrams != null) daySugar += it.sugarGrams!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 18,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: GlucioTheme.pillDecoration(
                  fill: GlucioTheme.accentLime.withValues(alpha: 0.35),
                ),
                child: Text(
                  '${daySugar.toStringAsFixed(1)}g total',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: GlucioTheme.inkBlack, thickness: 1.5),
          const SizedBox(height: 8),
          for (final item in items)
            _buildLogItemRow(context, item),
        ],
      ),
    );
  }

  Widget _buildLogItemRow(BuildContext context, FoodLogEntry item) {
    final isSelected = _selectedBarcodes.contains(item.barcode) ||
        (item.id != null && _selectedLogIds.contains(item.id));
    final hasSugar = item.sugarGrams != null;
    final timeStr =
        '${item.loggedAt.hour.toString().padLeft(2, '0')}:${item.loggedAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isMultiSelect = true;
          _toggleBarcodeSelection(item.barcode, logId: item.id);
        });
      },
      onTap: () {
        if (_isMultiSelect) {
          _toggleBarcodeSelection(item.barcode, logId: item.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? GlucioTheme.accentLime.withValues(alpha: 0.3)
              : GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? GlucioTheme.inkBlack : GlucioTheme.inkBlack,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            if (_isMultiSelect) ...[
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: GlucioTheme.inkBlack,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  Text(
                    '${item.portionLabel} • $timeStr',
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasSugar)
                    Text(
                      '${item.sugarGrams!.toStringAsFixed(1)}g sugar (${item.sugarTeaspoonsText})',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: GlucioTheme.inkBlack,
                      ),
                    )
                  else
                    const Text(
                      'Sugar unknown',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            if (!_isMultiSelect) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.black45),
                onPressed: () async {
                  if (item.id != null) {
                    await ref.read(allFoodLogsHistoryProvider.notifier).deleteLog(item.id!);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: SCAN HISTORY (ALL SCANNED PRODUCTS)
  // ==========================================

  Widget _buildScansTab(BuildContext context) {
    final scansAsync = ref.watch(scanHistoryProvider);

    return scansAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
      ),
      error: (err, _) => Center(
        child: Text('Error loading scan history: $err'),
      ),
      data: (scans) {
        if (scans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 48, color: Colors.black38),
                  const SizedBox(height: 12),
                  const Text(
                    'No scan history yet',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Every product you scan appears here, even if not added to your food logs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${scans.length} Scanned Products',
                  style: const TextStyle(
                    fontFamily: GlucioTheme.fontBody,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(scanHistoryProvider.notifier).clearHistory();
                  },
                  child: const Text(
                    'Clear History',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.levelHigh,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final scan in scans)
              _buildScanItemCard(context, scan),
          ],
        );
      },
    );
  }

  Widget _buildScanItemCard(BuildContext context, ScanHistoryEntry scan) {
    final isSelected = _selectedBarcodes.contains(scan.barcode);
    final sugarStr = scan.sugarPer100 != null
        ? '${scan.sugarPer100!.toStringAsFixed(1)}g sugar (${SugarCalculator.formatTeaspoonsPlain(scan.sugarPer100! / 4.0)})'
        : 'Sugar not listed';

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isMultiSelect = true;
          _toggleBarcodeSelection(scan.barcode);
        });
      },
      onTap: () async {
        if (_isMultiSelect) {
          _toggleBarcodeSelection(scan.barcode);
        } else {
          final repo = ref.read(productRepositoryProvider);
          final p = await repo.getProductByBarcode(scan.barcode);
          if (p != null && mounted) {
            Navigator.of(this.context).push(
              MaterialPageRoute(builder: (_) => ProductResultScreen(product: p)),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? GlucioTheme.accentLime.withValues(alpha: 0.3)
              : GlucioTheme.cardCream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: GlucioTheme.inkBlack,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: GlucioTheme.inkBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            if (_isMultiSelect) ...[
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: GlucioTheme.inkBlack,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 14,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  if (scan.brand != null && scan.brand!.isNotEmpty) ...[
                    Text(
                      scan.brand!,
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    sugarStr,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (scan.nutriScoreGrade != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: GlucioTheme.inkBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SCORE ${scan.nutriScoreGrade!.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (scan.novaGroup != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: GlucioTheme.levelMedium,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: GlucioTheme.inkBlack, width: 1),
                          ),
                          child: Text(
                            'NOVA ${scan.novaGroup}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: CUSTOM USER LISTS
  // ==========================================

  Widget _buildListsTab(BuildContext context) {
    final listsAsync = ref.watch(productListsProvider);

    return listsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
      ),
      error: (err, _) => Center(
        child: Text('Error loading lists: $err'),
      ),
      data: (lists) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            GestureDetector(
              onTap: _showCreateListDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_add_rounded, color: GlucioTheme.inkBlack, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+ Create New List',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (lists.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(28),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.cardCream,
                  radius: 18,
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bookmark_border_rounded, size: 40, color: Colors.black38),
                    SizedBox(height: 10),
                    Text(
                      'No Custom Lists Yet',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 18,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Organize your favorites: "Low sugar snacks", "Office treats", or "Avoid".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              for (final list in lists)
                _buildProductListCard(context, list),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProductListCard(BuildContext context, ProductList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: GlucioTheme.cardDecoration(
        surface: GlucioTheme.cardCream,
        radius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          title: Text(
            list.name,
            style: const TextStyle(
              fontFamily: GlucioTheme.fontDisplay,
              fontSize: 16,
              color: GlucioTheme.inkBlack,
            ),
          ),
          subtitle: Text(
            '${list.barcodes.length} products saved',
            style: const TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: GlucioTheme.levelHigh, size: 20),
            onPressed: () {
              ref.read(productListsProvider.notifier).deleteList(list.id);
            },
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.barcodes.isEmpty) ...[
                    const Text(
                      'No products in this list yet. Scan or search products to add them.',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ] else ...[
                    for (final barcode in list.barcodes)
                      _buildListItemRow(context, list.id, barcode),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildListItemRow(BuildContext context, String listId, String barcode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GlucioTheme.inkBlack, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final repo = ref.read(productRepositoryProvider);
                final p = await repo.getProductByBarcode(barcode);
                if (p != null && mounted) {
                  Navigator.of(this.context).push(
                    MaterialPageRoute(builder: (_) => ProductResultScreen(product: p)),
                  );
                }
              },
              child: Text(
                'Barcode: $barcode',
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GlucioTheme.inkBlack,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(productListsProvider.notifier).removeProduct(listId, barcode);
            },
            child: const Icon(Icons.close_rounded, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FLOATING MULTI-SELECT BAR
  // ==========================================

  Widget _buildMultiSelectBottomBar() {
    final count = _selectedBarcodes.length;
    final historyLogs = ref.read(allFoodLogsHistoryProvider).value ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: GlucioTheme.inkBlack,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: GlucioTheme.accentLime,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count selected',
              style: const TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: GlucioTheme.inkBlack,
              ),
            ),
          ),
          const Spacer(),
          // Compare action
          GestureDetector(
            onTap: count >= 2 && count <= 4 ? _compareSelected : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: count >= 2 && count <= 4
                    ? GlucioTheme.accentLime
                    : Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Compare ($count/4)',
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: count >= 2 && count <= 4
                      ? GlucioTheme.inkBlack
                      : Colors.white38,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Export action (for logs)
          if (_selectedSegment == 0 && _selectedLogIds.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _exportSelectedLogs(historyLogs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Close selection
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: _exitMultiSelect,
          ),
        ],
      ),
    );
  }
}

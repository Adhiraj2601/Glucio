import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../data/repositories/product_repository.dart';
import 'add_product_screen.dart';
import 'widgets/debug_trace_panel.dart';

/// Screen displayed when a scanned or entered barcode cannot be found in the catalog.
/// Neo-brutalist styling with a direct path to add the missing product.
class ProductNotFoundScreen extends StatelessWidget {
  final String barcode;
  final LookupTrace? trace;

  const ProductNotFoundScreen({
    super.key,
    required this.barcode,
    this.trace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: const Text(
          'Product Not Found',
          style: TextStyle(
            fontFamily: GlucioTheme.fontDisplay,
            color: GlucioTheme.inkBlack,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        backgroundColor: GlucioTheme.bgCream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GlucioTheme.inkBlack),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon container
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: GlucioTheme.accentLime,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: GlucioTheme.inkBlack,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Barcode Not Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontDisplay,
                  fontSize: 26,
                  color: GlucioTheme.inkBlack,
                ),
              ),
              const SizedBox(height: 10),

              // Description
              const Text(
                'We searched our verified Indian seed catalog and Open Food Facts, but could not find nutrition info for this barcode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Monospace Barcode Chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: GlucioTheme.cardCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    barcode,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 16,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Add This Product Action Button (Primary)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(initialBarcode: barcode),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: GlucioTheme.accentLime,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GlucioTheme.inkBlack, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: GlucioTheme.inkBlack,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: GlucioTheme.inkBlack),
                      SizedBox(width: 10),
                      Text(
                        'Add This Product',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Scan Another Product Button (Secondary)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: GlucioTheme.cardCream,
                    borderRadius: BorderRadius.circular(16),
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
                      Icon(Icons.qr_code_scanner, color: GlucioTheme.inkBlack),
                      SizedBox(width: 8),
                      Text(
                        'Scan Another Barcode',
                        style: TextStyle(
                          fontFamily: GlucioTheme.fontBody,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: GlucioTheme.inkBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Diagnostic Debug Trace Panel
              DebugTracePanel(trace: trace),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Screen displayed when a scanned or entered barcode cannot be found in the catalog.
class ProductNotFoundScreen extends StatelessWidget {
  final String barcode;

  const ProductNotFoundScreen({
    super.key,
    required this.barcode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Not Found'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Barcode Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'We searched our verified Indian seed catalog and Open Food Facts, but could not find nutrition info for this barcode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  barcode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another Product'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Crowdsourced product contribution will be unlocked in Slice 5!'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Missing Product (Slice 5)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

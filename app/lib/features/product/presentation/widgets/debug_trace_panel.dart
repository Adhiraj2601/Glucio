import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/repositories/product_repository.dart';

/// Diagnostic panel displayed only in debug builds showing barcode format and lookup path taken.
class DebugTracePanel extends StatelessWidget {
  final LookupTrace? trace;

  const DebugTracePanel({
    super.key,
    this.trace,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || trace == null) {
      return const SizedBox.shrink();
    }

    final t = trace!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: GlucioTheme.cardDecoration(
        surface: const Color(0xFFE8F5E9),
        radius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          initiallyExpanded: false,
        leading: const Icon(Icons.bug_report, color: GlucioTheme.inkBlack),
        title: const Text(
          'DEBUG TRACE (kDebugMode)',
          style: TextStyle(
            fontFamily: GlucioTheme.fontBody,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Text(
          'Barcode: ${t.rawBarcode} (${t.barcodeFormat})',
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRow('Raw Barcode', t.rawBarcode),
                _buildRow('Format', t.barcodeFormat),
                _buildRow('Status', t.isFound ? 'HIT' : 'MISS'),
                if (t.error != null) _buildRow('Error', t.error!),
                const SizedBox(height: 8),
                const Text(
                  'Lookup Pipeline Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                for (int i = 0; i < t.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      '${i + 1}. ${t.steps[i]}',
                      style: const TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

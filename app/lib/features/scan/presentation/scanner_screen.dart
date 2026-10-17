import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/repositories/product_repository.dart';
import '../../product/presentation/product_not_found_screen.dart';
import '../../product/presentation/product_result_screen.dart';

/// Scanner screen featuring real-time camera viewfinder, permission management,
/// and debug-only manual barcode input for automated/quick verification.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isNavigating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Central lookup pipeline fed by either real camera detection or manual entry.
  Future<void> _handleBarcodeLookup(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty || _isNavigating || _isLoading) return;

    setState(() {
      _isLoading = true;
      _isNavigating = true;
    });

    try {
      final repo = ref.read(productRepositoryProvider);
      final product = await repo.getProductByBarcode(barcode);

      if (!mounted) return;

      if (product != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(
              product: product,
              trace: repo.lastTrace,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductNotFoundScreen(
              barcode: barcode,
              trace: repo.lastTrace,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lookup error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNavigating = false;
        });
      }
    }
  }

  void _showManualBarcodeDialog() {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual Barcode Input (Debug)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Enter EAN-13 Barcode',
                  hintText: 'e.g. 8901063012130',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final code = textController.text.trim();
                  Navigator.of(ctx).pop();
                  if (code.isNotEmpty) {
                    _handleBarcodeLookup(code);
                  }
                },
                child: const Text('Lookup Product'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Test Seed Barcodes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickChip(ctx, 'Parle-G', '8901063012130'),
                  _buildQuickChip(ctx, 'Kissan Ketchup (Hidden)', '8901030383454'),
                  _buildQuickChip(ctx, 'Thums Up', '8901764012211'),
                  _buildQuickChip(ctx, 'Haldiram Alu Bhujia', '8901725181222'),
                  _buildQuickChip(ctx, 'Maggi Sauce (EAN-8)', '89080443'),
                  _buildQuickChip(ctx, 'Unknown (404)', '8909999999999'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickChip(BuildContext ctx, String label, String barcode) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        Navigator.of(ctx).pop();
        _handleBarcodeLookup(barcode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Product Barcode'),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Viewfinder
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final value = barcode.rawValue;
                if (value != null && value.isNotEmpty) {
                  _handleBarcodeLookup(value);
                  break;
                }
              }
            },
            errorBuilder: (context, error) {
              return _buildPermissionDeniedUI();
            },
          ),

          // Viewfinder reticle overlay
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 1,
                      color: Colors.redAccent.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Instruction Banner
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Align barcode inside the viewfinder',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Bottom Debug Manual Entry (kDebugMode only, per instructions)
          if (kDebugMode)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _showManualBarcodeDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text(
                      'Enter Barcode Manually (Debug)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedUI() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(28.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Access Needed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Glucio uses your camera to scan barcodes on packaged Indian food items and calculate sugar content in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await _controller.start();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Camera Access'),
            ),
            const SizedBox(height: 12),
            if (kDebugMode)
              OutlinedButton.icon(
                onPressed: _showManualBarcodeDialog,
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Use Manual Entry Instead',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

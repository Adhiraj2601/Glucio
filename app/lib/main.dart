import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/glucio_theme.dart';
import 'data/repositories/product_repository.dart';
import 'features/product/presentation/product_not_found_screen.dart';
import 'features/product/presentation/product_result_screen.dart';
import 'features/scan/presentation/scanner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Notice: .env file not found or empty. Using default fallback values.');
  }

  runApp(
    const ProviderScope(
      child: GlucioApp(),
    ),
  );
}

/// The root widget of the Glucio application.
class GlucioApp extends StatelessWidget {
  const GlucioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucio',
      debugShowCheckedModeBanner: false,
      theme: GlucioTheme.themeData,
      home: const HomeScreen(),
    );
  }
}

/// Home screen with quick camera scanning and seed test catalog.
/// Styled with Glucio's Neo-brutalist theme.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-warm the seed catalog in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productRepositoryProvider).loadSeedProducts();
    });
  }

  Future<void> _lookupBarcode(String barcode) async {
    final repo = ref.read(productRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: GlucioTheme.inkBlack),
      ),
    );

    try {
      final product = await repo.getProductByBarcode(barcode);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      if (product != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(
              product: product,
              trace: repo.lastTrace,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
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
        Navigator.of(context).pop(); // dismiss loading
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Lookup error: $e')),
        );
      }
    }
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();

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
                    'Manual Barcode Input',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 20,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GlucioTheme.inkBlack),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: GlucioTheme.fontBody,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter EAN Barcode',
                  hintText: 'e.g. 8901063012130',
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
                    borderSide: const BorderSide(color: GlucioTheme.primaryGreen, width: 2.5),
                  ),
                  prefixIcon: const Icon(Icons.qr_code, color: GlucioTheme.inkBlack),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  final code = textController.text.trim();
                  Navigator.of(ctx).pop();
                  if (code.isNotEmpty) {
                    _lookupBarcode(code);
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
                      'Lookup Product',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlucioTheme.bgCream,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: GlucioTheme.accentLime,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: const Icon(Icons.grain, color: GlucioTheme.inkBlack, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'Glucio',
              style: TextStyle(
                fontFamily: GlucioTheme.fontDisplay,
                color: GlucioTheme.inkBlack,
                fontSize: 24,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: GlucioTheme.bgCream,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Camera Scan Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.accentLime,
                  radius: 22,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
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
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 34,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Scan Food Barcode',
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontDisplay,
                        fontSize: 24,
                        color: GlucioTheme.inkBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Point camera at any packaged Indian snack or drink to see sugar in teaspoons & cubes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: GlucioTheme.fontBody,
                        color: GlucioTheme.inkBlack,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ScannerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Launch Camera Scanner',
                              style: TextStyle(
                                fontFamily: GlucioTheme.fontBody,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Manual Input Button
              GestureDetector(
                onTap: _showManualEntryDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: GlucioTheme.cardDecoration(
                    surface: GlucioTheme.cardCream,
                    radius: 14,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard, color: GlucioTheme.inkBlack, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Enter Barcode Manually (Debug)',
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
              const SizedBox(height: 20),

              // WHO Daily Sugar Context Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: GlucioTheme.cardDecoration(
                  surface: GlucioTheme.cardCream,
                  radius: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GlucioTheme.levelLow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: GlucioTheme.inkBlack,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHO Free Sugar Target',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Max 25g/day (~6¼ tsp). Most Indian packaged drinks or snacks exceed this in 1 serve!',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 11,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Quick Test Seed Products Section
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Test Products',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  Text(
                    'Slice 1.5 Test Catalog',
                    style: TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSeedProductTile(
                title: 'Parle-G Gluco Biscuits',
                subtitle: '8901063012134 • 25.5g sugar (Seed Catalog)',
                icon: Icons.cookie_outlined,
                fill: const Color(0xFFFFECC8),
                onTap: () => _lookupBarcode('8901063012134'),
              ),
              const SizedBox(height: 10),

              _buildSeedProductTile(
                title: 'Kissan Fresh Tomato Ketchup',
                subtitle: '8901030383458 • 25.4g sugar (Hidden Sugar Alert!)',
                icon: Icons.warning_amber_rounded,
                fill: const Color(0xFFFFD6D6),
                onTap: () => _lookupBarcode('8901030383458'),
              ),
              const SizedBox(height: 10),

              _buildSeedProductTile(
                title: 'Thums Up (300ml)',
                subtitle: '8901764012211 • 31.8g sugar (~8 tsp - Exceeds 100%)',
                icon: Icons.local_drink_outlined,
                fill: const Color(0xFFFFB800).withValues(alpha: 0.35),
                onTap: () => _lookupBarcode('8901764012211'),
              ),
              const SizedBox(height: 10),

              _buildSeedProductTile(
                title: 'Haldiram\'s Alu Bhujia',
                subtitle: '8901725181222 • 2.1g sugar (Low Sugar Namkeen)',
                icon: Icons.check_circle_outline,
                fill: GlucioTheme.levelLow.withValues(alpha: 0.25),
                onTap: () => _lookupBarcode('8901725181222'),
              ),
              const SizedBox(height: 10),

              _buildSeedProductTile(
                title: 'Maggi Tomato Sauce (EAN-8)',
                subtitle: '89080443 • Tests missing-sugar / EAN-8 flow',
                icon: Icons.help_outline,
                fill: const Color(0xFFE0E0E0),
                onTap: () => _lookupBarcode('89080443'),
              ),
              const SizedBox(height: 10),

              _buildSeedProductTile(
                title: 'Test Barcode Not Found (404)',
                subtitle: '8909999999999 • Tests Add This Product flow',
                icon: Icons.search_off_rounded,
                fill: GlucioTheme.cardCream,
                onTap: () => _lookupBarcode('8909999999999'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedProductTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color fill,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: GlucioTheme.cardDecoration(
          surface: GlucioTheme.cardCream,
          radius: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
              ),
              child: Icon(icon, color: GlucioTheme.inkBlack, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontBody,
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: GlucioTheme.inkBlack),
          ],
        ),
      ),
    );
  }
}

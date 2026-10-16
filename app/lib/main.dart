import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B), // Teal / Health primary
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/// Home screen with quick camera scanning and seed test catalog.
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final product = await repo.getProductByBarcode(barcode);
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading

      if (product != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(product: product),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductNotFoundScreen(barcode: barcode),
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
                    'Manual Barcode Input',
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
                    _lookupBarcode(code);
                  }
                },
                child: const Text('Lookup Product'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: Color(0xFF00796B)),
            SizedBox(width: 8),
            Text(
              'Glucio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Camera Scan Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00796B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan Food Barcode',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Point camera at any packaged Indian snack or drink to see sugar in teaspoons & cubes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF004D40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'Launch Camera Scanner',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Manual Input Button
              OutlinedButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard),
                label: const Text('Enter Barcode Manually (Debug / Testing)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // WHO Daily Sugar Context Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Color(0xFF2E7D32),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WHO Free Sugar Target',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Max 25g/day (~6.25 teaspoons). Most Indian canned drinks or large biscuits exceed this in a single serve!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Test Seed Products Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Test Products',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Slice 1 Seed Catalog',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildSeedProductTile(
                title: 'Parle-G Gluco Biscuits',
                subtitle: '8901063012130 • 25.5g sugar / 100g',
                icon: Icons.cookie_outlined,
                color: Colors.amber.shade800,
                onTap: () => _lookupBarcode('8901063012130'),
              ),
              const SizedBox(height: 8),

              _buildSeedProductTile(
                title: 'Kissan Fresh Tomato Ketchup',
                subtitle: '8901030383454 • 25.4g sugar (Hidden Sugar Alert!)',
                icon: Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                onTap: () => _lookupBarcode('8901030383454'),
              ),
              const SizedBox(height: 8),

              _buildSeedProductTile(
                title: 'Thums Up (300ml)',
                subtitle: '8901764012211 • 31.8g sugar (~8 tsp - Exceeds 100%)',
                icon: Icons.local_drink_outlined,
                color: Colors.red.shade900,
                onTap: () => _lookupBarcode('8901764012211'),
              ),
              const SizedBox(height: 8),

              _buildSeedProductTile(
                title: 'Haldiram\'s Alu Bhujia',
                subtitle: '8901725181222 • 2.1g sugar / 100g (Low Sugar)',
                icon: Icons.check_circle_outline,
                color: Colors.green.shade700,
                onTap: () => _lookupBarcode('8901725181222'),
              ),
              const SizedBox(height: 8),

              _buildSeedProductTile(
                title: 'Test Barcode Not Found (404)',
                subtitle: '8909999999999 • Tests product not found state',
                icon: Icons.search_off_rounded,
                color: Colors.grey.shade700,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}

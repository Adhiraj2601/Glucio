import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Ensure Flutter engine bindings are initialized before calling async code
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables if available; fail gracefully if not present
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // If .env is missing during early dev or testing, proceed with defaults
    debugPrint('Notice: .env file not found or empty. Using default fallback values.');
  }

  runApp(const GlucioApp());
}

/// The root widget of the Glucio application.
/// Configured with Android-first Material 3 design and warm health-focused palette.
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
      home: const HelloGlucioScreen(),
    );
  }
}

/// Hello screen for Slice 0: confirms app scaffold, permissions, and device connection.
class HelloGlucioScreen extends StatelessWidget {
  const HelloGlucioScreen({super.key});

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Icon & Badge
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 52,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                Text(
                  'Know Your Sugar,\nOne Scan at a Time',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Glucio translates confusing grams on Indian packaged snacks into visual teaspoons and sugar cubes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Slice 0 Status Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Slice 0: Environment & Scaffold Ready',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildStatusRow(
                          icon: Icons.fingerprint_rounded,
                          label: 'App ID',
                          value: 'com.glucio.app (Fixed)',
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          icon: Icons.camera_alt_outlined,
                          label: 'Camera Permission',
                          value: 'Configured in Manifest',
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          icon: Icons.wifi_rounded,
                          label: 'Internet Permission',
                          value: 'Configured in Manifest',
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          icon: Icons.straighten_rounded,
                          label: 'WHO Daily Limit',
                          value: '25 g (~6.25 tsp)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Next Step Indicator
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Next: Slice 1 will introduce real-time barcode scanning & the sugar cube visualizer!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

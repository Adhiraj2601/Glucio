import 'package:flutter/material.dart';
import '../../../../core/theme/glucio_theme.dart';
import '../../../../data/models/product_details.dart';

/// Modal dialog displaying high-resolution packaging images (Front, Ingredients, Nutrition).
class ProductImageGalleryModal extends StatefulWidget {
  final ProductImageUrls imageUrls;
  final String productName;

  const ProductImageGalleryModal({
    super.key,
    required this.imageUrls,
    required this.productName,
  });

  static void show(BuildContext context, ProductImageUrls urls, String name) {
    showDialog(
      context: context,
      builder: (_) => ProductImageGalleryModal(
        imageUrls: urls,
        productName: name,
      ),
    );
  }

  @override
  State<ProductImageGalleryModal> createState() =>
      _ProductImageGalleryModalState();
}

class _ProductImageGalleryModalState extends State<ProductImageGalleryModal> {
  int _activeTab = 0; // 0 = Front, 1 = Ingredients, 2 = Nutrition

  @override
  void initState() {
    super.initState();
    // Default to first available image
    if (widget.imageUrls.front == null) {
      if (widget.imageUrls.ingredients != null) {
        _activeTab = 1;
      } else if (widget.imageUrls.nutrition != null) {
        _activeTab = 2;
      }
    }
  }

  String? _getCurrentUrl() {
    switch (_activeTab) {
      case 0:
        return widget.imageUrls.front;
      case 1:
        return widget.imageUrls.ingredients;
      case 2:
        return widget.imageUrls.nutrition;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = _getCurrentUrl();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: GlucioTheme.cardDecoration(
          surface: GlucioTheme.bgCream,
          radius: 20,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: GlucioTheme.fontDisplay,
                      fontSize: 18,
                      color: GlucioTheme.inkBlack,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: GlucioTheme.inkBlack),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Segmented tabs: Front | Ingredients | Nutrition
            Row(
              children: [
                _buildTab(0, 'Front', widget.imageUrls.front != null),
                const SizedBox(width: 8),
                _buildTab(1, 'Ingredients', widget.imageUrls.ingredients != null),
                const SizedBox(width: 8),
                _buildTab(2, 'Nutrition', widget.imageUrls.nutrition != null),
              ],
            ),
            const SizedBox(height: 16),
            // Image viewport with ink border
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GlucioTheme.inkBlack, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: currentUrl != null
                  ? InteractiveViewer(
                      child: Image.network(
                        currentUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: GlucioTheme.inkBlack,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Text(
                            'Unable to load packaging photo',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 12,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.no_photography_outlined,
                            size: 40,
                            color: GlucioTheme.levelMissing,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No photo available for this angle',
                            style: TextStyle(
                              fontFamily: GlucioTheme.fontBody,
                              fontSize: 12,
                              color: GlucioTheme.inkBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pinch to zoom • Images CC-BY-SA via Open Food Facts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GlucioTheme.fontBody,
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, bool hasImage) {
    final isSelected = _activeTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? GlucioTheme.accentLime
                : (hasImage ? GlucioTheme.cardCream : const Color(0xFFECEAE0)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GlucioTheme.inkBlack, width: 1.5),
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
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: GlucioTheme.fontBody,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: hasImage ? GlucioTheme.inkBlack : Colors.black38,
            ),
          ),
        ),
      ),
    );
  }
}

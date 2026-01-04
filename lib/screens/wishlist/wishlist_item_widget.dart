import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../models/index.dart' show Product;
import '../../services/services.dart';
import '../../widgets/product/action_button_mixin.dart';
import '../../widgets/product/dialog_add_to_cart.dart';
import '../../widgets/product/widgets/pricing.dart';

class WishlistItem extends StatelessWidget with ActionButtonMixin {
  const WishlistItem({required this.product, this.onRemove});

  final Product product;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTapProduct(context, product: product),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    key: ValueKey(product.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ProductCard(product: product),
                      ),
                      const SizedBox(width: 8),
                      _RemoveButton(onRemove: onRemove),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove});

  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: IconButton(
        icon: Icon(Icons.close_rounded, color: Colors.red.shade400, size: 20),
        onPressed: onRemove,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        tooltip: 'Remove from wishlist',
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: SizedBox(
                  width: 100,
                  height: 130,
                  child: ImageResize(
                    url: (product.imageFeature?.isNotEmpty ?? false)
                        ? product.imageFeature!
                        : kDefaultImage,
                    width: 100,
                    height: 130,
                    fit: ImageTools.boxFit(kCartDetail['boxFit']),
                  ),
                ),
              ),
            ),
            if (product.onSale ?? false)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: const Text(
                    'SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                product.name ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      height: 1.3,
                      color: Colors.grey.shade900,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ProductPricing(
                product: product,
                hide: false,
                priceTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              if (kWishListConfig.showCartButton &&
                  Services().widget.enableShoppingCart(product))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onPressed: () {
                      final files = product.files ?? [];
                      if ((product.isPurchased) &&
                          (product.isDownloadable ?? false) &&
                          files.isNotEmpty &&
                          (files.first?.isNotEmpty ?? false)) {
                        Tools.launchURL(files.first,
                            mode: LaunchMode.externalApplication);
                        return;
                      }
                      DialogAddToCart.show(context, product: product);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (product.isPurchased && product.isDownloadable!)
                              ? Icons.download_rounded
                              : Icons.shopping_cart_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ((product.isPurchased && product.isDownloadable!)
                                  ? S.of(context).download
                                  : S.of(context).addToCart)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

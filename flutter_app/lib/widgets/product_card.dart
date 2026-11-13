import 'package:flutter/material.dart';
import '../models.dart';
import '../screens/product_detail_screen.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

void openProduct(BuildContext context, int id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(id: id)));

void addToCart(BuildContext context, ProductCardData p, [Variant? v]) {
  cart.add(p, v);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(duration: const Duration(milliseconds: 1200), content: Text('Added to cart', style: ts(13, c: Colors.black))));
}

class _AddButton extends StatelessWidget {
  const _AddButton(this.onTap, {this.height = 22, this.size = 10});

  final VoidCallback onTap;
  final double height;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFF7B500), borderRadius: BorderRadius.circular(6)),
        child: Text('Add +', style: ts(size, w: FontWeight.w700, c: Colors.black)),
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile(this.product, {super.key, this.withAdd = true});

  final ProductCardData product;
  final bool withAdd;

  @override
  Widget build(BuildContext context) {
    final v = product.variant;
    return GestureDetector(
      onTap: () => openProduct(context, product.id),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: withAdd ? const Color(0xFF14110C) : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: withAdd ? const Color(0xFF2A2218) : Colors.transparent, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: AppImage(product.image, fit: withAdd ? BoxFit.contain : BoxFit.cover))),
                  const Positioned(right: 1, top: 1, child: Icon(Icons.favorite_border, size: 11, color: Colors.white)),
                  if (!withAdd)
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: goldLight, borderRadius: BorderRadius.circular(4)),
                        child: Text(rupees(v.price), style: ts(6.5, w: FontWeight.w700, c: Colors.black)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(7, w: FontWeight.w500)),
            const SizedBox(height: 1),
            Row(
              children: [
                Text(rupees(v.price), style: ts(7.5, w: FontWeight.w700, c: withAdd ? goldLight : Colors.white)),
                if (v.discount > 0) ...[
                  const SizedBox(width: 2),
                  Flexible(child: Text(rupees(v.mrp), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(6, c: muted, d: TextDecoration.lineThrough))),
                ],
              ],
            ),
            if (withAdd) ...[const SizedBox(height: 3), _AddButton(() => addToCart(context, product), height: 17, size: 7.5)],
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key, this.compact = false});

  final ProductCardData product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final v = product.variant;
    final pad = compact ? 5.0 : 6.0;
    return GestureDetector(
      onTap: () => openProduct(context, product.id),
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(color: compact ? const Color(0xFF14110C) : const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(compact ? 8 : 10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(compact ? 6 : 8), child: AppImage(product.image))),
                  Positioned(right: 4, top: 4, child: Icon(Icons.favorite_border, size: compact ? 12 : 14, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            if (!compact && product.brand != null) Text(product.brand!, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(9, c: const Color(0xFFBDBDBD))),
            Text(product.name, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, style: ts(compact ? 8.5 : 9.5, w: FontWeight.w500, h: 1.25)),
            SizedBox(height: compact ? 2 : 4),
            Row(
              children: [
                Text(rupees(v.price), style: ts(compact ? 8.5 : 13, w: FontWeight.w600)),
                if (v.discount > 0) ...[
                  SizedBox(width: compact ? 3 : 4),
                  Flexible(child: Text(rupees(v.mrp), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(compact ? 7 : 9, c: muted, d: TextDecoration.lineThrough))),
                ],
              ],
            ),
            if (!compact && v.discount > 0)
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(4)),
                child: Text('↓${percent(v.discount)}', style: ts(8, w: FontWeight.w600, c: green)),
              ),
            SizedBox(height: compact ? 4 : 6),
            _AddButton(() => addToCart(context, product), height: compact ? 20 : 22, size: compact ? 8.5 : 10),
          ],
        ),
      ),
    );
  }
}

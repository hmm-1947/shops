import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureView<ProductDetail>(load: () => Api.product(id), builder: (_, p, _) => _Body(p)),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body(this.p);

  final ProductDetail p;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late int _selected = widget.p.variants.indexWhere((v) => v.isDefault).clamp(0, widget.p.variants.length - 1);
  int _image = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final v = p.variants[_selected];
    return Column(
      children: [
        Expanded(child: _content(p, v)),
        _bar(p, v),
      ],
    );
  }

  Widget _content(ProductDetail p, Variant v) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(itemCount: p.images.length, onPageChanged: (i) => setState(() => _image = i), itemBuilder: (_, i) => AppImage(p.images[i])),
          ),
        ),
        if (p.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < p.images.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _image ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(color: i == _image ? gold : muted, borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (p.brand != null)
          Text(
            p.brand!,
            style: const TextStyle(color: gold, fontWeight: FontWeight.w600),
          ),
        Text(p.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text('${p.category} / ${p.subcategory}', style: const TextStyle(color: muted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              rupees(v.price),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: gold),
            ),
            if (v.discount > 0) ...[
              const SizedBox(width: 8),
              Text(
                rupees(v.mrp),
                style: const TextStyle(color: muted, decoration: TextDecoration.lineThrough),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent(v.discount)} OFF',
                style: const TextStyle(color: gold, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        if (p.variants.length > 1) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < p.variants.length; i++)
                ChoiceChip(
                  label: Text(p.variants[i].name),
                  selected: i == _selected,
                  selectedColor: gold,
                  labelStyle: TextStyle(color: i == _selected ? Colors.black : Colors.white),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selected = i),
                ),
            ],
          ),
        ],
        if (p.description.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(p.description, style: const TextStyle(color: Colors.white70, height: 1.4)),
        ],
        if (p.specs.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final (k, val) in p.specs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(k, style: const TextStyle(color: muted)),
                  ),
                  Expanded(flex: 3, child: Text(val)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _bar(ProductDetail p, Variant v) {
    final card = ProductCardData(p.id, p.name, p.brand, p.images.isEmpty ? null : p.images.first, v);
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final i = cart.lines.indexWhere((l) => l.product.id == p.id && l.variant.id == v.id);
        final line = i >= 0 ? cart.lines[i] : null;
        Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
        );
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: surface,
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (line == null)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: () => addToCart(context, card, v),
                        icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                        label: Text(
                          'Add to cart · ${rupees(v.price)}',
                          style: ts(14, w: FontWeight.w600, c: Colors.black),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Container(
                    height: 48,
                    decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(26)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        btn(Icons.remove, () => cart.setQty(line, line.qty - 1)),
                        SizedBox(
                          width: 32,
                          child: Center(
                            child: Text(
                              '${line.qty}',
                              style: ts(15, w: FontWeight.w700, c: Colors.black),
                            ),
                          ),
                        ),
                        btn(Icons.add, () => cart.setQty(line, line.qty + 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: const BorderSide(color: gold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        onPressed: () => CartScreen.open(context),
                        child: Text(
                          'View cart (${cart.count})',
                          style: ts(14, w: FontWeight.w600, c: gold),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

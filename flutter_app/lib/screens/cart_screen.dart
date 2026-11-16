import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'checkout_screen.dart';
import 'location_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static Future<void> open(BuildContext context) {
    cart.loadCharges();
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen()));
  }

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surface,
        title: Text('Clear cart?', style: ts(16, w: FontWeight.w600)),
        content: Text('All items will be removed.', style: ts(12, c: muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: ts(13, c: muted))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Clear', style: ts(13, c: orange))),
        ],
      ),
    );
    if (ok == true) cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([cart, session]),
      builder: (context, _) {
        final empty = cart.lines.isEmpty;
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                  child: Row(
                    children: [
                      const BackCircle(),
                      Expanded(child: Text('My Cart (${cart.count})', textAlign: TextAlign.center, style: ts(15, w: FontWeight.w600))),
                      SizedBox(
                        width: 40,
                        child: empty
                            ? null
                            : GestureDetector(
                                onTap: () => _clear(context),
                                child: Align(alignment: Alignment.centerRight, child: Text('Edit', style: ts(13, w: FontWeight.w500, c: orange))),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: empty
                      ? const _Empty()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(15, 4, 15, 12),
                          children: [
                            Text('My Cart (${cart.count})', style: ts(20, w: FontWeight.w700)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => LocationScreen.open(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: muted),
                                  const SizedBox(width: 4),
                                  Text(session.city, style: ts(11, c: const Color(0xFFD0D0D0))),
                                  const Icon(Icons.keyboard_arrow_down, size: 16, color: muted),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const DeliveryProgress(),
                            const SizedBox(height: 12),
                            for (final l in cart.lines) ...[_CartLine(l, key: ObjectKey(l)), const SizedBox(height: 10)],
                            const OfferCard(),
                          ],
                        ),
                ),
                if (!empty) const _BillBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 56, color: muted),
          const SizedBox(height: 12),
          Text('Your cart is empty', style: ts(16, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add items to get started', style: ts(12, c: muted)),
          const SizedBox(height: 20),
          SizedBox(width: 180, child: OrangeButton('Browse products', height: 44, radius: 8, size: 13, onTap: () => Navigator.of(context).maybePop())),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine(this.line, {super.key});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final v = line.variant;
    final saved = (v.mrp - v.price) * line.qty;
    return PanelCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(width: 76, height: 96, child: AppImage(line.product.image))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(line.product.brand ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, c: const Color(0xFFD0D0D0)))),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => cart.setQty(line, 0),
                      child: const Padding(padding: EdgeInsets.only(left: 8, bottom: 4), child: Icon(Icons.delete_outline, size: 18, color: muted)),
                    ),
                  ],
                ),
                Text(line.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12.5, w: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(9.5, c: muted)),
                const SizedBox(height: 6),
                OffChip(v.discount),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(rupees(v.price * line.qty), style: ts(15, w: FontWeight.w700)),
                          if (v.mrp > v.price) ...[
                            const SizedBox(width: 6),
                            Flexible(child: Text(rupees(v.mrp * line.qty), overflow: TextOverflow.ellipsis, style: ts(10, c: muted, d: TextDecoration.lineThrough))),
                          ],
                        ],
                      ),
                    ),
                    QtyStepper(line, height: 30),
                  ],
                ),
                if (saved > 0) Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(top: 4), child: Text('You save ${rupees(saved)}', style: ts(10, c: green)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillBar extends StatelessWidget {
  const _BillBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      child: PanelCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BillSummary(bigTotal: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: OrangeButton('Add more items', fill: Colors.white, height: 44, radius: 8, size: 12.5, glow: false, onTap: () => Navigator.of(context).maybePop())),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: OrangeButton('Place order', height: 44, radius: 8, size: 14, glow: false, onTap: () => CheckoutScreen.open(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../screens/cart_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/product_list_screen.dart';
import '../api.dart';
import 'common.dart';
import '../theme.dart';

const dockColor = Color(0xF0E2D9D5);
const dockInk = Color(0xFF1A1A1A);
const dockHeight = 52.0;

class BottomDock extends StatelessWidget {
  const BottomDock({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FreeDeliveryPill(),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: dockHeight,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: dockColor, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    _DockItem(Icons.home_filled, 'Home', index == 0, () => onTap(0)),
                    _DockItem(Icons.grid_view_outlined, 'Categories', index == 1, () => onTap(1)),
                    _DockItem(Icons.local_cafe_outlined, 'Cafe', index == 2, () => onTap(2)),
                    const _DockBrand(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => OrdersScreen.open(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: dockHeight + 2,
                height: dockHeight + 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E5A1E),
                  border: Border.all(color: const Color(0xFF1F7A33), width: 2),
                ),
                child: const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem(this.icon, this.label, this.selected, this.onTap);

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: selected ? 5 : 4,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46,
          decoration: BoxDecoration(color: selected ? goldLight : Colors.transparent, borderRadius: BorderRadius.circular(26)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: dockInk),
              const SizedBox(height: 1),
              Text(label, style: ts(8.5, w: selected ? FontWeight.w700 : FontWeight.w500, c: dockInk)),
            ],
          ),
        ),
      ),
    );
  }
}

class FreeDeliveryPill extends StatelessWidget {
  const FreeDeliveryPill({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final done = cart.remaining == 0;
        return GestureDetector(onTap: () => CartScreen.open(context), behavior: HitTestBehavior.opaque, child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: dockColor, borderRadius: BorderRadius.circular(24)),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: goldLight, shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping_outlined, size: 14, color: dockInk),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: ts(11.5, c: dockInk),
                        children: done
                            ? [TextSpan(text: 'Free delivery unlocked', style: ts(11.5, w: FontWeight.w700, c: dockInk))]
                            : [
                                const TextSpan(text: 'Shop for '),
                                TextSpan(text: '${rupees(cart.remaining)}→Unlock free delivery', style: ts(11.5, w: FontWeight.w700, c: dockInk)),
                              ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: cart.progress, minHeight: 3.5, color: goldLight, backgroundColor: const Color(0xFF3A3A3A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
      },
    );
  }
}

class _DockBrand extends StatelessWidget {
  const _DockBrand();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DisplayBrand?>(
      valueListenable: displayBrand,
      builder: (context, b, _) {
        if (b == null) return const SizedBox.shrink();
        return Expanded(
          flex: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductListScreen(
                  title: b.name,
                  header: b.banner == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AspectRatio(aspectRatio: 16 / 7, child: AppImage(b.banner))),
                        ),
                  loader: (p, _) => Api.products({'brand_id': '${b.id}'}, p),
                ),
              ),
            ),
            child: SizedBox(
              height: 46,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(child: AppImage(b.image, fit: BoxFit.contain)),
                  ),
                  const SizedBox(height: 1),
                  Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(8.5, w: FontWeight.w500, c: dockInk)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cart_screen.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

String _products(int n) => n > 0 ? '$n+ Products' : '0 Products';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _keys = <int, GlobalKey>{};
  int _selected = 0;

  void _search() => SearchScreen.open(context);

  void _seeAll(Category c) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductListScreen(title: c.name, loader: (p, _) => Api.products({'category_id': '${c.id}'}, p))),
      );

  void _jump(int i, Category c) {
    setState(() => _selected = i);
    final ctx = _keys[c.id]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut, alignment: 0.02);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureView<List<Category>>(
        load: Api.categories,
        builder: (context, cats, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, homeBottomInsetValue),
            children: [
              _Header(onBack: widget.onBack, onSearch: _search),
              const SizedBox(height: 14),
              _Tabs(cats: cats, selected: _selected, onTap: _jump),
              const SizedBox(height: 12),
              const _DeliveryCard(),
              const SizedBox(height: 12),
              const _SortFilter(),
              const SizedBox(height: 14),
              for (final c in cats) ...[
                KeyedSubtree(key: _keys.putIfAbsent(c.id, GlobalKey.new), child: _CategorySection(c, onSeeAll: () => _seeAll(c))),
                const SizedBox(height: 14),
              ],
              const _PromoStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

const homeBottomInsetValue = 128.0;

class _CircleButton extends StatelessWidget {
  const _CircleButton(this.icon, this.onTap, {this.badge = 0});

  final IconData icon;
  final VoidCallback? onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0B0B0B), border: Border.all(color: const Color(0xFF3A3A3A))),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: goldLight, shape: BoxShape.circle),
                  child: Text('$badge', style: ts(8, w: FontWeight.w700, c: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onSearch});

  final VoidCallback? onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Row(
        children: [
          _CircleButton(Icons.arrow_back, onBack),
          Expanded(child: Text('All Categories', textAlign: TextAlign.center, style: ts(14, w: FontWeight.w600))),
          _CircleButton(Icons.shopping_cart_outlined, () => CartScreen.open(context), badge: cart.count),
          const SizedBox(width: 6),
          _CircleButton(Icons.search, onSearch),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.cats, required this.selected, required this.onTap});

  final List<Category> cats;
  final int selected;
  final void Function(int, Category) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (var i = 0; i < cats.length && i < 3; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(i, cats[i]),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: i == selected ? goldLight : const Color(0xFF3A3220), width: 1.5)),
                    child: ClipOval(child: AppImage(cats[i].image)),
                  ),
                  const SizedBox(height: 6),
                  Text(cats[i].name, style: ts(10, w: i == selected ? FontWeight.w600 : FontWeight.w400, c: i == selected ? goldLight : Colors.white)),
                  const SizedBox(height: 4),
                  Container(height: 1.5, color: i == selected ? goldLight : const Color(0xFF2A2A2A)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final done = cart.remaining == 0;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: const Color(0xFF0B0B0B), borderRadius: BorderRadius.circular(10), border: Border.all(color: lineGold)),
          child: Row(
            children: [
              const Icon(Icons.delivery_dining, size: 34, color: goldLight),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!done) Text('Shop for ${rupees(cart.remaining)} more', style: ts(9)),
                    Text(done ? 'Free delivery unlocked' : 'Unlock free\ndelivery', style: ts(11, w: FontWeight.w500, h: 1.2)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(width: 110, child: LinearProgressIndicator(value: cart.progress, minHeight: 4, color: goldLight, backgroundColor: const Color(0xFF3A3A3A))),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!done) Text('${rupees(cart.remaining)} away', style: ts(9, w: FontWeight.w600, c: goldLight)),
                  const SizedBox(height: 10),
                  Text('${rupees(cart.total)} | ${rupees(CartStore.freeDeliveryAt)}', style: ts(9, w: FontWeight.w500)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortFilter extends StatelessWidget {
  const _SortFilter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text.rich(TextSpan(style: ts(10, c: muted), children: [const TextSpan(text: 'Sort by  '), TextSpan(text: 'Relevance ⌄', style: ts(10, c: Colors.white))])),
            ),
          ),
          Container(width: 1, color: const Color(0xFF3A3A3A)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Icon(Icons.tune, size: 14, color: Colors.white), const SizedBox(width: 6), Text('Filter', style: ts(10))],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection(this.c, {required this.onSeeAll});

  final Category c;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(c.name, style: ts(14, w: FontWeight.w600)), Text(_products(c.count), style: ts(9.5, c: muted))],
              ),
            ),
            GestureDetector(onTap: onSeeAll, behavior: HitTestBehavior.opaque, child: Text('See All  ›', style: ts(10, w: FontWeight.w500, c: goldLight))),
          ],
        ),
        const SizedBox(height: 10),
        if (c.subs.isEmpty)
          Text('No subcategories', style: ts(11, c: muted))
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: [for (final s in c.subs) _SubTile(s)],
          ),
      ],
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile(this.s);

  final SubCategory s;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(ProductListScreen.forSubcategory(s)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E1E1E), Color(0xFF0E0E0E)]),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF262626), width: 0.8),
        ),
        child: Column(
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 0), child: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox.expand(child: AppImage(s.image, fit: BoxFit.contain))))),
            const SizedBox(height: 6),
            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, w: FontWeight.w500)),
            const SizedBox(height: 2),
            Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_products(s.count), style: ts(8.5, c: muted))),
          ],
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF0B0B0B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF262626))),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number, size: 30, color: goldLight),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FLAT 25% OFF', style: ts(9.5, w: FontWeight.w700, c: goldLight)),
                    Text('On your first order', style: ts(9.5)),
                    Text.rich(TextSpan(style: ts(9.5), children: [const TextSpan(text: 'Use code '), TextSpan(text: 'WEMATCH25', style: ts(9.5, c: goldLight))])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: goldLight)),
                    child: Text('COPY CODE', style: ts(9, w: FontWeight.w500, c: goldLight)),
                  ),
                  const SizedBox(height: 8),
                  Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.schedule, size: 9, color: muted), const SizedBox(width: 3), Text('Valid till 31 May, 2025', style: ts(7, c: muted))]),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (var i = 0; i < 5; i++) Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: i == 0 ? goldLight : const Color(0xFF4A4A4A)))],
        ),
      ],
    );
  }
}

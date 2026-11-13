import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/common.dart';
import '../widgets/home_parts.dart';
import '../widgets/product_card.dart';
import 'product_list_screen.dart';
import 'search_screen.dart';

const homeBottomInset = 128.0;

Future<(List<Section>, List<Category>)> _loadHome() async {
  final r = await Future.wait([Api.home(), Api.categories()]);
  return (r[0] as List<Section>, r[1] as List<Category>);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _search(BuildContext context) => SearchScreen.open(context);

  void _category(BuildContext context, Category c) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductListScreen(title: c.name, loader: (p, _) => Api.products({'category_id': '${c.id}'}, p))),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureView<(List<Section>, List<Category>)>(
        load: _loadHome,
        builder: (context, data, reload) {
          final (sections, cats) = data;
          final banners = sections.where((s) => s.isCarousel).toList();
          final lists = sections.where((s) => !s.isCarousel).toList();
          final exploreAt = lists.length > 1 ? lists.length - 1 : lists.length;
          const pad = EdgeInsets.symmetric(horizontal: 15);
          const gap = SizedBox(height: 12);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: homeBottomInset),
              children: [
                const Padding(padding: pad, child: HomeHeader()),
                const SizedBox(height: 10),
                Padding(padding: pad, child: HomeSearchBar(onTap: () => _search(context))),
                const SizedBox(height: 10),
                for (final b in banners) Padding(padding: pad, child: BannerCarousel(b.images)),
                const SizedBox(height: 8),
                if (cats.isNotEmpty) Padding(padding: pad, child: CategoryChips(categories: cats, onTap: (c) => _category(context, c))),
                if (cats.isNotEmpty) const SizedBox(height: 10),
                const Padding(padding: pad, child: CouponBanner()),
                gap,
                for (var i = 0; i < lists.length; i++) ...[
                  if (i == exploreAt && cats.isNotEmpty) ...[
                    Padding(
                      padding: pad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader('Explore by Category'),
                          ExploreCategoryRow(categories: cats, onTap: (c) => _category(context, c)),
                        ],
                      ),
                    ),
                    gap,
                  ],
                  _SectionView(lists[i]),
                  if (i == 0)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(15, 12, 15, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SectionHeader('Best Deals'), BestDealsBanner()]),
                    ),
                  gap,
                ],
                if (lists.length <= 1 && cats.isNotEmpty) ...[
                  Padding(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader('Explore by Category'),
                        ExploreCategoryRow(categories: cats, onTap: (c) => _category(context, c)),
                      ],
                    ),
                  ),
                ],
                if (sections.isEmpty) const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: Text('Nothing here yet', style: TextStyle(color: muted)))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView(this.s);

  final Section s;

  void _viewAll(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductListScreen(title: s.name, columns: s.display == 'list' ? s.columns : 2, loader: (p, _) => Api.itemClassProducts(s.id, p)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final withAdd = s.display == 'list';
    final width = (MediaQuery.of(context).size.width - 30 - 3 * 7) / 4;
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(right: 15), child: SectionHeader(s.name, onSeeAll: s.hasMore ? () => _viewAll(context) : null)),
          SizedBox(
            height: withAdd ? 116 : 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 15),
              itemCount: s.products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 7),
              itemBuilder: (_, i) => SizedBox(width: width, child: ProductTile(s.products[i], withAdd: withAdd)),
            ),
          ),
        ],
      ),
    );
  }
}

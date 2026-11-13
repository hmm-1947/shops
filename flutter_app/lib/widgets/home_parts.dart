import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';
import 'common.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 16, color: goldLight),
                    Text('9 minutes', style: ts(15, w: FontWeight.w700)),
                  ],
                ),
                Text('Other · ${session.city.toLowerCase()},kerala ⌄', style: ts(9, c: const Color(0xFFD0D0D0))),
              ],
            ),
          ),
          Container(
            height: 26,
            padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
            decoration: BoxDecoration(color: const Color(0xFF0B0B0B), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2A2A2A))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 24, height: 18, decoration: BoxDecoration(color: goldLight, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                Text('\$0', style: ts(11, w: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ProfileScreen.open(context),
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 16, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search products',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Expanded(child: Text('Search for cosmetics, jewellery and more...', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, c: const Color(0xFF6B6B6B)))),
              const Icon(Icons.center_focus_strong_outlined, size: 20, color: goldLight),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.categories, required this.onTap});

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < categories.length && i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(categories[i]),
              child: Container(
                height: 46,
                decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 22, height: 22, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: AppImage(categories[i].image))),
                    const SizedBox(height: 2),
                    Text('${categories[i].name} ›', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(8, w: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CouponBanner extends StatelessWidget {
  const CouponBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B0B0B), Color(0xFF2A2210)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineGold),
      ),
      child: Row(
        children: [
          Transform.rotate(angle: -0.3, child: const Icon(Icons.confirmation_number, size: 26, color: goldLight)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: ts(11.5, w: FontWeight.w600),
                    children: [
                      const TextSpan(text: 'Flat '),
                      TextSpan(text: '25%', style: ts(13, w: FontWeight.w700, c: goldLight)),
                      const TextSpan(text: ' OFF'),
                    ],
                  ),
                ),
                Text('On Your First Order', style: ts(7.5, c: const Color(0xFFD0D0D0))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), border: Border.all(color: goldLight.withValues(alpha: 0.7))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('WEMATCH25', style: ts(8, w: FontWeight.w600, c: goldLight)),
                const SizedBox(width: 4),
                const Icon(Icons.copy_outlined, size: 9, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: ts(12, w: FontWeight.w600))),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Text('See All →', style: ts(9.5, w: FontWeight.w500, c: goldLight)),
            ),
        ],
      ),
    );
  }
}

class BestDealsBanner extends StatelessWidget {
  const BestDealsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2A0A5E), Color(0xFF7B1FD1), Color(0xFF3A0F7A)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: ts(15, w: FontWeight.w700),
                    children: [
                      const TextSpan(text: 'Up to '),
                      TextSpan(text: '70%', style: ts(18, w: FontWeight.w800, c: goldLight)),
                      const TextSpan(text: ' OFF'),
                    ],
                  ),
                ),
                Text('On Top Brands', style: ts(9, c: const Color(0xFFE0D0F5))),
                const SizedBox(height: 4),
                Text('Shop Now →', style: ts(9, w: FontWeight.w600, c: goldLight)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
            child: const Icon(Icons.local_offer, color: goldLight, size: 26),
          ),
        ],
      ),
    );
  }
}

class ExploreCategoryRow extends StatelessWidget {
  const ExploreCategoryRow({super.key, required this.categories, required this.onTap});

  final List<Category> categories;
  final ValueChanged<Category> onTap;

  static const _tints = [
    [Color(0xFFF4A6C0), Color(0xFFE88BAA)],
    [Color(0xFFF6D77A), Color(0xFFE9A92A)],
    [Color(0xFFD9DDF7), Color(0xFFB9C1EE)],
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < categories.length && i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(categories[i]),
              child: Container(
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _tints[i]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Positioned(right: 0, top: 0, bottom: 0, width: 52, child: AppImage(categories[i].image)),
                    Padding(
                      padding: const EdgeInsets.all(7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categories[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(8.5, w: FontWeight.w700, c: Colors.black)),
                          Text('Shop Now →', style: ts(7, w: FontWeight.w500, c: Colors.black87)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

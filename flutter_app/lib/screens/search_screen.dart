import 'package:flutter/material.dart';
import 'dart:async';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';
import 'product_list_screen.dart';
import 'search_results_screen.dart';

const _trending = ['Lipstick', 'Face Serum', 'Moisturizer', 'Kajal', 'Compact', 'Sunscreen', 'Eyeliner', 'Nail Polish', 'Face Wash', 'Foundation'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<String> _sugg = [];
  List<ProductCardData> _prods = [];
  bool _busy = false;
  bool _failed = false;
  int _seq = 0;

  String get _q => _ctrl.text.trim();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final q = _q;
    if (q.isEmpty) {
      _seq++;
      setState(() {
        _sugg = [];
        _prods = [];
        _busy = false;
        _failed = false;
      });
      return;
    }
    setState(() => _busy = true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final n = ++_seq;
      try {
        final r = await Api.suggest(q);
        if (!mounted || n != _seq) return;
        setState(() {
          _sugg = r.$1;
          _prods = r.$2;
          _busy = false;
          _failed = false;
        });
      } catch (_) {
        if (mounted && n == _seq) {
          setState(() {
            _busy = false;
            _failed = true;
          });
        }
      }
    });
  }

  Widget _results() {
    if (_busy && _sugg.isEmpty && _prods.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_failed) return Center(child: Text('Could not load suggestions', style: ts(13, c: muted)));
    final low = _q.toLowerCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 4, 15, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final s in _sugg)
          InkWell(
            onTap: () => _run(s),
            child: Container(
              height: 46,
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF242424)))),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: muted),
                  const SizedBox(width: 14),
                  Expanded(child: _highlight(s, low)),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _fill(s),
                    child: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.north_west, size: 18, color: muted)),
                  ),
                ],
              ),
            ),
          ),
        if (_prods.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Products', style: ts(15, w: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final p in _prods)
            InkWell(
              onTap: () {
                session.addRecent(_q);
                openProduct(context, p.id);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 56, height: 56, child: AppImage(p.image))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.brand != null) Text(p.brand!, style: ts(10, c: gold)),
                          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13, w: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rupees(p.variant.price), style: ts(13, w: FontWeight.w700, c: gold)),
                        if (p.variant.discount > 0) Text(rupees(p.variant.mrp), style: ts(10, c: muted, d: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (!_busy && _sugg.isEmpty && _prods.isEmpty) Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text('No matches for "$_q"', style: ts(13, c: muted)))),
      ],
    );
  }

  Widget _highlight(String s, String low) {
    final i = s.toLowerCase().indexOf(low);
    if (i < 0 || low.isEmpty) return Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13));
    return Text.rich(
      TextSpan(
        style: ts(13, c: muted),
        children: [
          TextSpan(text: s.substring(0, i)),
          TextSpan(text: s.substring(i, i + low.length), style: ts(13, w: FontWeight.w700)),
          TextSpan(text: s.substring(i + low.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _fill(String q) {
    _ctrl.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
  }

  void _run(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    session.addRecent(t);
    SearchResultsScreen.open(context, t);
  }

  void _category(Category c) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductListScreen(title: c.name, loader: (p, _) => Api.products({'category_id': '${c.id}'}, p))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 15, 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.chevron_left, size: 28)),
                  Expanded(
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A2A))),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 20, color: muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              style: ts(13),
                              cursorColor: orange,
                              decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Search in WEMATCH', hintStyle: ts(13, c: muted)),
                              onSubmitted: _run,
                            ),
                          ),
                          GestureDetector(onTap: () => comingSoon(context), child: const Icon(Icons.mic_none, size: 20, color: orange)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: Text('Cancel', style: ts(13, w: FontWeight.w500, c: orange))),
                ],
              ),
            ),
            Expanded(
              child: _q.isNotEmpty ? _results() : ListView(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  ListenableBuilder(
                    listenable: session,
                    builder: (context, _) {
                      if (session.recents.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Recent searches', style: ts(15, w: FontWeight.w600)),
                              const Spacer(),
                              GestureDetector(onTap: session.clearRecents, child: Text('Clear all', style: ts(11, c: orange))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (final q in List.of(session.recents))
                            InkWell(
                              onTap: () => _run(q),
                              child: Container(
                                height: 46,
                                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF242424)))),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 20, color: muted),
                                    const SizedBox(width: 14),
                                    Expanded(child: Text(q, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13))),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _fill(q),
                                      child: const Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.north_west, size: 18, color: muted)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  Text('Trending searches', style: ts(15, w: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _trending)
                        GestureDetector(
                          onTap: () => _run(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.trending_up, size: 14, color: orange),
                                const SizedBox(width: 6),
                                Text(t, style: ts(11)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text('Explore categories', style: ts(15, w: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 132,
                    child: FutureView<List<Category>>(
                      load: Api.categories,
                      builder: (context, cats, _) => ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _category(cats[i]),
                          child: SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 100, height: 100, child: AppImage(cats[i].image))),
                                const SizedBox(height: 6),
                                Text(cats[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11, w: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import '../widgets/ui.dart';
import 'cart_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen(this.query, {super.key});

  final String query;

  static Future<void> open(BuildContext context, String query) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchResultsScreen(query)));

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final _field = TextEditingController(text: widget.query);
  final _scroll = ScrollController();
  final _items = <ProductCardData>[];
  late String _query = widget.query;
  int _page = 0;
  int _total = 0;
  int _generation = 0;
  bool _loading = false;
  bool _failed = false;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400 && _hasMore && !_loading && !_failed) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _submit(String v) {
    final t = v.trim();
    if (t.isEmpty || t == _query) return;
    session.addRecent(t);
    FocusScope.of(context).unfocus();
    setState(() {
      _generation++;
      _query = t;
      _page = 0;
      _total = 0;
      _items.clear();
      _failed = false;
    });
    _load();
  }

  Future<void> _load() async {
    final gen = _generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final r = await Api.products({'q': _query}, _page + 1);
      if (!mounted || gen != _generation) return;
      setState(() {
        _page++;
        _total = r.total;
        _items.addAll(r.items);
      });
    } catch (_) {
      if (mounted && gen == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
      child: Row(
        children: [
          const BackCircle(),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A2A))),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _field,
                      textInputAction: TextInputAction.search,
                      style: ts(13),
                      cursorColor: orange,
                      decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Search in WEMATCH', hintStyle: ts(13, c: muted)),
                      onSubmitted: _submit,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _field,
                    builder: (context, _) => _field.text.isEmpty
                        ? const SizedBox.shrink()
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _field.clear,
                            child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 18, color: muted)),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ListenableBuilder(
            listenable: cart,
            builder: (context, _) => CircleIcon(Icons.shopping_cart_outlined, onTap: () => CartScreen.open(context), badge: cart.count > 0 ? '${cart.count}' : null),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_items.isEmpty && _loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty && _failed) {
      return Center(child: TextButton(onPressed: _load, child: Text('Could not load. Retry', style: ts(13, c: orange))));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 52, color: muted),
            const SizedBox(height: 12),
            Text('No results for "$_query"', style: ts(15, w: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Try a different keyword', style: ts(12, c: muted)),
          ],
        ),
      );
    }
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 8),
          sliver: SliverToBoxAdapter(
            child: Text.rich(
              TextSpan(
                style: ts(11, c: muted),
                children: [
                  TextSpan(text: '$_total ${_total == 1 ? 'result' : 'results'} for '),
                  TextSpan(text: '"$_query"', style: ts(11, w: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72),
            itemCount: _items.length,
            itemBuilder: (_, i) => ProductCard(_items[i]),
          ),
        ),
        if (_loading || _failed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(child: _failed ? TextButton(onPressed: _load, child: Text('Retry', style: ts(13, c: orange))) : const CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }
}

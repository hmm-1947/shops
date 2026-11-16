import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.title, required this.loader, this.columns = 2, this.searchable = false, this.initialQuery, this.header});

  final String title;
  final int columns;
  final bool searchable;
  final String? initialQuery;
  final Widget? header;

  final Future<PageResult> Function(int page, String query) loader;

  static Route<void> forSubcategory(SubCategory s) => MaterialPageRoute(
        builder: (_) => ProductListScreen(title: s.name, loader: (p, _) => Api.products({'subcategory_id': '${s.id}'}, p)),
      );

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _scroll = ScrollController();
  final _items = <ProductCardData>[];
  Timer? _debounce;
  late String _query = widget.initialQuery ?? '';
  late final _field = TextEditingController(text: widget.initialQuery);
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
      if (_scroll.position.extentAfter < 400 && _hasMore && !_loading) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _field.dispose();
    super.dispose();
  }

  void _reset(String q) {
    _generation++;
    _query = q;
    _page = 0;
    _total = 0;
    _items.clear();
    _failed = false;
    _load();
  }

  Future<void> _load() async {
    final gen = _generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final r = await widget.loader(_page + 1, _query);
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

  @override
  Widget build(BuildContext context) {
    final compact = widget.columns >= 4;
    return Scaffold(
      appBar: AppBar(
        title: widget.searchable
            ? TextField(
                controller: _field, autofocus: widget.initialQuery == null,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(hintText: 'Search for cosmetics, jewellery and more...', border: InputBorder.none),
                onSubmitted: (v) { if (v.trim().isNotEmpty) session.addRecent(v.trim()); }, onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () => _reset(v.trim()));
                },
              )
            : Text(widget.title),
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          if (_items.isEmpty && !_loading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: _failed
                    ? TextButton(onPressed: _load, child: const Text('Could not load. Retry'))
                    : const Text('No products found', style: TextStyle(color: muted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: compact ? 0.55 : 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i < _items.length) return ProductCard(_items[i], compact: compact);
                    return Center(child: _failed ? TextButton(onPressed: _load, child: const Text('Retry')) : const CircularProgressIndicator());
                  },
                  childCount: _items.length + (_loading || _failed ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

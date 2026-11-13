String rupees(int paise) {
  final r = paise ~/ 100;
  final s = r.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  final f = paise % 100;
  return '₹$s${f == 0 ? '' : '.${f.toString().padLeft(2, '0')}'}';
}

String percent(num d) => '${d % 1 == 0 ? d.toInt() : d.toStringAsFixed(1)}%';

class Variant {
  Variant.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        price = j['price'],
        mrp = j['mrp'],
        discount = j['discount'],
        isDefault = j['is_default'] ?? true;

  final int id;
  final String name;
  final int price;
  final int mrp;
  final num discount;
  final bool isDefault;
}

class ProductCardData {
  ProductCardData(this.id, this.name, this.brand, this.image, this.variant);
  ProductCardData.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        brand = j['brand'],
        image = j['image'],
        variant = Variant.fromJson(j['variant']);

  final int id;
  final String name;
  final String? brand;
  final String? image;
  final Variant variant;
}

class PageResult {
  PageResult(this.items, this.total);

  final List<ProductCardData> items;
  final int total;
}

class Section {
  Section.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        display = j['display'],
        columns = j['columns'],
        isCarousel = j['type'] == 'carousel',
        hasMore = j['has_more'] ?? false,
        products = j['type'] == 'carousel' ? [] : (j['items'] as List).map((e) => ProductCardData.fromJson(e)).toList(),
        images = j['type'] == 'carousel' ? (j['items'] as List).map((e) => e['image'] as String).toList() : [];

  final int id;
  final String name;
  final String display;
  final int columns;
  final bool isCarousel;
  final bool hasMore;
  final List<ProductCardData> products;
  final List<String> images;
}

class SubCategory {
  SubCategory.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        image = j['image'],
        count = j['product_count'] ?? 0;

  final int id;
  final String name;
  final String image;
  final int count;
}

class Category {
  Category.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        image = j['image'],
        count = j['product_count'] ?? 0,
        subs = (j['subcategories'] as List).map((e) => SubCategory.fromJson(e)).toList();

  final int id;
  final String name;
  final String image;
  final int count;
  final List<SubCategory> subs;
}

class ProductDetail {
  ProductDetail.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        brand = j['brand'],
        category = j['category'],
        subcategory = j['subcategory'],
        description = j['description'] ?? '',
        specs = (j['specifications'] as List).map((s) => (s['key'] as String, s['value'] as String)).toList(),
        images = (j['images'] as List).cast<String>(),
        variants = (j['variants'] as List).map((v) => Variant.fromJson(v)).toList();

  final int id;
  final String name;
  final String? brand;
  final String category;
  final String subcategory;
  final String description;
  final List<(String, String)> specs;
  final List<String> images;
  final List<Variant> variants;
}

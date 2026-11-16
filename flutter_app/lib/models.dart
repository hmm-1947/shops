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

class Charge {
  Charge.fromJson(Map<String, dynamic> j)
      : name = j['name'],
        value = (j['value'] as num).toDouble(),
        percent = j['type'] == 'percent';

  final String name;
  final double value;
  final bool percent;

  int amountFor(int subtotal) => percent ? (subtotal * value / 100).round() : (value * 100).round();
}

class OrderItem {
  OrderItem.fromJson(Map<String, dynamic> j)
      : name = [j['brand'], j['product_name']].where((e) => e != null && e.toString().isNotEmpty).join(' '),
        variant = j['variant_name'] ?? '',
        image = j['image'],
        price = j['price'],
        qty = j['qty'];

  final String name;
  final String variant;
  final String? image;
  final int price;
  final int qty;
}

class Order {
  Order.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        status = j['status'],
        payment = j['payment_method'],
        createdAt = j['created_at'],
        subtotal = j['subtotal'],
        deliveryFee = j['delivery_fee'],
        chargesTotal = j['charges_total'] ?? 0,
        total = j['total'],
        city = j['city'] ?? '',
        addressLabel = (j['address'] as Map?)?['label'] ?? '',
        addressLines = ((j['address'] as Map?)?['lines'] as List?)?.cast<String>() ?? const [],
        charges = ((j['charges'] as List?) ?? const []).map((e) => (e['name'] as String, e['amount'] as int)).toList(),
        items = ((j['items'] as List?) ?? const []).map((e) => OrderItem.fromJson(e)).toList();

  final int id;
  final String status;
  final String payment;
  final int createdAt;
  final int subtotal;
  final int deliveryFee;
  final int chargesTotal;
  final int total;
  final String city;
  final String addressLabel;
  final List<String> addressLines;
  final List<(String, int)> charges;
  final List<OrderItem> items;

  int get itemCount => items.fold(0, (a, i) => a + i.qty);
}

class DisplayBrand {
  DisplayBrand.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        image = j['image'],
        banner = j['banner'];

  final int id;
  final String name;
  final String image;
  final String? banner;
}

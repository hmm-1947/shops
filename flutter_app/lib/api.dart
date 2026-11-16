import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth.dart';
import 'config.dart';
import 'models.dart';

class Api {
  static final _client = http.Client();

  static Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$apiBase/api/v1$path').replace(queryParameters: query);
    final r = await _client.get(uri).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('Request failed (${r.statusCode})');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static PageResult _page(dynamic j) =>
      PageResult((j['items'] as List).map((e) => ProductCardData.fromJson(e)).toList(), j['total']);

  static Future<List<Section>> home() async => ((await _get('/home'))['sections'] as List).map((e) => Section.fromJson(e)).toList();

  static Future<List<Category>> categories() async => ((await _get('/categories')) as List).map((e) => Category.fromJson(e)).toList();

  static Future<PageResult> products(Map<String, String> filters, int page) async =>
      _page(await _get('/products', {...filters, 'page': '$page', 'limit': '20'}));

  static Future<PageResult> itemClassProducts(int id, int page) async =>
      _page(await _get('/item-classes/$id/products', {'page': '$page', 'limit': '20'}));

  static Future<(List<String>, List<ProductCardData>)> suggest(String q) async {
    final j = await _get('/search/suggest', {'q': q});
    return ((j['suggestions'] as List).cast<String>(), (j['products'] as List).map((e) => ProductCardData.fromJson(e)).toList());
  }

  static Future<ProductDetail> product(int id) async => ProductDetail.fromJson(await _get('/products/$id'));

  static Future<List<Charge>> charges() async => ((await _get('/charges')) as List).map((e) => Charge.fromJson(e)).toList();

  static Future<DisplayBrand?> displayBrand() async {
    final j = await _get('/display-brand');
    return j == null ? null : DisplayBrand.fromJson(j);
  }

  static Future<dynamic> _authGet(String path) async {
    final token = await AuthService.idToken();
    if (token == null) throw Exception('Please sign in to view your orders');
    final r = await _client.get(Uri.parse('$apiBase/api/v1$path'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('Request failed (${r.statusCode})');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  static Future<List<Order>> orders() async => ((await _authGet('/orders')) as List).map((e) => Order.fromJson(e)).toList();

  static Future<Order> order(int id) async => Order.fromJson(await _authGet('/orders/$id'));

  static Future<int> placeOrder({
    required List<(int, int)> items,
    required String method,
    required String city,
    required String phone,
    required String addressLabel,
    required String name,
    required List<String> addressLines,
    double? lat,
    double? lng,
  }) async {
    final token = await AuthService.idToken();
    if (token == null) throw Exception('Please sign in to place an order');
    final r = await _client
        .post(
          Uri.parse('$apiBase/api/v1/orders'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({
            'items': [for (final i in items) {'variant_id': i.$1, 'qty': i.$2}],
            'payment_method': method,
            if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
            'city': city,
            'phone': phone,
            'address': {'label': addressLabel, 'name': name, 'lines': addressLines},
          }),
        )
        .timeout(const Duration(seconds: 20));
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode != 201) throw Exception(j is Map && j['error'] != null ? j['error'].toString() : 'Could not place order');
    return j['id'] as int;
  }
}

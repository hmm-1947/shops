import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class CartLine {
  CartLine(this.product, this.variant, this.qty);

  final ProductCardData product;
  final Variant variant;
  int qty;
}

class CartStore extends ChangeNotifier {
  static const freeDeliveryAt = 14900;
  static const deliveryFee = 2500;

  final lines = <CartLine>[];

  int get count => lines.fold(0, (a, l) => a + l.qty);
  int get total => lines.fold(0, (a, l) => a + l.variant.price * l.qty);
  int get mrpTotal => lines.fold(0, (a, l) => a + l.variant.mrp * l.qty);
  int get savings => mrpTotal - total;
  int get fee => lines.isEmpty || total >= freeDeliveryAt ? 0 : deliveryFee;
  int get payable => total + fee;
  int get remaining => max(0, freeDeliveryAt - total);
  double get progress => min(1.0, total / freeDeliveryAt);

  void add(ProductCardData p, [Variant? v]) {
    final variant = v ?? p.variant;
    final i = lines.indexWhere((l) => l.product.id == p.id && l.variant.id == variant.id);
    if (i >= 0) {
      lines[i].qty++;
    } else {
      lines.add(CartLine(p, variant, 1));
    }
    notifyListeners();
  }

  void setQty(CartLine l, int q) {
    if (q <= 0) {
      lines.remove(l);
    } else {
      l.qty = q;
    }
    notifyListeners();
  }

  void clear() {
    lines.clear();
    notifyListeners();
  }
}

final cart = CartStore();

class Session extends ChangeNotifier {
  String phone = '';
  String city = 'Kochi';
  String name = 'Ranjith ravi';
  String addressLabel = 'Home';
  final addressLines = <String>['4th Cross, 7th Main,', 'Koramangala 4th Block,', 'Bengaluru - 560034,', 'Karnataka'];
  final recents = <String>['Lakme lipstick', 'Maybelline foundation', 'Swiss beauty eyeliner'];

  String get shortName {
    final p = name.trim().split(' ');
    return p.length > 1 && p[1].isNotEmpty ? '${p.first} ${p[1][0].toUpperCase()}' : name;
  }

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  String get maskedPhone => '+91 •••• •••• ${phone.length >= 4 ? phone.substring(phone.length - 4) : '4567'}';

  String email = '';
  bool cityChosen = false;
  bool guest = false;

  String get contact => phone.isNotEmpty ? maskedPhone : email;

  void adopt(String? displayName, String? mail) {
    email = mail ?? '';
    final n = (displayName ?? '').trim();
    if (n.isNotEmpty) {
      name = n;
    } else if (email.contains('@')) {
      name = email.split('@').first;
    }
  }

  void enterAsGuest() {
    guest = true;
    notifyListeners();
  }

  void clearAccount() {
    guest = false;
    email = '';
    phone = '';
    notifyListeners();
  }

  void setCity(String c) {
    city = c;
    notifyListeners();
  }

  void addRecent(String q) {
    recents.remove(q);
    recents.insert(0, q);
    if (recents.length > 5) recents.removeLast();
    notifyListeners();
  }

  void clearRecents() {
    recents.clear();
    notifyListeners();
  }
}

final session = Session();

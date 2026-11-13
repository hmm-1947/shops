import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

const _methods = <(String, String, IconData)>[
  ('upi', 'UPI', Icons.qr_code_2),
  ('card', 'Card', Icons.credit_card),
  ('net', 'Net Banking', Icons.account_balance_outlined),
  ('wallet', 'Wallet', Icons.account_balance_wallet_outlined),
];

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _method = 'upi';
  bool _detailed = false;
  bool _placing = false;

  String get _methodLabel => _methods.firstWhere((m) => m.$1 == _method).$2;

  Future<void> _pay() async {
    if (cart.lines.isEmpty || _placing) return;
    final paid = rupees(cart.payable);
    final via = _methodLabel;
    setState(() => _placing = true);
    try {
      await Api.placeOrder(
        items: [for (final l in cart.lines) (l.variant.id, l.qty)],
        method: _method,
        city: session.city,
        phone: session.phone,
        addressLabel: session.addressLabel,
        name: session.name,
        addressLines: session.addressLines,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _placing = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''), style: ts(13, c: Colors.black))));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _placing = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.check_circle, size: 56, color: orange),
            const SizedBox(height: 12),
            Text('Order placed!', style: ts(18, w: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Arriving in 9 mins', style: ts(12, c: orange)),
            const SizedBox(height: 4),
            Text('Paid $paid via $via', style: ts(11, c: muted)),
            const SizedBox(height: 18),
            OrangeButton('Continue shopping', height: 44, radius: 8, size: 13, glow: false, onTap: () => Navigator.pop(c)),
          ],
        ),
      ),
    );
    cart.clear();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([cart, session]),
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                child: Row(
                  children: [
                    const BackCircle(),
                    Expanded(child: Text('Checkout', textAlign: TextAlign.center, style: ts(15, w: FontWeight.w600))),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(15, 4, 15, 12),
                  children: [
                    const _AddressCard(),
                    const SizedBox(height: 12),
                    const _ItemsCard(),
                    const SizedBox(height: 12),
                    const _SavingsBanner(),
                    const SizedBox(height: 12),
                    _paymentCard(),
                    const SizedBox(height: 12),
                    PanelCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const NumberDot(4),
                              const SizedBox(width: 8),
                              Text('Bill Details', style: ts(12, w: FontWeight.w500)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _detailed = !_detailed),
                                child: Text(_detailed ? 'Hide detailed bill' : 'View detailed bill', style: ts(11, c: orange)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          BillSummary(detailed: _detailed),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _payBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentCard() {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const NumberDot(3), const SizedBox(width: 8), Text('Payment Options', style: ts(12, w: FontWeight.w500))]),
          const SizedBox(height: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _method = 'upi'),
            child: Row(
              children: [
                Text('UPI', style: ts(12, w: FontWeight.w800, c: orange)),
                const SizedBox(width: 12),
                Expanded(child: Text('Pay by any UPI app', style: ts(11, c: const Color(0xFFD0D0D0)))),
                Icon(_method == 'upi' ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 18, color: _method == 'upi' ? orange : muted),
              ],
            ),
          ),
          const Divider(color: Color(0xFF222222), height: 22, thickness: 1),
          Text('More payment options', style: ts(10, c: muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final m in _methods.skip(1))
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _method = m.$1),
                    child: Row(
                      children: [
                        Icon(m.$3, size: 16, color: _method == m.$1 ? orange : muted),
                        const SizedBox(width: 6),
                        Flexible(child: Text(m.$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(10.5, c: _method == m.$1 ? orange : const Color(0xFFD0D0D0)))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payBar() {
    final empty = cart.lines.isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: const BoxDecoration(color: surface, border: Border(top: BorderSide(color: Color(0xFF222222)))),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rupees(cart.payable), style: ts(16, w: FontWeight.w700)),
              Text('View savings ${rupees(cart.savings)}', style: ts(10.5, c: green)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(child: OrangeButton(_placing ? 'Placing...' : 'Pay', height: 46, radius: 8, size: 16, glow: false, onTap: empty || _placing ? null : _pay)),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard();

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NumberDot(1),
              const SizedBox(width: 8),
              Text('Delivery Address', style: ts(12, w: FontWeight.w500)),
              const Spacer(),
              GestureDetector(onTap: () => comingSoon(context), child: Text('Change / Add', style: ts(11, c: orange))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.location_on_outlined, size: 20, color: orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(session.addressLabel, style: ts(11, w: FontWeight.w500)),
                        const SizedBox(width: 6),
                        _Tag('Default'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(session.shortName, style: ts(11, w: FontWeight.w500)),
                        const SizedBox(width: 6),
                        if (session.phone.isNotEmpty) _Tag(session.maskedPhone),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final l in session.addressLines) Text(l, style: ts(13, h: 1.7)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delivery_dining_outlined, size: 22, color: orange),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(style: ts(14, w: FontWeight.w500), children: [const TextSpan(text: 'Delivery in '), TextSpan(text: '9 mins', style: ts(14, w: FontWeight.w600, c: orange))])),
                  Text('Shipment of ${cart.count} items', style: ts(11, c: const Color(0xFFD0D0D0))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(color: lineGold, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: ts(8, c: gold)),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard();

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const NumberDot(2),
              const SizedBox(width: 8),
              Text('Items in your order ( ${cart.count} )', style: ts(12, w: FontWeight.w500)),
              const Spacer(),
              GestureDetector(onTap: () => Navigator.of(context).maybePop(), child: Text('View all items', style: ts(11, c: orange))),
            ],
          ),
          const SizedBox(height: 12),
          for (final l in cart.lines) _Line(l, key: ObjectKey(l)),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.line, {super.key});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final v = line.variant;
    final saved = (v.mrp - v.price) * line.qty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(width: 38, height: 50, child: AppImage(line.product.image))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line.product.brand ?? ''} ${line.product.name}'.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(10.5)),
                const SizedBox(height: 4),
                OffChip(v.discount),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(rupees(v.price), style: ts(11, w: FontWeight.w700)),
                    if (v.mrp > v.price) ...[const SizedBox(width: 6), Text(rupees(v.mrp), style: ts(9, c: muted, d: TextDecoration.lineThrough))],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QtyStepper(line),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => cart.setQty(line, 0),
                    child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.delete_outline, size: 16, color: muted)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(rupees(v.price * line.qty), style: ts(12, w: FontWeight.w700)),
              if (saved > 0) Text('You save ${rupees(saved)}', style: ts(8.5, c: green)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingsBanner extends StatelessWidget {
  const _SavingsBanner();

  @override
  Widget build(BuildContext context) {
    final done = cart.remaining == 0;
    return GestureDetector(
      onTap: done ? null : () => Navigator.of(context).maybePop(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF201A0E), borderRadius: BorderRadius.circular(10), border: Border.all(color: lineGold)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.bolt, color: Colors.black, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cart.savings > 0)
                    Text.rich(
                      TextSpan(
                        style: ts(11),
                        children: [
                          const TextSpan(text: 'Yay! You are saving '),
                          TextSpan(text: rupees(cart.savings), style: ts(14, w: FontWeight.w700, c: green)),
                          const TextSpan(text: ' on this order'),
                        ],
                      ),
                    ),
                  Text(
                    done ? 'Free delivery unlocked on this order' : 'Add items worth ${rupees(cart.remaining)} more to unlock free delivery',
                    style: ts(13, c: const Color(0xFFBDBDBD), h: 1.3),
                  ),
                ],
              ),
            ),
            if (!done) const Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}

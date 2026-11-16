import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

enum OrderFilter {
  all('All', <String>{}),
  processing('Processing', {'placed', 'confirmed', 'packed'}),
  transit('In Transit', {'out_for_delivery'}),
  delivered('Delivered', {'delivered'}),
  cancelled('Cancelled', {'cancelled'});

  const OrderFilter(this.label, this.statuses);

  final String label;
  final Set<String> statuses;

  bool matches(String status) => statuses.isEmpty || statuses.contains(status);
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _flow = ['placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered'];
const _statusLabels = {
  'placed': 'Order placed',
  'confirmed': 'Confirmed',
  'packed': 'Packed',
  'out_for_delivery': 'Out for delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};
const _payLabels = {'upi': 'UPI', 'card': 'Card', 'net': 'Net Banking', 'wallet': 'Wallet', 'cod': 'Cash on delivery'};
const _red = Color(0xFFFF5252);

String _when(int t) {
  final d = DateTime.fromMillisecondsSinceEpoch(t * 1000);
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${d.day} ${_months[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

Color _statusColor(String s) => switch (s) {
      'delivered' => green,
      'cancelled' => _red,
      'out_for_delivery' => goldLight,
      _ => orange,
    };

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(_statusLabels[status] ?? status, style: ts(10.5, w: FontWeight.w600, c: c)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow(this.item);

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 46, height: 46, child: AppImage(item.image))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(12, w: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${item.variant.isEmpty ? '' : '${item.variant}  '}x ${item.qty}', style: ts(10.5, c: muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(rupees(item.price * item.qty), style: ts(12, w: FontWeight.w500)),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.filter = OrderFilter.all});

  final OrderFilter filter;

  static Future<void> open(BuildContext context, {OrderFilter filter = OrderFilter.all}) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdersScreen(filter: filter)));

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late OrderFilter _filter = widget.filter;

  Widget _chips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          for (final f in OrderFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _filter == f ? orange : chipColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f.label, style: ts(11.5, w: FontWeight.w500, c: _filter == f ? Colors.black : Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(bool none) {
    return ListView(
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.shopping_bag_outlined, size: 54, color: muted),
        const SizedBox(height: 12),
        Center(child: Text(none ? 'No orders yet' : 'No ${_filter.label.toLowerCase()} orders', style: ts(14, w: FontWeight.w600))),
        const SizedBox(height: 4),
        Center(child: Text(none ? 'Your orders will show up here' : 'Try another filter', style: ts(11, c: muted))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
              child: Row(
                children: [
                  const BackCircle(),
                  Expanded(child: Text('My Orders', textAlign: TextAlign.center, style: ts(15, w: FontWeight.w600))),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            _chips(),
            const SizedBox(height: 12),
            Expanded(
              child: FutureView<List<Order>>(
                load: Api.orders,
                builder: (context, all, reload) {
                  final list = all.where((o) => _filter.matches(o.status)).toList();
                  return RefreshIndicator(
                    onRefresh: reload,
                    child: list.isEmpty
                        ? _empty(all.isEmpty)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _OrderCard(list[i], onBack: reload),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order, {required this.onBack});

  final Order order;
  final Future<void> Function() onBack;

  @override
  Widget build(BuildContext context) {
    final shown = order.items.take(3).toList();
    final more = order.items.length - shown.length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await OrderDetailScreen.open(context, order.id);
        await onBack();
      },
      child: PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order.id}', style: ts(13.5, w: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_when(order.createdAt), style: ts(10.5, c: muted)),
                    ],
                  ),
                ),
                _StatusPill(order.status),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF222222), height: 1, thickness: 1),
            for (final i in shown) _ItemRow(i),
            if (more > 0) Padding(padding: const EdgeInsets.only(top: 2, bottom: 4), child: Text('+ $more more item${more == 1 ? '' : 's'}', style: ts(10.5, c: orange))),
            const Divider(color: Color(0xFF222222), height: 14, thickness: 1),
            Row(
              children: [
                Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}  |  ${_payLabels[order.payment] ?? order.payment}', style: ts(10.5, c: muted)),
                const Spacer(),
                Text(rupees(order.total), style: ts(14, w: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen(this.id, {super.key});

  final int id;

  static Future<void> open(BuildContext context, int id) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(id)));

  Widget _tracker(Order o) {
    if (o.status == 'cancelled') {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, color: _red, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text('This order was cancelled', style: ts(12.5, w: FontWeight.w500, c: _red))),
        ],
      );
    }
    final current = _flow.indexOf(o.status);
    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= current ? (i == current ? _statusColor(o.status) : green) : chipColor,
                    ),
                    child: i < current || o.status == 'delivered' ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
                  ),
                  if (i < _flow.length - 1) Container(width: 2, height: 22, color: i < current ? green : chipColor),
                ],
              ),
              const SizedBox(width: 12),
              Text(_statusLabels[_flow[i]]!, style: ts(12, w: i == current ? FontWeight.w600 : FontWeight.w400, c: i <= current ? Colors.white : muted)),
            ],
          ),
      ],
    );
  }

  Widget _line(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: ts(bold ? 13 : 11.5, w: bold ? FontWeight.w600 : FontWeight.w400, c: bold ? Colors.white : const Color(0xFFBDBDBD))),
          const Spacer(),
          Text(value, style: ts(bold ? 14 : 11.5, w: bold ? FontWeight.w700 : FontWeight.w500, c: color ?? Colors.white)),
        ],
      ),
    );
  }

  Widget _body(Order o) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
      children: [
        PanelCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${o.id}', style: ts(15, w: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_when(o.createdAt), style: ts(10.5, c: muted)),
                  ],
                ),
              ),
              _StatusPill(o.status),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PanelCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order status', style: ts(13, w: FontWeight.w600)),
              const SizedBox(height: 14),
              _tracker(o),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items (${o.itemCount})', style: ts(13, w: FontWeight.w600)),
              const SizedBox(height: 6),
              for (final i in o.items) _ItemRow(i),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bill details', style: ts(13, w: FontWeight.w600)),
              const SizedBox(height: 8),
              _line('Item total', rupees(o.subtotal)),
              _line('Delivery fee', o.deliveryFee == 0 ? 'FREE' : rupees(o.deliveryFee), color: o.deliveryFee == 0 ? green : null),
              for (final c in o.charges) _line(c.$1, rupees(c.$2)),
              const Divider(color: Color(0xFF222222), height: 14, thickness: 1),
              _line('Total', rupees(o.total), bold: true),
              const SizedBox(height: 4),
              _line('Payment', _payLabels[o.payment] ?? o.payment),
            ],
          ),
        ),
        if (o.addressLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery address', style: ts(13, w: FontWeight.w600)),
                const SizedBox(height: 8),
                if (o.addressLabel.isNotEmpty) Text(o.addressLabel, style: ts(11.5, w: FontWeight.w500, c: orange)),
                const SizedBox(height: 2),
                Text(o.addressLines.join(', '), style: ts(11.5, c: const Color(0xFFBDBDBD), h: 1.4)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
              child: Row(
                children: [
                  const BackCircle(),
                  Expanded(child: Text('Order details', textAlign: TextAlign.center, style: ts(15, w: FontWeight.w600))),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: FutureView<Order>(
                load: () => Api.order(id),
                builder: (context, o, reload) => RefreshIndicator(onRefresh: reload, child: _body(o)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

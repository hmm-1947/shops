import 'package:flutter/material.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

class CircleIcon extends StatelessWidget {
  const CircleIcon(this.icon, {super.key, this.onTap, this.size = 36, this.fill, this.color = Colors.white, this.border = true, this.badge});

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? fill;
  final Color color;
  final bool border;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: border ? Border.all(color: const Color(0xFF4A4A4A)) : null),
              child: Icon(icon, size: size * 0.5, color: color),
            ),
            if (badge != null)
              Positioned(
                right: -3,
                top: -4,
                child: Container(
                  width: 15,
                  height: 15,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                  child: Text(badge!, style: ts(8, w: FontWeight.w700, c: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BackCircle extends StatelessWidget {
  const BackCircle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => CircleIcon(Icons.arrow_back, onTap: onTap ?? () => Navigator.of(context).maybePop());
}

class OrangeButton extends StatelessWidget {
  const OrangeButton(
    this.label, {
    super.key,
    this.onTap,
    this.height = 50,
    this.radius = 25,
    this.arrow = false,
    this.arrowEnd = false,
    this.fill = orange,
    this.fg = Colors.black,
    this.size = 16,
    this.icon,
    this.glow = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final bool arrow;
  final bool arrowEnd;
  final Color fill;
  final Color fg;
  final double size;
  final IconData? icon;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: glow ? [BoxShadow(color: fill.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))] : null),
      child: Material(
        color: fill,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
                    Text(label, style: ts(size, w: FontWeight.w600, c: fg)),
                    if (arrow) ...[const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 20, color: fg)],
                  ],
                ),
                if (arrowEnd) Positioned(right: 20, child: Icon(Icons.arrow_forward, size: 20, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 24)});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: IntrinsicHeight(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
        ),
      ),
    );
  }
}

class DashedBorder extends StatelessWidget {
  const DashedBorder({super.key, required this.child, this.color = gold, this.radius = 8, this.padding = EdgeInsets.zero});

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashPainter(color, radius), child: Padding(padding: padding, child: child));
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.radius != radius;
}

class DeliveryProgress extends StatelessWidget {
  const DeliveryProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final left = cart.remaining;
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: lineGold)),
          child: Row(
            children: [
              const Icon(Icons.delivery_dining_outlined, color: orange, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop for ${rupees(left)} more', style: ts(10)),
                    Text(left == 0 ? 'Free delivery unlocked' : 'Unlock free delivery', style: ts(14, w: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: cart.progress, minHeight: 4, color: orange, backgroundColor: const Color(0xFF2A2A2A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${rupees(left)} away', style: ts(12, w: FontWeight.w500, c: orange)),
                  const SizedBox(height: 6),
                  Text('₹0  |  ${rupees(CartStore.freeDeliveryAt)}', style: ts(10, c: muted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper(this.line, {super.key, this.height = 26});

  final CartLine line;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: orange.withValues(alpha: 0.6))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => cart.setQty(line, line.qty - 1),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.remove, size: 14, color: orange)),
          ),
          Text('${line.qty}', style: ts(11)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => cart.setQty(line, line.qty + 1),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.add, size: 14, color: orange)),
          ),
        ],
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  const OfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF222222))),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: Color(0xFFFF5C8A), shape: BoxShape.circle),
            child: const Icon(Icons.percent, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Extra 10% off on all orders', style: ts(12, w: FontWeight.w500)),
                Text('Use code: WEMATCH25', style: ts(10, c: const Color(0xFFBDBDBD))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFFF5C8A))),
            child: Text('Apply', style: ts(11, c: const Color(0xFFFF5C8A))),
          ),
        ],
      ),
    );
  }
}

class NumberDot extends StatelessWidget {
  const NumberDot(this.n, {super.key});

  final int n;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
        child: Text('$n', style: ts(8, w: FontWeight.w700, c: Colors.black)),
      );
}

class PanelCard extends StatelessWidget {
  const PanelCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF222222))),
      child: child,
    );
  }
}

class OffChip extends StatelessWidget {
  const OffChip(this.discount, {super.key});

  final num discount;

  @override
  Widget build(BuildContext context) {
    if (discount <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: greenBg, borderRadius: BorderRadius.circular(3)),
      child: Text('${percent(discount)} OFF', style: ts(8, w: FontWeight.w600, c: green)),
    );
  }
}

class BillSummary extends StatelessWidget {
  const BillSummary({super.key, this.detailed = false, this.bigTotal = false});

  final bool detailed;
  final bool bigTotal;

  Widget _row(String label, Widget value, {bool info = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: ts(11, c: const Color(0xFFBDBDBD))),
          if (info) ...[const SizedBox(width: 4), const Icon(Icons.info_outline, size: 12, color: muted)],
          const Spacer(),
          value,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Column(
        children: [
          if (detailed) ...[
            _row('Item MRP total', Text(rupees(cart.mrpTotal), style: ts(11))),
            _row('Product discount', Text('-${rupees(cart.savings)}', style: ts(11, c: green))),
          ],
          _row('Item Total', Text(rupees(cart.total), style: ts(11, w: FontWeight.w500))),
          for (final c in cart.appliedCharges)
            _row(c.name, Text(rupees(c.amountFor(cart.total)), style: ts(11, w: FontWeight.w500))),
          _row(
            'Delivery Fee',
            cart.fee == 0
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rupees(CartStore.deliveryFee), style: ts(11, c: muted, d: TextDecoration.lineThrough)),
                      const SizedBox(width: 6),
                      Text('FREE', style: ts(11, w: FontWeight.w600, c: green)),
                    ],
                  )
                : Text(rupees(cart.fee), style: ts(11, w: FontWeight.w500)),
            info: true,
          ),
          const Divider(color: Color(0xFF222222), height: 14, thickness: 1),
          Row(
            children: [
              Text('To Pay', style: ts(bigTotal ? 14 : 13, w: FontWeight.w600)),
              const Spacer(),
              Text(rupees(cart.payable), style: ts(bigTotal ? 20 : 13, w: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

void comingSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(duration: const Duration(milliseconds: 1200), content: Text('Coming soon', style: ts(13, c: Colors.black))));
}

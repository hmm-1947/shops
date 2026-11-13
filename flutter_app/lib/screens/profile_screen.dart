import 'package:flutter/material.dart';
import '../auth.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'address_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              Stack(
                children: [
                  const Positioned(left: 0, top: 0, child: BackCircle()),
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                          child: Text(session.initial, style: ts(32, w: FontWeight.w600, c: Colors.black)),
                        ),
                        const SizedBox(height: 10),
                        Text(session.name, style: ts(18, w: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(session.contact, style: ts(12, c: muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                decoration: BoxDecoration(color: const Color(0xFF201A0E), borderRadius: BorderRadius.circular(10), border: Border.all(color: lineGold)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get free delivery &\nextra savings', style: ts(14, w: FontWeight.w600, h: 1.3)),
                          const SizedBox(height: 4),
                          Text('With WeMatch Pass', style: ts(10, c: muted)),
                        ],
                      ),
                    ),
                    SizedBox(width: 112, child: OrangeButton('Join pass', height: 38, radius: 6, size: 12.5, glow: false, onTap: () => comingSoon(context))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PanelCard(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('My Orders', style: ts(15, w: FontWeight.w600)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => comingSoon(context),
                          child: Text('View all orders  ›', style: ts(11, c: orange, d: TextDecoration.underline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF222222))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _OrderTile(Icons.shopping_bag_outlined, 'All Orders', () => comingSoon(context)),
                          _OrderTile(Icons.shopping_bag_outlined, 'Processing', () => comingSoon(context)),
                          _OrderTile(Icons.delivery_dining_outlined, 'In Transit', () => comingSoon(context)),
                          _OrderTile(Icons.check_circle_outline, 'Delivered', () => comingSoon(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PanelCard(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Savings', style: ts(15, w: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _Row(const Icon(Icons.confirmation_number_outlined, color: orange, size: 24), 'Coupons', trailing: '6 Available', trailingColor: orange, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.local_offer_outlined, color: orange, size: 24), 'Offers', trailing: '12 Available', trailingColor: orange, onTap: () => comingSoon(context)),
                    _Row(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(4)),
                        child: Text('pass', style: ts(10, w: FontWeight.w700, c: Colors.black)),
                      ),
                      'WeMatch Pass',
                      trailing: 'View benefits',
                      trailingColor: orange,
                      onTap: () => comingSoon(context),
                    ),
                    _Row(const Icon(Icons.account_balance_wallet_outlined, color: orange, size: 24), 'Referral Rewards', trailing: '₹150', trailingColor: green, last: true, onTap: () => comingSoon(context)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              PanelCard(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: ts(14, w: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _Row(const Icon(Icons.location_on_outlined, size: 20), 'Address', small: true, trailing: session.hasAddress ? session.addressLabel : 'Add', trailingColor: orange, onTap: () => AddressScreen.open(context)),
                    _Row(const Icon(Icons.credit_card, size: 20), 'Payment Methods', small: true, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.account_balance_wallet_outlined, size: 20), 'Credits', small: true, trailing: '₹0', trailingColor: green, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.notifications_none, size: 20), 'Notification Preferences', small: true, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.help_outline, size: 20), 'Help & Support', small: true, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.shield_outlined, size: 20), 'Privacy Policy', small: true, onTap: () => comingSoon(context)),
                    _Row(const Icon(Icons.description_outlined, size: 20), 'Terms & Conditions', small: true, last: true, onTap: () => comingSoon(context)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    AuthService.signOut();
                  },
                  child: Text('Log out', style: ts(14, w: FontWeight.w500, c: const Color(0xFFFF2D2D), d: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(color: chipColor, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: orange),
          ),
          const SizedBox(height: 6),
          Text(label, style: ts(10.5)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.leading, this.label, {this.trailing, this.trailingColor = orange, this.last = false, this.small = false, this.onTap});

  final Widget leading;
  final String label;
  final String? trailing;
  final Color trailingColor;
  final bool last;
  final bool small;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: small ? 46 : 54,
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF222222)))),
        child: Row(
          children: [
            SizedBox(width: small ? 26 : 44, child: Align(alignment: Alignment.centerLeft, child: leading)),
            SizedBox(width: small ? 12 : 8),
            Expanded(child: Text(label, style: ts(small ? 13 : 14, w: small ? FontWeight.w400 : FontWeight.w500))),
            if (trailing != null) Text(trailing!, style: ts(small ? 11.5 : 13, w: FontWeight.w500, c: trailingColor)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

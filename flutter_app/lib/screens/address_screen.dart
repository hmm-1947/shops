import 'package:flutter/material.dart';
import '../auth.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressScreen()));

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  static const _labels = ['Home', 'Work', 'Other'];

  late String _label = _labels.contains(session.addressLabel) ? session.addressLabel : 'Home';
  late final _name = TextEditingController(text: session.nameEdited || session.hasAddress ? session.name : '');
  late final _phone = TextEditingController(text: session.phone);
  late final _address = TextEditingController(text: session.addressLines.join('\n'));
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _say(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m, style: ts(13, c: Colors.black))));
  }

  Future<void> _save() async {
    final lines = _address.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_name.text.trim().isEmpty) return _say('Enter your name');
    if (phone.length != 10) return _say('Enter a 10 digit phone number');
    if (lines.isEmpty) return _say('Enter your delivery address');
    if (lines.length > 6 || lines.any((l) => l.length > 120)) return _say('Address is too long');
    setState(() => _saving = true);
    await AuthService.saveAddress(label: _label, name: _name.text.trim(), phone: phone, lines: lines);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: ts(13, c: muted),
        filled: true,
        fillColor: surface,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orange)),
      );

  Widget _label_(String t) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(t, style: ts(12, c: const Color(0xFFD0D0D0))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
              child: Row(children: [const BackCircle(), const SizedBox(width: 14), Text('Delivery Address', style: ts(18, w: FontWeight.w600))]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(15, 4, 15, 16),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _label_('Save as'),
                  Row(
                    children: [
                      for (final l in _labels)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l),
                            selected: _label == l,
                            selectedColor: gold,
                            showCheckmark: false,
                            labelStyle: ts(12, c: _label == l ? Colors.black : Colors.white),
                            onSelected: (_) => setState(() => _label = l),
                          ),
                        ),
                    ],
                  ),
                  _label_('Full name'),
                  TextField(controller: _name, maxLength: 80, textCapitalization: TextCapitalization.words, style: ts(13), cursorColor: orange, decoration: _dec('Your name')),
                  _label_('Phone number'),
                  TextField(controller: _phone, maxLength: 10, keyboardType: TextInputType.phone, style: ts(13), cursorColor: orange, decoration: _dec('10 digit mobile number')),
                  _label_('Address (one line per row)'),
                  TextField(
                    controller: _address,
                    minLines: 4,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: ts(13),
                    cursorColor: orange,
                    decoration: _dec('House / flat no, street\nArea, landmark\nCity - pincode'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 12),
              child: OrangeButton(_saving ? 'Saving...' : 'Save address', height: 50, radius: 26, onTap: _saving ? () {} : _save),
            ),
          ],
        ),
      ),
    );
  }
}

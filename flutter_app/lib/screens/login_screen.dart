import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../auth.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  void _say(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m, style: ts(13, c: Colors.black))));
  }

  Future<void> _google() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AuthService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (!const ['canceled', 'web-context-canceled', 'cancelled-popup-request'].contains(e.code)) _say(e.message ?? e.code);
    } catch (e) {
      _say(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', width: 250),
                const SizedBox(height: 18),
                Text.rich(TextSpan(style: ts(26, w: FontWeight.w700), children: [const TextSpan(text: 'Welcome to '), TextSpan(text: 'WEMATCH', style: ts(26, w: FontWeight.w700, c: goldLight))])),
                const SizedBox(height: 8),
                Text('Login or sign up to continue', style: ts(15)),
                const SizedBox(height: 28),
                Container(
                  height: 50,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: lineGold)),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Text('+91', style: ts(15, w: FontWeight.w500)),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                      const SizedBox(width: 14),
                      Container(width: 1, height: 24, color: gold),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          style: ts(14),
                          cursorColor: orange,
                          decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: 'Enter mobile number', hintStyle: ts(14, c: muted)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                OrangeButton('Continue', height: 50, radius: 26, arrow: true, onTap: () => comingSoon(context)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Color(0xFF3A3A3A), height: 1)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('or', style: ts(13, c: const Color(0xFFD0D0D0)))),
                    const Expanded(child: Divider(color: Color(0xFF3A3A3A), height: 1)),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Social(onTap: _google, busy: _busy, child: Text('G', style: ts(22, w: FontWeight.w700, c: const Color(0xFF4285F4)))),
                    const SizedBox(width: 18),
                    _Social(onTap: () => comingSoon(context), child: const Icon(Icons.apple, size: 26)),
                    const SizedBox(width: 18),
                    _Social(onTap: () => comingSoon(context), child: const Icon(Icons.chat, size: 22, color: Color(0xFF25D366))),
                  ],
                ),
                const SizedBox(height: 36),
                Text('By continuing, you agree to our', style: ts(12)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: ts(12),
                    children: [
                      TextSpan(text: 'Terms & Conditions', style: ts(12, c: goldLight)),
                      const TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: ts(12, c: goldLight)),
                    ],
                  ),
                ),
                if (kDebugMode && !AuthService.ready) ...[
                  const SizedBox(height: 20),
                  GestureDetector(onTap: session.enterAsGuest, child: Text('Skip login (debug only)', style: ts(11, c: muted, d: TextDecoration.underline))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Social extends StatelessWidget {
  const _Social({required this.onTap, required this.child, this.busy = false});

  final VoidCallback onTap;
  final Widget child;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF111111), border: Border.all(color: const Color(0xFF2A2A2A))),
        child: busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: orange)) : child,
      ),
    );
  }
}

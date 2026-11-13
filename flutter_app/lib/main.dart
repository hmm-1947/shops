import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth.dart';
import 'screens/categories_screen.dart';
import 'screens/home_screen.dart';
import 'screens/location_screen.dart';
import 'screens/login_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/dock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await AuthService.init();
  runApp(const WeMatchApp());
}


class WeMatchApp extends StatelessWidget {
  const WeMatchApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(title: 'WeMatch', debugShowCheckedModeBanner: false, theme: appTheme, home: const AuthGate());
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.changes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return Scaffold(body: Center(child: Image.asset('assets/logo_mark.png', width: 140)));
        final user = snap.data;
        return ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            if (user == null && !session.guest) return const LoginScreen();
            if (user != null) session.adopt(user.displayName, user.email);
            return session.cityChosen ? const Shell() : const LocationScreen();
          },
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [const HomeScreen(), CategoriesScreen(onBack: () => setState(() => _tab = 0)), const SafeArea(child: Center(child: Text('Cafe coming soon', style: TextStyle(color: muted))))],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: SafeArea(top: false, minimum: const EdgeInsets.only(bottom: 10), child: BottomDock(index: _tab, onTap: (i) => setState(() => _tab = i))),
          ),
        ],
      ),
    );
  }
}

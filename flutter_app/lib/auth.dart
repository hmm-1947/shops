import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';

class AuthService {
  static bool ready = false;
  static bool _gsiReady = false;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      ready = true;
    } catch (_) {
      ready = false;
    }
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('city');
    if (city != null) {
      session.city = city;
      session.cityChosen = true;
    }
    session.loadAddress(prefs.getString('addr_label'), prefs.getString('addr_name'), prefs.getString('addr_phone'), prefs.getStringList('addr_lines'));
  }

  static Stream<User?> get changes => ready ? FirebaseAuth.instance.authStateChanges() : Stream<User?>.value(null);

  static User? get user => ready ? FirebaseAuth.instance.currentUser : null;

  static Future<void> signInWithGoogle() async {
    if (!ready) throw Exception('Firebase is not configured yet. Add google-services.json and rebuild.');
    final gsi = GoogleSignIn.instance;
    if (!_gsiReady) {
      await gsi.initialize(serverClientId: '152535738030-maq55sjrqlhsn6bfjd4h7dg1k0u1i36u.apps.googleusercontent.com');
      _gsiReady = true;
    }
    final account = await gsi.authenticate();
    final credential = GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    if (ready) await FirebaseAuth.instance.signOut();
    if (_gsiReady) await GoogleSignIn.instance.signOut().catchError((_) {});
    cartReset();
    session.clearAccount();
    session.clearAddress();
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['addr_label', 'addr_name', 'addr_phone', 'addr_lines']) {
      await prefs.remove(k);
    }
  }

  static Future<void> saveAddress({required String label, required String name, required String phone, required List<String> lines}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('addr_label', label);
    await prefs.setString('addr_name', name);
    await prefs.setString('addr_phone', phone);
    await prefs.setStringList('addr_lines', lines);
    session.setAddress(label: label, fullName: name, phoneNo: phone, lines: lines);
  }

  static Future<String?> idToken() async => user?.getIdToken();

  static Future<void> saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('city', city);
    session.cityChosen = true;
    session.setCity(city);
  }
}

void cartReset() => cart.clear();

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';

class AuthService {
  static bool ready = false;

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
  }

  static Stream<User?> get changes => ready ? FirebaseAuth.instance.authStateChanges() : Stream<User?>.value(null);

  static User? get user => ready ? FirebaseAuth.instance.currentUser : null;

  static Future<void> signInWithGoogle() async {
    if (!ready) throw Exception('Firebase is not configured yet. Add google-services.json and rebuild.');
    final provider = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    await FirebaseAuth.instance.signInWithProvider(provider);
  }

  static Future<void> signOut() async {
    if (ready) await FirebaseAuth.instance.signOut();
    cartReset();
    session.clearAccount();
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

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../auth.dart';
import '../theme.dart';
import '../widgets/ui.dart';

const _cities = <(String, double, double)>[
  ('Kochi', 9.9312, 76.2673),
  ('Trivandrum', 8.5241, 76.9366),
  ('Calicut', 11.2588, 75.7804),
  ('Thrissur', 10.5276, 76.2144),
];

const _maxKm = 150.0;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocationScreen()));

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _useLocation = true;
  bool _busy = false;
  String? _city;
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _finish() {
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _say(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m, style: ts(13, c: Colors.black))));
  }

  Future<void> _detect() async {
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _say('Turn on location services, or choose your city');
        setState(() => _useLocation = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _say('Location permission denied. Please choose your city');
        setState(() => _useLocation = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)));
      String? best;
      var bestKm = double.infinity;
      for (final c in _cities) {
        final km = Geolocator.distanceBetween(pos.latitude, pos.longitude, c.$2, c.$3) / 1000;
        if (km < bestKm) {
          bestKm = km;
          best = c.$1;
        }
      }
      if (best == null || bestKm > _maxKm) {
        _say('We are not in your area yet. Please choose a city');
        setState(() => _useLocation = false);
        return;
      }
      await AuthService.saveCity(best);
      _finish();
    } catch (_) {
      _say('Could not get your location. Please choose your city');
      if (mounted) setState(() => _useLocation = false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    if (_busy) return;
    if (_useLocation) return _detect();
    final typed = _custom.text.trim();
    final c = typed.isNotEmpty ? typed : _city;
    if (c == null) return _say('Enter or select a city to continue');
    await AuthService.saveCity(c);
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  if (Navigator.of(context).canPop()) const Align(alignment: Alignment.centerLeft, child: BackCircle()),
                  Center(child: Image.asset('assets/logo.png', width: 150)),
                  const SizedBox(height: 14),
                  Text('Select Your', style: ts(30, w: FontWeight.w700, h: 1.15)),
                  Text('Location', style: ts(30, w: FontWeight.w700, c: goldLight, h: 1.15)),
                  const SizedBox(height: 6),
                  Text('Find the best matches near you', style: ts(13, c: const Color(0xFFD0D0D0))),
                  const SizedBox(height: 28),
                  PanelCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: goldLight, size: 30),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Use Current Location', style: ts(13, w: FontWeight.w600)),
                              Text('Get personalised matches nearby', style: ts(9.5, c: muted)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _useLocation,
                          onChanged: (v) => setState(() {
                            _useLocation = v;
                            if (v) _city = null;
                          }),
                          activeThumbColor: Colors.white,
                          activeTrackColor: gold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text('Type Your City / Area', style: ts(11, c: const Color(0xFFD0D0D0)))),
                  const SizedBox(height: 10),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: _custom.text.trim().isNotEmpty ? orange : const Color(0xFF222222))),
                    child: Row(
                      children: [
                        const Icon(Icons.edit_location_alt_outlined, color: goldLight, size: 22),
                        const SizedBox(width: 18),
                        Expanded(
                          child: TextField(
                            controller: _custom,
                            maxLength: 60,
                            style: ts(13),
                            cursorColor: orange,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(border: InputBorder.none, isCollapsed: true, counterText: '', hintText: 'e.g. Edappally, Kochi', hintStyle: ts(13, c: muted)),
                            onChanged: (v) => setState(() {
                              if (v.trim().isNotEmpty) {
                                _useLocation = false;
                                _city = null;
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(child: Text('Or Choose Your City', style: ts(11, c: const Color(0xFFD0D0D0)))),
                  const SizedBox(height: 12),
                  for (final c in _cities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _custom.clear();
                          _city = c.$1;
                          _useLocation = false;
                        }),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _city == c.$1 ? orange : const Color(0xFF222222)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.temple_hindu_outlined, color: goldLight, size: 22),
                              const SizedBox(width: 18),
                              Expanded(child: Text(c.$1, style: ts(13))),
                              Icon(_city == c.$1 ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 22, color: _city == c.$1 ? orange : muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrangeButton(_busy ? 'Please wait...' : (_useLocation ? 'Allow Location Access' : 'Continue'), height: 50, radius: 26, arrowEnd: true, onTap: _continue),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _useLocation = false),
                    child: Padding(padding: const EdgeInsets.all(6), child: Text('Choose Manually', style: ts(12, c: orange))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

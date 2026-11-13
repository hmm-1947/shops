import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const bg = Color(0xFF191919);
const surface = Color(0xFF0B0B0B);
const cardColor = surface;
const chipColor = Color(0xFF242426);
const orange = Color(0xFFF5A623);
const gold = Color(0xFFE9B93F);
const goldLight = Color(0xFFF4C443);
const muted = Color(0xFF9B9BA5);
const green = Color(0xFF4ADE80);
const greenBg = Color(0xFF12301F);
const lineGold = Color(0xFF5A4520);
const beige = Color(0xFFE2D9D5);

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color c = Colors.white, double? h, TextDecoration? d}) =>
    GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c, height: h, decoration: d, decorationColor: c);

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: const ColorScheme.dark(primary: orange, onPrimary: Colors.black, surface: surface),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  appBarTheme: const AppBarTheme(backgroundColor: bg, surfaceTintColor: Colors.transparent),
  dividerColor: Colors.transparent,
  snackBarTheme: const SnackBarThemeData(backgroundColor: orange, contentTextStyle: TextStyle(color: Colors.black), behavior: SnackBarBehavior.floating),
);

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appTheme = ThemeData(
  primarySwatch: Colors.blueGrey,
  scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Nền sáng nhẹ
  textTheme: GoogleFonts.montserratTextTheme().apply(
    bodyColor: Color(0xFF2C3E50),
    displayColor: Color(0xFF2C3E50),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF3498DB),
    foregroundColor: Colors.white,
    elevation: 4,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  buttonTheme: const ButtonThemeData(
    buttonColor: Color(0xFF3498DB),
    textTheme: ButtonTextTheme.primary,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF3498DB),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
    ),
  ),
);
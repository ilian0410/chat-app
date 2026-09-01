import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFF74B9FF);
  static const Color accentColor = Color(0xFFFD79A8);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF2D3436);
  static const Color textSecondaryColor = Color(0xFF636E72);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color errorColor = Color(0xFFE17055);
  static const Color successColor = Color(0xFF55E170);
  static ThemeData lightTheme = ThemeData(


    useMaterial3: true,
    colorScheme: ColorScheme.light(

      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: cardColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: textPrimaryColor,
      onSurface: textPrimaryColor,
      error: errorColor,
    ),

textTheme: GoogleFonts.poppinsTextTheme().copyWith(
headlineLarge: GoogleFonts.poppins().copyWith(
  fontSize: 32,
  fontWeight: FontWeight.bold,
  color: textPrimaryColor,
),
headlineMedium: GoogleFonts.poppins().copyWith(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: textPrimaryColor,  
),
headlineSmall: GoogleFonts.poppins().copyWith(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  color: textPrimaryColor,
),
bodyLarge: GoogleFonts.poppins().copyWith(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: textSecondaryColor,
),
bodyMedium: GoogleFonts.poppins().copyWith(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: textSecondaryColor,
),
bodySmall: GoogleFonts.poppins().copyWith(
  fontSize: 12,
  fontWeight: FontWeight.normal,
  color: textSecondaryColor,
),
),
appBarTheme: AppBarTheme(
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true,
  titleTextStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
  iconTheme: const IconThemeData(
    color: textPrimaryColor ,
  ),  
),
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    textStyle:  GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),

),
  cardTheme: CardThemeData(
    elevation: 0,
color: cardColor,
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: BorderSide(
    color: borderColor,
    width: 1,
  ),
),  


  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cardColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
       
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: primaryColor,
        width: 2,
      ),

    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: errorColor,
        
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  );
}

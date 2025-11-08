import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const KitoDemoApp());
}

class KitoDemoApp extends StatelessWidget {
  const KitoDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kito Animation Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF8B4513), // Reddish-brown
          secondary: Color(0xFFD2691E), // Cardboard brown
          surface: Color(0xFFF5F5F5), // Light gray
          background: Color(0xFFEFEFEF),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1A1A1A), // Near black
          onBackground: Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.ibmPlexMonoTextTheme(),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB8621B), // Lighter reddish-brown
          secondary: Color(0xFFD2691E), // Cardboard brown
          surface: Color(0xFF2A2A2A), // Dark gray
          background: Color(0xFF1A1A1A), // Near black
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFE0E0E0), // Light gray text
          onBackground: Color(0xFFE0E0E0),
        ),
        textTheme: GoogleFonts.ibmPlexMonoTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eqron/screens/home_screen.dart';

class EqronApp extends StatelessWidget {
  const EqronApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EQron',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00FF88),
          surface: Color(0xFF1A1A2E),
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

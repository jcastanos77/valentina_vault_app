import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Login.dart';
import 'FinanceHomePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valentina´s Vault',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        primaryColor: const Color(0xFF2C3E50),
        fontFamily: 'SF Pro Display',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2C3E50),
          secondary: Color(0xFF3498DB),
          surface: Colors.white,
          background: Color(0xFFF8F9FA),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF2C3E50),
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");
    final createdAtMillis = prefs.getString("timeE");

    if (token != null && createdAtMillis != null) {
      final createdAt = DateTime.parse(createdAtMillis);
      final now = DateTime.now();
      final difference = now.difference(createdAt).inHours;

      if (difference < 24) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHomePage()),
        );
        return;
      } else {
        await prefs.clear();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Login.dart';
import 'package:valentinas_vault/Tabs/Goal_page.dart';
import 'package:valentinas_vault/Tabs/Home_page.dart';
import 'package:valentinas_vault/Tabs/Stats_page.dart';
import 'package:valentinas_vault/Tabs/Trasaction_page.dart';

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({Key? key}) : super(key: key);

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    TrasactionPage(),
    GoalPage(),
    StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Mi Billetera',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF1e3c72)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
              );
            },
            tooltip: "Cerrar sesión",
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: pages[_currentIndex],
          ),

          // 🔹 Bottom bar con animación cuando se abre el teclado
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            left: 20,
            right: 20,
            bottom: isKeyboardOpen ? -100 : 18, // 👈 se esconde con teclado
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isKeyboardOpen ? 0 : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(Icons.home_rounded, 'Inicio', 0, isDark),
                        _buildNavItem(Icons.add_circle_rounded, 'Agregar', 1, isDark),
                        _buildNavItem(Icons.flag_rounded, 'Metas', 2, isDark),
                        _buildNavItem(Icons.bar_chart_rounded, 'Stats', 3, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
      isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F7FB),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
              ? Colors.tealAccent.withOpacity(0.15)
              : const Color(0xFF667eea).withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.black54 : Colors.white,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

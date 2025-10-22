import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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


    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Mi Billetera 💸',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        // 🔹 Esta parte es clave
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark, // Android
          statusBarBrightness:
          isDark ? Brightness.dark : Brightness.light, // iOS
        ),
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: pages[_currentIndex],
          ),

          // 🔹 Custom Bottom Bar flotante
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
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
              color: isSelected
                  ? Colors.black
                  : Colors.white
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.black
                    : Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }
}

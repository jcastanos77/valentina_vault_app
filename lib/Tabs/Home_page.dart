import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Utils/CategoryProgressCard.dart';
import 'package:valentinas_vault/Utils/ui_helpers.dart';

import '../model/SavingsGoal.dart';
import '../model/Transaction.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  final _apiService = ApiService();
  final _authService = AuthService();
  Map<String, dynamic>? summary;
  Map<String, dynamic>? expansePorcentage;

  double _totalIncome = 0;
  double _accumulatedSavings = 0;
  int _basicosPercent = 0;
  int _ahorroPercent = 0;
  int _lujosPercent = 0;
  List<Transaction> _transactions = [];
  SavingsGoal _savingsGoal = SavingsGoal();

  Map<String, double> get budgets => {
    'basicos': _totalIncome * 0.5,
    'ahorro': _totalIncome * 0.3,
    'lujos': _totalIncome * 0.2,
  };

  Map<String, double> get spentByCategory {
    Map<String, double> spent = {'basicos': 0, 'ahorro': 0, 'lujos': 0};
    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        spent[transaction.category] = (spent[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return spent;
  }

  double get currentSavings {
    double ahorroDisponible = budgets['ahorro'] ?? 0;
    double ahorroGastado = spentByCategory['ahorro'] ?? 0;
    return ahorroDisponible - ahorroGastado;
  }

  Future<void> _loadSummary() async {
    String? token = await _authService.getToken();
    try {
      final data = await _apiService.getMonthlySummary(token!);
      setState(() {
        summary = data;
      });
      _loadRules();
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _loadPorcentages() async {
    String? token = await _authService.getToken();
    try {
      final data = await _apiService.getExpensesPorcentages(token!);
      setState(() {
        expansePorcentage = data;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _loadSavings() async {
    String? token = await _authService.getToken();
    try {
      final data = await ApiService().getTotalSavings(token!);
      setState(() {
        _accumulatedSavings = data['totalAhorro'];
      });
      _loadRules();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _loadRules() async {
    String? token = await _authService.getToken();
    try {
      final data = await ApiService().getRules(token!);
      setState(() {
        _ahorroPercent = data['ahorroPercent'];
        _lujosPercent = data['lujosPercent'];
        _basicosPercent = data['basicosPercent'];
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("ahorroPercent", _ahorroPercent);
      await prefs.setInt("lujosPercent", _lujosPercent);
      await prefs.setInt("basicosPercent", _basicosPercent);
      _loadPorcentages();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadSummary();
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Buenos días ☀️';
    if (hour >= 12 && hour < 19) return 'Buenas tardes 🌤️';
    return 'Buenas noches 🌙';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saludo y fecha
                    Text(
                      getGreeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tu resumen financiero',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              color: Colors.white.withOpacity(0.15),
                              child: Text(
                                '${getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Tarjeta principal con blur
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Balance total',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(Icons.wallet_rounded, color: Colors.white70),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\$${formatNumber(summary?['totalIncome']?.toDouble() ?? 0.0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildProgressBar(
                            basicos: 50,
                            ahorro: 30,
                            lujos: 20,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Categorías',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjetas de categorías
                    CategoryProgressCard('basicos', expansePorcentage?['basicosAssigned'].toDouble() ?? 0.0, expansePorcentage?['basicosSpent']?.toDouble() ?? 0.0, expansePorcentage?['basicosPercentageSpent']?.toDouble() ?? 0.0),
                    const SizedBox(height: 16),
                    CategoryProgressCard('ahorro', expansePorcentage?['ahorroAssigned']?.toDouble() ?? 0.0, expansePorcentage?['ahorroSpent']?.toDouble() ?? 0.0, expansePorcentage?['ahorroPercentageSpent']?.toDouble() ?? 0.0),
                    const SizedBox(height: 16),
                    CategoryProgressCard('lujos', expansePorcentage?['lujosAssigned']?.toDouble() ?? 0.0, expansePorcentage?['lujosSpent']?.toDouble() ?? 0.0, expansePorcentage?['lujosPercentageSpent']?.toDouble() ?? 0.0),
                    const SizedBox(height: 75),
                if (_savingsGoal.name.isNotEmpty && _savingsGoal.amount > 0) ...[
                  _buildGoalCard(),
                  SizedBox(height: 75),
                ]

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildProgressBar({required int basicos, required int ahorro, required int lujos}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.3),
          ),
          child: Row(
            children: [
              Expanded(flex: basicos, child: Container(color: Colors.blueAccent)),
              Expanded(flex: ahorro, child: Container(color: Colors.greenAccent)),
              Expanded(flex: lujos, child: Container(color: Colors.purpleAccent)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Básicos $basicos%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Ahorro $ahorro%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Lujo $lujos%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(
                _savingsGoal.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.45,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Meta: \$${_savingsGoal.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

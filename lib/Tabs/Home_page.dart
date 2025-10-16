import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Utils/CategoryProgressCard.dart';
import 'package:valentinas_vault/Utils/ui_helpers.dart';

import '../Utils/ModernCard.dart';
import '../model/SavingsGoal.dart';
import '../model/Transaction.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{
  final _apiService = ApiService();
  final _authService = AuthService();
  Map<String, dynamic>? summary;
  Map<String, dynamic>? expansePorcentage;
  late AnimationController _animationController;
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Buenos días 👋',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tu resumen financiero',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tarjeta de balance principal con glassmorphism
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balance Total',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        '\$${formatNumber(summary?['totalIncome']?.toDouble() ?? 0.0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Regla personalizada',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _basicosPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: _ahorroPercent,
                              child: Container(color: Colors.greenAccent),
                            ),
                            Expanded(
                              flex: _lujosPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Básicos ${_basicosPercent}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'Ahorro ${_ahorroPercent}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'Lujo ${_lujosPercent}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Mostrar ahorros acumulados si existen
          if (_accumulatedSavings > 0) ...[
            const SizedBox(height: 16),
            ModernCard(
              color: const Color(0xFF27AE60).withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ahorros Acumulados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ' \$${formatNumber(_accumulatedSavings?.toDouble() ?? 0.0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Categorías con diseño moderno
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          CategoryProgressCard('basicos', expansePorcentage?['basicosAssigned'].toDouble() ?? 0.0, expansePorcentage?['basicosSpent']?.toDouble() ?? 0.0, expansePorcentage?['basicosPercentageSpent']?.toDouble() ?? 0.0),
          CategoryProgressCard('ahorro', expansePorcentage?['ahorroAssigned']?.toDouble() ?? 0.0, expansePorcentage?['ahorroSpent']?.toDouble() ?? 0.0, expansePorcentage?['ahorroPercentageSpent']?.toDouble() ?? 0.0),
          CategoryProgressCard('lujos', expansePorcentage?['lujosAssigned']?.toDouble() ?? 0.0, expansePorcentage?['lujosSpent']?.toDouble() ?? 0.0, expansePorcentage?['lujosPercentageSpent']?.toDouble() ?? 0.0),

          // Meta de ahorro moderna
          if (_savingsGoal.name.isNotEmpty && _savingsGoal.amount > 0) ...[
            const SizedBox(height: 16),
            const Text(
              'Tu Meta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
           ModernCard(
              color: const Color(0xFFF39C12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _savingsGoal.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Meta: \$${_savingsGoal.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: currentSavings > 0
                          ? (currentSavings / _savingsGoal.amount).clamp(0.0, 1.0)
                          : 0.0,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${currentSavings > 0 ? ((currentSavings / _savingsGoal.amount) * 100).toStringAsFixed(1) : "0.0"}% completado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import '../model/Transaction.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  double _totalIncome = 0;
  List<Transaction> _transactions = [];

  // 💰 Cálculo de gastos por categoría
  Map<String, double> get spentByCategory {
    Map<String, double> spent = {'basicos': 0, 'ahorro': 0, 'lujos': 0};
    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        spent[transaction.category] =
            (spent[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return spent;
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final token = await AuthService().getToken();
    final data = await ApiService().getMonthlyStats(token!);

    setState(() {
      _totalIncome = data["totalIncome"] ?? 0;
      _transactions = (data["transactions"] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalExpenses = _transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);

    const Color darkBlue = Color(0xFF1e3c72);
    const Color lightBlue = Color(0xFF2a5298);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),

            // 📊 Resumen general
            Row(
              children: [
                Expanded(
                  child: _GlassCard(
                    gradient: const LinearGradient(
                      colors: [darkBlue, lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.trending_up,
                            size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('Ingresos',
                            style: TextStyle(color: Colors.white70)),
                        Text(
                          '\$${_totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GlassCard(
                    gradient: const LinearGradient(
                      colors: [darkBlue, lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            size: 32, color: Colors.white),
                        const SizedBox(height: 8),
                        const Text('Gastos',
                            style: TextStyle(color: Colors.white70)),
                        Text(
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📈 Distribución por categoría
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Gastos',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  ...spentByCategory.entries.map((entry) {
                    String category = entry.key;
                    double amount = entry.value;
                    double percentage =
                    totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(category.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B))),
                              Text(
                                '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor:
                              Colors.white.withOpacity(0.4),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  lightBlue),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 💸 Últimas transacciones
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Últimas Transacciones',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
                  if (_transactions.isEmpty)
                    const Center(
                      child: Text("Sin transacciones recientes 💤",
                          style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                      _transactions.length > 8 ? 8 : _transactions.length,
                      itemBuilder: (context, index) {
                        Transaction transaction =
                        _transactions.reversed.toList()[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: lightBlue,
                              child: Icon(
                                transaction.category == 'basicos'
                                    ? Icons.home
                                    : transaction.category == 'ahorro'
                                    ? Icons.savings
                                    : Icons.shopping_bag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              transaction.description,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B)),
                            ),
                            subtitle: Text(
                              '${transaction.category.toUpperCase()} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Text(
                              (transaction.type == 'income' ? '+' : '-') +
                                  '\$${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: transaction.type == 'income'
                                    ? lightBlue
                                    : Colors.redAccent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 65,)
          ],
        ),
      ),
    );
  }
}

/// 🌫️ Card con efecto glass + soporte para gradiente
class _GlassCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  const _GlassCard({required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient ??
                LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.4)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

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

  Map<String, double> get spentByCategory {
    Map<String, double> spent = {'basicos': 0, 'ahorro': 0, 'lujos': 0};
    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        spent[transaction.category] = (spent[transaction.category] ?? 0) + transaction.amount;
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
      print(data);
      _totalIncome = data["totalIncome"] ?? 0;
      final categoryData = Map<String, dynamic>.from(data["categories"]);
      _transactions = (data["transactions"] as List)
          .map((t) => Transaction.fromJson(t))
          .toList();

      // puedes recalcular los gastos si quieres
    });
  }


  @override
  Widget build(BuildContext context) {
    double totalExpenses = _transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Resumen general
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.trending_up, size: 32, color: Colors.green),
                        const SizedBox(height: 8),
                        Text('Ingresos', style: TextStyle(color: Colors.grey[600])),
                        Text(
                          '\$${_totalIncome.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 32, color: Colors.red),
                        const SizedBox(height: 8),
                        Text('Gastos Totales', style: TextStyle(color: Colors.grey[600])),
                        Text(
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Distribución por categoría
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribución de Gastos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...spentByCategory.entries.map((entry) {
                    String category = entry.key;
                    double amount = entry.value;
                    double percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0;
                    Color color = category == 'basicos' ? Colors.green :
                    (category == 'ahorro' ? Colors.blue : Colors.purple);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Últimas transacciones
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Últimas Transacciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _transactions.length > 10 ? 10 : _transactions.length,
                      itemBuilder: (context, index) {
                        Transaction transaction = _transactions.reversed.toList()[index];
                        Color categoryColor = transaction.category == 'basicos' ? Colors.green :
                        (transaction.category == 'ahorro' ? Colors.blue : Colors.purple);

                        return Card(
                          color: Colors.grey[50],
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: categoryColor,
                              child: Icon(
                                transaction.category == 'basicos' ? Icons.home :
                                (transaction.category == 'ahorro' ? Icons.savings : Icons.shopping_bag),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              transaction.description,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${transaction.category.toUpperCase()} • ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                            ),
                            trailing: Text(
                              '\$${transaction.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

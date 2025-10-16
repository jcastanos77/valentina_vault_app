import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Utils/showSnackBar.dart';
import '../model/SavingsGoal.dart';
import '../model/Transaction.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();

  SavingsGoal _savingsGoal = SavingsGoal();
  double _totalIncome = 0;
  List<Transaction> _transactions = [];

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

  void _updateGoal() {
    setState(() {
      _savingsGoal.name = _goalNameController.text;
      _savingsGoal.amount = double.tryParse(_goalAmountController.text) ?? 0;
    });
    showSnackBar('Meta actualizada 🎯', const Color(0xFFE67E22), context);
  }

  double get currentSavings {
    double ahorroDisponible = budgets['ahorro'] ?? 0;
    double ahorroGastado = spentByCategory['ahorro'] ?? 0;
    return ahorroDisponible - ahorroGastado;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meta de Ahorro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _goalNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la meta',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Vacaciones, Auto nuevo, etc.',
                    ),
                    onChanged: (value) => _savingsGoal.name = value,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _goalAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad objetivo',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) => _savingsGoal.amount = double.tryParse(value) ?? 0,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _updateGoal,
                      icon: const Icon(Icons.flag),
                      label: const Text('Actualizar Meta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Mostrar progreso si hay meta configurada
          if (_savingsGoal.name.isNotEmpty && _savingsGoal.amount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _savingsGoal.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progreso:', style: TextStyle(color: Colors.white)),
                      Text(
                        '\$${(currentSavings > 0 ? currentSavings : 0).toStringAsFixed(2)} / \$${_savingsGoal.amount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: currentSavings > 0 ? (currentSavings / _savingsGoal.amount) : 0,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${currentSavings > 0 ? ((currentSavings / _savingsGoal.amount) * 100).toStringAsFixed(1) : "0.0"}% completado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

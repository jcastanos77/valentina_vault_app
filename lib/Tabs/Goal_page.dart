import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Utils/showSnackBar.dart';
import '../model/SavingsGoal.dart';
import '../model/Transaction.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();

  List<SavingsGoal> _goals = []; // ✅ ahora almacenamos varias metas
  double _totalIncome = 0;
  List<Transaction> _transactions = [];
  bool isLoading = false;
  final _apiService = ApiService();
  final _authService = AuthService();

  Map<String, double> get budgets => {
    'basicos': _totalIncome * 0.5,
    'ahorro': _totalIncome * 0.3,
    'lujos': _totalIncome * 0.2,
  };

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

  double get currentSavings {
    double ahorroDisponible = budgets['ahorro'] ?? 0;
    double ahorroGastado = spentByCategory['ahorro'] ?? 0;
    return ahorroDisponible - ahorroGastado;
  }

  Future<void> _addGoal() async {
    final amountText = _goalAmountController.text.trim();
    final name = _goalNameController.text.trim();

    if (amountText.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor ingresa monto y nombre")),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(",", ""));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Monto inválido")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      String? token = await _authService.getToken();
      await _apiService.addGoal(name, amount, token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Meta agregada ✅")),
      );

      _goalAmountController.clear();
      _goalNameController.clear();

      await _getGoals(); // ✅ actualiza lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getGoals() async {
    try {
      String? token = await _authService.getToken();
      final data = await _apiService.getGoals(token!);

      setState(() {
        _goals = data
            .map<SavingsGoal>((goal) => SavingsGoal(
          name: goal["name"] ?? "",
          amount: (goal["targetAmount"] ?? 0).toDouble(),
          progress: (goal["progress"] ?? 0).toDouble(),
          id: goal["id"],
        ))
            .toList();
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _getGoals();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metas de Ahorro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 🧾 Formulario para agregar nueva meta
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
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _goalAmountController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad objetivo',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _addGoal,
                      icon: const Icon(Icons.flag),
                      label: const Text('Agregar Meta'),
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

          // 📋 Lista de metas
          if (_goals.isEmpty)
            const Center(child: Text("No tienes metas registradas aún 💤")),
          if (_goals.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                final progreso = currentSavings / (goal.amount > 0 ? goal.amount : 1);
                final porcentaje =
                (progreso.clamp(0, 1) * 100).toStringAsFixed(1);

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                        goal.name,
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
                          const Text('Progreso:',
                              style: TextStyle(color: Colors.white)),
                          Text(
                            '\$${currentSavings.toStringAsFixed(2)} / \$${goal.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progreso.clamp(0, 1),
                        backgroundColor: Colors.white30,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          '$porcentaje% completado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

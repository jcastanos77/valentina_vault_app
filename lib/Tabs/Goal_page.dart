import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<SavingsGoal> _goals = [];
  double _totalIncome = 0;
  List<Transaction> _transactions = [];
  bool isLoading = false;
  final _apiService = ApiService();
  final _authService = AuthService();

  Map<String, double> get budgets =>
      {
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

      await _getGoals();
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
            .map<SavingsGoal>((goal) =>
            SavingsGoal(
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
    final Color primary = const Color(0xFF667EEA);

    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          currentFocus.focusedChild!.unfocus();
        }
      },
      child: Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Metas de Ahorro',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🧾 Formulario glass
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _goalNameController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre de la meta',
                                  hintText: 'Ej: Vacaciones, Auto nuevo, etc.',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _goalAmountController,
                                decoration: InputDecoration(
                                  labelText: 'Cantidad objetivo',
                                  prefixText: '\$',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true),
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
                                  icon: const Icon(Icons.flag_rounded,
                                      color: Colors.white),
                                  label: const Text(
                                    'Agregar Meta',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 📋 Lista de metas (sin Expanded ni ListView)
                    if (_goals.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            "No tienes metas registradas aún 💤",
                            style:
                            TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _goals.map((goal) {
                          final progreso =
                              currentSavings / (goal.amount > 0 ? goal.amount : 1);
                          final porcentaje =
                          (progreso.clamp(0, 1) * 100).toStringAsFixed(1);

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.name,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Progreso:',
                                            style: TextStyle(color: Colors.grey)),
                                        Text(
                                          '\$${currentSavings.toStringAsFixed(2)} / \$${goal.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progreso.clamp(0, 1),
                                        minHeight: 8,
                                        backgroundColor:
                                        Colors.white.withOpacity(0.4),
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(primary),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Center(
                                      child: Text(
                                        '$porcentaje% completado',
                                        style: TextStyle(
                                          color: primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 65),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Utils/CurrencyInputFormatter.dart';
import '../Utils/ui_helpers.dart';
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
              currentAmount: (goal["currentAmount"] ?? 0).toDouble(),
              id: goal["id"],
            ))
            .toList();
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _deleteGoal(String id) async {
    try {
      String? token = await _authService.getToken();
      final data = await _apiService.deleteSavingsGoal(token!, id);

      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Se elimino la meta")),
        );
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
  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF667EEA);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 85.0),
        child: FloatingActionButton(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () {
            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.35),
              builder: (context) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12), // vidrio suave
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Nueva Meta de Ahorro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                // Close button
                                InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6.0),
                                    child: Icon(Icons.close, color: Colors.white70, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Nombre
                            TextFormField(
                              controller: _goalNameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ej: Vacaciones, Auto nuevo, etc.',
                                hintStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Monto
                            TextFormField(
                              controller: _goalAmountController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                hintText: 'Cantidad objetivo',
                                hintStyle: TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [CurrencyInputFormatter()],
                            ),
                            const SizedBox(height: 16),

                            // Buttons row
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.white.withOpacity(0.12)),
                                      backgroundColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      // limpiar campos si quiere el usuario
                                      _goalNameController.clear();
                                      _goalAmountController.clear();
                                    },
                                    child: const Text(
                                      'Limpiar',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                      // Cerrar dialogo antes de hacer la petición (mejor UX)
                                      Navigator.of(context).pop();
                                      await _addGoal();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF667EEA), // primary
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                        : const Text(
                                      'Agregar Meta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),

        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            currentFocus.focusedChild!.unfocus();
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metas de Ahorro',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_goals.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          "No tienes metas registradas aún 💤",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _goals.map((goal) {
                        final progreso =
                            goal.currentAmount / (goal.amount > 0 ? goal.amount : 1);
                        final porcentaje =
                        (progreso.clamp(0, 1) * 100).toStringAsFixed(1);

                        return Dismissible(
                          key: ValueKey(goal.name),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (direction) async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: Text(
                                    '¿Quieres eliminar "${goal.name}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                            );
                            if (result == true) {
                              await _deleteGoal(goal.id);
                            }
                            return result;
                          },
                          onDismissed: (_) {
                            setState(() {
                              _goals.remove(goal);
                            });
                          },
                          child: ClipRRect(
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                            style: TextStyle(
                                                color: Colors.black54)),
                                        Text(
                                          '\$${formatNumber(goal.currentAmount)} / \$${formatNumber(goal.amount)}',
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progreso.clamp(0, 1),
                                        minHeight: 8,
                                        backgroundColor:
                                        Colors.white.withOpacity(0.4),
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            primary),
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
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 65),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

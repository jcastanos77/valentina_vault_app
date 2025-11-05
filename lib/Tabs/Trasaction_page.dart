import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Utils/showSnackBar.dart';
import 'package:valentinas_vault/components/FullScreen_loading.dart';

import '../Utils/CurrencyInputFormatter.dart';
import '../model/SavingsGoal.dart';
import '../model/Transaction.dart';
import '../services/ApiService.dart';
import '../services/Auth.dart';

class TrasactionPage extends StatefulWidget {
  const TrasactionPage({super.key});

  @override
  State<TrasactionPage> createState() => _TrasactionPageState();
}

class _TrasactionPageState extends State<TrasactionPage> with SingleTickerProviderStateMixin{
  bool isLoading = false;
  final _apiService = ApiService();
  final _authService = AuthService();
  final _directSavingsController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _basicosPercent = 0;
  int _ahorroPercent = 0;
  int _lujosPercent = 0;

  String _selectedGoalId = "0";
  late AnimationController _animationController;
  List<SavingsGoal> _goals = [];
  List<Transaction> _transactions = [];
  String _selectedTransactionType = 'expense';
  String _selectedCategory = 'basicos';

  Map<String, double> get spentByCategory {
    Map<String, double> spent = {'basicos': 0, 'ahorro': 0, 'lujos': 0};
    for (var transaction in _transactions) {
      if (transaction.type == 'expense') {
        spent[transaction.category] = (spent[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return spent;
  }

  Future<void> _addDirectSavings() async{
    final amountText = _directSavingsController.text.trim();
    print(amountText);
    final amount = double.tryParse(amountText.replaceAll(",", ""));
    print(amount);
    if (amount == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Monto inválido")),
      );

      return;
    }

    try {
      String? token = await _authService.getToken();
      await _apiService.addDirectSaving(token!, amount, _selectedGoalId);

      _animationController.forward().then((_) => _animationController.reset());
      _amountController.clear();
      _descriptionController.clear();

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
    _directSavingsController.clear();
    Navigator.of(context).pop();
  }

  Future<void> _submitIncome() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullScreenLoading(),
    );
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor ingresa monto y descripción")),
      );
      Navigator.pop(context);
      return;
    }
    final amount = double.tryParse(amountText.replaceAll(",", ""));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Monto inválido")),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => isLoading = true);

    try {
      String? token = await _authService.getToken();
      await _apiService.addIncome(amount, description, token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ingreso agregado ✅")),
      );

      _animationController.forward().then((_) => _animationController.reset());
      _amountController.clear();
      _descriptionController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      Navigator.pop(context);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitExpense() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FullScreenLoading(),
    );
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor ingresa monto y descripción")),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll(",", ""));
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Monto inválido")),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => isLoading = true);

    try {
      String? token = await _authService.getToken();
      await _apiService.addExpense(amount, description, _selectedCategory,token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ingreso agregado ✅")),
      );

      _animationController.forward().then((_) => _animationController.reset());
      _amountController.clear();
      _descriptionController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      Navigator.pop(context);
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
              remainingAmount: (goal["remainingAmount"] ?? 0).toDouble(),
              id: goal["id"],
            ))
            .toList();
      });

    } catch (e) {
      print("Error: $e");
    }
  }


  // Mostrar diálogo de transferencia mensual
  Future <void>_setPorcentages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ahorroPercent = prefs.getInt("ahorroPercent")!;
      _lujosPercent = prefs.getInt("lujosPercent")!;
      _basicosPercent = prefs.getInt("basicosPercent")!;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _setPorcentages();
    _getGoals();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.focusedChild!.unfocus();
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1e3c72),
              Color(0xFF2a5298),],
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
                  'Nueva transacción',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                _glassCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de transacción',
                          style: TextStyle(color: Colors.white70, fontSize: 15)),
                      const SizedBox(height: 8),
                      _dropdownField(
                        value: _selectedTransactionType,
                        items: const [
                          DropdownMenuItem(value: 'income', child: Text('💰 Ingreso')),
                          DropdownMenuItem(value: 'expense', child: Text('💳 Gasto')),
                        ],
                        onChanged: (v) => setState(() => _selectedTransactionType = v!),
                      ),
                      if (_selectedTransactionType == 'expense') ...[
                        const SizedBox(height: 16),
                        const Text('Categoría',
                            style: TextStyle(color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 8),
                        _dropdownField(
                          value: _selectedCategory,
                          items: [
                            DropdownMenuItem(value: 'basicos', child: Text('🏠 Necesidades ($_basicosPercent%)')),
                            DropdownMenuItem(value: 'ahorro', child: Text('💰 Ahorros ($_ahorroPercent%)')),
                            DropdownMenuItem(value: 'lujos', child: Text('🛍️ Lujos ($_lujosPercent%)')),
                          ],
                          onChanged: (v) => setState(() => _selectedCategory = v!),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _textField(_amountController, 'Cantidad', prefix: '\$ '),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            hintText: 'Ej: Supermercado, Salario...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixStyle: const TextStyle(color: Colors.white),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _selectedTransactionType == 'expense'
                            ? _submitExpense
                            : _submitIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withOpacity(0.6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 22),
                            SizedBox(width: 8),
                            Text('Agregar Transacción',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              _glassCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aportación a tu meta 💰',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 📍 Dropdown de metas (ya cargadas desde el backend)
                    if (_goals.isNotEmpty) ...[
                      const Text(
                        'Selecciona una meta:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            value: _goals.any((g) => g.id == _selectedGoalId) ? _selectedGoalId : null,
                            hint: const Text(
                              'Selecciona una meta',
                              style: TextStyle(color: Colors.white70),
                            ),
                            items: _goals.map((goal) {
                              return DropdownMenuItem<String>(
                                value: goal.id,
                                child: Text(
                                  goal.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGoalId = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'No tienes metas registradas 💤',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 💵 Campo de texto + botón
                    Row(
                      children: [
                        Expanded(
                          child: _textField(
                            _directSavingsController,
                            _goals.isNotEmpty && _goals.any((g) => g.id == _selectedGoalId)
                                ? 'Cantidad para "${_goals.firstWhere((g) => g.id == _selectedGoalId).name}"'
                                : 'Cantidad para meta',
                            prefix: '\$ ',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            onPressed: (){
                              if (_goals.firstWhere((g) => g.id == _selectedGoalId).remainingAmount < int.parse(_directSavingsController.text.replaceAll(",", ""))){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("El monto es mayor al restante de la meta")),
                                );
                              }else{
                                _addDirectSavings();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const FullScreenLoading(),
                                );
                              }

                            },
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
                const SizedBox(height: 65),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Color(0xFF2a5298),
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        style: const TextStyle(color: Colors.white),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {String prefix = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixText: prefix,
          prefixStyle: const TextStyle(color: Colors.white),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),
    );
  }
}
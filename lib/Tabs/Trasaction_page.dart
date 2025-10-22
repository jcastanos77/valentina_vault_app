import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valentinas_vault/Utils/showSnackBar.dart';

import '../Utils/CurrencyInputFormatter.dart';
import '../Utils/ModernCard.dart';
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

  late AnimationController _animationController;

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
    double amount = double.tryParse(_directSavingsController.text) ?? 0;
    if (amount <= 0) return;

    try {
      String? token = await _authService.getToken();
      await _apiService.addDirectSaving(token!, amount);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ahorro agregado ✅")),
      );

      _animationController.forward().then((_) => _animationController.reset());
      _amountController.clear();
      _descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
    _directSavingsController.clear();
    showSnackBar('Ahorro agregado 💰', const Color(0xFF3498DB), context);
  }

  Future<void> _submitIncome() async {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor ingresa monto y descripción")),
      );
      return;
    }
    print(amountText);
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
      await _apiService.addIncome(amount, description, token!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ingreso agregado ✅")),
      );

      _animationController.forward().then((_) => _animationController.reset());
      _amountController.clear();
      _descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitExpense() async {
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
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
                      'Ahorro Directo 💰',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _textField(_directSavingsController, 'Cantidad a ahorrar', prefix: '\$ ')),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            onPressed: _addDirectSavings,
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
        dropdownColor: Colors.black87,
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
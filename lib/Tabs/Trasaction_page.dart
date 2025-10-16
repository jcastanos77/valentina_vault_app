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
  int _currentIndex = 0;
  bool isLoading = false;
  final _apiService = ApiService();
  final _authService = AuthService();
  final _directSavingsController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _basicosPercent = 0;
  int _ahorroPercent = 0;
  int _lujosPercent = 0;

  bool _hasShownMonthlyTransfer = false;
  DateTime _currentMonth = DateTime.now();
  late AnimationController _animationController;

  double _totalIncome = 0;
  List<Transaction> _transactions = [];
  List<Transaction> _allTransactions = [];
  String _selectedTransactionType = 'expense';
  String _selectedCategory = 'basicos';
  double _accumulatedSavings = 0;

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

  void _checkMonthlyTransfer() {
    DateTime now = DateTime.now();

    // Si cambió el mes y hay transacciones del mes anterior
    if (_currentMonth.month != now.month || _currentMonth.year != now.year) {
      if (_totalIncome > 0 && !_hasShownMonthlyTransfer) {
        _performMonthlyTransfer();
      }
      _currentMonth = now;
    }
  }

  void _performMonthlyTransfer() {
    // Calcular sobrantes del mes anterior
    double basicosRemaining = budgets['basicos']! - (spentByCategory['basicos'] ?? 0);
    double lujosRemaining = budgets['lujos']! - (spentByCategory['lujos'] ?? 0);

    double totalTransfer = 0;
    if (basicosRemaining > 0) totalTransfer += basicosRemaining;
    if (lujosRemaining > 0) totalTransfer += lujosRemaining;

    // Agregar ahorros directos al total acumulado
    double ahorrosDirectosMes = _transactions
        .where((t) => t.type == 'saving')
        .fold(0, (sum, t) => sum + t.amount);

    if (ahorrosDirectosMes > 0) {
      _accumulatedSavings += ahorrosDirectosMes;
    }

    if (totalTransfer > 0) {
      // Agregar transacción de transferencia automática
      _allTransactions.addAll(_transactions);
      _transactions.add(Transaction(
        id: 'monthly_transfer_${DateTime.now().millisecondsSinceEpoch}',
        type: 'transfer', // Nuevo tipo para transferencias automáticas
        category: 'ahorro',
        amount: totalTransfer,
        description: 'Transferencia mensual automática',
        date: DateTime.now(),
      ));

      _accumulatedSavings += totalTransfer;

      // Mostrar notificación de transferencia
      Future.delayed(const Duration(milliseconds: 500), () {
        _showMonthlyTransferDialog(totalTransfer, basicosRemaining, lujosRemaining, ahorrosDirectosMes);
      });
    } else if (ahorrosDirectosMes > 0) {
      // Solo mostrar si hubo ahorros directos pero no transferencia
      Future.delayed(const Duration(milliseconds: 500), () {
        _showMonthlyTransferDialog(0, 0, 0, ahorrosDirectosMes);
      });
    }

    // Reiniciar para el nuevo mes (limpiar todas las transacciones del mes)
    _allTransactions.addAll(_transactions);
    _transactions.clear();
    _totalIncome = 0; // Reiniciar ingresos
    _hasShownMonthlyTransfer = true;

    setState(() {});
  }

  Future<void> _submitIncome() async {
    _checkMonthlyTransfer();
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
    _checkMonthlyTransfer();
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
  void _showMonthlyTransferDialog(double total, double basicos, double lujos, double ahorroDirecto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Color(0xFF27AE60),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¡Transferencia Automática!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sobrantes transferidos al ahorro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (basicos > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sobrante Necesidades:'),
                    Text(
                      '+\${basicos.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (lujos > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sobrante Deseos:'),
                    Text(
                      '+\${lujos.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '¡Nuevo mes, nuevas oportunidades!\nAgrega tus ingresos para este mes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _currentIndex = 1); // Ir a agregar transacciones
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Agregar Ingresos'),
            ),
          ],
        );
      },
    );
  }

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
    _checkMonthlyTransfer();
    _setPorcentages();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Nueva transacción',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 24),

          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de transacción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTransactionType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('💰 Ingreso')),
                      DropdownMenuItem(value: 'expense', child: Text('💳 Gasto')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionType = value!;
                      });
                    },
                  ),
                ),

                if (_selectedTransactionType == 'expense') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Categoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [
                        DropdownMenuItem(value: 'basicos', child: Text('🏠 Necesidades ($_basicosPercent%)')),
                        DropdownMenuItem(value: 'ahorro', child: Text('💰 Ahorros ($_ahorroPercent%)')),
                        DropdownMenuItem(value: 'lujos', child: Text('🛍️ Deseos ($_lujosPercent%)')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                const Text(
                  'Cantidad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixText: '\$ ',
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      CurrencyInputFormatter(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: 'Ej: Supermercado, Salario...',
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedTransactionType == 'expense' ? _submitExpense : _submitIncome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Agregar Transacción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ahorro directo con diseño moderno
          ModernCard(
            color: const Color(0xFF3498DB).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.savings_rounded,
                      color: Color(0xFF3498DB),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Ahorro Directo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextFormField(
                          controller: _directSavingsController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            prefixText: '\$ ',
                            hintText: 'Cantidad a ahorrar',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            CurrencyInputFormatter(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: _addDirectSavings,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:valentinas_vault/services/Auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Variables para la fórmula de presupuesto
  bool _useDefaultBudget = true;
  double _basicosPercent = 50;
  double _lujosPercent = 30;
  double _ahorroPercent = 20;

  // Para el indicador de fuerza de contraseña
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    _passwordController.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _evaluatePasswordStrength() {
    String password = _passwordController.text;
    double strength = 0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }

    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$%\^&\*]').hasMatch(password)) strength += 0.25;

    strength = strength.clamp(0.0, 1.0);

    setState(() {
      _passwordStrength = strength;

      if (strength <= 0.25) {
        _passwordStrengthText = 'Muy débil';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _passwordStrengthText = 'Débil';
        _passwordStrengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _passwordStrengthText = 'Media';
        _passwordStrengthColor = Colors.amber;
      } else {
        _passwordStrengthText = 'Fuerte';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _adjustBudgetPercentages(String category, double value) {
    setState(() {
      if (category == 'basicos') {
        _basicosPercent = value;
        // Ajustar los otros dos manteniendo las restricciones
        double remaining = 100 - _basicosPercent;

        // Mantener lujos entre 10-30%
        if (_lujosPercent > remaining - 10) {
          _lujosPercent = remaining - 10;
        }
        if (_lujosPercent < 10) {
          _lujosPercent = 10;
        }
        if (_lujosPercent > 30) {
          _lujosPercent = 30;
        }

        _ahorroPercent = remaining - _lujosPercent;
      } else if (category == 'lujos') {
        _lujosPercent = value;
        double remaining = 100 - _lujosPercent;

        // Mantener ahorro entre 10-60%
        if (_ahorroPercent > remaining - 10) {
          _ahorroPercent = remaining - 10;
        }
        if (_ahorroPercent < 10) {
          _ahorroPercent = 10;
        }
        if (_ahorroPercent > 60) {
          _ahorroPercent = 60;
        }

        _basicosPercent = remaining - _ahorroPercent;
      } else if (category == 'ahorro') {
        _ahorroPercent = value;
        double remaining = 100 - _ahorroPercent;

        // Mantener lujos entre 10-30%
        if (_lujosPercent > remaining - 10) {
          _lujosPercent = remaining - 10;
        }
        if (_lujosPercent < 10) {
          _lujosPercent = 10;
        }
        if (_lujosPercent > 30) {
          _lujosPercent = 30;
        }

        _basicosPercent = remaining - _lujosPercent;
      }
    });
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos', isError: true);
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showSnackBar('Por favor ingresa un email válido', isError: true);
      return false;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('La contraseña debe tener al menos 8 caracteres', isError: true);
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden', isError: true);
      return false;
    }

    if (!_acceptTerms) {
      _showSnackBar('Debes aceptar los términos y condiciones', isError: true);
      return false;
    }

    // Validar que los porcentajes sumen 100
    double total = _basicosPercent + _lujosPercent + _ahorroPercent;
    if ((total - 100).abs() > 0.1) {
      _showSnackBar('Los porcentajes deben sumar 100%', isError: true);
      return false;
    }

    return true;
  }

  Future<void> _register() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final success = await _authService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _basicosPercent as int,
      _lujosPercent as int,
      _ahorroPercent as int
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSnackBar('¡Registro exitoso! Ahora puedes iniciar sesión', isError: false);
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    } else {
      _showSnackBar('Error en el registro. Intenta de nuevo', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showBudgetInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '💡 ¿Qué significan estas categorías?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoItem(
                icon: Icons.home_outlined,
                title: 'Básicos',
                description: 'Gastos esenciales como renta, comida, servicios, transporte y medicinas. Todo lo necesario para vivir.',
                color: const Color(0xFF6B5B95),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Lujos',
                description: 'Gastos no esenciales como entretenimiento, restaurantes, compras, viajes y hobbies. Todo lo que te da placer.',
                color: const Color(0xFF88B0D3),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.savings_outlined,
                title: 'Ahorro',
                description: 'Dinero que guardas para el futuro, emergencias, inversiones o metas a largo plazo.',
                color: const Color(0xFF82C0CC),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(
                color: Color(0xFF6B5B95),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B5B95),
              Color(0xFF88B0D3),
              Color(0xFF82C0CC),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          _buildRegisterForm(),
                          const SizedBox(height: 24),
                          _buildBudgetSection(),
                          const SizedBox(height: 30),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 30),
                          _buildRegisterButton(),
                          const SizedBox(height: 20),
                          _buildLoginLink(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Únete a Valentina\'s Vault',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            hint: 'Nombre completo',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            hint: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            hint: 'Contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            showPasswordToggle: true,
            obscureText: _obscurePassword,
            onTogglePassword: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Confirmar contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
            showPasswordToggle: true,
            obscureText: _obscureConfirmPassword,
            onTogglePassword: () {
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '💰 Tu Fórmula de Presupuesto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B5B95),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Color(0xFF6B5B95)),
                onPressed: _showBudgetInfoDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Opción: Usar fórmula por defecto
          Container(
            decoration: BoxDecoration(
              color: _useDefaultBudget
                  ? const Color(0xFF6B5B95).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _useDefaultBudget
                    ? const Color(0xFF6B5B95)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: RadioListTile<bool>(
              value: true,
              groupValue: _useDefaultBudget,
              onChanged: (value) {
                setState(() {
                  _useDefaultBudget = value!;
                  if (_useDefaultBudget) {
                    _basicosPercent = 50;
                    _lujosPercent = 30;
                    _ahorroPercent = 20;
                  }
                });
              },
              title: const Text(
                'Usar fórmula recomendada',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('50% Básicos, 30% Lujos, 20% Ahorro'),
              activeColor: const Color(0xFF6B5B95),
            ),
          ),

          const SizedBox(height: 12),

          // Opción: Personalizar
          Container(
            decoration: BoxDecoration(
              color: !_useDefaultBudget
                  ? const Color(0xFF6B5B95).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !_useDefaultBudget
                    ? const Color(0xFF6B5B95)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: RadioListTile<bool>(
              value: false,
              groupValue: _useDefaultBudget,
              onChanged: (value) {
                setState(() => _useDefaultBudget = value!);
              },
              title: const Text(
                'Personalizar mi fórmula',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Ajusta los porcentajes a tu medida'),
              activeColor: const Color(0xFF6B5B95),
            ),
          ),

          // Sliders personalizados (solo si no usa default)
          if (!_useDefaultBudget) ...[
            const SizedBox(height: 24),
            const Text(
              'Ajusta tus porcentajes:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildBudgetSlider(
              label: 'Básicos',
              value: _basicosPercent,
              icon: Icons.home_outlined,
              color: const Color(0xFF6B5B95),
              onChanged: (value) => _adjustBudgetPercentages('basicos', value),
              min: 10,
              max: 80,
            ),

            const SizedBox(height: 16),

            _buildBudgetSlider(
              label: 'Lujos',
              value: _lujosPercent,
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFF88B0D3),
              onChanged: (value) => _adjustBudgetPercentages('lujos', value),
              min: 10,
              max: 30,
            ),

            const SizedBox(height: 16),

            _buildBudgetSlider(
              label: 'Ahorro',
              value: _ahorroPercent,
              icon: Icons.savings_outlined,
              color: const Color(0xFF82C0CC),
              onChanged: (value) => _adjustBudgetPercentages('ahorro', value),
              min: 10,
              max: 60,
            ),

            const SizedBox(height: 16),

            // Resumen total
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${(_basicosPercent + _lujosPercent + _ahorroPercent).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: (_basicosPercent + _lujosPercent + _ahorroPercent - 100).abs() < 0.1
                          ? Colors.green
                          : Colors.red,
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

  Widget _buildBudgetSlider({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.3),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 5).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool showPasswordToggle = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF6B5B95),
          ),
          suffixIcon: showPasswordToggle
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onTogglePassword,
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _passwordStrengthText,
              style: TextStyle(
                color: _passwordStrengthColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Usa 8+ caracteres, mayúsculas, números y símbolos',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() => _acceptTerms = value ?? false);
              },
              activeColor: const Color(0xFF6B5B95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'términos y condiciones',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'política de privacidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
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

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B5B95), Color(0xFF88B0D3)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B5B95).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _register,
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Ya tienes una cuenta? ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Inicia Sesión',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
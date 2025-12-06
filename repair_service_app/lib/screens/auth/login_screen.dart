import 'package:flutter/material.dart';
import 'package:repair_service_app/config/app_config.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/utils/validators.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';
import 'package:repair_service_app/widgets/dialogs/alert_dialog.dart';
import 'package:repair_service_app/widgets/forms/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final String username = _usernameController.text.trim();
      final String password = _passwordController.text;
      
      final response = await _authService.login(username, password);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (response.success && response.data != null) {
        final User user = response.data!;
        
        if (!mounted) return;
        
        // Navegar a la pantalla correspondiente según el rol del usuario
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.getInitialRouteByRole(user.role),
        );
      } else {
        if (!mounted) return;
        
        // Mostrar mensaje de error
        showErrorDialog(
          context: context,
          title: 'Error de inicio de sesión',
          message: response.message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        showErrorDialog(
          context: context,
          title: 'Error',
          message: 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const FullscreenLoadingIndicator(
              message: 'Iniciando sesión...',
            ),
        ],
      ),
    );
  }
  
  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
            AppTheme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.3, 0.6],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              // Mientras no se tenga la imagen real, usar un placeholder
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.home_repair_service,
                  size: 60,
                  color: AppTheme.primaryColor,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Título
        Text(
          AppConfig.appName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Subtítulo
        Text(
          AppConfig.companyName,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Usuario',
              hint: 'Ingresa tu nombre de usuario',
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person,
              validator: Validators.validateRequired,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock,
              validator: Validators.validateRequired,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const Text('Recordarme'),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Implementar recuperación de contraseña si es necesario
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Información de contacto o ayuda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '¿Necesitas ayuda? Contacta al administrador',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
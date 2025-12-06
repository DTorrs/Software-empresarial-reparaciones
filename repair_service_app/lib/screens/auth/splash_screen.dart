import 'package:flutter/material.dart';
import 'package:repair_service_app/config/app_config.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
    
    _checkAuthStatus();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 2000)); // Mostrar splash mínimo 2 segundos
    
    final bool isLoggedIn = await _authService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      final response = await _authService.verifyToken();
      
      if (response.success && response.data != null) {
        final userRole = response.data!.role;
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.getInitialRouteByRole(userRole),
        );
      } else {
        // Token inválido, redirigir a login
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      // No hay sesión, redirigir a login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de la empresa
                    Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                      // Mientras no se tenga la imagen real, usar un placeholder
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_repair_service,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.companyName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
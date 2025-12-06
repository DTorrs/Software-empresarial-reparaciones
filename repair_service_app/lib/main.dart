import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:repair_service_app/config/app_config.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/providers/auth_provider.dart';
import 'package:repair_service_app/providers/location_provider.dart';
import 'package:repair_service_app/providers/service_provider.dart';
import 'package:repair_service_app/providers/user_provider.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Establecer orientación preferida
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Personalizar la barra de navegación y estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const RepairServiceApp());
}

class RepairServiceApp extends StatelessWidget {
  const RepairServiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers para gestión de estado
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        // Configuración de rutas
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: AppRoutes.generateRoute,
        // Mostrar ícono de debug solo en modo desarrollo
        debugShowMaterialGrid: false,
        // Configuración de localización
        locale: const Locale('es', 'MX'),
        // Configuración de animaciones
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          // Ajustar escala de texto
          final scale = mediaQueryData.textScaleFactor.clamp(0.9, 1.1);
          return MediaQuery(
            data: mediaQueryData.copyWith(textScaleFactor: scale),
            child: child!,
          );
        },
      ),
    );
  }
}

// Clase para implementar GlobalKey de ScaffoldMessengerState para mensajes globales
class GlobalScaffoldKey {
  static final GlobalKey<ScaffoldMessengerState> key = GlobalKey<ScaffoldMessengerState>();

  // Mostrar mensaje
  static void showSnackBar(String message, {bool isError = false}) {
    key.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mostrar mensaje de error
  static void showErrorSnackBar(String message) {
    showSnackBar(message, isError: true);
  }

  // Mostrar mensaje de éxito
  static void showSuccessSnackBar(String message) {
    showSnackBar(message, isError: false);
  }
}
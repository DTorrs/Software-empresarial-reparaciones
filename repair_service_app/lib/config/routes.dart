import 'package:flutter/material.dart';

// Auth screens
import 'package:repair_service_app/screens/auth/login_screen.dart';
import 'package:repair_service_app/screens/auth/splash_screen.dart';

// Admin screens
import 'package:repair_service_app/screens/admin/admin_dashboard.dart';
import 'package:repair_service_app/screens/admin/admin_users_screen.dart';
import 'package:repair_service_app/screens/admin/admin_technicians_screen.dart';
import 'package:repair_service_app/screens/admin/admin_locations_screen.dart';
import 'package:repair_service_app/screens/admin/admin_reports_screen.dart';
import 'package:repair_service_app/screens/admin/admin_payments_screen.dart';

// Secretary screens
import 'package:repair_service_app/screens/secretary/secretary_dashboard.dart';
import 'package:repair_service_app/screens/secretary/secretary_new_service_screen.dart';
import 'package:repair_service_app/screens/secretary/secretary_service_details_screen.dart';
import 'package:repair_service_app/screens/secretary/secretary_assign_technician_screen.dart';
import 'package:repair_service_app/screens/secretary/secretary_warranty_screen.dart';
import 'package:repair_service_app/screens/secretary/secretary_clients_screen.dart';

// Technician screens
import 'package:repair_service_app/screens/technician/technician_dashboard.dart';
import 'package:repair_service_app/screens/technician/technician_service_details_screen.dart';
import 'package:repair_service_app/screens/technician/technician_upload_photos_screen.dart';
import 'package:repair_service_app/screens/technician/technician_create_quote_screen.dart';
import 'package:repair_service_app/screens/technician/technician_payments_screen.dart';

// Models
import 'package:repair_service_app/models/service.dart';

class AppRoutes {
  // Nombres de rutas
  static const String splash = '/';
  static const String login = '/login';
  
  // Rutas de admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminTechnicians = '/admin/technicians';
  static const String adminLocations = '/admin/locations';
  static const String adminReports = '/admin/reports';
  static const String adminPayments = '/admin/payments';
  
  // Rutas de secretaria
  static const String secretaryDashboard = '/secretary/dashboard';
  static const String secretaryNewService = '/secretary/service/new';
  static const String secretaryServiceDetails = '/secretary/service/details';
  static const String secretaryAssignTechnician = '/secretary/service/assign';
  static const String secretaryWarranty = '/secretary/service/warranty';
  static const String secretaryClients = '/secretary/clients';
  
  
  
  // Rutas de técnico
  static const String technicianDashboard = '/technician/dashboard';
  static const String technicianServiceDetails = '/technician/service/details';
  static const String technicianUploadPhotos = '/technician/service/photos';
  static const String technicianCreateQuote = '/technician/service/quote';
  static const String technicianPayments = '/technician/payments';
  
  // Mapa de rutas para la configuración de MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      // Auth routes
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      
      // Admin routes
      adminDashboard: (context) => const AdminDashboard(),
      adminUsers: (context) => const AdminUsersScreen(),
      adminTechnicians: (context) => const AdminTechniciansScreen(),
      adminLocations: (context) => const AdminLocationsScreen(),
      adminReports: (context) => const AdminReportsScreen(),
      adminPayments: (context) => const AdminPaymentsScreen(),
      
      // Secretary routes - basic routes without parameters
      secretaryDashboard: (context) => const SecretaryDashboard(),
      secretaryNewService: (context) => const SecretaryNewServiceScreen(),
      secretaryWarranty: (context) => const SecretaryWarrantyScreen(),
      secretaryClients: (context) => const SecretaryClientsScreen(),
      
      // Technician routes - basic routes without parameters
      technicianDashboard: (context) => const TechnicianDashboard(),
      technicianPayments: (context) => const TechnicianPaymentsScreen(),
    };
  }
  
  // Generador de rutas para rutas dinámicas o con parámetros
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extraer argumentos si existen
    final args = settings.arguments;
    
    switch (settings.name) {
      // Auth Routes
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
        
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      // Admin Routes
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
        
      case adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
        
      case adminTechnicians:
        return MaterialPageRoute(builder: (_) => const AdminTechniciansScreen());
        
      case adminLocations:
        return MaterialPageRoute(builder: (_) => const AdminLocationsScreen());
        
      case adminReports:
        return MaterialPageRoute(builder: (_) => const AdminReportsScreen());
        
      case adminPayments:
        return MaterialPageRoute(builder: (_) => const AdminPaymentsScreen());
        
      // Secretary Routes
      case secretaryDashboard:
        return MaterialPageRoute(builder: (_) => const SecretaryDashboard());
        
      case secretaryNewService:
        return MaterialPageRoute(builder: (_) => const SecretaryNewServiceScreen());
        
      case secretaryWarranty:
        return MaterialPageRoute(builder: (_) => const SecretaryWarrantyScreen());
        
      case secretaryClients:
        return MaterialPageRoute(builder: (_) => const SecretaryClientsScreen());
        
      case secretaryServiceDetails:
        // Check if we have a service ID
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => SecretaryServiceDetailsScreen(serviceId: args),
          );
        }
        // Error handling
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Se requiere el ID del servicio')),
          ),
        );
        
      case secretaryAssignTechnician:
        // Check if we have a service ID
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => SecretaryAssignTechnicianScreen(serviceId: args),
          );
        // If no args, use the default constructor
        } else if (args == null) {
          return MaterialPageRoute(builder: (_) => const SecretaryAssignTechnicianScreen());
        }
        // Error handling
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Parámetros incorrectos')),
          ),
        );
        
      // Technician Routes
      case technicianDashboard:
        return MaterialPageRoute(builder: (_) => const TechnicianDashboard());
        
      case technicianServiceDetails:
        // Check if we have a service ID
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => TechnicianServiceDetailsScreen(serviceId: args),
          );
        }
        // Error handling
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Error: Se requiere el ID del servicio')),
          ),
        );
        
      case technicianUploadPhotos:
        // For TechnicianUploadPhotosScreen we need specific parameters as a Map
        if (args is Map<String, dynamic> && 
            args.containsKey('service') && 
            args.containsKey('photoType') && 
            args.containsKey('onPhotosUploaded')) {
          return MaterialPageRoute(
            builder: (_) => TechnicianUploadPhotosScreen(
              service: args['service'],
              photoType: args['photoType'],
              onPhotosUploaded: args['onPhotosUploaded'],
            ),
          );
        }
        // Error handling
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Error: Se requieren parámetros completos para subir fotos'),
            ),
          ),
        );
        
      case technicianCreateQuote:
        // The constructor only takes serviceId
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => TechnicianCreateQuoteScreen(serviceId: args),
          );
        }
        // Error handling
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Error: Se requiere el ID del servicio'),
            ),
          ),
        );
        
      case technicianPayments:
        return MaterialPageRoute(builder: (_) => const TechnicianPaymentsScreen());
  
      default:
        // Si la ruta no está definida, mostrar pantalla de error
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('Ruta no encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  // Navegación basada en rol
  static String getInitialRouteByRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminDashboard;
      case 'secretary':
        return secretaryDashboard;
      case 'technician':
        return technicianDashboard;
      default:
        return login;
    }
  }
  
  // Helper methods for navigating to screens with complex parameters
  
  // Helper for navigating to the technician upload photos screen
  static void navigateToTechnicianUploadPhotos(
    BuildContext context,
    Service service,
    String photoType,
    Function onPhotosUploaded,
  ) {
    Navigator.pushNamed(
      context,
      technicianUploadPhotos,
      arguments: {
        'service': service,
        'photoType': photoType,
        'onPhotosUploaded': onPhotosUploaded,
      },
    );
  }
}
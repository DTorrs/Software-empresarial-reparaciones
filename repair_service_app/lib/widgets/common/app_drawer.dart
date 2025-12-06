import 'package:flutter/material.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/config/routes.dart';

class AppDrawer extends StatelessWidget {
  final User user;
  final String? currentRoute;
  final AuthService authService;
  
  // Changed constructor approach to handle AuthService
  const AppDrawer({
    Key? key,
    required this.user,
    this.currentRoute,
    required this.authService,
  }) : super(key: key);
  
  // Factory constructor that provides default AuthService
  factory AppDrawer.withDefaultAuth({
    required User user,
    String? currentRoute,
    Key? key,
  }) {
    return AppDrawer(
      key: key,
      user: user,
      currentRoute: currentRoute,
      authService: AuthService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          _buildMenuItems(context),
          const Divider(),
          _buildLogoutButton(context),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      accountName: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      accountEmail: Text(
        user.email,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 30.0,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      otherAccountsPictures: [
        Tooltip(
          message: 'Rol: ${_getRoleName(user.role)}',
          child: CircleAvatar(
            backgroundColor: Colors.white70,
            child: Icon(
              _getRoleIcon(user.role),
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuItems(BuildContext context) {
    // Obtener los elementos de menú según el rol del usuario
    final List<DrawerMenuItem> menuItems = _getMenuItemsByRole(user.role);
    
    return Column(
      children: menuItems.map((item) {
        final bool isSelected = currentRoute == item.route;
        
        return ListTile(
          leading: Icon(
            item.icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
          ),
          title: Text(
            item.title,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          tileColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          onTap: () {
            Navigator.pop(context); // Cerrar drawer
            
            if (currentRoute != item.route) {
              Navigator.pushReplacementNamed(context, item.route);
            }
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.exit_to_app,
        color: Colors.red,
      ),
      title: const Text(
        'Cerrar Sesión',
        style: TextStyle(
          color: Colors.red,
        ),
      ),
      onTap: () => _showLogoutConfirmation(context),
    );
  }
  
  // Mostrar diálogo de confirmación de cierre de sesión
  Future<void> _showLogoutConfirmation(BuildContext context) async {
    Navigator.pop(context); // Cerrar drawer
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'CERRAR SESIÓN',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      await authService.logout();
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }
  
  // Obtener nombre amigable del rol
  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'secretary':
        return 'Secretaria';
      case 'technician':
        return 'Técnico';
      default:
        return role.capitalize();
    }
  }
  
  // Obtener ícono según rol
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'secretary':
        return Icons.manage_accounts;
      case 'technician':
        return Icons.engineering;
      default:
        return Icons.person;
    }
  }
  
  // Obtener elementos del menú según rol
  List<DrawerMenuItem> _getMenuItemsByRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [
          DrawerMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            route: AppRoutes.adminDashboard,
          ),
          DrawerMenuItem(
            title: 'Usuarios',
            icon: Icons.people,
            route: AppRoutes.adminUsers,
          ),
          DrawerMenuItem(
            title: 'Técnicos',
            icon: Icons.engineering,
            route: AppRoutes.adminTechnicians,
          ),
          DrawerMenuItem(
            title: 'Ubicaciones',
            icon: Icons.location_on,
            route: AppRoutes.adminLocations,
          ),
          DrawerMenuItem(
            title: 'Pagos',
            icon: Icons.payments,
            route: AppRoutes.adminPayments,
          ),
          DrawerMenuItem(
            title: 'Reportes',
            icon: Icons.bar_chart,
            route: AppRoutes.adminReports,
          ),
        ];
      
      case 'secretary':
        return [
          DrawerMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            route: AppRoutes.secretaryDashboard,
          ),
          DrawerMenuItem(
            title: 'Nuevo Servicio',
            icon: Icons.add_circle,
            route: AppRoutes.secretaryNewService,
          ),
          DrawerMenuItem(
            title: 'Servicios',
            icon: Icons.home_repair_service,
            route: AppRoutes.secretaryServiceDetails,
          ),
          DrawerMenuItem(
            title: 'Clientes',
            icon: Icons.people,
            route: AppRoutes.secretaryClients,
          ),
          DrawerMenuItem(
            title: 'Garantías',
            icon: Icons.verified,
            route: AppRoutes.secretaryWarranty,
          ),
        ];
      
      case 'technician':
        return [
          DrawerMenuItem(
            title: 'Dashboard',
            icon: Icons.dashboard,
            route: AppRoutes.technicianDashboard,
          ),
          DrawerMenuItem(
            title: 'Mis Servicios',
            icon: Icons.home_repair_service,
            route: AppRoutes.technicianServiceDetails,
          ),
          DrawerMenuItem(
            title: 'Mis Pagos',
            icon: Icons.payments,
            route: AppRoutes.technicianPayments,
          ),
        ];
      
      default:
        return [];
    }
  }
}

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final String route;
  
  const DrawerMenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

// Extensión para capitalizar la primera letra
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
import 'package:flutter/material.dart';
import 'package:repair_service_app/config/routes.dart';
import 'package:repair_service_app/config/theme.dart';
import 'package:repair_service_app/models/user.dart';
import 'package:repair_service_app/services/auth_service.dart';
import 'package:repair_service_app/widgets/common/app_drawer.dart';
import 'package:repair_service_app/widgets/common/custom_app_bar.dart';
import 'package:repair_service_app/widgets/common/loading_indicator.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({Key? key}) : super(key: key);

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _authService.verifyToken();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _currentUser = response.data;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Cargando dashboard...'),
      );
    }
    
    if (_currentUser == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Error',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar la información del usuario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadUserData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard Secretaria',
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: null,
          ),
        ],
      ),
      drawer: AppDrawer(
  user: _currentUser!,
  currentRoute: '/secretary/dashboard',
  authService: _authService,  // Añadir esta línea
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.secretaryNewService);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              _buildQuickActionsGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Servicios por Estado'),
              const SizedBox(height: 8),
              _buildServiceStatusCards(),
              const SizedBox(height: 24),
              _buildSectionTitle('Servicios Recientes'),
              const SizedBox(height: 8),
              _buildRecentServicesList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Garantías Pendientes'),
              const SizedBox(height: 8),
              _buildPendingWarrantiesList(),
              const SizedBox(height: 80), // Espacio para el FAB
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWelcomeCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                radius: 24,
                child: Text(
                  _currentUser!.name.isNotEmpty 
                      ? _currentUser!.name[0].toUpperCase() 
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${_currentUser!.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rol: Secretaria',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoBadge(
                  'Asignados Hoy', 
                  '8', 
                  AppTheme.assignedServiceColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBadge(
                  'En Garantía', 
                  '3', 
                  AppTheme.warrantyServiceColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoBadge(
                  'Pendientes', 
                  '12', 
                  AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildInfoBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionsGrid() {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    childAspectRatio: 0.8, // Taller cells
    crossAxisSpacing: 16,
    mainAxisSpacing: 16,
    children: [
      _buildActionCard('Nuevo Servicio', Icons.add_circle, AppTheme.primaryColor, () => Navigator.pushNamed(context, AppRoutes.secretaryNewService)),
      _buildActionCard('Asignar Técnico', Icons.assignment_ind, AppTheme.assignedServiceColor, () => Navigator.pushNamed(context, AppRoutes.secretaryAssignTechnician)),
      _buildActionCard('Crear Garantía', Icons.verified, AppTheme.warrantyServiceColor, () => Navigator.pushNamed(context, AppRoutes.secretaryWarranty)),
      _buildActionCard('Ver Clientes', Icons.people, Colors.teal, () => Navigator.pushNamed(context, AppRoutes.secretaryClients)),
      _buildActionCard('Buscar Servicio', Icons.search, Colors.indigo, () {}),
      _buildActionCard('Reportes', Icons.bar_chart, Colors.deepOrange, () {}),
    ],
  );
}
  
  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildServiceStatusCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.0,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildStatusCard(
          'Nuevos',
          '5',
          AppTheme.newServiceColor,
          Icons.fiber_new,
        ),
        _buildStatusCard(
          'Asignados',
          '12',
          AppTheme.assignedServiceColor,
          Icons.assignment_ind,
        ),
        _buildStatusCard(
          'En Progreso',
          '7',
          AppTheme.inProgressServiceColor,
          Icons.build,
        ),
        _buildStatusCard(
          'Completado',
          '18',
          AppTheme.completedServiceColor,
          Icons.check_circle,
        ),
        _buildStatusCard(
          'Cancelados',
          '2',
          AppTheme.cancelledServiceColor,
          Icons.cancel,
        ),
        _buildViewAllCard(() {}),
      ],
    );
  }
  
  Widget _buildStatusCard(
    String status,
    String count,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navegar a la lista de servicios con este estado
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildViewAllCard(VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[700],
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ver Todos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecentServicesList() {
    // Lista de servicios recientes
    final List<Map<String, dynamic>> services = [
      {
        'id': 125,
        'client': 'Ana Rodríguez',
        'device': 'Refrigerador Samsung',
        'status': 'new',
        'issue': 'No enfría correctamente',
        'date': 'Hoy, 10:30 AM',
      },
      {
        'id': 124,
        'client': 'Carlos Gómez',
        'device': 'Lavadora LG',
        'status': 'assigned',
        'issue': 'No desagua',
        'date': 'Hoy, 09:15 AM',
      },
      {
        'id': 123,
        'client': 'María López',
        'device': 'Televisor Sony',
        'status': 'in_progress',
        'issue': 'No enciende',
        'date': 'Ayer',
      },
      {
        'id': 122,
        'client': 'Juan Pérez',
        'device': 'Horno de Microondas',
        'status': 'completed',
        'issue': 'No calienta',
        'date': 'Ayer',
      },
    ];
    
    if (services.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay servicios recientes'),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final service = services[index];
          return ListTile(
            title: Row(
              children: [
                Text(
                  'Servicio #${service['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(service['status']),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${service['device']} - ${service['client']}',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                Text(
                  service['issue'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service['date'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ),
            onTap: () {
              // Navegar a los detalles del servicio
            },
          );
        },
      ),
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'new':
        color = AppTheme.newServiceColor;
        text = 'Nuevo';
        break;
      case 'assigned':
        color = AppTheme.assignedServiceColor;
        text = 'Asignado';
        break;
      case 'in_progress':
        color = AppTheme.inProgressServiceColor;
        text = 'En Progreso';
        break;
      case 'completed':
        color = AppTheme.completedServiceColor;
        text = 'Completado';
        break;
      case 'cancelled':
        color = AppTheme.cancelledServiceColor;
        text = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconocido';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPendingWarrantiesList() {
    // Lista de garantías pendientes
    final List<Map<String, dynamic>> warranties = [
      {
        'id': 45,
        'original_id': 89,
        'client': 'Pedro Sánchez',
        'device': 'Aire Acondicionado Carrier',
        'issue': 'Volvió a presentar fuga',
        'date': 'Hace 2 días',
      },
      {
        'id': 43,
        'original_id': 76,
        'client': 'Laura Martínez',
        'device': 'Refrigerador Whirlpool',
        'issue': 'No mantiene la temperatura',
        'date': 'Hace 5 días',
      },
      {
        'id': 42,
        'original_id': 68,
        'client': 'Roberto Díaz',
        'device': 'Lavadora Mabe',
        'issue': 'Sigue sin centrifugar',
        'date': 'Hace 1 semana',
      },
    ];
    
    if (warranties.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay garantías pendientes'),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warrantyServiceColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: AppTheme.warrantyServiceColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Garantías que requieren atención',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warrantyServiceColor,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: warranties.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final warranty = warranties[index];
              return ListTile(
                title: Row(
                  children: [
                    Text(
                      'Garantía #${warranty['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(Original #${warranty['original_id']})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${warranty['device']} - ${warranty['client']}',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      warranty['issue'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      warranty['date'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                onTap: () {
                  // Navegar a los detalles de la garantía
                },
              );
            },
          ),
        ],
      ),
    );
  }
}